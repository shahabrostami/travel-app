-- Fix RLS policies to allow public read on interests
-- Previously required auth, but interests should be readable by anyone
-- (needed for onboarding flow before user signs in)

-- Drop old policies
DROP POLICY IF EXISTS "Anyone can view interest categories" ON interest_categories;
DROP POLICY IF EXISTS "Anyone can view interests" ON interests;

-- Create new public-read policies
CREATE POLICY "Interest categories are public"
  ON interest_categories FOR SELECT
  USING (true);

CREATE POLICY "Interests are public"
  ON interests FOR SELECT
  USING (true);
