# Supabase Setup Guide

This guide walks through setting up the Supabase backend for the Travel Social Coordination App.

## Overview

The database uses:
- **PostgreSQL** with **PostGIS** extension for geospatial queries
- **Row Level Security (RLS)** for data access control
- **RPC Functions** for complex matching logic
- **Materialized Views** for performance optimization
- **150+ interest taxonomy** for user preferences

---

## Step 1: Create Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in details:
   - **Name**: `travel-app` (or your choice)
   - **Database Password**: Generate a strong password and save it
   - **Region**: Choose closest to your target users
4. Wait 2-3 minutes for project creation

---

## Step 2: Enable PostGIS Extension

PostGIS is **critical** for geospatial queries (finding nearby users/meetups).

### Via SQL Editor:
1. Go to SQL Editor in Supabase dashboard
2. Run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```
3. Verify:
   ```sql
   SELECT PostGIS_Version();
   ```

---

## Step 3: Run Migrations

Run the 4 migration files in order:

### Migration 001: Initial Schema
Creates all tables with PostGIS geography columns, indexes, and triggers.

**File**: `supabase/migrations/001_initial_schema.sql`

**What it creates**:
- ✅ 10 core tables (profiles, itineraries, meetups, etc.)
- ✅ PostGIS geospatial columns for location data
- ✅ Critical indexes for geo-temporal queries
- ✅ Triggers for auto-updating timestamps
- ✅ Auto-profile creation on signup

**To run**:
1. Copy contents of `001_initial_schema.sql`
2. Paste into Supabase SQL Editor
3. Click "Run"

### Migration 002: Matching Functions
Creates RPC functions for finding overlaps and meetups.

**File**: `supabase/migrations/002_matching_functions.sql`

**What it creates**:
- ✅ `find_itinerary_overlaps()` - Core matching algorithm
- ✅ `find_relevant_meetups()` - Meetup discovery
- ✅ `create_meetup_from_itinerary_item()` - Quick meetup creation
- ✅ `rsvp_to_meetup()` - RSVP with capacity checking
- ✅ `get_active_cities()` - Nearby city discovery
- ✅ `calculate_match_score()` - Scoring algorithm

**To run**:
1. Copy contents of `002_matching_functions.sql`
2. Paste into Supabase SQL Editor
3. Click "Run"

### Migration 003: RLS Policies
Enables Row Level Security to control data access.

**File**: `supabase/migrations/003_rls_policies.sql`

**What it creates**:
- ✅ RLS enabled on all tables
- ✅ Users can only edit their own data
- ✅ Public profiles viewable by all
- ✅ Match-only profiles viewable by overlapping users
- ✅ Proper visibility enforcement (private/matches_only/public)

**To run**:
1. Copy contents of `003_rls_policies.sql`
2. Paste into Supabase SQL Editor
3. Click "Run"

### Migration 004: Materialized Views
Creates pre-computed views for performance.

**File**: `supabase/migrations/004_materialized_views.sql`

**What it creates**:
- ✅ `itinerary_overlaps` materialized view (refresh every 6 hours)
- ✅ `user_stats` view (profile statistics)
- ✅ `meetup_stats` view (RSVP counts)
- ✅ `popular_interests` view (trending interests)
- ✅ `get_user_overlaps()` - Fast lookup function

**To run**:
1. Copy contents of `004_materialized_views.sql`
2. Paste into Supabase SQL Editor
3. Click "Run"

---

## Step 4: Seed Interest Taxonomy

Load 150+ interests across 12 categories.

**File**: `supabase/seed/001_interests_taxonomy.sql`

**Categories**:
1. Food & Dining (20 interests)
2. Outdoor & Adventure (18 interests)
3. Arts & Culture (16 interests)
4. Coworking & Professional (12 interests)
5. Sports & Fitness (14 interests)
6. Nightlife & Social (12 interests)
7. Learning & Education (11 interests)
8. Wellness & Mindfulness (10 interests)
9. Technology & Gaming (10 interests)
10. Community & Volunteering (8 interests)
11. Entertainment & Hobbies (10 interests)
12. Travel & Exploration (9 interests)

**To run**:
1. Copy contents of `001_interests_taxonomy.sql`
2. Paste into Supabase SQL Editor
3. Click "Run"
4. Verify with:
   ```sql
   SELECT COUNT(*) FROM interests; -- Should return 150+
   SELECT COUNT(*) FROM interest_categories; -- Should return 12
   ```

---

## Step 5: Get API Keys

1. Go to Project Settings → API
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp...`
   - **service_role key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp...` (keep secret!)

3. Add to `.env.local` (create if doesn't exist):
   ```bash
   EXPO_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
   EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp...
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp... # Server-side only!
   ```

---

## Step 6: Test Connection

### Option A: Via Supabase SQL Editor
```sql
-- Test geospatial query
SELECT ST_AsText(ST_Point(-9.1393, 38.7223)::geography::geometry) AS lisbon_location;

-- Test interest data
SELECT ic.name AS category, COUNT(i.id) AS interest_count
FROM interest_categories ic
LEFT JOIN interests i ON ic.id = i.category_id
GROUP BY ic.name
ORDER BY ic.name;
```

### Option B: Via App (after Supabase client setup)
```typescript
import { supabase } from './lib/supabase';

// Test connection
const { data, error } = await supabase
  .from('interest_categories')
  .select('*')
  .limit(5);

console.log('Categories:', data);
```

---

## Step 7: Configure Periodic Jobs (Optional)

For production, set up cron jobs to refresh materialized views.

### Enable pg_cron Extension:
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

### Schedule Materialized View Refresh (every 6 hours):
```sql
SELECT cron.schedule(
  'refresh-itinerary-overlaps',
  '0 */6 * * *',
  'SELECT refresh_itinerary_overlaps();'
);
```

### Schedule Cleanup Jobs:
```sql
-- Clean old notifications (daily at 2 AM)
SELECT cron.schedule(
  'cleanup-old-notifications',
  '0 2 * * *',
  'DELETE FROM notification_queue WHERE created_at < NOW() - INTERVAL ''30 days'';'
);

-- Archive completed meetups (daily at 3 AM)
SELECT cron.schedule(
  'archive-completed-meetups',
  '0 3 * * *',
  'UPDATE meetups SET status = ''completed'' WHERE status = ''active'' AND start_time < NOW() - INTERVAL ''7 days'';'
);
```

---

## Database Schema Overview

### Core Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `profiles` | User profiles | Privacy settings, trust score, verification |
| `interests` | Interest taxonomy | 150+ interests across 12 categories |
| `user_interests` | User's selected interests | Many-to-many with proficiency levels |
| `itineraries` | Travel plans | Visibility: private/matches_only/public |
| `itinerary_items` | Cities/locations | **PostGIS geography**, dates, activities |
| `meetups` | Events/gatherings | **PostGIS geography**, capacity, RSVP |
| `meetup_attendees` | RSVPs | Status: going/interested/maybe, waitlist |
| `user_connections` | Trust/blocking | Trusted users and blocked users |
| `notification_queue` | Push notifications | Pending notifications to send |

### Critical Indexes

```sql
-- Geospatial-temporal composite index (CRITICAL for performance)
idx_itinerary_items_geo_temporal -- GIST index on (location, date_range)
idx_meetups_geo_temporal -- GIST index on (location, time_range)
```

These indexes enable sub-500ms queries for finding overlaps within 50km and date ranges.

---

## Performance Considerations

### Query Performance Targets
- Itinerary overlap query: < 500ms
- Meetup discovery: < 300ms
- Profile load: < 100ms

### Optimization Strategies
1. **Materialized View**: Pre-compute overlaps, refresh every 6 hours
2. **GIST Indexes**: Geo-temporal composite indexes on location + date
3. **RLS Policies**: Efficient policies using EXISTS with proper indexes
4. **Connection Pooling**: Use Supabase's built-in pooler for high traffic

### Monitoring
Track these in production:
- Slow queries > 1 second
- Materialized view refresh time
- RLS policy query plans (use `EXPLAIN ANALYZE`)

---

## Security Notes

### Row Level Security (RLS)
- ✅ Enabled on all tables
- ✅ Users can only modify their own data
- ✅ Visibility settings properly enforced
- ✅ Blocked users cannot see each other

### API Keys
- `anon key`: Safe to use in app (client-side)
- `service_role key`: NEVER expose client-side (server-only for Edge Functions)

### Testing RLS Policies
```sql
-- Test as a specific user
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "user-uuid-here"}';

-- Try queries to verify RLS
SELECT * FROM profiles WHERE id != 'user-uuid-here';
```

---

## Common Issues

### Issue: PostGIS not found
**Error**: `type "geography" does not exist`
**Solution**: Run `CREATE EXTENSION IF NOT EXISTS postgis;`

### Issue: RLS blocking all queries
**Error**: No rows returned even though data exists
**Solution**: Verify you're authenticated. Check `auth.uid()` is set correctly.

### Issue: Slow overlap queries
**Error**: Queries taking > 2 seconds
**Solution**:
1. Verify GIST indexes exist: `\d itinerary_items`
2. Run `EXPLAIN ANALYZE` on slow query
3. Refresh materialized view: `SELECT refresh_itinerary_overlaps();`

### Issue: Migration order
**Error**: Functions or tables not found
**Solution**: Run migrations in exact order (001 → 002 → 003 → 004)

---

## Next Steps

After Supabase is set up:

1. ✅ **Create Supabase Client** (`lib/supabase.ts`)
2. ✅ **Set up Auth Store** (`store/authStore.ts`)
3. ✅ **Implement Auth Flows** (login, signup, Google OAuth)
4. ✅ **Test Geospatial Queries** (verify PostGIS works)
5. ✅ **Build Itinerary UI** (create/edit itineraries)

---

## Verification Checklist

Before moving to next phase, verify:

- [ ] PostGIS extension enabled
- [ ] All 4 migrations ran successfully
- [ ] 150+ interests seeded
- [ ] RLS policies enabled (no direct table access without auth)
- [ ] API keys copied to `.env.local`
- [ ] Test query returns data
- [ ] Materialized view has data (`SELECT COUNT(*) FROM itinerary_overlaps;`)

---

## Useful SQL Queries

### Check table sizes
```sql
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### View all indexes
```sql
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

### Test geospatial distance
```sql
-- Distance between Lisbon and Porto
SELECT ROUND(
  ST_Distance(
    ST_Point(-9.1393, 38.7223)::geography, -- Lisbon
    ST_Point(-8.6291, 41.1579)::geography  -- Porto
  ) / 1000
) AS distance_km; -- Should return ~275 km
```

---

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [PostGIS Documentation](https://postgis.net/docs/)
- [PostgreSQL RLS Guide](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Supabase CLI](https://supabase.com/docs/guides/cli) (for local development)
