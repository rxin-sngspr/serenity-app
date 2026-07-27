import 'dart:convert';
import 'package:flutter/services.dart';

class QuestionItem {
  final int id;
  final String category;
  final String text;

  const QuestionItem({
    required this.id,
    required this.category,
    required this.text,
  });

  factory QuestionItem.fromJson(Map<String, dynamic> json) => QuestionItem(
        id: json['id'] as int,
        category: json['category'] as String,
        text: json['text'] as String,
      );
}

class QuestionRepository {
  static List<QuestionItem>? _cache;

  static Future<List<QuestionItem>> loadQuestions() async {
    if (_cache != null) return _cache!;

    final data = await rootBundle.loadString('assets/questions/questions.json');
    final list = json.decode(data) as List<dynamic>;
    _cache = list.map((e) => QuestionItem.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  static QuestionItem getQuestionForDate(
    DateTime date,
    List<QuestionItem> questions,
  ) {
    final dayIndex = date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final index = dayIndex % questions.length;
    return questions[index];
  }
}
