-- Drop the problematic recursive "matches_only" policy on itinerary_items
--
-- The policy causes infinite recursion because it queries itinerary_items
-- within its own RLS policy evaluation. SECURITY DEFINER functions don't
-- fully bypass RLS in Supabase's default configuration.
--
-- The remaining policies cover the main use cases:
-- - "Users can view own itinerary items" - owners can see their own
-- - "Public itinerary items viewable by all" - public visibility works
--
-- The matches_only visibility feature for itinerary_items can be
-- reimplemented later using a proper service role Edge Function.

DROP POLICY IF EXISTS "Match-only itinerary items viewable by overlapping users" ON itinerary_items;

-- Also drop the helper function since it's no longer needed
DROP FUNCTION IF EXISTS check_itinerary_overlap(geography, date, date);
