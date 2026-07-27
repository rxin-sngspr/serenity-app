import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../sync/sync_provider.dart';
import '../sync/sync_state.dart';

/// Small icon shown in the app bar to reflect the current sync status.
///
/// * Synced  -> check icon (green)
/// * Syncing -> spinning progress indicator
/// * Error   -> alert circle (error colour)
/// * Offline -> wifi-off (muted)
/// * Idle    -> cloud (muted)
class SyncStatusIndicator extends ConsumerWidget {
  final double size;

  const SyncStatusIndicator({super.key, this.size = 18});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final theme = Theme.of(context);

    switch (syncState.status) {
      case SyncStatus.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        );

      case SyncStatus.synced:
        return Icon(
          LucideIcons.checkCheck,
          size: size,
          color: theme.colorScheme.primary,
        );

      case SyncStatus.error:
        return Icon(
          LucideIcons.alertCircle,
          size: size,
          color: theme.colorScheme.error,
        );

      case SyncStatus.offline:
        return Icon(
          LucideIcons.wifiOff,
          size: size,
          color: theme.colorScheme.onSurfaceVariant,
        );

      case SyncStatus.idle:
        return Icon(
          LucideIcons.cloud,
          size: size,
          color: theme.colorScheme.onSurfaceVariant,
        );
    }
  }
}
