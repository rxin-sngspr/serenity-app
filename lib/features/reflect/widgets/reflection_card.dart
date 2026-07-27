import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/components/serenity_card.dart';
import '../providers/reflect_provider.dart';

class ReflectionCard extends ConsumerStatefulWidget {
  const ReflectionCard({super.key});

  @override
  ConsumerState<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends ConsumerState<ReflectionCard> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _save() async {
    final count = await ref.read(todayReflectionCountProvider.future);
    if (count >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max reflections for today reached'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    try {
      final prompt = ref.read(currentReflectionPromptProvider);
      final dao = ref.read(reflectionsDaoProvider);
      final today = DateTime.now();
      final existing = await dao.getReflectionsByDate(today);

      final companion = ReflectionsCompanion(
        promptType: Value('daily'),
        promptText: Value(prompt?.text ?? 'What made you feel most connected today?'),
        content: Value(text),
        moodScore: Value(null),
        date: Value(today),
      );

      if (existing.isNotEmpty) {
        final mostRecent = existing.first;
        await dao.updateReflection(
          companion.copyWith(id: Value(mostRecent.id)),
        );
      } else {
        await dao.createReflection(companion);
      }

      _controller.clear();
      if (mounted) {
        ref.invalidate(todayReflectionCountProvider);
        ref.invalidate(recentReflectionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reflection saved'),
            duration: Duration(seconds: 2),
          ),
        );
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
    final prompt = ref.watch(currentReflectionPromptProvider);
    final countAsync = ref.watch(todayReflectionCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    final isMaxed = count >= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SerenityCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Counter banner
            if (count >= 1 && count < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${3 - count} remaining today',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            if (isMaxed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Max reflections for today',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Text(
              "Today's Reflection",
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              prompt?.text ?? 'What made you feel most connected today?',
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Reflect on your connection...',
                isDense: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              enabled: !isMaxed,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: (_saving || isMaxed) ? null : _save,
                child: _saving
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
  }
}
