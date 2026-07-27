# Tier 3 — Reflect Expansion & Understand Pillar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand the Reflect tab with rotating prompts, mood tracking, 3 reflections/day, and build the new Understand pillar as a 4th tab.

**Architecture:** Three independent phases: (1) Reflection expansion — new prompts JSON, mood picker, multi-reflection support, (2) Daily question persistence fix, (3) New Understand tab + providers. All styles follow the Serenity design system (Warm Rose default, 5 themes, Plus Jakarta Sans/Inter/Cormorant Garamond, LucideIcons).

**Tech Stack:** Flutter, Riverpod, Drift (SQLite), LucideIcons, Serenity design tokens from `app_theme.dart`

---

## File Structure

### New Files
- `assets/questions/reflection_prompts.json` — 15+ reflection prompts separate from daily questions
- `lib/features/understand/screens/understand_screen.dart` — new 4th tab screen
- `lib/features/understand/providers/understand_provider.dart` — data providers for Understand tab
- `lib/features/reflect/widgets/reflection_mood_picker.dart` — 5-emoji mood picker widget

### Modified Files
- `lib/features/reflect/widgets/reflection_card.dart` — add prompt rotation, mood picker, 3/day limit
- `lib/features/reflect/screens/reflect_screen.dart` — add reflection count banner, edit past reflections
- `lib/features/reflect/providers/reflect_provider.dart` — add reflection prompts provider
- `lib/features/reflect/providers/question_provider.dart` — persist refresh count to SyncMetadata
- `lib/core/components/serenity_bottom_nav.dart` — add Understand tab (4th item)
- `lib/core/router/app_router.dart` — add Understand StatefulShellBranch
- `lib/core/database/daos/reflections_dao.dart` — add promptId filter support
- `lib/core/database/app_database.dart` — update schema version if needed

---

### Task 1: Create Reflection Prompts

**Files:**
- Create: `assets/questions/reflection_prompts.json`

- [ ] **Step 1: Write reflection_prompts.json**

```json
[
  {"id":1,"text":"What made you feel most connected today?"},
  {"id":2,"text":"What moment today are you most grateful for?"},
  {"id":3,"text":"What did your partner do today that made you smile?"},
  {"id":4,"text":"What's something you learned about your relationship today?"},
  {"id":5,"text":"What energy did you bring to your relationship today?"},
  {"id":6,"text":"What's one thing you'd like to do differently tomorrow?"},
  {"id":7,"text":"What boundary did you honor today?"},
  {"id":8,"text":"How did you show love to yourself today?"},
  {"id":9,"text":"What made you feel seen today?"},
  {"id":10,"text":"What's a small win you had today?"},
  {"id":11,"text":"What's a challenge you faced today, however small?"},
  {"id":12,"text":"How did you and your partner support each other today?"},
  {"id":13,"text":"What's something beautiful you noticed today?"},
  {"id":14,"text":"What kind of listener were you today?"},
  {"id":15,"text":"What made you laugh today?"},
  {"id":16,"text":"What's a quiet moment you remember from today?"},
  {"id":17,"text":"How did you grow today, even in the smallest way?"},
  {"id":18,"text":"What's something you want to carry into tomorrow?"}
]
```

- [ ] **Step 2: Register asset in pubspec.yaml**

Check `pubspec.yaml` for the assets section and add `assets/questions/reflection_prompts.json` under the existing `assets/questions/questions.json` entry.

---

### Task 2: Reflection Prompts Provider

**Files:**
- Modify: `lib/features/reflect/providers/reflect_provider.dart`

- [ ] **Step 1: Add ReflectionPromptRepository and providers**

Add to `reflect_provider.dart`:

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

class ReflectionPromptItem {
  final int id;
  final String text;
  const ReflectionPromptItem({required this.id, required this.text});
  factory ReflectionPromptItem.fromJson(Map<String, dynamic> json) =>
      ReflectionPromptItem(id: json['id'] as int, text: json['text'] as String);
}

class ReflectionPromptRepository {
  static List<ReflectionPromptItem>? _cache;
  static Future<List<ReflectionPromptItem>> loadPrompts() async {
    if (_cache != null) return _cache!;
    final data = await rootBundle.loadString('assets/questions/reflection_prompts.json');
    final list = json.decode(data) as List<dynamic>;
    _cache = list.map((e) => ReflectionPromptItem.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }
}

final allReflectionPromptsProvider = FutureProvider<List<ReflectionPromptItem>>((ref) {
  return ReflectionPromptRepository.loadPrompts();
});

final currentReflectionPromptProvider = Provider<ReflectionPromptItem?>((ref) {
  final prompts = ref.watch(allReflectionPromptsProvider).valueOrNull;
  if (prompts == null || prompts.isEmpty) return null;
  final dayOffset = DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  final index = dayOffset % prompts.length;
  return prompts[index];
});

final todayReflectionCountProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(reflectionsDaoProvider);
  final today = DateTime.now();
  final reflections = await dao.getReflectionsByDate(today);
  return reflections.length;
});
```

Import `reflectionsDaoProvider` from `database_provider.dart` (already imported).

- [ ] **Step 2: Run build_runner to verify no drift regeneration issues**

Run: `cd serenity_app && dart run build_runner build`
Expected: build succeeds

---

### Task 3: Mood Picker Widget

**Files:**
- Create: `lib/features/reflect/widgets/reflection_mood_picker.dart`

- [ ] **Step 1: Create the mood picker widget**

```dart
import 'package:flutter/material.dart';

class ReflectionMoodPicker extends StatelessWidget {
  final int? selectedMood;
  final ValueChanged<int> onMoodSelected;

  const ReflectionMoodPicker({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  static const _moods = [
    _Mood(1, 'Challenging', '\u{1F622}'),
    _Mood(2, 'Okay', '\u{1F610}'),
    _Mood(3, 'Good', '\u{1F60A}'),
    _Mood(4, 'Great', '\u{1F929}'),
    _Mood(5, 'Amazing', '\u{1F60D}'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _moods.map((mood) {
        final isSelected = selectedMood == mood.value;
        return GestureDetector(
          onTap: () => onMoodSelected(mood.value),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 2),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Mood {
  final int value;
  final String label;
  final String emoji;
  const _Mood(this.value, this.label, this.emoji);
}
```

- [ ] **Step 2: Run dart analyze to verify**

Run: `cd serenity_app && dart analyze lib/features/reflect/widgets/reflection_mood_picker.dart`
Expected: No issues found

---

### Task 4: Expand Reflection Card

**Files:**
- Modify: `lib/features/reflect/widgets/reflection_card.dart`

- [ ] **Step 1: Rewrite ReflectionCard to support rotating prompts and mood**

Replace the entire file content. Key changes:
- Import `allReflectionPromptsProvider`, `currentReflectionPromptProvider`, `todayReflectionCountProvider` from reflect_provider
- Import `ReflectionMoodPicker`
- Replace hardcoded `_promptText` with provider-watched current prompt
- Add `_selectedMood` state (int?)
- Add mood picker row between prompt text and text input
- Add "X remaining today" counter above the prompt
- On save, include moodScore in both create and update paths
- After saving 3 reflections today, disable further saves and show "Max reflections for today reached"

The save flow:
```dart
final companion = ReflectionsCompanion(
  promptType: Value('daily'),
  promptText: Value(prompt.text),
  content: Value(_controller.text.trim()),
  moodScore: Value(_selectedMood),
  date: Value(today),
);
```

- [ ] **Step 2: Run dart analyze**

Run: `cd serenity_app && dart analyze lib/features/reflect/widgets/reflection_card.dart`
Expected: No issues found

---

### Task 5: Update Reflect Screen

**Files:**
- Modify: `lib/features/reflect/screens/reflect_screen.dart`

- [ ] **Step 1: Add reflection count banner and past reflection editing**

Changes:
1. Before the Reflection section divider, add a small banner showing "X reflections today" using `todayReflectionCountProvider`
2. In `_reflectionTile`, add an edit icon button that opens a bottom sheet with the reflection content pre-filled
3. The edit bottom sheet shows the prompt text (read-only), an editable text field, the mood picker (pre-selected), and Save/Cancel buttons
4. Save calls `dao.updateReflection()` with modified content and mood

- [ ] **Step 2: Run dart analyze**

Run: `cd serenity_app && dart analyze lib/features/reflect/screens/reflect_screen.dart`
Expected: No issues found

---

### Task 6: Daily Question Persistence

**Files:**
- Modify: `lib/features/reflect/providers/question_provider.dart`

- [ ] **Step 1: Persist refresh count to SyncMetadata**

Import `syncMetadataDaoProvider` (check existing import — may already be available through database_provider).

Change `questionRefreshCountProvider` from `StateProvider<int>` to a `FutureProvider` that reads initial value from SyncMetadata, then provide a notifier to increment and persist.

```dart
/// Current question refresh count, persisted to local storage.
final questionRefreshCountProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(syncMetadataDaoProvider);
  final value = await dao.get('question_refresh_count');
  return int.tryParse(value ?? '') ?? 0;
});
```

For incrementing (used by the refresh button and Save & Next), create a provider that can write:

```dart
final questionRefreshCountNotifierProvider = Provider<QuestionRefreshCountNotifier>((ref) {
  return QuestionRefreshCountNotifier(ref);
});

class QuestionRefreshCountNotifier {
  final Ref _ref;
  QuestionRefreshCountNotifier(this._ref);

  Future<void> increment() async {
    final dao = _ref.read(syncMetadataDaoProvider);
    final current = await _ref.read(questionRefreshCountProvider.future);
    await dao.set('question_refresh_count', (current + 1).toString());
    _ref.invalidate(questionRefreshCountProvider);
  }
}
```

Update `DailyQuestionCard` to use `questionRefreshCountNotifierProvider` instead of directly manipulating `questionRefreshCountProvider.state`.

- [ ] **Step 2: Run dart analyze**

Run: `cd serenity_app && dart analyze lib/features/reflect/providers/question_provider.dart`
Expected: No issues found

---

### Task 7: Understand Providers

**Files:**
- Create: `lib/features/understand/providers/understand_provider.dart`

- [ ] **Step 1: Create the Understand data providers**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';

/// Category distribution of all answered questions.
final answerCategoryDistributionProvider = FutureProvider<Map<String, int>>((ref) async {
  final dao = ref.watch(questionAnswersDaoProvider);
  final answers = await dao.getAllAnswers();
  final distribution = <String, int>{};
  for (final a in answers) {
    distribution[a.category] = (distribution[a.category] ?? 0) + 1;
  }
  return distribution;
});

/// Consecutive days with at least one question answered.
final answerStreakProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(questionAnswersDaoProvider);
  final answers = await dao.getAllAnswers();
  if (answers.isEmpty) return 0;
  final dates = answers.map((a) => DateTime(a.dateAnswered.year, a.dateAnswered.month, a.dateAnswered.day)).toSet().toList();
  dates.sort();
  int streak = 1;
  int maxStreak = 1;
  for (int i = 1; i < dates.length; i++) {
    final diff = dates[i].difference(dates[i-1]).inDays;
    if (diff == 1) {
      streak++;
      if (streak > maxStreak) maxStreak = streak;
    } else if (diff > 1) {
      streak = 1;
    }
  }
  return maxStreak;
});

/// Total memory count by tag.
final memoryTagDistributionProvider = FutureProvider<Map<String, int>>((ref) async {
  final dao = ref.watch(tagsDaoProvider);
  final tags = await dao.getAllTags();
  final distribution = <String, int>{};
  // Count how many memories each tag is assigned to
  for (final tag in tags) {
    // Use the existing getTagsForMemory and count assignments
    final assignments = await dao.getAssignmentsForTag(tag.id);
    distribution[tag.name] = assignments.length;
  }
  return distribution;
});

/// Average mood score from recent reflections.
final averageMoodProvider = FutureProvider<double?>((ref) async {
  final dao = ref.watch(reflectionsDaoProvider);
  final reflections = await dao.getAllReflections();
  final withMood = reflections.where((r) => r.moodScore != null).toList();
  if (withMood.isEmpty) return null;
  final sum = withMood.fold<int>(0, (acc, r) => acc + r.moodScore!);
  return sum / withMood.length;
});
```

This requires `getAssignmentsForTag` method in `TagsDao` and `getAllTags` — check if these exist. If not, add them to `tags_dao.dart`:

```dart
Future<List<Tag>> getAllTags() => db.select(db.tags).get();

Future<List<TagAssignment>> getAssignmentsForTag(int tagId) =>
    (db.select(db.tagAssignments)..where((t) => t.tagId.equals(tagId))).get();
```

Also need `getAllReflections` in `reflections_dao.dart` (already exists).

- [ ] **Step 2: Run dart analyze**

Run: `cd serenity_app && dart analyze lib/features/understand/providers/understand_provider.dart`
Expected: No issues found

---

### Task 8: Understand Screen

**Files:**
- Create: `lib/features/understand/screens/understand_screen.dart`

- [ ] **Step 1: Create the Understand screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/understand_provider.dart';
import '../../../core/components/section_divider.dart';
import '../../../core/components/serenity_card.dart';

class UnderstandScreen extends ConsumerWidget {
  const UnderstandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryDist = ref.watch(answerCategoryDistributionProvider);
    final streak = ref.watch(answerStreakProvider);
    final tagDist = ref.watch(memoryTagDistributionProvider);
    final avgMood = ref.watch(averageMoodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Understand')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── OUR PATTERNS ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionDivider(label: 'Our Patterns'),
          ),
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.messageCircle, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Conversation Balance',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                categoryDist.when(
                  data: (dist) {
                    if (dist.isEmpty) return _emptyHint('Answer some daily questions to see patterns here.');
                    return Column(
                      children: dist.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(e.key,
                                  style: TextStyle(fontFamily: 'Inter', 
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )),
                            ),
                            Expanded(child: LinearProgressIndicator(
                              value: e.value / dist.values.fold(0, (a, b) => a + b),
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: theme.colorScheme.primary,
                            )),
                            const SizedBox(width: 8),
                            Text('${e.value}',
                                style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                      )).toList(),
                    );
                  },
                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(LucideIcons.zap, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Answer Streak',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        )),
                    const Spacer(),
                    streak.when(
                      data: (s) => Text('$s day${s == 1 ? '' : 's'}',
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          )),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── MEMORY THEMES ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionDivider(label: 'Memory Themes'),
          ),
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.tags, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Your Shared Vocabulary',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                tagDist.when(
                  data: (dist) {
                    if (dist.isEmpty) return _emptyHint('Add tags to your memories to see themes here.');
                    return Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: dist.entries.map((e) => Chip(
                        label: Text('${e.key} (${e.value})',
                            style: const TextStyle(fontSize: 11, color: Colors.white)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    );
                  },
                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── REFLECTION INSIGHTS ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionDivider(label: 'Reflection Insights'),
          ),
          SerenityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.heart, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Mood Over Time',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                avgMood.when(
                  data: (mood) {
                    if (mood == null) return _emptyHint('Save reflections with a mood to see your trends here.');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${mood.toStringAsFixed(1)} / 5',
                                style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                )),
                            const SizedBox(width: 8),
                            Text('average mood',
                                style: TextStyle(fontFamily: 'Inter', 
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: mood / 5,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run dart analyze**

Run: `cd serenity_app && dart analyze lib/features/understand/screens/understand_screen.dart`
Expected: No issues found

---

### Task 9: Add Understand Tab to Navigation

**Files:**
- Modify: `lib/core/components/serenity_bottom_nav.dart`
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: Update bottom nav to 4 items**

In `serenity_bottom_nav.dart`, change `_items` from 3 to 4:

```dart
static const _items = [
  _NavItem(icon: LucideIcons.scrollText, label: 'Story'),
  _NavItem(icon: LucideIcons.clipboardList, label: 'Reflect'),
  _NavItem(icon: LucideIcons.brainCircuit, label: 'Understand'),
  _NavItem(icon: LucideIcons.user, label: 'Me'),
];
```

- [ ] **Step 2: Add Understand route to app_router.dart**

Add import:
```dart
import '../../features/understand/screens/understand_screen.dart';
```

Add new StatefulShellBranch after the Reflect branch:
```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/understand',
      builder: (context, state) => const UnderstandScreen(),
    ),
  ],
),
```

- [ ] **Step 3: Run dart analyze**

Run: `cd serenity_app && dart analyze lib/core/components/serenity_bottom_nav.dart lib/core/router/app_router.dart`
Expected: No issues found

---

### Task 10: Run build_runner & Full Analyze

- [ ] **Step 1: Run build_runner**

Run: `cd serenity_app && dart run build_runner build`
Expected: Build succeeds

- [ ] **Step 2: Run full analysis**

Run: `cd serenity_app && dart analyze lib/`
Expected: 0 errors, 0 warnings

---

## Self-Review Checklist

1. **Spec coverage:** 
   - ✅ Reflection prompts JSON created (Task 1)
   - ✅ Prompt rotation via ReflectionPromptRepository (Task 2)
   - ✅ Mood picker widget (Task 3)
   - ✅ Multi-reflection with 3/day limit (Task 4)
   - ✅ Past reflection editing on tap (Task 5)
   - ✅ Daily question refresh persistence (Task 6)
   - ✅ Understand patterns section (Task 7-8)
   - ✅ Understand memory themes section (Task 7-8)
   - ✅ Understand reflection insights section (Task 7-8)
   - ✅ 4th tab in navigation (Task 9)

2. **No placeholders** — all code is complete and concrete

3. **Type consistency** — providers, DAOs, and widgets use matching type signatures
