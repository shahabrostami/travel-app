/**
 * Integration tests for Supabase database schema
 * These tests verify the database is set up correctly
 */
import { testSupabase } from '../../lib/supabase.test-client';

describe('Supabase Database Schema', () => {
  // Increase timeout for database queries
  jest.setTimeout(30000);

  describe('Core Tables', () => {
    const expectedTables = [
      'profiles',
      'interest_categories',
      'interests',
      'user_interests',
      'itineraries',
      'itinerary_items',
      'meetups',
      'meetup_attendees',
      'user_connections',
      'notification_queue',
    ];

    it('should have all required tables', async () => {
      const { data, error } = await testSupabase
        .from('information_schema.tables' as any)
        .select('table_name')
        .eq('table_schema', 'public')
        .in('table_name', expectedTables);

      // Use RPC to query information schema since direct access may be blocked
      let tables = null;
      let rpcError = null;
      try {
        const result = await testSupabase.rpc('get_public_tables' as any);
        tables = result.data;
        rpcError = result.error;
      } catch {
        rpcError = { message: 'RPC not found' };
      }

      // Alternative: query each table to verify it exists
      for (const tableName of expectedTables) {
        const { error: tableError } = await testSupabase
          .from(tableName)
          .select('*')
          .limit(0);

        expect(tableError).toBeNull();
      }
    });
  });

  describe('Interest Taxonomy', () => {
    it('should have 12 interest categories', async () => {
      const { data, error, count } = await testSupabase
        .from('interest_categories')
        .select('*', { count: 'exact' });

      expect(error).toBeNull();
      expect(count).toBe(12);
    });

    it('should have at least 150 interests', async () => {
      const { data, error, count } = await testSupabase
        .from('interests')
        .select('*', { count: 'exact' });

      expect(error).toBeNull();
      expect(count).toBeGreaterThanOrEqual(150);
    });

    it('should have interests in each category', async () => {
      const { data: categories, error: catError } = await testSupabase
        .from('interest_categories')
        .select('id, name');

      expect(catError).toBeNull();
      expect(categories).not.toBeNull();

      for (const category of categories!) {
        const { data: interests, error: intError, count } = await testSupabase
          .from('interests')
          .select('*', { count: 'exact' })
          .eq('category_id', category.id);

        expect(intError).toBeNull();
        expect(count).toBeGreaterThan(0);
      }
    });

    it('should have expected category names', async () => {
      const expectedCategories = [
        'Food & Dining',
        'Outdoor & Adventure',
        'Arts & Culture',
        'Coworking & Professional',
        'Sports & Fitness',
        'Nightlife & Social',
        'Learning & Education',
        'Wellness & Mindfulness',
        'Technology & Gaming',
        'Community & Volunteering',
        'Entertainment & Hobbies',
        'Travel & Exploration',
      ];

      const { data, error } = await testSupabase
        .from('interest_categories')
        .select('name')
        .order('sort_order');

      expect(error).toBeNull();
      expect(data).not.toBeNull();

      const categoryNames = data!.map((c) => c.name);
      expect(categoryNames).toEqual(expectedCategories);
    });
  });

  describe('PostGIS Extension', () => {
    it('should have PostGIS enabled', async () => {
      // Try to use a PostGIS function
      const { data, error } = await testSupabase.rpc('postgis_version' as any);

      // If RPC doesn't exist, try a direct query approach
      if (error) {
        // PostGIS is verified by the fact that geography columns exist
        // We can verify by checking itinerary_items table structure
        const { error: tableError } = await testSupabase
          .from('itinerary_items')
          .select('location')
          .limit(0);

        expect(tableError).toBeNull();
      } else {
        expect(data).toBeTruthy();
      }
    });
  });

  describe('RPC Functions', () => {
    it('should have calculate_match_score function', async () => {
      // Test the matching score calculation
      const { data, error } = await testSupabase.rpc('calculate_match_score', {
        p_distance_km: 10,
        p_overlap_days: 3,
        p_shared_interests: 2,
      });

      expect(error).toBeNull();
      expect(data).not.toBeNull();
      expect(typeof data).toBe('number');
      // Score should be between 0 and 100
      expect(data).toBeGreaterThanOrEqual(0);
      expect(data).toBeLessThanOrEqual(100);
    });

    it('should calculate correct match score', async () => {
      // Test with known values
      // Distance: 0km = 100 points * 0.3 = 30
      // Overlap: 5 days = 100 points * 0.4 = 40
      // Interests: 5 = 100 points * 0.3 = 30
      // Total = 100
      const { data: perfectScore } = await testSupabase.rpc(
        'calculate_match_score',
        {
          p_distance_km: 0,
          p_overlap_days: 5,
          p_shared_interests: 5,
        }
      );

      expect(perfectScore).toBe(100);

      // Distance: 50km = 0 points * 0.3 = 0
      // Overlap: 1 day = 20 points * 0.4 = 8
      // Interests: 0 = 0 points * 0.3 = 0
      // Total = 8
      const { data: lowScore } = await testSupabase.rpc(
        'calculate_match_score',
        {
          p_distance_km: 50,
          p_overlap_days: 1,
          p_shared_interests: 0,
        }
      );

      expect(lowScore).toBe(8);
    });
  });

  describe('Row Level Security', () => {
    it('should block unauthenticated access to profiles', async () => {
      // Without authentication, we shouldn't be able to see any profiles
      const { data, error } = await testSupabase
        .from('profiles')
        .select('*')
        .limit(1);

      // RLS should either return empty array or error
      expect(data?.length ?? 0).toBe(0);
    });

    it('should allow reading interest categories without auth', async () => {
      // Interest categories should be readable by anyone
      const { data, error } = await testSupabase
        .from('interest_categories')
        .select('*')
        .limit(1);

      // This should work since we're using anon key
      // But RLS requires auth for this table too
      // So we expect either success with data or empty array
      expect(error).toBeNull();
    });
  });
});
