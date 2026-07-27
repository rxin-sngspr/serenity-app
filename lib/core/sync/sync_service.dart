import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../database/daos/sync_metadata_dao.dart';

/// Outcome of a single push / pull cycle.
enum SyncResult { success, noCouple, error }

/// Core sync engine.
///
/// Pushes local unsynced rows to Supabase, then pulls remote changes newer
/// than the last pull timestamp.  Conflict resolution is last-write-wins
/// based on `updated_at`.  Tables without `updated_at` (reflections,
/// question_answers, tags, tag_assignments) use `created_at` for pull
/// filtering and never overwrite existing local rows.
class SyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  late final SyncMetadataDao _syncDao = SyncMetadataDao(_db);

  SyncService(this._db, this._supabase);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Push all locally-unsynced rows to Supabase.
  Future<SyncResult> push() async {
    final coupleId = await _syncDao.get('couple_id');
    if (coupleId == null) return SyncResult.noCouple;

    try {
      await _pushMemories(coupleId);
      await _pushMilestones(coupleId);
      await _pushReflections(coupleId);
      await _pushQuestionAnswers(coupleId);
      await _pushTags(coupleId);
      await _pushTagAssignments(coupleId);
      return SyncResult.success;
    } catch (_) {
      return SyncResult.error;
    }
  }

  /// Pull remote rows changed since the last pull time.
  Future<SyncResult> pull() async {
    final coupleId = await _syncDao.get('couple_id');
    if (coupleId == null) return SyncResult.noCouple;

    final lastPullStr = await _syncDao.get('last_pull_at');
    final since =
        lastPullStr != null ? DateTime.parse(lastPullStr) : DateTime(2000);

    try {
      await _pullMemories(since, coupleId);
      await _pullMilestones(since, coupleId);
      await _pullReflections(since, coupleId);
      await _pullQuestionAnswers(since, coupleId);
      await _pullTags(coupleId);
      await _pullTagAssignments(coupleId);

      await _syncDao.set(
        'last_pull_at',
        DateTime.now().toUtc().toIso8601String(),
      );
      return SyncResult.success;
    } catch (_) {
      return SyncResult.error;
    }
  }

  // ---------------------------------------------------------------------------
  // Push helpers  (one per table)
  // ---------------------------------------------------------------------------

  Future<void> _pushMemories(String coupleId) async {
    final rows = await (_db.select(_db.memories)
      ..where((t) => t.isSynced.equals(false))).get();
    if (rows.isEmpty) return;
    await _supabase
        .from('memories')
        .upsert(rows.map((r) => _memoryToJson(r, coupleId)).toList());
    for (final r in rows) {
      await (_db.update(_db.memories)..where((t) => t.id.equals(r.id)))
          .write(const MemoriesCompanion(isSynced: Value(true)));
    }
  }

  Future<void> _pushMilestones(String coupleId) async {
    final rows = await (_db.select(_db.milestones)
      ..where((t) => t.isSynced.equals(false))).get();
    if (rows.isEmpty) return;
    await _supabase
        .from('milestones')
        .upsert(rows.map((r) => _milestoneToJson(r, coupleId)).toList());
    for (final r in rows) {
      await (_db.update(_db.milestones)..where((t) => t.id.equals(r.id)))
          .write(const MilestonesCompanion(isSynced: Value(true)));
    }
  }

  Future<void> _pushReflections(String coupleId) async {
    final rows = await (_db.select(_db.reflections)
      ..where((t) => t.isSynced.equals(false))).get();
    if (rows.isEmpty) return;
    await _supabase
        .from('reflections')
        .upsert(rows.map((r) => _reflectionToJson(r, coupleId)).toList());
    for (final r in rows) {
      await (_db.update(_db.reflections)..where((t) => t.id.equals(r.id)))
          .write(const ReflectionsCompanion(isSynced: Value(true)));
    }
  }

  Future<void> _pushQuestionAnswers(String coupleId) async {
    final rows = await (_db.select(_db.questionAnswers)
      ..where((t) => t.isSynced.equals(false))).get();
    if (rows.isEmpty) return;
    await _supabase
        .from('question_answers')
        .upsert(rows.map((r) => _questionAnswerToJson(r, coupleId)).toList());
    for (final r in rows) {
      await (_db.update(_db.questionAnswers)..where((t) => t.id.equals(r.id)))
          .write(const QuestionAnswersCompanion(isSynced: Value(true)));
    }
  }

  Future<void> _pushTags(String coupleId) async {
    final rows = await (_db.select(_db.tags)
      ..where((t) => t.isSynced.equals(false))).get();
    if (rows.isEmpty) return;
    await _supabase
        .from('tags')
        .upsert(rows.map((r) => _tagToJson(r, coupleId)).toList());
    for (final r in rows) {
      await (_db.update(_db.tags)..where((t) => t.id.equals(r.id)))
          .write(const TagsCompanion(isSynced: Value(true)));
    }
  }

  Future<void> _pushTagAssignments(String coupleId) async {
    final rows = await (_db.select(_db.tagAssignments)
      ..where((t) => t.isSynced.equals(false))).get();
    if (rows.isEmpty) return;
    await _supabase
        .from('tag_assignments')
        .upsert(rows.map((r) => _tagAssignmentToJson(r, coupleId)).toList());
    for (final r in rows) {
      await (_db.update(_db.tagAssignments)..where((t) => t.id.equals(r.id)))
          .write(const TagAssignmentsCompanion(isSynced: Value(true)));
    }
  }

  // ---------------------------------------------------------------------------
  // Pull helpers  (one per table)
  // ---------------------------------------------------------------------------

  /// Memories use `updated_at` for conflict resolution.
  Future<void> _pullMemories(DateTime since, String coupleId) async {
    final remoteRows = await _supabase
        .from('memories')
        .select()
        .eq('couple_id', coupleId)
        .gte('updated_at', since.toUtc().toIso8601String());
    for (final json in remoteRows) {
      final remoteId = json['id'] as int;
      final remoteUpdated = DateTime.parse(json['updated_at'] as String);
      final local = await (_db.select(_db.memories)
        ..where((t) => t.id.equals(remoteId))).getSingleOrNull();
      if (local == null) {
        await _insertMemoryFromJson(json);
      } else if (_isRemoteNewer(local.updatedAt, remoteUpdated)) {
        await _updateMemoryFromJson(json);
      }
    }
  }

  /// Milestones use `updated_at` for conflict resolution.
  Future<void> _pullMilestones(DateTime since, String coupleId) async {
    final remoteRows = await _supabase
        .from('milestones')
        .select()
        .eq('couple_id', coupleId)
        .gte('updated_at', since.toUtc().toIso8601String());
    for (final json in remoteRows) {
      final remoteId = json['id'] as int;
      final remoteUpdated = DateTime.parse(json['updated_at'] as String);
      final local = await (_db.select(_db.milestones)
        ..where((t) => t.id.equals(remoteId))).getSingleOrNull();
      if (local == null) {
        await _insertMilestoneFromJson(json);
      } else if (_isRemoteNewer(local.updatedAt, remoteUpdated)) {
        await _updateMilestoneFromJson(json);
      }
    }
  }

  /// Reflections have no `updated_at`; use `created_at` for filtering.
  Future<void> _pullReflections(DateTime since, String coupleId) async {
    final remoteRows = await _supabase
        .from('reflections')
        .select()
        .eq('couple_id', coupleId)
        .gte('created_at', since.toUtc().toIso8601String());
    for (final json in remoteRows) {
      final remoteId = json['id'] as int;
      final local = await (_db.select(_db.reflections)
        ..where((t) => t.id.equals(remoteId))).getSingleOrNull();
      if (local == null) {
        await _insertReflectionFromJson(json);
      }
      // Local wins if already present (no updated_at to compare)
    }
  }

  /// QuestionAnswers have no `updated_at`; use `created_at` for filtering.
  Future<void> _pullQuestionAnswers(DateTime since, String coupleId) async {
    final remoteRows = await _supabase
        .from('question_answers')
        .select()
        .eq('couple_id', coupleId)
        .gte('created_at', since.toUtc().toIso8601String());
    for (final json in remoteRows) {
      final remoteId = json['id'] as int;
      final local = await (_db.select(_db.questionAnswers)
        ..where((t) => t.id.equals(remoteId))).getSingleOrNull();
      if (local == null) {
        await _insertQuestionAnswerFromJson(json);
      }
    }
  }

  /// Tags have no timestamps; pull any not already present locally.
  Future<void> _pullTags(String coupleId) async {
    final remoteRows =
        await _supabase.from('tags').select().eq('couple_id', coupleId);
    for (final json in remoteRows) {
      final remoteId = json['id'] as int;
      final local = await (_db.select(_db.tags)
        ..where((t) => t.id.equals(remoteId))).getSingleOrNull();
      if (local == null) {
        await _insertTagFromJson(json);
      }
    }
  }

  /// TagAssignments have no timestamps; pull any not already present locally.
  Future<void> _pullTagAssignments(String coupleId) async {
    final remoteRows = await _supabase
        .from('tag_assignments')
        .select()
        .eq('couple_id', coupleId);
    for (final json in remoteRows) {
      final remoteId = json['id'] as int;
      final local = await (_db.select(_db.tagAssignments)
        ..where((t) => t.id.equals(remoteId))).getSingleOrNull();
      if (local == null) {
        await _insertTagAssignmentFromJson(json);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // JSON -> local row insert / update helpers
  // ---------------------------------------------------------------------------

  Future<void> _insertMemoryFromJson(Map<String, dynamic> json) async {
    await _db.into(_db.memories).insertOnConflictUpdate(MemoriesCompanion(
      id: Value(json['id'] as int),
      type: Value(json['type'] as String? ?? 'memory'),
      title: Value(json['title'] as String),
      body: Value(json['body'] as String),
      date: Value(DateTime.parse(json['date'] as String)),
      isFavorite: Value(json['is_favorite'] is bool
          ? json['is_favorite'] as bool
          : json['is_favorite'] == 1),
      isDeleted: Value(json['is_deleted'] is bool
          ? json['is_deleted'] as bool
          : json['is_deleted'] == 1),
      createdBy: Value(json['created_by'] as String?),
      coupleId: Value(json['couple_id'] as String?),
      isSynced: const Value(true),
    ));
  }

  Future<void> _updateMemoryFromJson(Map<String, dynamic> json) async {
    await (_db.update(_db.memories)..where((t) => t.id.equals(json['id'] as int)))
        .write(MemoriesCompanion(
      title: Value(json['title'] as String),
      body: Value(json['body'] as String),
      date: Value(DateTime.parse(json['date'] as String)),
      isFavorite: Value(json['is_favorite'] is bool
          ? json['is_favorite'] as bool
          : json['is_favorite'] == 1),
      isDeleted: Value(json['is_deleted'] is bool
          ? json['is_deleted'] as bool
          : json['is_deleted'] == 1),
      isSynced: const Value(true),
    ));
  }

  Future<void> _insertMilestoneFromJson(Map<String, dynamic> json) async {
    await _db.into(_db.milestones).insertOnConflictUpdate(MilestonesCompanion(
      id: Value(json['id'] as int),
      title: Value(json['title'] as String),
      date: Value(DateTime.parse(json['date'] as String)),
      description: Value(json['description'] as String?),
      icon: Value(json['icon'] as String?),
      color: Value(json['color'] as String?),
      type: Value(json['type'] as String? ?? 'milestone'),
      isDeleted: Value(json['is_deleted'] is bool
          ? json['is_deleted'] as bool
          : json['is_deleted'] == 1),
      createdBy: Value(json['created_by'] as String?),
      coupleId: Value(json['couple_id'] as String?),
      isSynced: const Value(true),
    ));
  }

  Future<void> _updateMilestoneFromJson(Map<String, dynamic> json) async {
    await (_db.update(_db.milestones)
        ..where((t) => t.id.equals(json['id'] as int))).write(
      MilestonesCompanion(
        title: Value(json['title'] as String),
        date: Value(DateTime.parse(json['date'] as String)),
        description: Value(json['description'] as String?),
        icon: Value(json['icon'] as String?),
        color: Value(json['color'] as String?),
        type: Value(json['type'] as String? ?? 'milestone'),
        isDeleted: Value(json['is_deleted'] is bool
            ? json['is_deleted'] as bool
            : json['is_deleted'] == 1),
        isSynced: const Value(true),
      ),
    );
  }

  Future<void> _insertReflectionFromJson(Map<String, dynamic> json) async {
    await _db.into(_db.reflections).insertOnConflictUpdate(
      ReflectionsCompanion(
        id: Value(json['id'] as int),
        promptType: Value(json['prompt_type'] as String),
        promptText: Value(json['prompt_text'] as String),
        content: Value(json['content'] as String),
        moodScore: Value(json['mood_score'] as int?),
        date: Value(DateTime.parse(json['date'] as String)),
        isSynced: const Value(true),
      ),
    );
  }

  Future<void> _insertQuestionAnswerFromJson(
      Map<String, dynamic> json) async {
    await _db.into(_db.questionAnswers).insertOnConflictUpdate(
      QuestionAnswersCompanion(
        id: Value(json['id'] as int),
        questionId: Value(json['question_id'] as int),
        category: Value(json['category'] as String),
        answerText: Value(json['answer_text'] as String),
        dateAnswered: Value(DateTime.parse(json['date_answered'] as String)),
        createdBy: Value(json['created_by'] as String?),
        isSynced: const Value(true),
      ),
    );
  }

  Future<void> _insertTagFromJson(Map<String, dynamic> json) async {
    await _db.into(_db.tags).insertOnConflictUpdate(TagsCompanion(
      id: Value(json['id'] as int),
      name: Value(json['name'] as String),
      color: Value(json['color'] as String?),
      icon: Value(json['icon'] as String?),
      isPreset: Value(json['is_preset'] is bool
          ? json['is_preset'] as bool
          : json['is_preset'] == 1),
      isSynced: const Value(true),
    ));
  }

  Future<void> _insertTagAssignmentFromJson(Map<String, dynamic> json) async {
    await _db.into(_db.tagAssignments).insertOnConflictUpdate(
      TagAssignmentsCompanion(
        id: Value(json['id'] as int),
        tagId: Value(json['tag_id'] as int),
        memoryId: Value(json['memory_id'] as int),
        isSynced: const Value(true),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Local row -> JSON converters  (excludes local-only `isSynced` field)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _memoryToJson(Memory memory, String coupleId) {
    return {
      'id': memory.id,
      'couple_id': coupleId,
      'type': memory.type,
      'title': memory.title,
      'body': memory.body,
      'date': memory.date.toUtc().toIso8601String(),
      'is_favorite': memory.isFavorite,
      'is_deleted': memory.isDeleted,
      'created_by': memory.createdBy,
      'created_at': memory.createdAt.toUtc().toIso8601String(),
      'updated_at': memory.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _milestoneToJson(Milestone milestone, String coupleId) {
    return {
      'id': milestone.id,
      'couple_id': coupleId,
      'title': milestone.title,
      'date': milestone.date.toUtc().toIso8601String(),
      'description': milestone.description,
      'icon': milestone.icon,
      'color': milestone.color,
      'type': milestone.type,
      'is_deleted': milestone.isDeleted,
      'created_by': milestone.createdBy,
      'created_at': milestone.createdAt.toUtc().toIso8601String(),
      'updated_at': milestone.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _reflectionToJson(
      Reflection reflection, String coupleId) {
    return {
      'id': reflection.id,
      'couple_id': coupleId,
      'prompt_type': reflection.promptType,
      'prompt_text': reflection.promptText,
      'content': reflection.content,
      'mood_score': reflection.moodScore,
      'date': reflection.date.toUtc().toIso8601String(),
      'created_at': reflection.createdAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _questionAnswerToJson(
      QuestionAnswer qa, String coupleId) {
    return {
      'id': qa.id,
      'couple_id': coupleId,
      'question_id': qa.questionId,
      'category': qa.category,
      'answer_text': qa.answerText,
      'date_answered': qa.dateAnswered.toUtc().toIso8601String(),
      'created_by': qa.createdBy,
      'created_at': qa.createdAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _tagToJson(Tag tag, String coupleId) {
    return {
      'id': tag.id,
      'couple_id': coupleId,
      'name': tag.name,
      'color': tag.color,
      'icon': tag.icon,
      'is_preset': tag.isPreset,
    };
  }

  Map<String, dynamic> _tagAssignmentToJson(
      TagAssignment ta, String coupleId) {
    return {
      'id': ta.id,
      'couple_id': coupleId,
      'tag_id': ta.tagId,
      'memory_id': ta.memoryId,
    };
  }

  // ---------------------------------------------------------------------------
  // Conflict resolution
  // ---------------------------------------------------------------------------

  /// Returns true when the remote timestamp is strictly newer.
  /// Local wins on equal timestamps (no unnecessary remote overwrite).
  bool _isRemoteNewer(DateTime localUpdatedAt, DateTime remoteUpdatedAt) {
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }
}
