-- ============================================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- ============================================================================

-- Materialized view for itinerary overlaps
-- Pre-computes overlaps to speed up matching queries
-- Should be refreshed periodically (e.g., every 6 hours via cron)
CREATE MATERIALIZED VIEW itinerary_overlaps AS
SELECT
  itin1.user_id AS user1_id,
  itin2.user_id AS user2_id,
  item1.id AS item1_id,
  item2.id AS item2_id,
  item1.city AS overlap_city,
  item1.country AS overlap_country,
  GREATEST(item1.start_date, item2.start_date) AS overlap_start_date,
  LEAST(item1.end_date, item2.end_date) AS overlap_end_date,
  (LEAST(item1.end_date, item2.end_date) - GREATEST(item1.start_date, item2.start_date)) AS overlap_days,
  ROUND((ST_Distance(item1.location, item2.location) / 1000)::numeric, 2) AS distance_km,
  (
    SELECT COUNT(DISTINCT ui2.interest_id)
    FROM user_interests ui1
    INNER JOIN user_interests ui2 ON ui1.interest_id = ui2.interest_id
    WHERE ui1.user_id = itin1.user_id AND ui2.user_id = itin2.user_id
  ) AS shared_interest_count
FROM itinerary_items item1
INNER JOIN itineraries itin1 ON item1.itinerary_id = itin1.id
INNER JOIN itinerary_items item2 ON ST_DWithin(item1.location, item2.location, 50000) -- 50km
INNER JOIN itineraries itin2 ON item2.itinerary_id = itin2.id
WHERE
  -- Both itineraries are published
  itin1.status = 'published'
  AND itin2.status = 'published'

  -- Different users
  AND itin1.user_id < itin2.user_id -- Avoid duplicates (A-B same as B-A)

  -- Date overlap (at least 1 day)
  AND daterange(item1.start_date, item1.end_date, '[]') &&
      daterange(item2.start_date, item2.end_date, '[]')
  AND (LEAST(item1.end_date, item2.end_date) - GREATEST(item1.start_date, item2.start_date)) >= 1

  -- Still in future or recent past (last 30 days)
  AND item1.end_date >= CURRENT_DATE - INTERVAL '30 days'
  AND item2.end_date >= CURRENT_DATE - INTERVAL '30 days';

-- Indexes for materialized view
CREATE INDEX idx_mv_overlaps_user1 ON itinerary_overlaps(user1_id);
CREATE INDEX idx_mv_overlaps_user2 ON itinerary_overlaps(user2_id);
CREATE INDEX idx_mv_overlaps_dates ON itinerary_overlaps(overlap_start_date, overlap_end_date);
CREATE INDEX idx_mv_overlaps_city ON itinerary_overlaps(overlap_city, overlap_country);
CREATE INDEX idx_mv_overlaps_distance ON itinerary_overlaps(distance_km);
CREATE INDEX idx_mv_overlaps_shared_interests ON itinerary_overlaps(shared_interest_count);

-- Function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_itinerary_overlaps()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY itinerary_overlaps;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- AGGREGATE STATISTICS VIEWS
-- ============================================================================

-- View for user statistics (for profile display)
CREATE VIEW user_stats AS
SELECT
  p.id AS user_id,
  p.display_name,
  COUNT(DISTINCT i.id) AS itinerary_count,
  COUNT(DISTINCT m.id) AS organized_meetup_count,
  COUNT(DISTINCT ma.meetup_id) AS attended_meetup_count,
  COUNT(DISTINCT ui.interest_id) AS interest_count,
  (
    SELECT COUNT(DISTINCT o.user2_id)
    FROM itinerary_overlaps o
    WHERE o.user1_id = p.id
    UNION
    SELECT COUNT(DISTINCT o.user1_id)
    FROM itinerary_overlaps o
    WHERE o.user2_id = p.id
  ) AS potential_match_count
FROM profiles p
LEFT JOIN itineraries i ON p.id = i.user_id AND i.status = 'published'
LEFT JOIN meetups m ON p.id = m.organizer_id AND m.status = 'active'
LEFT JOIN meetup_attendees ma ON p.id = ma.user_id AND ma.status = 'going'
LEFT JOIN user_interests ui ON p.id = ui.user_id
GROUP BY p.id, p.display_name;

-- View for meetup statistics
CREATE VIEW meetup_stats AS
SELECT
  m.id AS meetup_id,
  m.title,
  m.meetup_type,
  m.city,
  m.country,
  m.start_time,
  m.capacity,
  m.current_attendees,
  COUNT(CASE WHEN ma.status = 'going' THEN 1 END) AS going_count,
  COUNT(CASE WHEN ma.status = 'interested' THEN 1 END) AS interested_count,
  COUNT(CASE WHEN ma.status = 'maybe' THEN 1 END) AS maybe_count,
  COUNT(CASE WHEN ma.is_waitlisted THEN 1 END) AS waitlist_count,
  CASE
    WHEN m.capacity IS NOT NULL AND m.current_attendees >= m.capacity THEN TRUE
    ELSE FALSE
  END AS is_full
FROM meetups m
LEFT JOIN meetup_attendees ma ON m.id = ma.meetup_id
GROUP BY m.id, m.title, m.meetup_type, m.city, m.country, m.start_time, m.capacity, m.current_attendees;

-- View for popular interests
CREATE VIEW popular_interests AS
SELECT
  i.id,
  i.name,
  i.slug,
  ic.name AS category_name,
  i.popularity_score,
  COUNT(ui.user_id) AS user_count
FROM interests i
INNER JOIN interest_categories ic ON i.category_id = ic.id
LEFT JOIN user_interests ui ON i.id = ui.interest_id
GROUP BY i.id, i.name, i.slug, ic.name, i.popularity_score
ORDER BY i.popularity_score DESC, user_count DESC;

-- ============================================================================
-- CRON JOBS (requires pg_cron extension)
-- ============================================================================

-- Note: These need to be set up manually in Supabase dashboard or via SQL
-- after enabling the pg_cron extension

-- Refresh itinerary overlaps every 6 hours
-- SELECT cron.schedule(
--   'refresh-itinerary-overlaps',
--   '0 */6 * * *', -- Every 6 hours
--   'SELECT refresh_itinerary_overlaps();'
-- );

-- Clean up old notifications (older than 30 days)
-- SELECT cron.schedule(
--   'cleanup-old-notifications',
--   '0 2 * * *', -- Daily at 2 AM
--   'DELETE FROM notification_queue WHERE created_at < NOW() - INTERVAL ''30 days'';'
-- );

-- Archive completed meetups (older than 7 days)
-- SELECT cron.schedule(
--   'archive-completed-meetups',
--   '0 3 * * *', -- Daily at 3 AM
--   'UPDATE meetups SET status = ''completed'' WHERE status = ''active'' AND start_time < NOW() - INTERVAL ''7 days'';'
-- );

-- ============================================================================
-- PERFORMANCE HELPER FUNCTIONS
-- ============================================================================

-- Fast lookup of user overlaps using materialized view
CREATE OR REPLACE FUNCTION get_user_overlaps(
  p_user_id UUID,
  p_min_match_score NUMERIC DEFAULT 30
)
RETURNS TABLE (
  matched_user_id UUID,
  overlap_city TEXT,
  overlap_country TEXT,
  overlap_start_date DATE,
  overlap_end_date DATE,
  overlap_days INTEGER,
  distance_km NUMERIC,
  shared_interest_count INTEGER,
  match_score NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    CASE
      WHEN o.user1_id = p_user_id THEN o.user2_id
      ELSE o.user1_id
    END AS matched_user_id,
    o.overlap_city,
    o.overlap_country,
    o.overlap_start_date,
    o.overlap_end_date,
    o.overlap_days,
    o.distance_km,
    o.shared_interest_count,
    calculate_match_score(o.distance_km, o.overlap_days, o.shared_interest_count) AS match_score
  FROM itinerary_overlaps o
  WHERE
    (o.user1_id = p_user_id OR o.user2_id = p_user_id)
    AND calculate_match_score(o.distance_km, o.overlap_days, o.shared_interest_count) >= p_min_match_score
  ORDER BY match_score DESC, overlap_start_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON MATERIALIZED VIEW itinerary_overlaps IS 'Pre-computed itinerary overlaps for fast matching. Refresh every 6 hours.';
COMMENT ON VIEW user_stats IS 'Aggregate statistics for user profiles';
COMMENT ON VIEW meetup_stats IS 'Aggregate statistics for meetups including RSVP counts';
COMMENT ON VIEW popular_interests IS 'Most popular interests ranked by popularity score and user count';
COMMENT ON FUNCTION refresh_itinerary_overlaps IS 'Refresh materialized view of itinerary overlaps. Should be called periodically via cron.';
COMMENT ON FUNCTION get_user_overlaps IS 'Fast lookup of overlapping users using pre-computed materialized view';

-- ============================================================================
-- INITIAL REFRESH
-- ============================================================================

-- Refresh materialized view for the first time
REFRESH MATERIALIZED VIEW itinerary_overlaps;
