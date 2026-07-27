import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../couple/providers/couple_provider.dart';

final userNameProvider = FutureProvider<String?>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  return dao.get('display_name');
});

final partnerNameProvider = FutureProvider<String?>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  return dao.get('partner_name');
});

final themeIndexProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  final val = await dao.get('theme_index');
  if (val == null) return 0;
  return int.tryParse(val) ?? 0;
});

final profilePhotoPathProvider = FutureProvider<String?>((ref) async {
  final dao = ref.watch(settingsDaoProvider);
  return dao.get('profile_photo_path');
});

final partnerAnswersProvider = FutureProvider<List<QuestionAnswer>>((ref) async {
  final couple = await ref.watch(coupleStatusProvider.future);
  if (couple == null) return [];

  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  if (currentUserId == null) return [];

  final partnerUserId = couple['partner_a_id'] == currentUserId
      ? couple['partner_b_id'] as String
      : couple['partner_a_id'] as String;

  if (partnerUserId.isEmpty) return [];

  final dao = ref.watch(questionAnswersDaoProvider);
  return dao.getAnswersByUser(partnerUserId, limit: 10);
});
