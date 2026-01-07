-- Fix circular RLS recursion between itinerary_items and itineraries
--
-- The following circular dependency exists:
-- 1. itinerary_items "Public items" policy checks itineraries table
-- 2. itineraries "Match-only" policy checks itinerary_items table
-- 3. This causes infinite recursion
--
-- Solution: Drop the complex "matches_only" policies that create these cycles.
-- The owner and public visibility policies will still work correctly.
-- The matches_only feature can be reimplemented using Edge Functions with
-- service role that bypasses RLS.

-- Drop matches_only policy on itineraries (references itinerary_items)
DROP POLICY IF EXISTS "Match-only itineraries viewable by overlapping users" ON itineraries;

-- Drop matches_only policy on profiles (also references itinerary_items)
DROP POLICY IF EXISTS "Match-only profiles viewable by overlapping users" ON profiles;

-- Drop matches_only policy on meetups (references itinerary_items)
DROP POLICY IF EXISTS "Match-only meetups viewable by overlapping users" ON meetups;

-- Drop the complex user_interests policy that references itinerary_items
DROP POLICY IF EXISTS "Users can view others interests if profile visible" ON user_interests;

-- Create a simpler replacement: users can view interests of public profiles
CREATE POLICY "Users can view interests of public profiles"
  ON user_interests FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = user_interests.user_id
      AND p.profile_visibility = 'public'
    )
  );
