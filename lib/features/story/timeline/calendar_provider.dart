import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';

final calendarDatesProvider =
    FutureProvider.family<Set<String>, DateTime>((ref, month) async {
  final dao = ref.watch(calendarDaoProvider);
  return dao.getDatesWithEntries(month.year, month.month);
});
