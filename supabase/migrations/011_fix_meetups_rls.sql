-- Fix meetups infinite recursion
--
-- The policy "Private meetups viewable by attendees" references meetup_attendees,
-- and meetup_attendees policy references meetups, creating a circular dependency.

-- Drop the problematic policy
DROP POLICY IF EXISTS "Private meetups viewable by attendees" ON meetups;

-- For private meetups, users need to be explicitly invited.
-- Since we can't check meetup_attendees without recursion, private meetups
-- will only be visible to organizers via the existing "Users can view own meetups" policy.
-- Attendees can access private meetups through an Edge Function using service role.
