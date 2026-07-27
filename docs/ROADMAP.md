# Serenity — Roadmap

> **Owner:** Product + Engineering teams
> **Purpose:** Track progress by milestones with clear gates. Product decisions in [PRODUCT.md](PRODUCT.md), build concerns in [BUILD.md](BUILD.md).
> **Related:** [Product Guide](PRODUCT.md) | [Architecture](ARCHITECTURE.md) | [Changelog](CHANGELOG.md) | [Decisions](DECISIONS.md)

---

## Milestone Structure

Each milestone has:
- **Goal** — What we're trying to achieve
- **Definition of Done** — Explicit pass/fail criteria
- **Current Status** — % complete or blocked/stopped
- **Risks** — What could prevent completion
- **Dependencies** — What must be true before starting
- **Exit Criteria** — What proves this milestone is complete

---

## Phase 1: Vision

| Field | Detail |
|-------|--------|
| **Goal** | Define the product vision, pillars, and scope |
| **Status** | ✅ Complete |
| **Risks** | None |
| **Dependencies** | None |
| **Exit Criteria** | Product vision documented, pillars defined, MVP scope agreed |

---

## Phase 2: Design System

| Field | Detail |
|-------|--------|
| **Goal** | Create visual identity, theme system, and component library |
| **Status** | ✅ Complete |
| **Risks** | None |
| **Dependencies** | Phase 1 (vision) |
| **Exit Criteria** | 5 themes defined, typography system documented, 10+ shared components built |

---

## Phase 3: Architecture

| Field | Detail |
|-------|--------|
| **Goal** | Establish the technical foundation: Flutter, Drift, Riverpod, local-first pattern |
| **Status** | ✅ Complete |
| **Risks** | None |
| **Dependencies** | Phase 1 (vision), Phase 2 (design system) |
| **Exit Criteria** | Local DB schema v1 working, DAOs built, providers wired, navigation working |

---

## Phase 4: Flutter Foundation

| Field | Detail |
|-------|--------|
| **Goal** | Core features working locally: memories, milestones, timeline, reflections, tags |
| **Status** | ✅ Complete |
| **Dependencies** | Phase 3 (architecture) |
| **Risks** | Feature creep (scope trimmed to MVP) |
| **Exit Criteria** | User can create memories, milestones, reflections, view timeline, manage tags |

---

## Phase 5: Supabase Integration

| Field | Detail |
|-------|--------|
| **Goal** | Auth, couple linking, and sync engine working end-to-end |
| **Status** | 🔄 In Progress (~95%) |
| **Risks** | Build environment issues (NDK/CMake), passkeys native compilation, SQL schema drift |
| **Dependencies** | Phase 4 (foundation), Supabase project provisioned, anon key available |
| **Exit Criteria** | See build verification checklist below |

### Remaining Work

- [x] SQL schema deployed to Supabase (8 tables, 23 RLS policies)
- [x] 16 implementation files created (auth, couple, sync engine, providers)
- [x] All DAOs set isSynced=false on writes
- [x] AuthGate routes unauthenticated → sign in, uncoupled → couple linking
- [x] INTERNET permission fix applied
- [x] publishableKey parameter (fixed deprecation)
- [x] CMake 3.31.4 configured (bypasses NDK 28 incompatibility)
- [x] Flutter analyze: 0 errors, 0 warnings
- [ ] Build release APK on clean machine
- [ ] Install APK on device
- [ ] Verify sign-up works
- [ ] Verify sign-in + session persist
- [ ] Verify couple linking (create + join invite code)
- [ ] Verify memory syncs to partner
- [ ] Verify offline → online sync recovery

### Build Verification Checklist

This is the Phase 5 Definition of Done. All must pass:

1. APK installs successfully
2. App launches
3. Sign Up works (email + password + profile creation)
4. Sign In works
5. Session persists across app restarts
6. Create Couple works (generate invite code)
7. Invite Code entry works (join couple)
8. Partner joins successfully
9. Create Memory works
10. Memory syncs to partner
11. Offline edits sync after reconnect
12. Sync status indicator shows correct state

---

## Phase 6: Closed Alpha

| Field | Detail |
|-------|--------|
| **Goal** | First real-couple test. Ship APK to trusted users and validate end-to-end. |
| **Status** | ⏳ Not Started |
| **Risks** | Undiscovered edge cases in sync, couple linking UX confusion |
| **Dependencies** | Phase 5 (Supabase), clean build, install on 2 devices |
| **Exit Criteria** | At least one external couple successfully uses the app for 1 week |

---

## Phase 7: Public Beta

| Field | Detail |
|-------|--------|
| **Goal** | Open TestFlight/Google Play beta for broader feedback |
| **Status** | ⏳ Not Started |
| **Risks** | Scaling Supabase, unexpected database load, feedback volume |
| **Dependencies** | Phase 6 (alpha validation), Play Store/App Store account, production code signing |
| **Exit Criteria** | 50+ active couples, crash-free rate > 99.5% |

---

## Phase 8: Play Store Release

| Field | Detail |
|-------|--------|
| **Goal** | Public launch |
| **Status** | ⏳ Not Started |
| **Risks** | App Store review, privacy compliance, long-term maintenance |
| **Dependencies** | Phase 7 (beta), legal review, marketing assets |
| **Exit Criteria** | App published on Google Play, 100+ downloads |

---

## History

See [CHANGELOG.md](CHANGELOG.md) for completed work by version.

## Architecture Decisions

See [DECISIONS.md](DECISIONS.md) for every major architectural choice and its rationale.
