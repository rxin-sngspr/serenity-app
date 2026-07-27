/// Tracks the current sync engine status.
enum SyncStatus { idle, syncing, synced, error, offline }

/// Immutable state snapshot for the sync StateNotifier.
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncState._({
    required this.status,
    this.lastSyncedAt,
    this.errorMessage,
  });

  factory SyncState.idle() => const SyncState._(status: SyncStatus.idle);

  factory SyncState.syncing() => const SyncState._(status: SyncStatus.syncing);

  factory SyncState.synced(DateTime at) => SyncState._(
        status: SyncStatus.synced,
        lastSyncedAt: at,
      );

  factory SyncState.error(String message) => SyncState._(
        status: SyncStatus.error,
        errorMessage: message,
      );

  factory SyncState.offline() => const SyncState._(status: SyncStatus.offline);
}
