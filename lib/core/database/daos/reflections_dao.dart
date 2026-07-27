import 'package:drift/drift.dart';
import '../app_database.dart';

class ReflectionsDao {
  final AppDatabase db;
  ReflectionsDao(this.db);

  Future<List<Reflection>> getAllReflections() =>
      (db.select(db.reflections)
            ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
          .get();

  Future<Reflection?> getReflectionById(int id) =>
      (db.select(db.reflections)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Reflection>> getReflectionsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (db.select(db.reflections)
          ..where((t) => t.date.isBetween(Variable(start), Variable(end)))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<Reflection>> getRecentReflections({int limit = 5}) =>
      (db.select(db.reflections)
            ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
            ..limit(limit))
          .get();

  Future<int> createReflection(ReflectionsCompanion entry) =>
      db.into(db.reflections).insert(entry.copyWith(
        isSynced: const Value(false),
      ));

  Future<bool> updateReflection(ReflectionsCompanion entry) =>
      db.update(db.reflections).replace(entry.copyWith(
        isSynced: const Value(false),
      ));

  Future<int> deleteReflection(int id) =>
      (db.delete(db.reflections)..where((t) => t.id.equals(id))).go();
}
