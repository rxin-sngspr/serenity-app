# Home Screen Refresh — Design Spec

## Overview

Refresh the Story tab (home screen) with brand widgets, proper typography, and a layout that feels like a relationship home rather than a chronological list.

## Layout Architecture

The home screen is a single scrollable `ListView` with 6 widget zones stacked vertically:

1. **Daily Question (Hero)** — Top zone
2. **Quick Actions** — Row of 3 action tiles
3. **Relationship Stats Bar** — Days together, memory count, milestone count
4. **Daily Reflection Nudge** — Shown only if no reflection today
5. **Partner / Sync Status** — Shown only when couple is linked
6. **Timeline** — Existing timeline + calendar (collapsible)

---

### 1. Daily Question (Hero)

**What:** The existing `DailyQuestionCard` at the very top. Not wrapped in any container — full-width card.

**Behavior:**
- If the user hasn't answered today's question: show the full interactive card with the question prompt + answer input
- If they already answered: collapse to a compact single-line summary card with the question text + a peek at their answer. Tap expands inline to show full answer.

**Data:** `questionProvider` (already exists), `todayQuestionAnswerProvider`

**Empty/Loading:** If questions haven't loaded yet, show a skeleton card (40px height, rounded rect with shimmer). If no question for today (edge case), render nothing — the zone collapses.

**Visual:**
- Uses `SerenityCard` or `DailyQuestionCard` as-is (already brand-correct)
- No changes needed to the card itself, just placement

---

### 2. Quick Actions

**What:** Three horizontal tiles replacing the FAB expand menu pattern.

```
┌──────────┐ ┌──────────┐ ┌──────────┐
│  ✏️      │ │  💭      │ │  ⭐      │
│  Memory  │ │  Reflect │ │ Milestone│
└──────────┘ └──────────┘ └──────────┘
```

**Item spec:**
- Width: 100px, Height: 72px
- Background: `Color(0xFF2C2C2E)` (existing card surface)
- Border radius: 12px
- Lucide icon at top (24px), label below (11px Inter Medium)
- Icon color: `theme.colorScheme.primary`
- Label color: `theme.colorScheme.onSurfaceVariant`
- On tap: navigates to create-memory, reflect, or create-milestone respectively
- Haptic feedback on tap

**Data:** No data dependency — purely navigation

**Empty/Loading:** Always visible. No loading state needed.

---

### 3. Relationship Stats Bar

**What:** A horizontal row showing key relationship metrics.

```
❤️  247 days together    📝  34 memories    ⭐  12 milestones
```

**Data:** New `relationshipStatsProvider` that aggregates:
- Days since `start_date` from Settings table (or couple's `linked_at`)
- Total memories from `memoriesDao.countAll()`
- Total milestones from `milestonesDao.countAll()`

**Empty/Loading:** If `start_date` is not set, show a single prompt: "Set your start date →" that navigates to Me screen to set it. Otherwise show the stats.

**Visual:**
- Background: slightly tinted container (primary at 8% opacity)
- Border radius: 12px
- Inner padding: 12px horizontal, 10px vertical
- Each stat: Lucide icon (14px) + number + label. Icon uses primary color.
- Font: Inter 12px Medium for numbers, Inter 10px Regular for labels
- Uses `Wrap` widget to handle narrow screens gracefully

---

### 4. Daily Reflection Nudge

**What:** A compact prompt to reflect if the user hasn't reflected today.

**Visibility:** Only renders when `todayReflectionCountProvider` returns 0 reflections for today.

```
┌──────────────────────────────────────┐
│  💭  How are you feeling today?      │
│       [😢] [🙁] [😐] [🙂] [😊]      │
│            [ Reflect now ]           │
└──────────────────────────────────────┘
```

**Behavior:**
- Shows a 5-emoji mini mood picker row (reuse `ReflectionMoodPicker` but inline, not in a bottom sheet)
- Tapping any mood opens the full Reflect screen with that mood preselected
- After reflecting, this zone auto-hides (provider updates → widget rebuilds)
- If user has already reflected today, this zone doesn't render at all

**Data:** `todayReflectionCountProvider` (exists), `ReflectionMoodPicker` widget (exists)

**Empty/Loading:** Not applicable — either renders or doesn't.

**Visual:**
- Compact card matching Quick Actions surface style
- Inner padding: 12px
- Title: Inter 13px Medium
- Mood icons: 28px each
- "Reflect now" button: TextButton with primary color, compact padding

---

### 5. Partner / Sync Status

**What:** A single-line status indicator for the couple connection.

**Visibility:** Only renders when `coupleStatusProvider` returns a valid couple (i.e., fully linked).

```
●  Connected  ·  Synced 2m ago
```

**Behavior:**
- Green dot when synced, yellow dot when syncing, red dot on error, grey dot when offline
- "Synced X ago" text updates reactively from `syncStateProvider`
- On tap: opens CoupleSettingsScreen for quick partner management
- When partner is not yet linked: this zone doesn't render

**Data:** `coupleStatusProvider`, `syncStateProvider` (both exist)

**Empty/Loading:** No loading state — either renders or doesn't.

**Visual:**
- Small row, minimal height (32px)
- Colored dot: 8px circle
- Text: Inter 11px Medium, `onSurfaceVariant` color
- Right-aligned or full-width with subtle separator line above

---

### 6. Timeline

**What:** The existing timeline content unchanged — calendar toggle, date groups, memory cards, milestone chips, FAB.

**No changes** to the timeline rendering or card components. The FAB remains for quick access but is now a secondary entry point (Quick Actions are primary).

---

## Typography Audit

Replace all inline `fontFamily: 'Inter'` declarations with proper theme text styles. Mapped cases:

| File | Line(s) | Current | Replace With |
|---|---|---|---|
| `timeline_screen.dart` | 39-44, 93-98 | `TextStyle(fontFamily: 'Inter', fontSize: 11, ...)` | `theme.textTheme.labelSmall` |
| `timeline_screen.dart` | 280-281, 290-291 | `TextStyle(fontFamily: 'Inter', fontSize: 14, ...)` | `theme.textTheme.bodyMedium` |
| `timeline_screen.dart` | 328-331 | `TextStyle(fontFamily: 'Inter', fontSize: 14, ...)` | `theme.textTheme.bodyMedium` |
| `empty_state.dart` | all | Inline Inter | `theme.textTheme` equivalent |
| `create_memory_screen.dart` | various | Inline Inter | body theme styles |
| `create_milestone_screen.dart` | various | Inline Inter | body theme styles |
| `reflect_screen.dart` | various | Inline Inter | body/label theme styles |
| `understand_screen.dart` | various | Inline Inter | body/label theme styles |

---

## New Files

### `lib/core/components/home_stats_bar.dart`
- New `HomeStatsBar` ConsumerWidget
- Reads `relationshipStatsProvider`
- Renders the stats row with icons
- Handles "no start date" state

### `lib/core/components/quick_actions.dart`
- New `QuickActions` stateless widget
- Three action tiles in a `Row` with `Expanded` children
- Navigation callbacks passed in

### `lib/core/components/reflection_nudge.dart`
- New `ReflectionNudge` ConsumerWidget
- Reads `todayReflectionCountProvider`
- Shows mood picker + reflect button when count is 0
- Tapping mood navigates to Reflect tab with preselected mood

### `lib/core/components/partner_status.dart` (optional)
- New `PartnerStatus` ConsumerWidget
- Reads `coupleStatusProvider` + `syncStateProvider`
- Single-line status with colored dot
- Only renders when couple is linked

## New Providers

### `lib/features/story/providers/home_providers.dart`
- `relationshipStatsProvider` — FutureProvider that returns `({int daysTogether, int memoryCount, int milestoneCount})`
- Reads from Settings table (`start_date`), Memories DAO (count), Milestones DAO (count)
- Handles missing start_date gracefully (returns null for that field)

---

## Implementation Order

**Phase A — Font fixes only** (15 min, pure refactor, no visual change)
- Replace all inline `fontFamily: 'Inter'` with proper theme text styles across all files
- Verify with `dart analyze`

**Phase B — Hero zone + Stats bar** (45 min)
- Move DailyQuestionCard to top of timeline layout
- Create `HomeStatsBar` widget + `relationshipStatsProvider`
- Wire into timeline_screen.dart

**Phase C — Quick Actions + Reflection Nudge** (30 min)
- Create `QuickActions` widget
- Create `ReflectionNudge` widget
- Insert between daily question and stats bar

**Phase D — Partner Status + Polish** (30 min)
- Create `PartnerStatus` widget
- Final spacing/alignment pass
- Test with both linked and unlinked states

---

## Motion Spec

- Widget zones stagger in on first load: hero (0ms), quick actions (100ms), stats (150ms), nudge (200ms), partner status (250ms)
- Use `AnimatedOpacity` + `SlideTransition` (offset 20px up) with 300ms duration, `Curves.easeOut`
- Stats numbers animate on change using `TweenAnimationBuilder` (200ms)
- Reflection nudge fades in/out on state change (300ms)
- No motion on subsequent scroll — only on first render per session

## Accessibility

- All touch targets minimum 44x44px (Quick Actions exceed this at 100x72)
- Colored dot for sync status also has text label (not color-only)
- Stat icons have semantic labels for screen readers
- Reflection nudge mood emojis wrapped in `Semantics` with label text
