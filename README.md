# Serenity

> A private home for your relationship story.

A Flutter app designed for couples to build stronger relationships through shared memories, daily reflections, milestones, and emotional awareness — all private, all local-first.

**Platform:** Android, iOS, Linux, macOS, Windows  
**Framework:** Flutter 3.12+ | Dart 3.12+  
**License:** MIT

---

## Features

- **Timeline** — Shared feed of memories and milestones from both partners
- **Reflect** — Daily reflection prompts and questions to spark meaningful conversations
- **Daily Questions** — Answer one question per day, see your partner's answers
- **Partner Sync** — Automatically sync memories, milestones, and reflections between devices
- **Calendar** — Tap any day to see what happened that day
- **Privacy First** — No analytics, no notifications, no gamification, no noise

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.12+ / Dart 3.12+ |
| State Management | Riverpod |
| Local Database | Drift (SQLite) |
| Cloud Sync | Supabase (PostgreSQL) |
| Authentication | Supabase Auth (email, passkeys) |
| Navigation | GoRouter |
| Icons | Lucide Icons |
| Typography | Inter, Plus Jakarta Sans, Cormorant Garamond |

---

## Project Structure

```
lib/
  ├── core/
  │   ├── auth/            # Authentication gate & provider
  │   ├── components/      # Shared UI components
  │   ├── database/        # Drift schema, DAOs, providers
  │   ├── router/          # GoRouter configuration
  │   ├── supabase/        # Supabase initialization
  │   ├── sync/            # Push/pull sync engine
  │   └── theme/           # Theme system & palette
  ├── features/
  │   ├── auth/            # Sign in, sign up, onboarding
  │   ├── couple/          # Couple linking & settings
  │   ├── me/              # Profile & partner answers
  │   ├── reflect/         # Daily questions & reflection
  │   └── story/           # Timeline, memories, milestones
  ├── app.dart
  └── main.dart

assets/
  ├── fonts/               # Inter, Jakarta, Cormorant
  └── questions/           # Question & prompt bundles

docs/
  ├── INDEX.md             # Documentation guide
  ├── PRODUCT.md           # Product vision
  ├── ARCHITECTURE.md      # Technical design
  ├── BUILD.md             # Build instructions
  ├── ROADMAP.md           # Roadmap & milestones
  ├── DECISIONS.md         # Architecture decisions
  ├── FUTURE.md            # Parked ideas
  └── CHANGELOG.md         # Completed work
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.12+
- A Supabase project (free tier works)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/rxin-sngspr/serenity-app.git
   cd serenity-app
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

3. **Get dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

5. **Build an APK**
   ```bash
   flutter build apk --debug
   ```

### Supabase Setup

1. Create a Supabase project
2. Set up Row Level Security policies (see `docs/ARCHITECTURE.md`)
3. Copy your project URL and anon key into `.env`

---

## Architecture & Design

**Local-First** — Data lives on your device first. Sync happens in the background.

**Private-First** — No analytics, no tracking, no cloud creep. Your relationship story stays yours.

**Warm & Minimal** — Five theme presets (Warm Rose, Sage Garden, Ocean Calm, Terracotta, Lavender Night) with calm, intentional design.

For deep technical details, see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Documentation

- **[INDEX.md](docs/INDEX.md)** — Documentation guide
- **[PRODUCT.md](docs/PRODUCT.md)** — Product vision & principles
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** — System design, data flow, database schema
- **[BUILD.md](docs/BUILD.md)** — Build instructions & troubleshooting
- **[ROADMAP.md](docs/ROADMAP.md)** — Milestones & current status
- **[DECISIONS.md](docs/DECISIONS.md)** — Why we made key technical choices
- **[FUTURE.md](docs/FUTURE.md)** — Parked ideas not in scope
- **[CHANGELOG.md](docs/CHANGELOG.md)** — What's been shipped

---

## Contributing

This is a personal project, but ideas and feedback are welcome. Feel free to fork, explore, and learn.

---

## License

MIT
