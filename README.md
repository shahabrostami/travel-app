# Travel Social Coordination App

A mobile app that helps travelers build flexible itineraries and intelligently connects them with meetups based on location/time overlap and shared interests.

## 🎯 Core Value Proposition

Not just "who's nearby" — but **"what's actually happening when you'll be there."**

The app proactively suggests meetups and connections by matching:
- **Location overlap**: Travelers in the same city
- **Time overlap**: When you'll both be there
- **Shared interests**: Activities, work styles, travel preferences

## 🛠 Tech Stack

- **Frontend**: React Native + Expo (cross-platform)
- **Backend**: Supabase (Postgres + PostGIS + Auth + Real-time)
- **State Management**: Zustand + React Query
- **Maps**: React Native Maps
- **Notifications**: Expo Notifications

## 📋 Project Status

**Current Phase**: Foundation (Weeks 1-3)
**Target**: MVP in 3-4 months

### Roadmap
- **Phase 1**: Foundation (Weeks 1-3) - Setup, auth, basic structure
- **Phase 2**: Itinerary Builder (Weeks 4-6) - Core travel planning
- **Phase 3**: Meetups (Weeks 7-9) - Event creation and RSVP
- **Phase 4**: Matching & Discovery (Weeks 10-12) - Intelligent connections
- **Phase 5**: Notifications & Polish (Weeks 13-15) - Push notifications, UX refinement
- **Phase 6**: Beta Launch (Week 16+) - Soft launch in 1-2 cities

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- Expo CLI
- iOS Simulator (Mac) or Android Emulator
- Supabase account

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/travel-app.git
cd travel-app

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your Supabase credentials

# Start the development server
npx expo start
```

### Supabase Setup

1. Create a new Supabase project at https://supabase.com
2. Run migrations in order:
```bash
# From Supabase SQL Editor or CLI
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_matching_functions.sql
supabase/migrations/003_rls_policies.sql
supabase/migrations/004_materialized_views.sql
```
3. Update `.env.local` with your project URL and anon key

## 🏗 Architecture

### Key Features (MVP)
- ✅ Itinerary creation with cities, dates, and activities
- ✅ Manual meetup creation and RSVP
- ✅ Geospatial-temporal matching (who's nearby when)
- ✅ Simple scoring algorithm (distance + time + interests)
- ✅ Profile with interests and travel style
- ✅ Privacy controls (private/matches_only/public)
- ✅ Push notifications for overlaps and updates
- ✅ Email + Google OAuth authentication

### Database
PostgreSQL with PostGIS extension for geospatial queries. Core tables:
- `profiles` - User profiles and settings
- `itineraries` + `itinerary_items` - Travel plans with location data
- `meetups` + `meetup_attendees` - Events and RSVPs
- `interests` - Activity taxonomy
- `itinerary_overlaps` - Materialized view for fast matching

### Matching Algorithm
Simple weighted scoring based on:
- Distance (30% weight): Closer = higher score
- Time overlap (40% weight): More days = higher score
- Interest match (30% weight): More shared = higher score

## 📁 Project Structure

```
/TravelApp
├── app/                    # Expo Router (file-based routing)
│   ├── (auth)/            # Auth screens
│   ├── (tabs)/            # Main tab navigation
│   ├── meetup/            # Meetup screens
│   └── itinerary/         # Itinerary screens
├── components/            # Reusable components
├── lib/                   # Core utilities (Supabase client, etc.)
├── hooks/                 # React Query hooks
├── store/                 # Zustand stores
├── types/                 # TypeScript types
└── supabase/             # Database migrations
```

## 🤝 Contributing

This is currently a solo development project. Issues and PRs follow a structured workflow:

### Workflow
1. Create issue from template (feature/bug/phase-kickoff)
2. Assign to milestone (current phase)
3. Create feature branch: `feature/phase1-feature-name`
4. Commit with convention: `feat(scope): description`
5. Open PR using template
6. Self-review and merge to main

### Commit Convention
- `feat(scope):` New feature
- `fix(scope):` Bug fix
- `refactor(scope):` Code refactoring
- `docs(scope):` Documentation
- `chore(scope):` Maintenance

## 📊 Success Metrics

### Activation
- 60% of users publish an itinerary
- 20% of users create a meetup

### Engagement
- 40% of users RSVP to a meetup
- 10+ meetups discovered per user

### Network Effects
- 3+ overlaps per itinerary (network density)
- 50% of meetups have 2+ attendees

## 📝 License

[To be determined]

## 📧 Contact

[Your contact information]

---

**Built with ❤️ for digital nomads, slow travelers, and adventure seekers**
