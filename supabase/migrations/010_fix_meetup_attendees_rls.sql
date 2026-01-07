-- Fix meetup_attendees infinite recursion
--
-- The policy "Users can view attendees of visible meetups" has self-reference:
--   "OR EXISTS (SELECT 1 FROM meetup_attendees ma2 WHERE ...)"
-- This causes infinite recursion when evaluating RLS.

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can view attendees of visible meetups" ON meetup_attendees;

-- Create a simpler replacement without self-reference
-- Users can view attendees of meetups they organize or public meetups
CREATE POLICY "Users can view attendees of their meetups"
  ON meetup_attendees FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM meetups m
      WHERE m.id = meetup_attendees.meetup_id
      AND (
        m.organizer_id = auth.uid()
        OR (m.status = 'active' AND m.visibility = 'public')
      )
    )
  );

-- Users can view their own RSVP entries
CREATE POLICY "Users can view own RSVPs"
  ON meetup_attendees FOR SELECT
  USING (auth.uid() = user_id);
