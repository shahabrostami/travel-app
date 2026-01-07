-- Test helper functions for RLS integration tests
-- These functions allow testing RLS policies by simulating user context

-- Function to test if a user can see another user's profile
-- This simulates the RLS policy logic for testing purposes
CREATE OR REPLACE FUNCTION test_can_user_see_profile(
  viewer_user_id uuid,
  target_user_id uuid
)
RETURNS TABLE(id uuid, display_name text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Set the auth context to simulate the viewer
  PERFORM set_config('request.jwt.claims', json_build_object('sub', viewer_user_id, 'role', 'authenticated')::text, true);

  -- Return profiles visible to this user
  RETURN QUERY
  SELECT p.id, p.display_name
  FROM profiles p
  WHERE p.id = target_user_id
  AND (
    -- User can always see own profile
    p.id = viewer_user_id
    OR
    -- Public profiles are visible to all authenticated users
    p.profile_visibility = 'public'
    OR
    -- Matches-only profiles visible if itineraries overlap
    (
      p.profile_visibility = 'matches_only'
      AND user_has_overlapping_itinerary(p.id)
    )
  );
END;
$$;

COMMENT ON FUNCTION test_can_user_see_profile IS 'Test helper: Check if viewer can see target profile based on RLS rules';
