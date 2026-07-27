import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:drift/drift.dart' hide Column;
import '../widgets/daily_question_card.dart';
import '../widgets/quick_appreciation.dart';
import '../widgets/reflection_card.dart';
import '../providers/reflect_provider.dart';
import '../providers/question_provider.dart';
import '../repositories/question_repository.dart';
import '../../../core/components/section_divider.dart';
import '../../../core/components/category_badge.dart';
import '../../../core/components/serenity_card.dart';
import '../../../core/components/appreciation_block.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/sync_status_indicator.dart';

/// Recent appreciations (last 5).
final _recentAppreciationsProvider = FutureProvider.autoDispose((ref) async {
  final dao = ref.watch(memoriesDaoProvider);
  return dao.getMemoriesByType('appreciation');
});

class ReflectScreen extends ConsumerWidget {
  const ReflectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentAsync = ref.watch(recentReflectionsProvider);
    final allAnswersAsync = ref.watch(allAnswersProvider);
    final allQuestionsAsync = ref.watch(allQuestionsProvider);
    final appreciationsAsync = ref.watch(_recentAppreciationsProvider);
    final todayReflectionCountAsync = ref.watch(todayReflectionCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reflect'),
        actions: [
          const SyncStatusIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.clock),
            onPressed: () => context.pushNamed('question-history'),
            tooltip: 'Question History',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 4),

          // ── TODAY'S QUESTION ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SectionDivider(label: "Today's Question"),
          ),
          const DailyQuestionCard(),
          const SizedBox(height: 8),

          // ── APPRECIATION ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SectionDivider(label: 'Appreciation'),
          ),
          const QuickAppreciation(),
          const SizedBox(height: 4),

          // Recent appreciations
          appreciationsAsync.when(
            data: (appreciations) {
              if (appreciations.isEmpty) return const SizedBox.shrink();
              return Column(
                children: appreciations.take(5).map((a) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: AppreciationBlock(
                    title: a.title,
                    body: a.body,
                  ),
                )).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),

          // ── REFLECTION COUNT BANNER ──
          _ReflectionCountBanner(count: todayReflectionCountAsync.valueOrNull ?? 0),
          const SizedBox(height: 4),

          // ── REFLECTIONS ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SectionDivider(label: 'Reflections'),
          ),
          const ReflectionCard(),
          const SizedBox(height: 12),

          // Recent reflections
          recentAsync.when(
            data: (reflections) {
              if (reflections.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...reflections.map((r) => _reflectionTile(context, ref, r)),
                  const SizedBox(height: 12),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // ── PAST QUESTIONS ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SectionDivider(label: 'Past Questions'),
          ),
          allAnswersAsync.when(
            data: (answers) {
              if (answers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    'No answers yet. Answer today\'s question to get started.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              // Map answers to their questions
              final questions = allQuestionsAsync.valueOrNull ?? [];
              final questionMap = <int, QuestionItem>{};
              for (final q in questions) {
                questionMap[q.id] = q;
              }

              return Column(
                children: [
                  ...answers.take(5).map((answer) {
                    final question = questionMap[answer.questionId];
                    return _pastQuestionTile(
                      context,
                      category: answer.category,
                      question: question?.text ?? 'Unknown question',
                      date: answer.dateAnswered,
                      onTap: () {
                        _showPastAnswer(context, answer, question);
                      },
                    );
                  }),
                  if (answers.length > 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: TextButton(
                        onPressed: () => context.pushNamed('question-history'),
                        child: Text(
                          'View all ${answers.length} questions',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _reflectionTile(BuildContext context, WidgetRef ref, dynamic reflection) {
    final theme = Theme.of(context);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = '${reflection.date.day} ${months[reflection.date.month - 1]} ${reflection.date.year}';
    final title = (reflection.promptText?.isNotEmpty == true)
        ? reflection.promptText
        : "Today's Reflection";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: SerenityCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.pencil, size: 14),
                  onPressed: () => _showEditReflectionSheet(context, ref, reflection),
                  tooltip: 'Edit reflection',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reflection.content.isNotEmpty
                  ? reflection.content
                  : 'No reflection written',
              style: TextStyle(fontFamily: 'Cormorant Garamond',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReflectionSheet(BuildContext context, WidgetRef ref, dynamic reflection) {
    final textController = TextEditingController(text: reflection.content ?? '');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Edit Reflection',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Prompt text (read-only)
                    Text(
                      reflection.promptText ?? "Today's Reflection",
                      style: TextStyle(
                        fontFamily: 'Cormorant Garamond',
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Editable text field
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'Reflect on your connection...',
                        isDense: true,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        onPressed: saving
                            ? null
                            : () async {
                                setSheetState(() => saving = true);
                                try {
                                  final dao = ref.read(reflectionsDaoProvider);
                                  await dao.updateReflection(
                                    ReflectionsCompanion(
                                      id: Value(reflection.id),
                                      promptType: Value(reflection.promptType ?? 'daily'),
                                      promptText: Value(reflection.promptText ?? ''),
                                      content: Value(textController.text.trim()),
                                      moodScore: Value(null),
                                      date: Value(reflection.date),
                                    ),
                                  );
                                  if (ctx.mounted) {
                                    ref.invalidate(recentReflectionsProvider);
                                    ref.invalidate(todayReflectionCountProvider);
                                    Navigator.of(ctx).pop();
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to update: $e')),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setSheetState(() => saving = false);
                                  }
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pastQuestionTile(
    BuildContext context, {
    required String category,
    required String question,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CategoryBadge(label: category),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showPastAnswer(BuildContext context, dynamic answer, QuestionItem? question) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CategoryBadge(label: answer.category),
              const SizedBox(height: 12),
              if (question != null)
                Text(
                  question.text,
                  style: TextStyle(fontFamily: 'Cormorant Garamond', 
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  answer.answerText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Answered ${_formatDate(answer.dateAnswered)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Banner showing today's reflection count.
class _ReflectionCountBanner extends StatelessWidget {
  final int count;

  const _ReflectionCountBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isMaxed = count >= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        isMaxed ? '3 reflections today \u2014 max reached' : 'Reflections today: $count/3',
        style: theme.textTheme.labelMedium?.copyWith(
          color: isMaxed
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
      ),
    );
  }
}
