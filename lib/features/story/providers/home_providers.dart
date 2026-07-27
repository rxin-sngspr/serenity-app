import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';

/// Aggregated relationship stats for the home screen stats bar.
///
/// Returns daysTogether (null if start_date is not set), memoryCount,
/// and milestoneCount.
final relationshipStatsProvider = FutureProvider<
    ({int? daysTogether, int memoryCount, int milestoneCount})>((ref) async {
  final memoriesDao = ref.watch(memoriesDaoProvider);
  final milestonesDao = ref.watch(milestonesDaoProvider);
  final settingsDao = ref.watch(settingsDaoProvider);

  final memoryCount = await memoriesDao.countAll();
  final milestoneCount = await milestonesDao.countAll();

  // Read start_date from settings
  final startDateStr = await settingsDao.get('start_date');
  int? daysTogether;
  if (startDateStr != null) {
    final startDate = DateTime.tryParse(startDateStr);
    if (startDate != null) {
      daysTogether = DateTime.now().difference(startDate).inDays;
    }
  }

  return (
    daysTogether: daysTogether,
    memoryCount: memoryCount,
    milestoneCount: milestoneCount,
  );
});
