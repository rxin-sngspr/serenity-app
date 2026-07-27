# Tier 3 — Reflect Expansion & Understand Pillar

## Brand Context
- **Theme**: 5 themes (Warm Rose default, Sage, Ocean, Terracotta, Lavender), dark/light mode
- **Fonts**: Plus Jakarta Sans (headings), Inter (body), Cormorant Garamond (editorial/reflective, italic)
- **Icons**: LucideIcons throughout
- **Core values**: Private, local-first, no analytics, no gamification, no metrics
- **Pillars**: Remember (Story), Reflect, Appreciate, Understand

## 1. Reflection Expansion

### Current State
- Single hardcoded prompt: "What made you feel most connected today?"
- One reflection per day (upserts by date)
- No editing of past reflections
- No prompt rotation

### Changes

#### 1a. Reflection Prompts (separate from daily questions)
- New file: `assets/questions/reflection_prompts.json`
- 15+ prompts focused on daily connection and gratitude
- Examples:
  - "What made you feel most connected today?"
  - "What moment today are you most grateful for?"
  - "What did your partner do today that made you smile?"
  - "What's something you learned about your relationship today?"
  - "What energy did you bring to your relationship today?"
  - "What's one thing you'd like to do differently tomorrow?"
  - "What boundary did you honor today?"
  - "How did you show love to yourself today?"
  - "What made you feel seen today?"
  - "What's a small win you had today?"

#### 1b. Reflection Cycling
- Load from JSON, cycle through prompts using same date-based offset as daily questions
- Track used prompts per day (separate from daily questions)
- `ReflectionCards` table: add `promptId` column for tracking which prompt was used

#### 1c. Multi-Reflection (3/day)
- Allow up to 3 reflections per day
- Each with its own prompt from the rotation
- Show "X remaining today" counter
- All 3 appear in the recent reflections list

#### 1d. Past Reflection Editing
- Tapping a past reflection tile opens an edit bottom sheet
- Similar to `_showPastAnswer` pattern
- Updates the existing reflection row (already supported by `updateReflection`)

#### 1e. Mood Score
- The `moodScore` column already exists in the `Reflections` table (nullable integer)
- Add a 5-emoji mood picker below the reflection text input
- Save mood score with reflection
- Display as emoji dots in the reflection tiles

### UI Design (from visualizer.html)
- Reflection card: centered, `reflection-card` class style
  - "Today's Reflection" label (Plus Jakarta Sans 14px 500, text-secondary)
  - Date (Inter 12px, text-secondary)
  - Prompt text (Cormorant Garamond 18px italic 500, body text)
  - Text input field (Inter, multi-line)
  - Mood picker row (5 emoji/dot choices)
  - Save button (right-aligned, tonal)
- Past reflection tiles: SerenityCard with title (prompt), content preview (Cormorant italic, max 3 lines), date
- Reflection count banner: "3 remaining today" label

## 2. Understand Pillar

### Current State
- No Understand tab, screen, or feature exists
- 4th Serenity pillar is completely missing

### Design
- New 4th tab in bottom nav: Story | Reflect | Understand | Me
- LucideIcons icon: `LucideIcons.brainCircuit` or `LucideIcons.sparkles`
- Screen structure with 3 sections:

#### 2a. Our Patterns
- Shows trends from question answers over time
- Category distribution (Deep Talk, Fun, Never Have I Ever, Spicy) — how many answers per category
- Answer streak: consecutive days with answers
- NO scores, NO percentages, NO gamification. Pure pattern observation.

#### 2b. Memory Themes
- Tag cloud or cluster from memory tags
- Timeline density visualization (calendar heatmap from existing data)
- Most-used tags, tag combinations over time
- "Your shared vocabulary" — list of recurring themes

#### 2c. Reflection Insights
- Mood trends (average mood score over time)
- Most-used reflection prompt categories
- Writing consistency (how often reflections are written)

### Key Constraint
- **No metrics, no gamification.** No streaks displayed as competition, no scores, no rankings. Pure insight and pattern recognition. This aligns with Serenity's privacy-first philosophy.

## Files to Create
- `assets/questions/reflection_prompts.json`
- `lib/features/understand/screens/understand_screen.dart`
- `lib/features/understand/providers/understand_provider.dart`
- `lib/features/reflect/widgets/reflection_prompt_pool.dart` (provider for reflection prompts)

## Files to Modify
- `lib/core/router/app_router.dart` — add Understand tab to StatefulShellRoute
- `lib/core/components/serenity_bottom_nav.dart` — add 4th tab item
- `lib/features/reflect/widgets/reflection_card.dart` — multi-prompt, mood picker, 3/day limit
- `lib/features/reflect/widgets/daily_question_card.dart` — persist refresh count to SyncMetadata
- `lib/features/reflect/screens/reflect_screen.dart` — reflection count banner, edit past reflections
- `lib/core/database/daos/reflections_dao.dart` — add promptId query support if needed
- `lib/features/reflect/repositories/question_repository.dart` (not needed — separate file for reflections)

## Not In Scope
- Partner visibility/sync (deferred to future Tier)
- Daily question refresh persistence (small fix, handled separately)
- Visualizer UI polish pass (deferred)
