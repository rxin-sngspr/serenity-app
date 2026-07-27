import 'package:drift/drift.dart';
import '../app_database.dart';

class MilestonesDao {
  final AppDatabase db;
  MilestonesDao(this.db);

  Future<List<Milestone>> getAllMilestones() =>
      (db.select(db.milestones)
        ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
          .get();

  Future<Milestone?> getMilestoneById(int id) =>
      (db.select(db.milestones)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createMilestone(MilestonesCompanion entry) =>
      db.into(db.milestones).insert(entry.copyWith(
        isSynced: const Value(false),
      ));

  Future<bool> updateMilestone(MilestonesCompanion entry) =>
      db.update(db.milestones).replace(entry.copyWith(
        isSynced: const Value(false),
      ));

  Future<int> countAll() async {
    final rows = await db
        .customSelect(
            'SELECT COUNT(*) AS cnt FROM milestones WHERE is_deleted = 0')
        .get();
    return rows.first.read<int>('cnt');
  }

  Future<int> deleteMilestone(int id) =>
      (db.delete(db.milestones)..where((t) => t.id.equals(id))).go();
}
