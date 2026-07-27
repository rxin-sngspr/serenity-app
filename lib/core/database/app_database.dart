import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/memories_table.dart';
import 'tables/memory_media_table.dart';
import 'tables/milestones_table.dart';
import 'tables/settings_table.dart';
import 'tables/reflections_table.dart';
import 'tables/question_answers_table.dart';
import 'tables/tags_table.dart';
import 'tables/tag_assignments_table.dart';
import 'tables/sync_metadata_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Memories,
    MemoryMedia,
    Milestones,
    Settings,
    Reflections,
    QuestionAnswers,
    Tags,
    TagAssignments,
    SyncMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

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

          // Mark all existing rows as synced (they're already saved locally)
          await customStatement('UPDATE memories SET is_synced = 1');
          await customStatement('UPDATE milestones SET is_synced = 1');
          await customStatement('UPDATE reflections SET is_synced = 1');
          await customStatement('UPDATE question_answers SET is_synced = 1');

          // Add type column to Milestones
          await m.addColumn(milestones, milestones.type);
          await customStatement(
            "UPDATE milestones SET type = 'milestone' WHERE type IS NULL",
          );

          // Create Tags table
          await m.createTable(tags);

          // Create TagAssignments table
          await m.createTable(tagAssignments);

          // Migrate existing free-form tags to Tags table as custom tags
          await customStatement('''
            INSERT OR IGNORE INTO tags (name, is_preset, is_synced)
            SELECT DISTINCT tag, 0, 1 FROM memory_tags
          ''');

          // Link existing memory-tag relationships
          await customStatement('''
            INSERT INTO tag_assignments (tag_id, memory_id, is_synced)
            SELECT t.id, mt.memory_id, 1
            FROM memory_tags mt
            JOIN tags t ON t.name = mt.tag
          ''');

          // Drop old MemoryTags table
          await m.deleteTable('memory_tags');

          // Seed 10 preset tags (will be refined later)
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
        }

        if (from < 3) {
          // Add sync columns to Memories
          await m.addColumn(memories, memories.createdBy);
          await m.addColumn(memories, memories.coupleId);
          await m.addColumn(memories, memories.isDeleted);

          // Add sync columns to Milestones
          await m.addColumn(milestones, milestones.createdBy);
          await m.addColumn(milestones, milestones.coupleId);
          await m.addColumn(milestones, milestones.isDeleted);

          // Add sync columns to Reflections
          await m.addColumn(reflections, reflections.createdBy);
          await m.addColumn(reflections, reflections.coupleId);

          // Add sync columns to QuestionAnswers
          await m.addColumn(questionAnswers, questionAnswers.createdBy);
          await m.addColumn(questionAnswers, questionAnswers.coupleId);

          // Add sync columns to Tags
          await m.addColumn(tags, tags.createdBy);
          await m.addColumn(tags, tags.coupleId);

          // Create SyncMetadata table
          await m.createTable(syncMetadata);

          // Mark all existing rows as synced
          await customStatement('UPDATE memories SET is_synced = 1');
          await customStatement('UPDATE milestones SET is_synced = 1');
          await customStatement('UPDATE reflections SET is_synced = 1');
          await customStatement('UPDATE question_answers SET is_synced = 1');
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'serenity.sqlite'));
    return NativeDatabase(file);
  });
}
