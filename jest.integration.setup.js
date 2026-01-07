/**
 * Jest setup for integration tests
 * Uses real Supabase client - no mocking
 */

// Load environment variables
require('dotenv').config({ path: '.env.local' });

// Verify environment variables are set
if (!process.env.EXPO_PUBLIC_SUPABASE_URL || !process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY) {
  throw new Error(
    'Integration tests require EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY in .env.local'
  );
}

// Set longer timeout for database operations
jest.setTimeout(30000);
