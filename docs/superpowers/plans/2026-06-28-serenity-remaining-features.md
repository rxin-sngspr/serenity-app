# Serenity Remaining Features — Implementation Plan

**Date:** 2026-06-28
**Author:** onyx-architect
**Phase:** Planning
**Target Flutter SDK:** ^3.12.1
**Current schemaVersion:** 1
**Target schemaVersion:** 2

---

## Overview

Four remaining feature areas for the Serenity Flutter app, ordered by dependency:

1. **Supabase Prep** (foundation for sync — schema changes affect everything else)
2. **Custom Tags System** (replaces free-form MemoryTags)
3. **Anniversary Section** (type field on Milestones + relationship age)
4. **Build Release APK** (signing config + release build)

The order matters. Schema changes in Supabase Prep (schemaVersion bump to 2) should happen first since Tags and Anniversary both add columns/tables. The APK build is last.

---

## Feature 1: Supabase Prep

### Goal
Prepare the database schema and config for future Supabase sync. No sync logic yet — just the columns, dependency, and client config.

### 1.1 Database Schema Changes

**Milestones table** — add missing `updatedAt`:
```dart
// CURRENT: no updatedAt column
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

// AFTER:
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
```

**Add `isSynced` column to 4 data tables:**

- `Memories` — add `BoolColumn get isSynced => boolean().withDefault(const Constant(false))();`
- `Milestones` — add same
- `Reflections` — add same
- `QuestionAnswers` — add same

**No changes needed on:**
- `Settings` (key-value, synced differently or not at all)
- `MemoryMedia` (pulled via memory relationship)
- `MemoryTags` (being replaced — see Feature 2)

### 1.2 Migration Strategy (schemaVersion 1 -> 2)

```dart
// In AppDatabase
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Milestones: add updatedAt
        await m.addColumn(milestones, milestones.updatedAt);
        // Set existing updatedAt = createdAt for backward compat
        await customStatement(
          'UPDATE milestones SET updated_at = created_at WHERE updated_at IS NULL',
        );

        // Add isSynced to Memories
        await m.addColumn(memories, memories.isSynced);

        // Add isSynced to Milestones
        await m.addColumn(milestones, milestones.isSynced);

        // Add isSynced to Reflections
        await m.addColumn(reflections, reflections.isSynced);

        // Add isSynced to QuestionAnswers
        await m.addColumn(questionAnswers, questionAnswers.isSynced);

        // Mark all existing rows as synced (they're local, no pending sync)
        await customStatement('UPDATE memories SET is_synced = 1');
        await customStatement('UPDATE milestones SET is_synced = 1');
        await customStatement('UPDATE reflections SET is_synced = 1');
        await customStatement('UPDATE question_answers SET is_synced = 1');
      }
    },
  );
}
```

### 1.3 New Dependency

Add to `pubspec.yaml`:
```yaml
supabase_flutter: ^2.8.0
```

Then run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` to regenerate drift models.

### 1.4 File Changes

| File | Change |
|------|--------|
| `lib/core/database/tables/milestones_table.dart` | Add `updatedAt` column |
| `lib/core/database/tables/memories_table.dart` | Add `isSynced` column |
| `lib/core/database/tables/milestones_table.dart` | Add `isSynced` column |
| `lib/core/database/tables/reflections_table.dart` | Add `isSynced` column |
| `lib/core/database/tables/question_answers_table.dart` | Add `isSynced` column |
| `lib/core/database/app_database.dart` | Bump schemaVersion to 2, add migration steps |
| `lib/core/supabase/supabase_config.dart` | **NEW** — Supabase client config with placeholder values |
| `pubspec.yaml` | Add `supabase_flutter` dependency |
| `lib/main.dart` | Initialize Supabase client before runApp |

### 1.5 Supabase Config File

```dart
// lib/core/supabase/supabase_config.dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
```

In `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: SerenityApp()));
}
```

### 1.6 Supabase Tables (for reference — created in Supabase dashboard)

Run this SQL in Supabase SQL Editor when ready:

```sql
CREATE TABLE memories (
  id BIGINT PRIMARY KEY,
  type TEXT DEFAULT 'memory',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_favorite BOOLEAN DEFAULT FALSE,
  is_synced BOOLEAN DEFAULT FALSE
);

CREATE TABLE milestones (
  id BIGINT PRIMARY KEY,
  title TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  description TEXT,
  icon TEXT,
  color TEXT,
  type TEXT DEFAULT 'milestone',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_synced BOOLEAN DEFAULT FALSE
);

CREATE TABLE reflections (
  id BIGINT PRIMARY KEY,
  prompt_type TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  content TEXT NOT NULL,
  mood_score INT,
  date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_synced BOOLEAN DEFAULT FALSE
);

CREATE TABLE question_answers (
  id BIGINT PRIMARY KEY,
  question_id INT NOT NULL,
  category TEXT NOT NULL,
  answer_text TEXT NOT NULL,
  date_answered TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_synced BOOLEAN DEFAULT FALSE
);
```

---

## Feature 2: Custom Tags System

### Goal
Replace free-form text tags with structured tags that have color, icon, and preset/ custom distinction. Keep it simple — no taxonomy, no hierarchy, no tag groups.

### 2.1 Database Schema Changes

**New table: `Tags`** (`lib/core/database/tables/tags_table.dart`):
```dart
import 'package:drift/drift.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();  // hex string, nullable for presets without color override
  TextColumn get icon => text().nullable()();    // lucide icon name
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
```

**New table: `TagAssignments`** (`lib/core/database/tables/tag_assignments_table.dart`):
```dart
import 'package:drift/drift.dart';

@TableIndex(name: 'tag_assignments_memory_id_idx', columns: {#memoryId})
@TableIndex(name: 'tag_assignments_tag_id_idx', columns: {#tagId})
class TagAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tagId => integer()();
  IntColumn get memoryId => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
```

**Drop table: `MemoryTags`** — remove from DriftDatabase list and migration.

### 2.2 Preset Tags (10)

Seeded on migration from schemaVersion 1->2 if they don't exist:

| Name | Icon (Lucide) | Color |
|------|---------------|-------|
| Date Night | LucideIcons.heart | #D4737A |
| Travel | LucideIcons.plane | #6A9FB5 |
| Growth | LucideIcons.trendingUp | #7A9E7A |
| Grateful | LucideIcons.heartHandshake | #E9C46A |
| Challenge | LucideIcons.shield | #C27A5A |
| Inside Joke | LucideIcons.laugh | #CDB4DB |
| Romantic | LucideIcons.sparkles | #E8A87C |
| Family | LucideIcons.users | #A8DADC |
| Friends | LucideIcons.userPlus | #8A7AB5 |
| Milestone | LucideIcons.star | #F4A261 |

### 2.3 Migration Steps (schemaVersion 1 -> 2, continued)

In the existing `from < 2` block, add:

```dart
// Create Tags table
await m.createTable(tags);

// Create TagAssignments table
await m.createTable(tagAssignments);

// Migrate existing free-form tags to Tags table
await customStatement('''
  INSERT OR IGNORE INTO tags (name, is_preset, is_synced)
  SELECT DISTINCT tag, 0, 1 FROM memory_tags
''');

// Create tag assignments for existing relationships
await customStatement('''
  INSERT INTO tag_assignments (tag_id, memory_id, is_synced)
  SELECT t.id, mt.memory_id, 1
  FROM memory_tags mt
  JOIN tags t ON t.name = mt.tag
''');

// Drop old MemoryTags table
await m.deleteTable('memory_tags');

// Seed preset tags
final presets = [
  ('Date Night', '#D4737A', 'heart'),
  ('Travel', '#6A9FB5', 'plane'),
  ('Growth', '#7A9E7A', 'trending_up'),
  ('Grateful', '#E9C46A', 'heart_handshake'),
  ('Challenge', '#C27A5A', 'shield'),
  ('Inside Joke', '#CDB4DB', 'laugh'),
  ('Romantic', '#E8A87C', 'sparkles'),
  ('Family', '#A8DADC', 'users'),
  ('Friends', '#8A7AB5', 'user_plus'),
  ('Milestone', '#F4A261', 'star'),
];
for (final (name, color, icon) in presets) {
  await into(tags).insert(TagsCompanion(
    name: Value(name),
    color: Value(color),
    icon: Value(icon),
    isPreset: const Value(true),
  ));
}
```

### 2.4 New DAO: `TagsDao`

`lib/core/database/daos/tags_dao.dart`:

```dart
class TagsDao {
  final AppDatabase db;
  TagsDao(this.db);

  // Get all tags sorted by isPreset desc then name asc
  Future<List<Tag>> getAllTags() =>
      (db.select(db.tags)
        ..orderBy([
          (t) => OrderingTerm(expression: t.isPreset, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.name),
        ])
      ).get();

  Future<List<Tag>> getPresetTags() =>
      (db.select(db.tags)..where((t) => t.isPreset.equals(true))).get();

  Future<List<Tag>> getCustomTags() =>
      (db.select(db.tags)..where((t) => t.isPreset.equals(false))).get();

  Future<Tag?> getTagById(int id) =>
      (db.select(db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createTag(TagsCompanion entry) =>
      db.into(db.tags).insert(entry);

  Future<bool> updateTag(TagsCompanion entry) =>
      db.update(db.tags).replace(entry);

  Future<int> deleteTag(int id) =>
      (db.delete(db.tags)..where((t) => t.id.equals(id))).go();

  // Tag assignments
  Future<int> assignTag(int tagId, int memoryId) =>
      db.into(db.tagAssignments).insert(TagAssignmentsCompanion(
        tagId: Value(tagId),
        memoryId: Value(memoryId),
      ));

  Future<List<TagAssignment>> getAssignmentsForMemory(int memoryId) =>
      (db.select(db.tagAssignments)
        ..where((t) => t.memoryId.equals(memoryId))
      ).get();

  Future<int> removeAssignment(int id) =>
      (db.delete(db.tagAssignments)..where((t) => t.id.equals(id))).go();

  Future<void> removeAllAssignmentsForMemory(int memoryId) =>
      (db.delete(db.tagAssignments)
        ..where((t) => t.memoryId.equals(memoryId))
      ).go();

  // Query tags by memory
  Future<List<Tag>> getTagsForMemory(int memoryId) async {
    final assignments = await getAssignmentsForMemory(memoryId);
    if (assignments.isEmpty) return [];
    final tagIds = assignments.map((a) => a.tagId).toList();
    return (db.select(db.tags)
      ..where((t) => t.id.isIn(tagIds))
    ).get();
  }
}
```

### 2.5 Provider Registration

Add to `lib/core/database/database_provider.dart`:
```dart
import 'daos/tags_dao.dart';

final tagsDaoProvider = Provider<TagsDao>((ref) {
  return TagsDao(ref.watch(databaseProvider));
});
```

### 2.6 UI Changes — Tag Selector in CreateMemoryScreen

Replace the current free-form text tag input with a two-section tag selector:

**Section 1: Preset Pills** — horizontal wrap of colored pills. Each pill shows the tag name with its color and a checkmark if selected.

**Section 2: Custom Tag Input** — type a new tag name, hit enter. Creates a custom tag on the fly (with no color/icon) or auto-completes from existing custom tags.

New file: `lib/features/story/create/widgets/tag_selector.dart`

```dart
class TagSelector extends ConsumerStatefulWidget {
  final List<int> selectedTagIds;
  final ValueChanged<List<int>> onChanged;
  // ...
}
```

The tag selector:
- Loads all tags from `tagsDaoProvider`
- Shows presets as colored pills (filled if selected, outlined if not)
- Shows a text field for "Add custom tag..."
- When user types and submits, either matches existing custom tag or creates new one
- Passes back list of selected tag IDs

**CreateMemoryScreen changes:**
- Replace the current tag section with `TagSelector`
- On save, call `tagsDaoProvider` to assign tags via `assignTag()`

### 2.7 UI Changes — Tags in Timeline

**TimelineDAO** — update `getTimeline()` to use new tag structure:
- Instead of querying `memoryTags`, query `tagAssignments` join `tags`
- Return `List<Tag>` instead of `List<String>` in `MemoryEntry`
- Update `TimelineEntry` model

**TimelineEntry model** — change `tags` from `List<String>` to `List<Tag>`:
```dart
class MemoryEntry extends TimelineEntry {
  final Memory memory;
  final List<Tag> tags;       // was List<String>
  final String? photoPath;
  // ...
}
```

**TimelineCard** — update tag rendering to use tag colors and icons:
```dart
// Instead of just text chips, show colored pills matching tag color
// Fallback to theme primary if no color set
Chip(
  label: Text(tag.name),
  backgroundColor: Color(int.parse(tag.color!.substring(1), radix: 16) | 0xFF000000).withAlpha(40),
  // ...
)
```

### 2.8 UI Changes — Tag Management Screen

New screen: `lib/features/me/screens/tag_management_screen.dart`

Routed from Me screen as a new list item under "Data" section.

Shows:
- List of all tags, grouped by Preset / Custom
- Preset tags: display only (grayed out delete button)
- Custom tags: editable (name, color, icon) and deletable
- FAB to create new custom tag

Create/Edit tag modal: bottom sheet with:
- Tag name text field
- Color picker (reuse the 13-color grid from CreateMilestoneScreen, minus the theme palette colors, add a few more like yellow, mint, coral)
- Icon picker (reuse icon picker pattern from CreateMilestoneScreen, expanded to 20-25 Lucide icons relevant to relationships)

### 2.9 File Changes Summary

| File | Change |
|------|--------|
| `lib/core/database/tables/tags_table.dart` | **NEW** — Tags table definition |
| `lib/core/database/tables/tag_assignments_table.dart` | **NEW** — TagAssignments bridge table |
| `lib/core/database/tables/memory_tags_table.dart` | **DELETE** — removed from project |
| `lib/core/database/app_database.dart` | Add Tags + TagAssignments to DriftDatabase, remove MemoryTags, add migration steps |
| `lib/core/database/daos/tags_dao.dart` | **NEW** — TagsDao class |
| `lib/core/database/database_provider.dart` | Add tagsDaoProvider |
| `lib/features/story/create/widgets/tag_selector.dart` | **NEW** — Tag selector widget |
| `lib/features/story/create/create_memory_screen.dart` | Replace tag section with TagSelector |
| `lib/features/story/models/timeline_entry.dart` | Change tags from `List<String>` to `List<Tag>` |
| `lib/core/database/daos/timeline_dao.dart` | Update tag query to use TagAssignments + Tags |
| `lib/core/database/daos/memories_dao.dart` | Remove old MemoryTags methods, add new TagAssignment methods (or remove entirely — TagsDao handles it) |
| `lib/features/story/timeline/widgets/memory_card.dart` | Update tag rendering to use tag color/icon |
| `lib/core/components/timeline_card.dart` | Update tag chip rendering |
| `lib/features/story/timeline/timeline_screen.dart` | Update tag display in memory cards |
| `lib/features/me/screens/me_screen.dart` | Add "Tags" list item in Data section, navigate to TagManagementScreen |
| `lib/features/me/screens/tag_management_screen.dart` | **NEW** — tag management screen |
| `lib/core/router/app_router.dart` | Add routes for TagManagementScreen |
| `lib/core/database/daos/memories_dao.dart` | Update to use new tag system |

### 2.10 Migration Edge Cases

- **Empty tags**: If user had no tags, migration creates empty Tags table and skips copy logic. No-op.
- **Duplicate tag names**: `INSERT OR IGNORE` handles this. Two memories with tag "funny" produce one Tag row.
- **MemoryTags table not empty but Tags table creation failed**: The migration is wrapped in a transaction by Drift, so it either all succeeds or rolls back.
- **Presets idempotency**: Check if presets exist before inserting (check by name). The migration should be safe to run multiple times.

---

## Feature 3: Anniversary Section

### Goal
Add a `type` field to Milestones so users can mark entries as anniversaries. Show relationship age on the timeline. Let users set a relationship start date.

### 3.1 Database Schema Changes

**Milestones table** — add `type` column:
```dart
TextColumn get type => text().withDefault(const Constant('milestone'))();
```

Values: `'milestone'` | `'anniversary'` | `'birthday'`

This column is part of the schemaVersion 2 migration (added alongside Supabase Prep columns).

**Settings keys** (no schema change — uses existing Settings table):
- `relationship_start_date` — ISO date string (e.g., `'2023-06-15'`)

### 3.2 Migration

In the `from < 2` block:
```dart
// Add type column to Milestones
await m.addColumn(milestones, milestones.type);

// Set default type for existing milestones
await customStatement(
  'UPDATE milestones SET type = \'milestone\' WHERE type IS NULL',
);
```

### 3.3 UI Changes — CreateMilestoneScreen

Add a type selector at the top of the form (after title):

```dart
enum MilestoneType { milestone, anniversary, birthday }

// In build method:
SegmentedButton<MilestoneType>(
  segments: [
    ButtonSegment(value: MilestoneType.milestone, label: Text('Milestone')),
    ButtonSegment(value: MilestoneType.anniversary, label: Text('Anniversary')),
    ButtonSegment(value: MilestoneType.birthday, label: Text('Birthday')),
  ],
  selected: {_selectedType},
  onSelectionChanged: (Set<MilestoneType> selected) {
    setState(() => _selectedType = selected.first);
  },
)
```

When type is `anniversary` or `birthday`, auto-populate icon and color:
- Anniversary: `heart` icon, primary color
- Birthday: `cake` icon (LucideIcons.cake), accent color

### 3.4 UI Changes — Timeline Screen

**Anniversary header card** — between the calendar and the SectionDivider:

```dart
// New widget: lib/features/story/timeline/widgets/anniversary_banner.dart
class AnniversaryBanner extends ConsumerWidget {
  // Reads relationship_start_date from settingsDaoProvider
  // Calculates years/months/days since start date
  // Returns SizedBox.shrink() if no start date set
  // Returns a SerenityCard with relationship age
}
```

The banner shows:
- If within 30 days of anniversary: "3 years together coming up on June 15!" with a sparkle icon
- If within 7 days after anniversary: "Celebrated 3 years together!" with heart icon
- Otherwise: "Together for 3 years, 2 months" (subdued, smaller)

**Milestone card display** — special treatment for anniversary-type milestones:
- Show a heart icon instead of milestone badge
- Show "2nd Anniversary" with a special background tint
- Add a small date display showing "June 15, 2023"

### 3.5 UI Changes — Me Screen

Add a "Relationship" section between Profile and Theme:

```dart
// In me_screen.dart, after Profile section:
SerenityCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Relationship',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', ...)),
      const SizedBox(height: 8),
      // Relationship start date
      ListTile(
        leading: Icon(LucideIcons.calendarHeart),
        title: Text('Anniversary Date'),
        subtitle: Text(startDate != null ? formatDate(startDate) : 'Not set'),
        trailing: Icon(LucideIcons.chevronRight),
        onTap: () => _pickStartDate(context),
      ),
      // Relationship duration (read-only, computed)
      if (startDate != null)
        Padding(
          padding: EdgeInsets.only(left: 56, bottom: 8),
          child: Text('Together for ${_computeDuration(startDate)}'),
        ),
    ],
  ),
),
```

### 3.6 New Provider

```dart
// lib/features/me/providers/relationship_provider.dart

final relationshipStartDateProvider = FutureProvider<DateTime?>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  final val = await dao.get('relationship_start_date');
  if (val == null) return null;
  return DateTime.tryParse(val);
});

final anniversaryCountProvider = FutureProvider<int>((ref) async {
  final startDate = await ref.watch(relationshipStartDateProvider.future);
  if (startDate == null) return 0;
  final now = DateTime.now();
  int years = now.year - startDate.year;
  if (now.month < startDate.month || (now.month == startDate.month && now.day < startDate.day)) {
    years--;
  }
  return years;
});
```

### 3.7 File Changes Summary

| File | Change |
|------|--------|
| `lib/core/database/tables/milestones_table.dart` | Add `type` column |
| `lib/core/database/app_database.dart` | Add type column migration |
| `lib/features/story/create/create_milestone_screen.dart` | Add type selector, auto-icon/color for anniversary/birthday |
| `lib/features/story/timeline/widgets/anniversary_banner.dart` | **NEW** — relationship age banner |
| `lib/features/story/timeline/timeline_screen.dart` | Add AnniversaryBanner between calendar and timeline |
| `lib/features/story/timeline/timeline_screen.dart` | Update _buildMilestoneCard for anniversary type display |
| `lib/features/me/screens/me_screen.dart` | Add Relationship section with start date picker |
| `lib/features/me/providers/relationship_provider.dart` | **NEW** — start date + anniversary count providers |
| `lib/features/me/providers/me_provider.dart` | Add relationshipStartDateProvider (or in its own file) |

---

## Feature 4: Build Release APK

### Goal
Build a signed release APK for sideloading. Since this is a private app, debug build is acceptable for now, but the plan covers both paths.

### 4.1 Signing Configuration

**Option A: Debug build (quick path)**

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

No signing needed. Easy sideloading on Android.

**Option B: Release build with debug keystore (recommended)**

Generate a debug keystore (only for development, not for Play Store):

```bash
keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Debug, OU=Debug, O=Serenity, L=Unknown, ST=Unknown, C=US"
```

Create `android/key.properties`:
```
storePassword=android
keyPassword=android
keyAlias=androiddebugkey
storeFile=../debug.keystore
```

Modify `android/app/build.gradle` to reference key.properties (standard Flutter signing config).

### 4.2 Build Command

```bash
flutter build apk --release --split-per-abi
```

This produces:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

For a single universal APK:
```bash
flutter build apk --release
```

### 4.3 Build Prerequisites

Run before building:
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze  # must be 0 errors
flutter test     # must pass
```

### 4.4 Proguard / R8

Add to `android/app/proguard-rules.pro` (if needed for supabase_flutter):
```
-keep class com.supabase.** { *; }
```

### 4.5 File Changes

| File | Change |
|------|--------|
| `android/key.properties` | **NEW** (or manual generation) |
| `android/app/build.gradle` | Add signing config from key.properties |
| `android/app/proguard-rules.pro` | Add Supabase keep rules |

---

## Implementation Order

The recommended execution sequence:

### Phase 1: Schema Foundation (1 session)
1. Add `isSynced` columns to Memories, Milestones, Reflections, QuestionAnswers
2. Add `updatedAt` to Milestones
3. Add `type` to Milestones
4. Add Tags + TagAssignments tables
5. Drop MemoryTags table  
6. Write the full migration (schemaVersion 1 -> 2)
7. Add `supabase_flutter` dependency
8. Create `SupabaseConfig` file
9. Initialize Supabase in `main.dart`
10. Run `flutter pub get && dart run build_runner build`
11. Run `flutter analyze` — 0 errors

### Phase 2: Tags System (1-2 sessions)
1. Create `TagsDao` with all CRUD
2. Create tag selector widget
3. Update CreateMemoryScreen to use TagSelector
4. Update TimelineDAO + TimelineEntry model
5. Update timeline card rendering for colored tags
6. Create TagManagementScreen
7. Add route + Me screen entry point
8. Update MemoriesDao (remove old tag methods)
9. Run `flutter analyze` — 0 errors
10. Run `flutter test` — existing tests pass

### Phase 3: Anniversary (1 session)
1. Create relationship provider
2. Add anniversary banner widget
3. Update CreateMilestoneScreen with type selector
4. Update milestone card display for anniversary type
5. Add Relationship section to Me screen
6. Run `flutter analyze` — 0 errors

### Phase 4: Build (1 session)
1. Configure signing
2. `flutter clean && flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter analyze && flutter test`
5. `flutter build apk --release`
6. Verify APK installs and runs

---

## Dependency Graph

```
Supabase Prep ──────────────────────────────┐
                                            │
Tags System ── depends on schemaVersion 2 ──┤
                                            │
Anniversary ── depends on schemaVersion 2 ──┘
                                            │
Build APK ──── depends on all features complete
```

If building before tags/anniversary is done: Supabase Prep is the only blocking dependency. You can build an APK after Phase 1 with just the schema changes.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Drift migration fails on existing data | Low | Test migration on a copy of the real database. `INSERT OR IGNORE` for safety. |
| `supabase_flutter` dependency conflicts | Medium | Pin to `^2.8.0`, check compatibility with Flutter SDK ^3.12. Test after `flutter pub get`. |
| User loses existing free-form tags during migration | Low | Migration preserves all existing tag strings as custom tags. No data loss. |
| Anniversary banner shows incorrect count near year boundaries | Low | Test with date edge cases (Feb 29, month boundaries). Use `DateTime` comparison carefully. |
| APK size too large | Low | Use `--split-per-abi` to reduce per-device size. Consider `--obfuscate` for release. |

---

## YAGNI Checklist

- ❌ No tag groups/categories (user didn't ask)
- ❌ No tag search/filter (YAGNI)
- ❌ No full sync service yet (just prep)
- ❌ No cloud backup UI (future)
- ❌ No anniversary notifications (YAGNI)
- ❌ No multiple anniversaries tracking (keep it to relationship start date)
- ✅ Tags have colors + icons (explicit ask)
- ✅ Tags are structured (explicit ask)
- ✅ Schema ready for sync (explicit ask)
- ✅ Anniversary type on milestones (explicit ask)
- ✅ Relationship age display (natural extension)

---

## Files Created (New)

1. `lib/core/supabase/supabase_config.dart`
2. `lib/core/database/tables/tags_table.dart`
3. `lib/core/database/tables/tag_assignments_table.dart`
4. `lib/core/database/daos/tags_dao.dart`
5. `lib/features/story/create/widgets/tag_selector.dart`
6. `lib/features/me/screens/tag_management_screen.dart`
7. `lib/features/story/timeline/widgets/anniversary_banner.dart`
8. `lib/features/me/providers/relationship_provider.dart`
9. `android/key.properties` (manual)
10. `docs/superpowers/plans/2026-06-28-serenity-remaining-features.md` (this file)

## Files Modified

1. `lib/core/database/app_database.dart`
2. `lib/core/database/tables/milestones_table.dart`
3. `lib/core/database/tables/memories_table.dart`
4. `lib/core/database/tables/reflections_table.dart`
5. `lib/core/database/tables/question_answers_table.dart`
6. `lib/core/database/database_provider.dart`
7. `lib/core/database/daos/timeline_dao.dart`
8. `lib/core/database/daos/memories_dao.dart`
9. `lib/features/story/models/timeline_entry.dart`
10. `lib/features/story/create/create_memory_screen.dart`
11. `lib/features/story/create/create_milestone_screen.dart`
12. `lib/features/story/timeline/timeline_screen.dart`
13. `lib/features/story/timeline/widgets/memory_card.dart`
14. `lib/core/components/timeline_card.dart`
15. `lib/features/me/screens/me_screen.dart`
16. `lib/features/me/providers/me_provider.dart`
17. `lib/core/router/app_router.dart`
18. `pubspec.yaml`
19. `lib/main.dart`
20. `android/app/build.gradle`
21. `android/app/proguard-rules.pro`

## Files Deleted

1. `lib/core/database/tables/memory_tags_table.dart` (replaced by Tags + TagAssignments)
2. `lib/core/database/app_database.g.dart` (regenerated by build_runner)

---

## Acceptance Criteria

### Supabase Prep
- [ ] schemaVersion is 2
- [ ] Milestones has updatedAt column
- [ ] Memories, Milestones, Reflections, QuestionAnswers have isSynced column (default false)
- [ ] Existing rows have isSynced = true after migration
- [ ] supabase_flutter dependency added without conflicts
- [ ] Supabase config exists with placeholder values
- [ ] flutter analyze passes with 0 errors
- [ ] Existing tests pass

### Tags System
- [ ] Tags table exists with name, color, icon, isPreset
- [ ] 10 preset tags are seeded on migration
- [ ] Existing free-form tags migrated to Tags table as custom tags
- [ ] Tag assignments preserved (memories keep their tags)
- [ ] CreateMemoryScreen shows colored preset pills
- [ ] Custom tag creation works (type name, press enter)
- [ ] Tags show with their color on timeline cards
- [ ] Tag management screen lists all tags
- [ ] Custom tags can be edited (name, color, icon)
- [ ] Custom tags can be deleted
- [ ] Preset tags cannot be deleted (UI grays out delete)
- [ ] No MemoryTags table remains

### Anniversary Section
- [ ] Milestones has type column (milestone/anniversary/birthday)
- [ ] CreateMilestoneScreen has type selector
- [ ] Anniversary milestones show with heart icon
- [ ] Relationship start date can be set in Me screen
- [ ] Anniversary banner appears on timeline when start date is set
- [ ] Banner shows correct year count
- [ ] Birthday milestones auto-select cake icon

### Build APK
- [ ] APK builds without errors
- [ ] APK installs on device
- [ ] App opens and runs correctly
- [ ] All existing functionality works in release build
