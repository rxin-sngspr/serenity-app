import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/components/serenity_card.dart';
import '../../story/providers/timeline_provider.dart';

class QuickAppreciation extends ConsumerStatefulWidget {
  const QuickAppreciation({super.key});

  @override
  ConsumerState<QuickAppreciation> createState() => _QuickAppreciationState();
}

class _QuickAppreciationState extends ConsumerState<QuickAppreciation> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      await db.into(db.memories).insert(
        MemoriesCompanion(
          title: Value('Today I appreciated...'),
          body: Value(text),
          date: Value(DateTime.now()),
          type: const Value('appreciation'),
        ),
      );
      _controller.clear();
      if (mounted) {
        ref.invalidate(timelineProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appreciation saved'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SerenityCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '\u2665',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Quick Appreciation',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Today I appreciated...',
                isDense: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
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
