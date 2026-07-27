import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/reflect/providers/reflect_provider.dart';

/// Compact card prompting the user to reflect if they haven't today.
///
/// Only renders when [todayReflectionCountProvider] returns 0.
/// Shows a "Reflect now" button.
class ReflectionNudge extends ConsumerWidget {
  const ReflectionNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final countAsync = ref.watch(todayReflectionCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    // Don't render if already reflected today
    if (count > 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Reflect on your day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Reflect now button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _navigateToReflect(context),
                icon: const Icon(LucideIcons.sparkles, size: 16),
                label: const Text('Reflect now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReflect(BuildContext context) {
    // Switch to the Reflect tab (index 1) within the shell
    try {
      StatefulNavigationShell.of(context).goBranch(1);
    } catch (_) {
      // Fallback if not inside a shell context
      context.go('/reflect');
    }
  }
}


