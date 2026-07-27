import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/category_badge.dart';
import '../../../core/components/serenity_card.dart';
import '../providers/question_provider.dart';

class DailyQuestionCard extends ConsumerStatefulWidget {
  const DailyQuestionCard({super.key});

  @override
  ConsumerState<DailyQuestionCard> createState() => _DailyQuestionCardState();
}

class _DailyQuestionCardState extends ConsumerState<DailyQuestionCard> {
  final _controller = TextEditingController();
  bool _saving = false;
  bool _showAnswer = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAnswer(String text, int questionId, String category) async {
    setState(() => _saving = true);
    try {
      final dao = ref.read(questionAnswersDaoProvider);
      await dao.saveAnswer(
        QuestionAnswersCompanion(
          questionId: Value(questionId),
          category: Value(category),
          answerText: Value(text),
          dateAnswered: Value(DateTime.now()),
        ),
      );
      if (mounted) {
        ref.invalidate(todayAnswerProvider);
        ref.invalidate(allAnswersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = ref.watch(currentQuestionProvider);
    final answerAsync = ref.watch(todayAnswerProvider);

    if (question == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SerenityCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryBadge(label: question.category),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  onPressed: () {
                    ref.read(questionRefreshCountNotifierProvider).increment();
                  },
                  tooltip: 'Next Question',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              question.text,
              style: TextStyle(fontFamily: 'Cormorant Garamond',
                fontSize: 17,
                height: 24 / 17,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            answerAsync.when(
              data: (answer) {
                if (answer != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showAnswer = !_showAnswer),
                        child: Row(
                          children: [
                            Icon(
                              _showAnswer
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showAnswer ? 'Hide my answer' :                             'Show my answer',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showAnswer) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            answer.answerText,
                            style: TextStyle(fontFamily: 'Cormorant Garamond',
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Write your answer...',
                        isDense: true,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          onPressed: () {
                            ref.read(questionRefreshCountNotifierProvider).increment();
                          },
                          label: const Text('Skip'),
                        ),
                        FilledButton.tonal(
                          onPressed: _saving
                              ? null
                              : () {
                                  final text = _controller.text.trim();
                                  if (text.isNotEmpty) {
                                    _saveAnswer(text, question.id, question.category);
                                    _controller.clear();
                                    ref.read(questionRefreshCountNotifierProvider).increment();
                                  }
                                },
                          child: _saving
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save & Next'),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
