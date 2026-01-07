/**
 * Integration tests for RLS matching policies
 *
 * Tests that matches_only visibility works correctly using RPC functions
 * that execute with user context (not service role which bypasses RLS).
 *
 * SETUP REQUIRED:
 * Add to .env.local:
 *   SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
 */
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

const hasServiceRole = !!serviceRoleKey;

const serviceClient = hasServiceRole
  ? createClient(supabaseUrl, serviceRoleKey!, { auth: { persistSession: false } })
  : null;

describe('RLS Matching Policies', () => {
  if (!hasServiceRole) {
    it.skip('requires SUPABASE_SERVICE_ROLE_KEY in .env.local', () => {});
    return;
  }

  // Test user IDs from our SQL setup
  const testUsers = {
    tokyo1: {
      id: 'e2537361-85a4-4eb9-9ea8-1ad942af5cef',
      displayName: 'Test User 1',
    },
    tokyo2: {
      id: '40df1d3c-4fc1-43c7-b5ba-c8cc8f2f80d9',
      displayName: 'Test User 2',
    },
    nyc: {
      id: '259d3daf-097e-462f-aa15-fe8adc8333ed',
      displayName: 'Test User 3 NYC',
    },
  };

  beforeAll(async () => {
    // Verify test users exist (created via SQL earlier)
    const { data: profiles } = await serviceClient!
      .from('profiles')
      .select('id, display_name')
      .in('id', [testUsers.tokyo1.id, testUsers.tokyo2.id, testUsers.nyc.id]);

    if (!profiles || profiles.length < 3) {
      throw new Error('Test users not found. Run SQL setup first.');
    }
  }, 30000);

  describe('Profile visibility with matches_only', () => {
    it('Tokyo User 1 can see Tokyo User 2 (overlapping itineraries)', async () => {
      const { data, error } = await serviceClient!.rpc('test_can_user_see_profile', {
        viewer_user_id: testUsers.tokyo1.id,
        target_user_id: testUsers.tokyo2.id,
      });

      expect(error).toBeNull();
      expect(data).toHaveLength(1);
      expect(data![0].display_name).toBe('Test User 2');
    });

    it('Tokyo User 2 can see Tokyo User 1 (bidirectional)', async () => {
      const { data, error } = await serviceClient!.rpc('test_can_user_see_profile', {
        viewer_user_id: testUsers.tokyo2.id,
        target_user_id: testUsers.tokyo1.id,
      });

      expect(error).toBeNull();
      expect(data).toHaveLength(1);
      expect(data![0].display_name).toBe('Test User 1');
    });

    it('Tokyo User 1 CANNOT see NYC User (no geographic overlap)', async () => {
      const { data, error } = await serviceClient!.rpc('test_can_user_see_profile', {
        viewer_user_id: testUsers.tokyo1.id,
        target_user_id: testUsers.nyc.id,
      });

      expect(error).toBeNull();
      expect(data).toHaveLength(0);
    });

    it('NYC User CANNOT see Tokyo User 1 (no overlap)', async () => {
      const { data, error } = await serviceClient!.rpc('test_can_user_see_profile', {
        viewer_user_id: testUsers.nyc.id,
        target_user_id: testUsers.tokyo1.id,
      });

      expect(error).toBeNull();
      expect(data).toHaveLength(0);
    });
  });

  describe('Helper function validation', () => {
    it('user_has_overlapping_itinerary function exists', async () => {
      // Test the helper function exists (won't work without auth context)
      const { error } = await serviceClient!.rpc('user_has_overlapping_itinerary', {
        target_user_id: testUsers.tokyo2.id,
      });

      // Function should exist even if it returns null without auth
      expect(error?.message || '').not.toContain('does not exist');
    });

    it('user_is_meetup_attendee function exists', async () => {
      const { error } = await serviceClient!.rpc('user_is_meetup_attendee', {
        meetup_uuid: '00000000-0000-0000-0000-000000000000',
      });

      // Function should exist even if it returns false
      expect(error?.message || '').not.toContain('does not exist');
    });
  });

  describe('Users can always see their own data', () => {
    it('User can see own profile via helper', async () => {
      const { data, error } = await serviceClient!.rpc('test_can_user_see_profile', {
        viewer_user_id: testUsers.tokyo1.id,
        target_user_id: testUsers.tokyo1.id,
      });

      expect(error).toBeNull();
      expect(data).toHaveLength(1);
    });
  });
});
