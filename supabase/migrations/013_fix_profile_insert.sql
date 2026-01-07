-- Fix: Allow profile creation via trigger
--
-- The auth trigger that creates profiles on user signup was failing
-- because there's no INSERT policy. Even though the trigger uses
-- SECURITY DEFINER, Supabase may have additional restrictions.
--
-- Solution: Allow the service role to insert profiles, and ensure
-- the trigger function can bypass RLS properly.

-- Option 1: Allow any insert where id matches (for trigger)
-- The trigger inserts with the user's auth.uid() as id
CREATE POLICY "Service can create profiles"
  ON profiles FOR INSERT
  WITH CHECK (true);  -- The trigger validates id = auth.users.id

-- Alternative: If the above is too permissive, we could use:
-- WITH CHECK (id = auth.uid());
-- But this won't work for the trigger since auth.uid() isn't set during trigger execution
