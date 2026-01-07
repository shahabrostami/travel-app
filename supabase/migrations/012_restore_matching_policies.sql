-- Restore the "matches_only" visibility functionality properly
--
-- The previous attempts failed because:
-- 1. Direct RLS policies that reference the same table cause infinite recursion
-- 2. LANGUAGE sql functions can be inlined, losing SECURITY DEFINER context
--
-- Solution: Use LANGUAGE plpgsql SECURITY DEFINER functions which:
-- - Execute as the function owner (postgres superuser)
-- - Bypass RLS when querying tables
-- - Cannot be inlined by the query planner

-- ============================================================================
-- HELPER FUNCTION: Check if current user has overlapping itinerary
-- ============================================================================
CREATE OR REPLACE FUNCTION user_has_overlapping_itinerary(
  target_user_id uuid,
  check_location geography DEFAULT NULL,
  check_start_date date DEFAULT NULL,
  check_end_date date DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  has_overlap boolean := false;
BEGIN
  -- If no location/dates provided, check if ANY overlap exists with target user
  IF check_location IS NULL THEN
    SELECT EXISTS (
      SELECT 1
      FROM itinerary_items my_item
      INNER JOIN itineraries my_itin ON my_item.itinerary_id = my_itin.id
      INNER JOIN itineraries their_itin ON their_itin.user_id = target_user_id
        AND their_itin.status = 'published'
      INNER JOIN itinerary_items their_item ON their_item.itinerary_id = their_itin.id
      WHERE
        my_itin.user_id = auth.uid()
        AND my_itin.status = 'published'
        AND ST_DWithin(my_item.location, their_item.location, 50000)
        AND daterange(my_item.start_date, my_item.end_date, '[]') &&
            daterange(their_item.start_date, their_item.end_date, '[]')
    ) INTO has_overlap;
  ELSE
    -- Check overlap with specific location/dates
    SELECT EXISTS (
      SELECT 1
      FROM itinerary_items item
      INNER JOIN itineraries itin ON item.itinerary_id = itin.id
      WHERE
        itin.user_id = auth.uid()
        AND itin.status = 'published'
        AND ST_DWithin(item.location, check_location, 50000)
        AND daterange(item.start_date, item.end_date, '[]') &&
            daterange(check_start_date, check_end_date, '[]')
    ) INTO has_overlap;
  END IF;

  RETURN has_overlap;
END;
$$;

-- ============================================================================
-- RESTORE: Match-only profiles viewable by overlapping users
-- ============================================================================
CREATE POLICY "Match-only profiles viewable by overlapping users"
  ON profiles FOR SELECT
  USING (
    profile_visibility = 'matches_only'
    AND auth.uid() IS NOT NULL
    AND auth.uid() != id  -- Don't use this policy for own profile
    AND user_has_overlapping_itinerary(id)
  );

-- ============================================================================
-- RESTORE: Match-only itineraries viewable by overlapping users
-- ============================================================================
CREATE POLICY "Match-only itineraries viewable by overlapping users"
  ON itineraries FOR SELECT
  USING (
    status = 'published'
    AND visibility = 'matches_only'
    AND auth.uid() IS NOT NULL
    AND auth.uid() != user_id  -- Don't use this policy for own itineraries
    AND user_has_overlapping_itinerary(user_id)
  );

-- ============================================================================
-- RESTORE: Match-only itinerary items viewable by overlapping users
-- ============================================================================
CREATE POLICY "Match-only itinerary items viewable by overlapping users"
  ON itinerary_items FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM itineraries itin
      WHERE itin.id = itinerary_items.itinerary_id
      AND itin.status = 'published'
      AND itin.visibility = 'matches_only'
      AND itin.user_id != auth.uid()
    )
    AND user_has_overlapping_itinerary(
      NULL,  -- We'll get user from the itinerary
      itinerary_items.location,
      itinerary_items.start_date,
      itinerary_items.end_date
    )
  );

-- ============================================================================
-- RESTORE: Match-only meetups viewable by overlapping users
-- ============================================================================
CREATE POLICY "Match-only meetups viewable by overlapping users"
  ON meetups FOR SELECT
  USING (
    status = 'active'
    AND visibility = 'matches_only'
    AND auth.uid() IS NOT NULL
    AND auth.uid() != organizer_id
    AND user_has_overlapping_itinerary(
      NULL,
      meetups.location,
      DATE(meetups.start_time),
      COALESCE(DATE(meetups.end_time), DATE(meetups.start_time))
    )
  );

-- ============================================================================
-- RESTORE: Private meetups viewable by attendees
-- ============================================================================
-- This needs a separate helper to avoid meetup_attendees recursion
CREATE OR REPLACE FUNCTION user_is_meetup_attendee(meetup_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  is_attendee boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM meetup_attendees
    WHERE meetup_id = meetup_uuid
    AND user_id = auth.uid()
  ) INTO is_attendee;

  RETURN is_attendee;
END;
$$;

CREATE POLICY "Private meetups viewable by attendees"
  ON meetups FOR SELECT
  USING (
    status = 'active'
    AND visibility = 'private'
    AND auth.uid() IS NOT NULL
    AND user_is_meetup_attendee(id)
  );

-- ============================================================================
-- RESTORE: Users can view others' interests if profile visible
-- ============================================================================
-- Drop the simplified version we created
DROP POLICY IF EXISTS "Users can view interests of public profiles" ON user_interests;

CREATE POLICY "Users can view others interests if profile visible"
  ON user_interests FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND auth.uid() != user_id  -- Don't use this for own interests
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = user_interests.user_id
      AND (
        p.profile_visibility = 'public'
        OR (
          p.profile_visibility = 'matches_only'
          AND user_has_overlapping_itinerary(p.id)
        )
      )
    )
  );

-- ============================================================================
-- RESTORE: Meetup attendees visibility with helper function
-- ============================================================================
DROP POLICY IF EXISTS "Users can view attendees of their meetups" ON meetup_attendees;

CREATE POLICY "Users can view attendees of visible meetups"
  ON meetup_attendees FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      -- User is an attendee themselves
      user_id = auth.uid()
      OR
      -- User can see the meetup
      EXISTS (
        SELECT 1 FROM meetups m
        WHERE m.id = meetup_attendees.meetup_id
        AND (
          m.organizer_id = auth.uid()
          OR (m.status = 'active' AND m.visibility = 'public')
          OR (
            m.status = 'active'
            AND m.visibility = 'matches_only'
            AND user_has_overlapping_itinerary(
              NULL,
              m.location,
              DATE(m.start_time),
              COALESCE(DATE(m.end_time), DATE(m.start_time))
            )
          )
          OR (
            m.status = 'active'
            AND m.visibility = 'private'
            AND user_is_meetup_attendee(m.id)
          )
        )
      )
    )
  );

-- Clean up the old broken helper function
DROP FUNCTION IF EXISTS check_itinerary_overlap(geography, date, date);
