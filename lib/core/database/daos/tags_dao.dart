import 'package:drift/drift.dart';
import '../app_database.dart';

class TagsDao {
  final AppDatabase db;
  TagsDao(this.db);

  /// Get tags for a memory via tag_assignments join.
  Future<List<Tag>> getTagsForMemory(int memoryId) async {
    final query = db.select(db.tags).join([
      innerJoin(
        db.tagAssignments,
        db.tagAssignments.tagId.equalsExp(db.tags.id),
      ),
    ]);
    query.where(db.tagAssignments.memoryId.equals(memoryId));
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.tags)).toList();
  }

  /// Finds a tag by name or creates a new one, returns it.
  Future<Tag> getOrCreateTag(String name) async {
    final existing = await (db.select(db.tags)
      ..where((t) => t.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing;
    final id = await db.into(db.tags).insert(TagsCompanion(
      name: Value(name),
    ).copyWith(isSynced: const Value(false)));
    return (db.select(db.tags)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Assigns a tag to a memory.
  Future<int> assignTag(int tagId, int memoryId) =>
      db.into(db.tagAssignments).insert(TagAssignmentsCompanion(
        tagId: Value(tagId),
        memoryId: Value(memoryId),
      ));

  /// Removes all tag assignments for a memory (for editing).
  Future<void> removeAllAssignmentsForMemory(int memoryId) =>
      (db.delete(db.tagAssignments)
        ..where((t) => t.memoryId.equals(memoryId))).go();

  /// Get all tags.
  Future<List<Tag>> getAllTags() => db.select(db.tags).get();

  /// Get all tag assignments for a specific tag.
  Future<List<TagAssignment>> getAssignmentsForTag(int tagId) =>
      (db.select(db.tagAssignments)..where((t) => t.tagId.equals(tagId))).get();

  /// Batch load tags for multiple memories (used by TimelineDAO).
  /// Returns a map of memoryId -> list of Tags.
  Future<Map<int, List<Tag>>> getTagsForMemories(List<int> memoryIds) async {
    if (memoryIds.isEmpty) return {};
    final query = db.select(db.tags).join([
      innerJoin(
        db.tagAssignments,
        db.tagAssignments.tagId.equalsExp(db.tags.id),
      ),
    ]);
    query.where(db.tagAssignments.memoryId.isIn(memoryIds));
    final rows = await query.get();
    final result = <int, List<Tag>>{};
    for (final row in rows) {
      final tag = row.readTable(db.tags);
      final assignment = row.readTable(db.tagAssignments);
      result.putIfAbsent(assignment.memoryId, () => []).add(tag);
    }
    return result;
  }
}
