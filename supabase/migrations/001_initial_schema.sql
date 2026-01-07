-- Enable PostGIS extension for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Note: Using gen_random_uuid() (built-in PostgreSQL 13+) instead of uuid-ossp

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,

  -- Privacy settings
  profile_visibility TEXT NOT NULL DEFAULT 'matches_only' CHECK (profile_visibility IN ('private', 'matches_only', 'public')),
  itinerary_visibility TEXT NOT NULL DEFAULT 'matches_only' CHECK (itinerary_visibility IN ('nobody', 'matches_only', 'everyone')),

  -- Travel preferences
  travel_pace TEXT CHECK (travel_pace IN ('slow', 'moderate', 'fast')),
  travel_budget TEXT CHECK (travel_budget IN ('budget', 'moderate', 'luxury')),
  travel_vibe JSONB, -- Array of vibes: ['solo', 'group', 'remote_work', 'adventure', 'relaxation']

  -- Trust and verification
  trust_score INTEGER DEFAULT 50 CHECK (trust_score BETWEEN 0 AND 100),
  is_verified BOOLEAN DEFAULT FALSE,
  verification_badges JSONB DEFAULT '[]'::jsonb, -- ['email', 'phone', 'photo', 'government_id']

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Interest categories (taxonomy)
CREATE TABLE interest_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  icon TEXT, -- Icon name/emoji
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Interests (100-200 total)
CREATE TABLE interests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES interest_categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  popularity_score INTEGER DEFAULT 0, -- Track how many users have this interest
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(category_id, name)
);

-- User interests (many-to-many with proficiency)
CREATE TABLE user_interests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  interest_id UUID NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
  proficiency TEXT CHECK (proficiency IN ('beginner', 'intermediate', 'expert')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, interest_id)
);

-- Itineraries (travel plans)
CREATE TABLE itineraries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,

  -- Visibility
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
  visibility TEXT NOT NULL DEFAULT 'matches_only' CHECK (visibility IN ('private', 'matches_only', 'public')),

  -- Dates
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,

  -- Metadata
  trip_type TEXT, -- 'leisure', 'digital_nomad', 'business', 'volunteer'
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Itinerary items (cities/locations within an itinerary)
-- CRITICAL: Uses PostGIS geography type for geospatial queries
CREATE TABLE itinerary_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  itinerary_id UUID NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,

  -- Location (PostGIS)
  location GEOGRAPHY(POINT, 4326) NOT NULL, -- lat/lng coordinates
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  country_code TEXT NOT NULL, -- ISO 3166-1 alpha-2
  neighborhood TEXT, -- Specific area within city

  -- Dates
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,

  -- Activities and preferences
  activity_types JSONB DEFAULT '[]'::jsonb, -- ['coworking', 'hiking', 'dining', 'nightlife']
  time_preferences JSONB DEFAULT '{}'::jsonb, -- {'morning': true, 'afternoon': true, 'evening': false}

  -- Work schedule (for digital nomads)
  work_schedule JSONB, -- {'days': ['monday', 'tuesday'], 'hours': '9-5'}

  -- Associated interests
  interest_ids UUID[] DEFAULT '{}',

  -- Notes
  notes TEXT,

  -- Sort order within itinerary
  sort_order INTEGER NOT NULL DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_date_range CHECK (end_date >= start_date)
);

-- Meetups (events/gatherings)
CREATE TABLE meetups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Basic info
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  meetup_type TEXT NOT NULL CHECK (meetup_type IN (
    'coffee', 'coworking', 'meal', 'drinks', 'hike',
    'activity', 'cultural', 'party', 'skill_share', 'other'
  )),

  -- Location (PostGIS)
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  location_name TEXT, -- Venue name
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  address TEXT,

  -- Time
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ, -- Optional end time

  -- Capacity
  capacity INTEGER, -- NULL = unlimited
  current_attendees INTEGER DEFAULT 0,

  -- Visibility and status
  visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('private', 'matches_only', 'public')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'cancelled', 'completed')),

  -- Interests
  interest_ids UUID[] DEFAULT '{}',

  -- Source (if created from itinerary)
  source_itinerary_item_id UUID REFERENCES itinerary_items(id) ON DELETE SET NULL,

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_capacity CHECK (capacity IS NULL OR capacity > 0)
);

-- Meetup attendees (RSVPs)
CREATE TABLE meetup_attendees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meetup_id UUID NOT NULL REFERENCES meetups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- RSVP status
  status TEXT NOT NULL DEFAULT 'interested' CHECK (status IN ('interested', 'going', 'maybe', 'declined')),

  -- Waitlist (if at capacity)
  is_waitlisted BOOLEAN DEFAULT FALSE,
  waitlist_position INTEGER,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(meetup_id, user_id)
);

-- User connections (trust network and blocking)
CREATE TABLE user_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  connected_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Connection type
  connection_type TEXT NOT NULL CHECK (connection_type IN ('trusted', 'blocked')),

  -- Notes
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, connected_user_id),
  CONSTRAINT no_self_connection CHECK (user_id != connected_user_id)
);

-- Notification queue (for push notifications)
CREATE TABLE notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Notification type
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'overlap_detected', 'meetup_invite', 'meetup_update',
    'meetup_cancelled', 'meetup_reminder'
  )),

  -- Content
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb, -- Deep link data

  -- Status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  sent_at TIMESTAMPTZ,
  error TEXT,

  -- Priority and batching
  priority INTEGER DEFAULT 0, -- Higher = more urgent
  batch_key TEXT, -- For grouping notifications (e.g., "overlaps_2024-01-15")

  -- Scheduled delivery
  scheduled_for TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Profile indexes
CREATE INDEX idx_profiles_visibility ON profiles(profile_visibility);
CREATE INDEX idx_profiles_created_at ON profiles(created_at);

-- Interest indexes
CREATE INDEX idx_interests_category ON interests(category_id);
CREATE INDEX idx_interests_popularity ON interests(popularity_score DESC);
CREATE INDEX idx_user_interests_user ON user_interests(user_id);
CREATE INDEX idx_user_interests_interest ON user_interests(interest_id);

-- Itinerary indexes
CREATE INDEX idx_itineraries_user ON itineraries(user_id);
CREATE INDEX idx_itineraries_status ON itineraries(status);
CREATE INDEX idx_itineraries_dates ON itineraries(start_date, end_date);
CREATE INDEX idx_itineraries_visibility ON itineraries(visibility);

-- Itinerary items - CRITICAL GEOSPATIAL-TEMPORAL INDEX
CREATE INDEX idx_itinerary_items_itinerary ON itinerary_items(itinerary_id);
CREATE INDEX idx_itinerary_items_geo_temporal ON itinerary_items
  USING GIST (location, daterange(start_date, end_date, '[]'));
CREATE INDEX idx_itinerary_items_dates ON itinerary_items(start_date, end_date);
CREATE INDEX idx_itinerary_items_location ON itinerary_items USING GIST (location);

-- Meetup indexes - GEOSPATIAL-TEMPORAL
CREATE INDEX idx_meetups_organizer ON meetups(organizer_id);
CREATE INDEX idx_meetups_status ON meetups(status);
CREATE INDEX idx_meetups_visibility ON meetups(visibility);
CREATE INDEX idx_meetups_type ON meetups(meetup_type);
-- Separate indexes for location and time (combined geo-temporal not supported with COALESCE)
CREATE INDEX idx_meetups_start_time ON meetups(start_time);
CREATE INDEX idx_meetups_location ON meetups USING GIST (location);

-- Meetup attendee indexes
CREATE INDEX idx_meetup_attendees_meetup ON meetup_attendees(meetup_id);
CREATE INDEX idx_meetup_attendees_user ON meetup_attendees(user_id);
CREATE INDEX idx_meetup_attendees_status ON meetup_attendees(status);

-- Connection indexes
CREATE INDEX idx_connections_user ON user_connections(user_id);
CREATE INDEX idx_connections_connected_user ON user_connections(connected_user_id);
CREATE INDEX idx_connections_type ON user_connections(connection_type);

-- Notification indexes
CREATE INDEX idx_notifications_user ON notification_queue(user_id);
CREATE INDEX idx_notifications_status ON notification_queue(status);
CREATE INDEX idx_notifications_scheduled ON notification_queue(scheduled_for) WHERE status = 'pending';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_itineraries_updated_at BEFORE UPDATE ON itineraries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_itinerary_items_updated_at BEFORE UPDATE ON itinerary_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meetups_updated_at BEFORE UPDATE ON meetups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_profile_for_user();

-- Update interest popularity when user adds/removes interest
CREATE OR REPLACE FUNCTION update_interest_popularity()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE interests
    SET popularity_score = popularity_score + 1
    WHERE id = NEW.interest_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE interests
    SET popularity_score = popularity_score - 1
    WHERE id = OLD.interest_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_interest_popularity_on_user_interest
  AFTER INSERT OR DELETE ON user_interests
  FOR EACH ROW EXECUTE FUNCTION update_interest_popularity();

-- Update meetup attendee count
CREATE OR REPLACE FUNCTION update_meetup_attendee_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT' AND NEW.status = 'going') THEN
    UPDATE meetups
    SET current_attendees = current_attendees + 1
    WHERE id = NEW.meetup_id;
  ELSIF (TG_OP = 'DELETE' AND OLD.status = 'going') THEN
    UPDATE meetups
    SET current_attendees = current_attendees - 1
    WHERE id = OLD.meetup_id;
  ELSIF (TG_OP = 'UPDATE' AND OLD.status != NEW.status) THEN
    IF (OLD.status = 'going' AND NEW.status != 'going') THEN
      UPDATE meetups
      SET current_attendees = current_attendees - 1
      WHERE id = NEW.meetup_id;
    ELSIF (OLD.status != 'going' AND NEW.status = 'going') THEN
      UPDATE meetups
      SET current_attendees = current_attendees + 1
      WHERE id = NEW.meetup_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_meetup_attendee_count_trigger
  AFTER INSERT OR UPDATE OR DELETE ON meetup_attendees
  FOR EACH ROW EXECUTE FUNCTION update_meetup_attendee_count();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE profiles IS 'User profiles with travel preferences and privacy settings';
COMMENT ON TABLE interest_categories IS 'Top-level categories for interests (Food, Outdoor, Arts, etc.)';
COMMENT ON TABLE interests IS 'Specific interests within categories (Hiking, Jazz, Coworking, etc.)';
COMMENT ON TABLE itineraries IS 'User travel plans with multiple destinations';
COMMENT ON TABLE itinerary_items IS 'Individual cities/locations within an itinerary with dates and activities';
COMMENT ON TABLE meetups IS 'Events and gatherings organized by users';
COMMENT ON TABLE meetup_attendees IS 'RSVP tracking for meetups with capacity management';
COMMENT ON TABLE user_connections IS 'Trust network and blocked users';
COMMENT ON TABLE notification_queue IS 'Pending push notifications to be sent via Edge Function';

COMMENT ON COLUMN itinerary_items.location IS 'PostGIS geography point for geospatial queries (lat/lng)';
COMMENT ON COLUMN meetups.location IS 'PostGIS geography point for geospatial queries (lat/lng)';
COMMENT ON INDEX idx_itinerary_items_geo_temporal IS 'Critical index for finding itinerary overlaps by location and time';
