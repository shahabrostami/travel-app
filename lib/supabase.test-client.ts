/**
 * Supabase client for testing
 * Uses environment variables and doesn't require AsyncStorage
 *
 * Environment variables are loaded by jest.integration.setup.js
 */
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!;

export const testSupabase: SupabaseClient = createClient(
  supabaseUrl,
  supabaseAnonKey
);

export { supabaseUrl, supabaseAnonKey };
