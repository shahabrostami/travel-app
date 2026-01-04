-- ============================================================================
-- MATCHING RPC FUNCTIONS
-- ============================================================================

-- Function to find itinerary overlaps for a user
-- Returns users whose itineraries overlap with the given user's itinerary
-- in terms of location (within max_distance_km) and time (min_overlap_days)
CREATE OR REPLACE FUNCTION find_itinerary_overlaps(
  p_user_id UUID,
  p_max_distance_km NUMERIC DEFAULT 50,
  p_min_overlap_days INTEGER DEFAULT 1
)
RETURNS TABLE (
  matched_user_id UUID,
  matched_user_display_name TEXT,
  matched_user_avatar_url TEXT,
  overlap_city TEXT,
  overlap_country TEXT,
  overlap_start_date DATE,
  overlap_end_date DATE,
  distance_km NUMERIC,
  shared_interest_count INTEGER,
  my_itinerary_item_id UUID,
  their_itinerary_item_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id AS matched_user_id,
    p.display_name AS matched_user_display_name,
    p.avatar_url AS matched_user_avatar_url,
    item2.city AS overlap_city,
    item2.country AS overlap_country,
    GREATEST(item1.start_date, item2.start_date) AS overlap_start_date,
    LEAST(item1.end_date, item2.end_date) AS overlap_end_date,
    ROUND((ST_Distance(item1.location, item2.location) / 1000)::numeric, 2) AS distance_km,
    (
      SELECT COUNT(DISTINCT ui2.interest_id)
      FROM user_interests ui1
      INNER JOIN user_interests ui2 ON ui1.interest_id = ui2.interest_id
      WHERE ui1.user_id = p_user_id AND ui2.user_id = p.id
    )::INTEGER AS shared_interest_count,
    item1.id AS my_itinerary_item_id,
    item2.id AS their_itinerary_item_id
  FROM itinerary_items item1
  INNER JOIN itineraries itin1 ON item1.itinerary_id = itin1.id
  INNER JOIN itinerary_items item2 ON ST_DWithin(
    item1.location,
    item2.location,
    p_max_distance_km * 1000 -- Convert km to meters
  )
  INNER JOIN itineraries itin2 ON item2.itinerary_id = itin2.id
  INNER JOIN profiles p ON itin2.user_id = p.id
  LEFT JOIN user_connections uc ON (
    uc.user_id = p_user_id AND
    uc.connected_user_id = p.id AND
    uc.connection_type = 'blocked'
  )
  WHERE
    -- My itineraries
    itin1.user_id = p_user_id
    AND itin1.status = 'published'

    -- Their itineraries
    AND itin2.user_id != p_user_id
    AND itin2.status = 'published'

    -- Not blocked
    AND uc.id IS NULL

    -- Date overlap (at least p_min_overlap_days)
    AND daterange(item1.start_date, item1.end_date, '[]') &&
        daterange(item2.start_date, item2.end_date, '[]')
    AND (LEAST(item1.end_date, item2.end_date) - GREATEST(item1.start_date, item2.start_date)) >= p_min_overlap_days

    -- Respect visibility settings
    AND (
      itin2.visibility = 'public'
      OR (itin2.visibility = 'matches_only' AND EXISTS (
        SELECT 1 FROM itinerary_items check_item
        WHERE check_item.itinerary_id IN (
          SELECT id FROM itineraries WHERE user_id = p_user_id AND status = 'published'
        )
        AND ST_DWithin(check_item.location, item2.location, p_max_distance_km * 1000)
        AND daterange(check_item.start_date, check_item.end_date, '[]') &&
            daterange(item2.start_date, item2.end_date, '[]')
      ))
    )
  ORDER BY
    distance_km ASC,
    overlap_start_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to find relevant meetups for a user
-- Returns meetups that match the user's itinerary and interests
CREATE OR REPLACE FUNCTION find_relevant_meetups(
  p_user_id UUID,
  p_max_distance_km NUMERIC DEFAULT 50,
  p_min_interest_match INTEGER DEFAULT 1
)
RETURNS TABLE (
  meetup_id UUID,
  title TEXT,
  description TEXT,
  meetup_type TEXT,
  location_name TEXT,
  city TEXT,
  country TEXT,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  capacity INTEGER,
  current_attendees INTEGER,
  organizer_display_name TEXT,
  organizer_avatar_url TEXT,
  distance_km NUMERIC,
  shared_interest_count INTEGER,
  is_attending BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id AS meetup_id,
    m.title,
    m.description,
    m.meetup_type,
    m.location_name,
    m.city,
    m.country,
    m.start_time,
    m.end_time,
    m.capacity,
    m.current_attendees,
    p.display_name AS organizer_display_name,
    p.avatar_url AS organizer_avatar_url,
    MIN(ROUND((ST_Distance(item.location, m.location) / 1000)::numeric, 2)) AS distance_km,
    (
      SELECT COUNT(*)::INTEGER
      FROM user_interests ui
      WHERE ui.user_id = p_user_id
      AND ui.interest_id = ANY(m.interest_ids)
    ) AS shared_interest_count,
    EXISTS(
      SELECT 1 FROM meetup_attendees ma
      WHERE ma.meetup_id = m.id AND ma.user_id = p_user_id
    ) AS is_attending
  FROM meetups m
  INNER JOIN profiles p ON m.organizer_id = p.id
  INNER JOIN itineraries itin ON itin.user_id = p_user_id AND itin.status = 'published'
  INNER JOIN itinerary_items item ON item.itinerary_id = itin.id
  LEFT JOIN user_connections uc ON (
    uc.user_id = p_user_id AND
    uc.connected_user_id = m.organizer_id AND
    uc.connection_type = 'blocked'
  )
  WHERE
    -- Meetup is active
    m.status = 'active'

    -- Meetup is in the future
    AND m.start_time > NOW()

    -- Not blocked
    AND uc.id IS NULL

    -- Location proximity (within max_distance_km)
    AND ST_DWithin(item.location, m.location, p_max_distance_km * 1000)

    -- Time overlap (meetup during itinerary dates)
    AND DATE(m.start_time) BETWEEN item.start_date AND item.end_date

    -- Interest match (at least p_min_interest_match shared interests)
    AND (
      SELECT COUNT(*)
      FROM user_interests ui
      WHERE ui.user_id = p_user_id
      AND ui.interest_id = ANY(m.interest_ids)
    ) >= p_min_interest_match

    -- Respect visibility
    AND (
      m.visibility = 'public'
      OR (m.visibility = 'matches_only' AND EXISTS (
        SELECT 1 FROM itinerary_items check_item
        WHERE check_item.itinerary_id IN (
          SELECT id FROM itineraries WHERE user_id = p_user_id AND status = 'published'
        )
        AND ST_DWithin(check_item.location, m.location, p_max_distance_km * 1000)
        AND DATE(m.start_time) BETWEEN check_item.start_date AND check_item.end_date
      ))
    )
  GROUP BY
    m.id, m.title, m.description, m.meetup_type, m.location_name,
    m.city, m.country, m.start_time, m.end_time, m.capacity,
    m.current_attendees, p.display_name, p.avatar_url, m.interest_ids
  ORDER BY
    shared_interest_count DESC,
    distance_km ASC,
    m.start_time ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a meetup from an itinerary item
-- Convenience function to quickly convert travel plans into meetups
CREATE OR REPLACE FUNCTION create_meetup_from_itinerary_item(
  p_itinerary_item_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_meetup_type TEXT,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ DEFAULT NULL,
  p_location_name TEXT DEFAULT NULL,
  p_capacity INTEGER DEFAULT NULL,
  p_visibility TEXT DEFAULT 'public'
)
RETURNS UUID AS $$
DECLARE
  v_organizer_id UUID;
  v_location GEOGRAPHY;
  v_city TEXT;
  v_country TEXT;
  v_interest_ids UUID[];
  v_meetup_id UUID;
BEGIN
  -- Get itinerary item details
  SELECT
    i.user_id,
    ii.location,
    ii.city,
    ii.country,
    ii.interest_ids
  INTO
    v_organizer_id,
    v_location,
    v_city,
    v_country,
    v_interest_ids
  FROM itinerary_items ii
  INNER JOIN itineraries i ON ii.itinerary_id = i.id
  WHERE ii.id = p_itinerary_item_id;

  IF v_organizer_id IS NULL THEN
    RAISE EXCEPTION 'Itinerary item not found';
  END IF;

  -- Create meetup
  INSERT INTO meetups (
    organizer_id,
    title,
    description,
    meetup_type,
    location,
    location_name,
    city,
    country,
    start_time,
    end_time,
    capacity,
    visibility,
    interest_ids,
    source_itinerary_item_id
  ) VALUES (
    v_organizer_id,
    p_title,
    p_description,
    p_meetup_type,
    v_location,
    p_location_name,
    v_city,
    v_country,
    p_start_time,
    p_end_time,
    p_capacity,
    p_visibility,
    v_interest_ids,
    p_itinerary_item_id
  )
  RETURNING id INTO v_meetup_id;

  -- Auto-RSVP organizer as "going"
  INSERT INTO meetup_attendees (meetup_id, user_id, status)
  VALUES (v_meetup_id, v_organizer_id, 'going');

  RETURN v_meetup_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to RSVP to a meetup with capacity checking
CREATE OR REPLACE FUNCTION rsvp_to_meetup(
  p_meetup_id UUID,
  p_user_id UUID,
  p_status TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_capacity INTEGER;
  v_current_attendees INTEGER;
  v_existing_status TEXT;
  v_is_waitlisted BOOLEAN := FALSE;
  v_waitlist_position INTEGER := NULL;
BEGIN
  -- Validate status
  IF p_status NOT IN ('interested', 'going', 'maybe', 'declined') THEN
    RAISE EXCEPTION 'Invalid RSVP status: %', p_status;
  END IF;

  -- Get meetup details
  SELECT capacity, current_attendees
  INTO v_capacity, v_current_attendees
  FROM meetups
  WHERE id = p_meetup_id AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Meetup not found or not active';
  END IF;

  -- Get existing RSVP status
  SELECT status INTO v_existing_status
  FROM meetup_attendees
  WHERE meetup_id = p_meetup_id AND user_id = p_user_id;

  -- Check capacity if changing to "going"
  IF p_status = 'going' AND (v_existing_status IS NULL OR v_existing_status != 'going') THEN
    IF v_capacity IS NOT NULL AND v_current_attendees >= v_capacity THEN
      -- At capacity, add to waitlist
      v_is_waitlisted := TRUE;
      SELECT COALESCE(MAX(waitlist_position), 0) + 1
      INTO v_waitlist_position
      FROM meetup_attendees
      WHERE meetup_id = p_meetup_id AND is_waitlisted = TRUE;
    END IF;
  END IF;

  -- Insert or update RSVP
  INSERT INTO meetup_attendees (meetup_id, user_id, status, is_waitlisted, waitlist_position)
  VALUES (p_meetup_id, p_user_id, p_status, v_is_waitlisted, v_waitlist_position)
  ON CONFLICT (meetup_id, user_id)
  DO UPDATE SET
    status = p_status,
    is_waitlisted = v_is_waitlisted,
    waitlist_position = v_waitlist_position,
    updated_at = NOW();

  -- If declining and was on waitlist, remove waitlist data
  IF p_status = 'declined' THEN
    UPDATE meetup_attendees
    SET is_waitlisted = FALSE, waitlist_position = NULL
    WHERE meetup_id = p_meetup_id AND user_id = p_user_id;
  END IF;

  -- Return result
  RETURN jsonb_build_object(
    'success', TRUE,
    'status', p_status,
    'is_waitlisted', v_is_waitlisted,
    'waitlist_position', v_waitlist_position
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get nearby cities with active travelers
-- Useful for discovery/explore features
CREATE OR REPLACE FUNCTION get_active_cities(
  p_center_lat NUMERIC,
  p_center_lng NUMERIC,
  p_max_distance_km NUMERIC DEFAULT 500,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  city TEXT,
  country TEXT,
  country_code TEXT,
  traveler_count BIGINT,
  meetup_count BIGINT,
  distance_km NUMERIC,
  center_location GEOGRAPHY
) AS $$
BEGIN
  RETURN QUERY
  WITH city_stats AS (
    SELECT
      item.city,
      item.country,
      item.country_code,
      item.location,
      COUNT(DISTINCT itin.user_id) AS traveler_count,
      ST_Centroid(ST_Collect(item.location::geometry))::geography AS center_location
    FROM itinerary_items item
    INNER JOIN itineraries itin ON item.itinerary_id = itin.id
    WHERE
      itin.status = 'published'
      AND item.end_date >= CURRENT_DATE
      AND ST_DWithin(
        item.location,
        ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography,
        p_max_distance_km * 1000
      )
    GROUP BY item.city, item.country, item.country_code
  )
  SELECT
    cs.city,
    cs.country,
    cs.country_code,
    cs.traveler_count,
    (
      SELECT COUNT(*)
      FROM meetups m
      WHERE
        m.city = cs.city
        AND m.country = cs.country
        AND m.status = 'active'
        AND m.start_time > NOW()
    ) AS meetup_count,
    ROUND((ST_Distance(
      cs.center_location,
      ST_SetSRID(ST_MakePoint(p_center_lng, p_center_lat), 4326)::geography
    ) / 1000)::numeric, 2) AS distance_km,
    cs.center_location
  FROM city_stats cs
  ORDER BY cs.traveler_count DESC, distance_km ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Calculate match score between two users
-- Used in app logic for ranking/filtering
CREATE OR REPLACE FUNCTION calculate_match_score(
  p_distance_km NUMERIC,
  p_overlap_days INTEGER,
  p_shared_interests INTEGER
)
RETURNS NUMERIC AS $$
DECLARE
  v_distance_score NUMERIC;
  v_time_score NUMERIC;
  v_interest_score NUMERIC;
BEGIN
  -- Distance score: 0km = 100, 50km = 0 (linear interpolation)
  v_distance_score := GREATEST(0, 100 - (p_distance_km * 2));

  -- Time score: 1 day = 20, 5+ days = 100
  v_time_score := LEAST(100, 20 * p_overlap_days);

  -- Interest score: 0 = 0, 5+ = 100
  v_interest_score := LEAST(100, 20 * p_shared_interests);

  -- Weighted average: distance 30%, time 40%, interests 30%
  RETURN ROUND((v_distance_score * 0.3 + v_time_score * 0.4 + v_interest_score * 0.3)::numeric, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON FUNCTION find_itinerary_overlaps IS 'Find users with overlapping itineraries within distance and time constraints';
COMMENT ON FUNCTION find_relevant_meetups IS 'Find meetups relevant to user based on itinerary and interests';
COMMENT ON FUNCTION create_meetup_from_itinerary_item IS 'Quickly create a meetup from an existing itinerary item';
COMMENT ON FUNCTION rsvp_to_meetup IS 'RSVP to a meetup with capacity checking and waitlist management';
COMMENT ON FUNCTION get_active_cities IS 'Get nearby cities with active travelers and meetups';
COMMENT ON FUNCTION calculate_match_score IS 'Calculate match score (0-100) based on distance, time overlap, and shared interests';
