import 'package:drift/drift.dart';
import '../../../features/story/models/timeline_entry.dart';
import '../app_database.dart';

class TimelineDao {
  final AppDatabase db;
  TimelineDao(this.db);

  Future<List<TimelineGroup>> getTimeline({int limit = 20}) async {
    final memories = await (db.select(db.memories)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
      ..limit(limit)
    ).get();

    final milestones = await (db.select(db.milestones)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).get();

    // Collect memory IDs for tag/media queries
    final memoryIds = memories.map((m) => m.id).toList();

    // Batch load tags via Tags + TagAssignments
    final tagsByMemory = <int, List<Tag>>{};
    if (memoryIds.isNotEmpty) {
      final query = db.select(db.tags).join([
        innerJoin(
          db.tagAssignments,
          db.tagAssignments.tagId.equalsExp(db.tags.id),
        ),
      ]);
      query.where(db.tagAssignments.memoryId.isIn(memoryIds));
      final rows = await query.get();
      for (final row in rows) {
        final tag = row.readTable(db.tags);
        final assignment = row.readTable(db.tagAssignments);
        tagsByMemory.putIfAbsent(assignment.memoryId, () => []).add(tag);
      }
    }

    // Batch load media
    final allMedia = memoryIds.isEmpty
        ? <MemoryMediaData>[]
        : await (db.select(db.memoryMedia)
            ..where((t) => t.memoryId.isIn(memoryIds))
          ).get();
    final mediaByMemory = <int, String?>{};
    for (final media in allMedia) {
      mediaByMemory[media.memoryId] = media.path;
    }

    // Build entries
    final entries = <TimelineEntry>[];
    for (final memory in memories) {
      entries.add(MemoryEntry(
        memory.date,
        memory,
        tagsByMemory[memory.id] ?? [],
        mediaByMemory[memory.id],
        createdBy: memory.createdBy,
      ));
    }
    for (final milestone in milestones) {
      entries.add(MilestoneEntry(
        milestone.date,
        milestone,
        createdBy: milestone.createdBy,
      ));
    }

    // Sort all entries by date descending
    entries.sort((a, b) => b.date.compareTo(a.date));

    // Group by date (date only, not time)
    final grouped = <String, List<TimelineEntry>>{};
    final dateOrder = <String, DateTime>{};
    for (final entry in entries) {
      final key = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      grouped.putIfAbsent(key, () => []).add(entry);
      dateOrder.putIfAbsent(key, () => entry.date);
    }

    // Convert to ordered list
    final result = dateOrder.entries.map((e) {
      final dt = e.value;
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      return TimelineGroup(dateKey, grouped[e.key]!);
    }).toList();

    return result;
  }
}
