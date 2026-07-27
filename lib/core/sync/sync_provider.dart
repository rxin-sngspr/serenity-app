import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_provider.dart';
import 'sync_service.dart';
import 'sync_state.dart';

/// Provides the core [SyncService] with database and Supabase client.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db, Supabase.instance.client);
});

/// Manages sync state and triggers push/pull cycles on connectivity changes.
final syncStateProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncNotifier(this._ref) : super(SyncState.idle()) {
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (result.contains(ConnectivityResult.none)) {
        state = SyncState.offline();
      } else if (state.status == SyncStatus.offline ||
          state.status == SyncStatus.idle) {
        triggerSync();
      }
    });
  }

  /// Run a full push-then-pull cycle.
  ///
  /// No-ops if a sync is already in progress.
  /// Returns early to idle if the database isn't ready yet, avoiding a
  /// spurious error flash on startup before migrations complete.
  Future<void> triggerSync() async {
    if (state.status == SyncStatus.syncing) return;

    state = SyncState.syncing();
    try {
      final service = _ref.read(syncServiceProvider);
      await service.push();
      await service.pull();
      state = SyncState.synced(DateTime.now());
    } catch (e) {
      // If the database hasn't finished initializing, silently return to idle.
      // The couple-status listener in app.dart will retry on the next change.
      if (e.toString().contains('no such table') ||
          e.toString().contains('is closed') ||
          e.toString().contains('DatabaseException')) {
        state = SyncState.idle();
        return;
      }
      state = SyncState.error(e.toString());
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
