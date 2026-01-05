-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE interest_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE itinerary_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetups ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetup_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_queue ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Public profiles are viewable by all authenticated users
CREATE POLICY "Public profiles are viewable"
  ON profiles FOR SELECT
  USING (
    profile_visibility = 'public'
    AND auth.uid() IS NOT NULL
  );

-- Match-only profiles are viewable by users with itinerary overlap
CREATE POLICY "Match-only profiles viewable by overlapping users"
  ON profiles FOR SELECT
  USING (
    profile_visibility = 'matches_only'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM itinerary_items item1
      INNER JOIN itineraries itin1 ON item1.itinerary_id = itin1.id
      INNER JOIN itinerary_items item2 ON ST_DWithin(item1.location, item2.location, 50000)
      INNER JOIN itineraries itin2 ON item2.itinerary_id = itin2.id
      WHERE
        itin1.user_id = auth.uid()
        AND itin1.status = 'published'
        AND itin2.user_id = profiles.id
        AND itin2.status = 'published'
        AND daterange(item1.start_date, item1.end_date, '[]') &&
            daterange(item2.start_date, item2.end_date, '[]')
    )
  );

-- ============================================================================
-- INTEREST CATEGORIES & INTERESTS
-- ============================================================================

-- All authenticated users can view interest categories
CREATE POLICY "Anyone can view interest categories"
  ON interest_categories FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- All authenticated users can view interests
CREATE POLICY "Anyone can view interests"
  ON interests FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ============================================================================
-- USER INTERESTS
-- ============================================================================

-- Users can view their own interests
CREATE POLICY "Users can view own interests"
  ON user_interests FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own interests
CREATE POLICY "Users can insert own interests"
  ON user_interests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own interests
CREATE POLICY "Users can delete own interests"
  ON user_interests FOR DELETE
  USING (auth.uid() = user_id);

-- Other users can view interests if profile is visible to them
CREATE POLICY "Users can view others interests if profile visible"
  ON user_interests FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = user_interests.user_id
      AND (
        p.profile_visibility = 'public'
        OR (
          p.profile_visibility = 'matches_only'
          AND EXISTS (
            SELECT 1
            FROM itinerary_items item1
            INNER JOIN itineraries itin1 ON item1.itinerary_id = itin1.id
            INNER JOIN itinerary_items item2 ON ST_DWithin(item1.location, item2.location, 50000)
            INNER JOIN itineraries itin2 ON item2.itinerary_id = itin2.id
            WHERE
              itin1.user_id = auth.uid()
              AND itin1.status = 'published'
              AND itin2.user_id = user_interests.user_id
              AND itin2.status = 'published'
              AND daterange(item1.start_date, item1.end_date, '[]') &&
                  daterange(item2.start_date, item2.end_date, '[]')
          )
        )
      )
    )
  );

-- ============================================================================
-- ITINERARIES
-- ============================================================================

-- Users can view their own itineraries
CREATE POLICY "Users can view own itineraries"
  ON itineraries FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own itineraries
CREATE POLICY "Users can insert own itineraries"
  ON itineraries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own itineraries
CREATE POLICY "Users can update own itineraries"
  ON itineraries FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own itineraries
CREATE POLICY "Users can delete own itineraries"
  ON itineraries FOR DELETE
  USING (auth.uid() = user_id);

-- Public itineraries are viewable by all
CREATE POLICY "Public itineraries viewable by all"
  ON itineraries FOR SELECT
  USING (
    status = 'published'
    AND visibility = 'public'
    AND auth.uid() IS NOT NULL
  );

-- Match-only itineraries viewable by overlapping users
CREATE POLICY "Match-only itineraries viewable by overlapping users"
  ON itineraries FOR SELECT
  USING (
    status = 'published'
    AND visibility = 'matches_only'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM itinerary_items item1
      INNER JOIN itineraries itin1 ON item1.itinerary_id = itin1.id
      INNER JOIN itinerary_items item2 ON item2.itinerary_id = itineraries.id
      WHERE
        itin1.user_id = auth.uid()
        AND itin1.status = 'published'
        AND ST_DWithin(item1.location, item2.location, 50000)
        AND daterange(item1.start_date, item1.end_date, '[]') &&
            daterange(item2.start_date, item2.end_date, '[]')
    )
  );

-- ============================================================================
-- ITINERARY ITEMS
-- ============================================================================

-- Users can view their own itinerary items
CREATE POLICY "Users can view own itinerary items"
  ON itinerary_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM itineraries
      WHERE id = itinerary_items.itinerary_id
      AND user_id = auth.uid()
    )
  );

-- Users can insert items to their own itineraries
CREATE POLICY "Users can insert own itinerary items"
  ON itinerary_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM itineraries
      WHERE id = itinerary_items.itinerary_id
      AND user_id = auth.uid()
    )
  );

-- Users can update their own itinerary items
CREATE POLICY "Users can update own itinerary items"
  ON itinerary_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM itineraries
      WHERE id = itinerary_items.itinerary_id
      AND user_id = auth.uid()
    )
  );

-- Users can delete their own itinerary items
CREATE POLICY "Users can delete own itinerary items"
  ON itinerary_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM itineraries
      WHERE id = itinerary_items.itinerary_id
      AND user_id = auth.uid()
    )
  );

-- Public itinerary items viewable by all
CREATE POLICY "Public itinerary items viewable by all"
  ON itinerary_items FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM itineraries
      WHERE id = itinerary_items.itinerary_id
      AND status = 'published'
      AND visibility = 'public'
    )
  );

-- Match-only itinerary items viewable by overlapping users
CREATE POLICY "Match-only itinerary items viewable by overlapping users"
  ON itinerary_items FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM itineraries itin
      WHERE itin.id = itinerary_items.itinerary_id
      AND itin.status = 'published'
      AND itin.visibility = 'matches_only'
      AND EXISTS (
        SELECT 1
        FROM itinerary_items item1
        INNER JOIN itineraries itin1 ON item1.itinerary_id = itin1.id
        WHERE
          itin1.user_id = auth.uid()
          AND itin1.status = 'published'
          AND ST_DWithin(item1.location, itinerary_items.location, 50000)
          AND daterange(item1.start_date, item1.end_date, '[]') &&
              daterange(itinerary_items.start_date, itinerary_items.end_date, '[]')
      )
    )
  );

-- ============================================================================
-- MEETUPS
-- ============================================================================

-- Users can view their own meetups
CREATE POLICY "Users can view own meetups"
  ON meetups FOR SELECT
  USING (auth.uid() = organizer_id);

-- Users can insert their own meetups
CREATE POLICY "Users can insert own meetups"
  ON meetups FOR INSERT
  WITH CHECK (auth.uid() = organizer_id);

-- Users can update their own meetups
CREATE POLICY "Users can update own meetups"
  ON meetups FOR UPDATE
  USING (auth.uid() = organizer_id);

-- Users can delete their own meetups
CREATE POLICY "Users can delete own meetups"
  ON meetups FOR DELETE
  USING (auth.uid() = organizer_id);

-- Public meetups viewable by all
CREATE POLICY "Public meetups viewable by all"
  ON meetups FOR SELECT
  USING (
    status = 'active'
    AND visibility = 'public'
    AND auth.uid() IS NOT NULL
  );

-- Match-only meetups viewable by overlapping users
CREATE POLICY "Match-only meetups viewable by overlapping users"
  ON meetups FOR SELECT
  USING (
    status = 'active'
    AND visibility = 'matches_only'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM itinerary_items item
      INNER JOIN itineraries itin ON item.itinerary_id = itin.id
      WHERE
        itin.user_id = auth.uid()
        AND itin.status = 'published'
        AND ST_DWithin(item.location, meetups.location, 50000)
        AND DATE(meetups.start_time) BETWEEN item.start_date AND item.end_date
    )
  );

-- Private meetups viewable by attendees
CREATE POLICY "Private meetups viewable by attendees"
  ON meetups FOR SELECT
  USING (
    status = 'active'
    AND visibility = 'private'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM meetup_attendees
      WHERE meetup_id = meetups.id
      AND user_id = auth.uid()
    )
  );

-- ============================================================================
-- MEETUP ATTENDEES
-- ============================================================================

-- Users can view attendees of meetups they can see
CREATE POLICY "Users can view attendees of visible meetups"
  ON meetup_attendees FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM meetups m
      WHERE m.id = meetup_attendees.meetup_id
      AND (
        m.organizer_id = auth.uid()
        OR (m.status = 'active' AND m.visibility = 'public')
        OR (
          m.status = 'active'
          AND m.visibility = 'matches_only'
          AND EXISTS (
            SELECT 1
            FROM itinerary_items item
            INNER JOIN itineraries itin ON item.itinerary_id = itin.id
            WHERE
              itin.user_id = auth.uid()
              AND itin.status = 'published'
              AND ST_DWithin(item.location, m.location, 50000)
              AND DATE(m.start_time) BETWEEN item.start_date AND item.end_date
          )
        )
        OR EXISTS (
          SELECT 1 FROM meetup_attendees ma2
          WHERE ma2.meetup_id = meetup_attendees.meetup_id
          AND ma2.user_id = auth.uid()
        )
      )
    )
  );

-- Users can insert their own RSVPs
CREATE POLICY "Users can insert own RSVPs"
  ON meetup_attendees FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own RSVPs
CREATE POLICY "Users can update own RSVPs"
  ON meetup_attendees FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own RSVPs
CREATE POLICY "Users can delete own RSVPs"
  ON meetup_attendees FOR DELETE
  USING (auth.uid() = user_id);

-- Organizers can update any attendee (for waitlist management)
CREATE POLICY "Organizers can update attendees"
  ON meetup_attendees FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM meetups
      WHERE id = meetup_attendees.meetup_id
      AND organizer_id = auth.uid()
    )
  );

-- ============================================================================
-- USER CONNECTIONS
-- ============================================================================

-- Users can view their own connections
CREATE POLICY "Users can view own connections"
  ON user_connections FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own connections
CREATE POLICY "Users can insert own connections"
  ON user_connections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own connections
CREATE POLICY "Users can update own connections"
  ON user_connections FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own connections
CREATE POLICY "Users can delete own connections"
  ON user_connections FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- NOTIFICATION QUEUE
-- ============================================================================

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notification_queue FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read, etc.)
CREATE POLICY "Users can update own notifications"
  ON notification_queue FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notification_queue FOR DELETE
  USING (auth.uid() = user_id);

-- System can insert notifications (via service role)
-- Note: This will be handled by Edge Functions using service role key

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON POLICY "Users can view own profile" ON profiles IS 'Users always have full access to their own profile';
COMMENT ON POLICY "Public profiles are viewable" ON profiles IS 'Profiles set to public visibility are viewable by all authenticated users';
COMMENT ON POLICY "Match-only profiles viewable by overlapping users" ON profiles IS 'Profiles with matches_only visibility are only viewable by users with overlapping itineraries (within 50km and overlapping dates)';
COMMENT ON POLICY "Match-only itineraries viewable by overlapping users" ON itineraries IS 'Itineraries with matches_only visibility follow the same logic as profiles - only visible to users with geographic and temporal overlap';
COMMENT ON POLICY "Match-only meetups viewable by overlapping users" ON meetups IS 'Meetups with matches_only visibility are only shown to users whose itineraries overlap with the meetup location and time';
