import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';

/// A single reflection prompt item.
class ReflectionPromptItem {
  final int id;
  final String text;

  const ReflectionPromptItem({required this.id, required this.text});

  factory ReflectionPromptItem.fromJson(Map<String, dynamic> json) =>
      ReflectionPromptItem(
        id: json['id'] as int,
        text: json['text'] as String,
      );
}

/// Repository for loading reflection prompts from the JSON bundle.
class ReflectionPromptRepository {
  static List<ReflectionPromptItem>? _cache;

  static Future<List<ReflectionPromptItem>> loadPrompts() async {
    if (_cache != null) return _cache!;

    final data = await rootBundle
        .loadString('assets/questions/reflection_prompts.json');
    final list = json.decode(data) as List<dynamic>;
    _cache = list
        .map((e) => ReflectionPromptItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}

/// Loads all reflection prompts from the JSON bundle.
final allReflectionPromptsProvider =
    FutureProvider<List<ReflectionPromptItem>>((ref) {
  return ReflectionPromptRepository.loadPrompts();
});

/// Cycles through prompts using a date-based offset (same pattern as
/// currentQuestionProvider).
final currentReflectionPromptProvider =
    Provider<ReflectionPromptItem?>((ref) {
  final prompts = ref.watch(allReflectionPromptsProvider).valueOrNull;
  if (prompts == null || prompts.isEmpty) return null;
  final dayOffset =
      DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  final index = dayOffset % prompts.length;
  return prompts[index];
});

/// Counts today's reflections.
final todayReflectionCountProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(reflectionsDaoProvider);
  final reflections = await dao.getReflectionsByDate(DateTime.now());
  return reflections.length;
});

/// Recent reflections for the Reflect tab.
final recentReflectionsProvider = FutureProvider<List<Reflection>>((ref) async {
  final dao = ref.watch(reflectionsDaoProvider);
  return dao.getRecentReflections(limit: 3);
});

