# Serenity — Changelog

> **Owner:** Engineering team
> **Purpose:** Only completed, shipped work. No ideas, discussions, or in-progress items.
> **Related:** [Roadmap](ROADMAP.md) | [Architecture](ARCHITECTURE.md) | [Decisions](DECISIONS.md)

---

## 1.0.0 (Pre-release)

### Phase 5 — Supabase Integration (95% complete)

- **Synced auth flow:** Sign-in, sign-up with Supabase email/password authentication. AuthGate routes unauthenticated users through the auth flow, authenticated uncoupled users to couple linking, and authenticated coupled users to the main app. Profile row creation on sign-up (uses `response.user` not `auth.currentUser`).
- **Couple linking:** 6-character alphanumeric invite code with 24h expiry. Create code (partner A), enter code (partner B). Full edge case handling: self-link prevention, expiry, already-used codes, unlink (partner A deletes couple, partner B clears link). Couple status provider invalidated on create/join/unlink.
- **Sync engine:** Push/pull service for 6 content tables (memories, milestones, reflections, question_answers, tags, tag_assignments). Connectivity-triggered sync via `connectivity_plus`. Last-write-wins conflict resolution. `isSynced` flag on all DAO writes. Synced state indicator component.
- **Sync infrastructure:** `SyncMetadata` table for `last_pull_at`, `couple_id`, `user_id`. v3 database migration (sync columns added to all content tables). 16 Dart files created for auth, couple, sync.
- **Supabase SQL schema deployed:** 8 tables (profiles, couples, memories, milestones, reflections, question_answers, tags, tag_assignments), 5 custom indexes, 23 RLS policies. All verified via pg_tables, pg_indexes, pg_policies.

### Phase 4 — Flutter Foundation (Complete)

- **Onboarding:** Name + partner name entry, saved to local settings
- **Timeline:** Chronological display of memories and milestones. Timeline entries from both partners after sync.
- **Memories:** Create, edit, favorite, delete. Tags support via TagAssignments.
- **Milestones:** Create, edit, delete. Icons, colors, milestone types.
- **Reflections:** Daily question with answer. 90 questions with categories. Unlimited refresh (cycles all questions via date offset + refresh count). Partners see same question sequence per day.
- **Calendar:** Date-based view of all entries.
- **Tags:** 10 preset tags seeded on migration. Custom tags with color hex. Colored pill rendering on timeline and memory detail. Tags DAO for creation and assignment.
- **Theme system:** 5 themes (Warm Rose default, Sage, Ocean, Terracotta, Lavender). Dark + light mode. Settings persistence.
- **3-tab navigation:** Story, Reflect, Me. StatefulShellRoute preserves tab state.

### Phase 3 — Architecture (Complete)

- **Database:** Drift with 9 tables (memories, memory_media, milestones, settings, reflections, question_answers, tags, tag_assignments, sync_metadata). v3 migration path.
- **DAOs:** 9 Data Access Objects with type-safe CRUD operations.
- **Providers:** Riverpod providers for all data access, auth state, couple status, sync state, theme preferences.
- **Code generation:** build_runner + drift_dev for type-safe database code.

### Phase 2 — Design System (Complete)

- **Components:** 10 shared components (bottom nav, card, header, timeline card, calendar widget, category badge, milestone chip, appreciation block, section divider, sync status indicator)
- **Typography:** 3 typefaces (Plus Jakarta Sans, Inter, Cormorant Garamond), 11 styles
- **Palette:** 5 themes × 2 brightness = 10 complete palettes with exact hex values

### Phase 1 — Vision (Complete)

- Product vision, 4 pillars, design principles, MVP scope documented
- Decision to build local-first, no gamification, no social features

---

## Known Issues (not shipped, documented for tracking)

None at this time. See [BUILD.md](BUILD.md) for build environment issues.
