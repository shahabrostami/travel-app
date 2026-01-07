-- Fix infinite recursion in itinerary_items RLS policy
-- The original policy queried itinerary_items within its own policy, causing recursion
-- Solution: Use a SECURITY DEFINER function to bypass RLS for the overlap check

-- Create helper function with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION check_itinerary_overlap(
  check_location geography,
  check_start_date date,
  check_end_date date
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
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
  )
$$;

-- Drop the recursive policy
DROP POLICY IF EXISTS "Match-only itinerary items viewable by overlapping users" ON itinerary_items;

-- Recreate using the helper function (no recursion)
CREATE POLICY "Match-only itinerary items viewable by overlapping users"
  ON itinerary_items FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM itineraries itin
      WHERE itin.id = itinerary_items.itinerary_id
      AND itin.status = 'published'
      AND itin.visibility = 'matches_only'
    )
    AND check_itinerary_overlap(
      itinerary_items.location,
      itinerary_items.start_date,
      itinerary_items.end_date
    )
  );
