<p align="center">
  <img src="assets/icon/icon.png" alt="Serenity" width="100" height="100">
</p>

<h1 align="center">Serenity</h1>

<p align="center">
  <em>A private home for your relationship story.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Android%20|%20iOS%20|%20Linux%20|%20macOS%20|%20Windows-blue" alt="Platforms">
  <img src="https://img.shields.io/badge/Flutter-3.12+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

---

## Overview

Serenity is a private couple's journaling app. It gives you and your partner a shared space to capture memories, reflect on your day together, and build a timeline of your relationship — all without notifications, analytics, or gamification.

### Features

- **Timeline** — Shared feed of memories and milestones from both partners.
- **Reflect** — Daily reflection prompts and questions to spark meaningful conversations.
- **Daily Questions** — Answer one question per day. See your partner's answers.
- **Partner Sync** — Automatically sync memories, milestones, and reflections through Supabase.
- **Calendar Filter** — Tap any day on the calendar to see what happened that day.
- **Privacy First** — No analytics, no push notifications, no gamification.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.12+ / Dart 3.12+ |
| State | Riverpod |
| Database | Drift (SQLite) |
| Sync | Supabase (PostgreSQL) |
| Auth | Supabase Auth (email, passkeys) |
| Navigation | GoRouter |
| Icons | Lucide Icons |
| Fonts | Inter, Plus Jakarta Sans, Cormorant Garamond |

---

## Project Structure

```
serenity_app/
├── lib/
│   ├── core/
│   │   ├── auth/            # Authentication gate & provider
│   │   ├── components/      # Shared UI components
│   │   ├── database/        # Drift schema, DAOs, providers
│   │   ├── router/          # GoRouter configuration
│   │   ├── supabase/        # Supabase initialization & config
│   │   ├── sync/            # Push/pull sync engine
│   │   └── theme/           # Theme system & palette
│   ├── features/
│   │   ├── auth/            # Sign in / sign up / onboarding
│   │   ├── couple/          # Couple linking & settings
│   │   ├── me/              # Profile & partner answers
│   │   ├── reflect/         # Daily questions & reflection
│   │   └── story/           # Timeline, memories, milestones
│   ├── generated/           # Drift-generated code
│   ├── app.dart
│   └── main.dart
├── assets/
│   ├── fonts/               # Inter, Jakarta, Cormorant
│   └── questions/           # Question & prompt JSON bundles
├── docs/
│   ├── SQL_RLS_POLICIES.sql # Supabase Row Level Security
│   ├── ARCHITECTURE.md      # App architecture documentation
│   ├── BUILD.md             # Build order & setup
│   ├── PRODUCT.md           # Product specification
│   └── ...
└── test/
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
   cd serenity-app/serenity_app
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

1. Create a Supabase project.
2. Run the SQL policies in `docs/SQL_RLS_POLICIES.sql`.
3. Disable email confirmation in Supabase Auth settings (optional for dev).
4. Copy your project URL and anon key into `.env`.

---

## Design

Serenity uses a warm, intimate visual language:

- **Default theme** — Warm rose (`#D4737A`) on dark backgrounds
- **5 theme presets** — Warm Rose, Sage, Ocean, Terracotta, Lavender
- **Typography** — Plus Jakarta Sans (UI), Inter (body), Cormorant Garamond (quotes)
- **Icons** — Lucide Icons throughout
- **Philosophy** — Calm, private, human. No notifications. No streaks. No noise.

---

## License

MIT
