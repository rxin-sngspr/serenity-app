import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/database/database_provider.dart';
import 'core/sync/sync_provider.dart';
import 'features/couple/providers/couple_provider.dart';

/// Reads saved preferences from DB on startup and syncs to in-memory providers.
final appInitProvider = FutureProvider<void>((ref) async {
  final dao = ref.watch(settingsDaoProvider);

  // Check if user completed onboarding
  final name = await dao.get('display_name');
  if (name != null && name.isNotEmpty) {
    ref.read(onboardedProvider.notifier).state = true;
  }

  // Restore saved theme
  final themeIdx = await dao.get('theme_index');
  if (themeIdx != null) {
    final idx = int.tryParse(themeIdx) ?? 0;
    if (idx >= 0 && idx < AppTheme.values.length) {
      ref.read(themeModeProvider.notifier).state = AppTheme.values[idx];
    }
  }

  // Restore saved brightness
  final bri = await dao.get('brightness');
  if (bri == 'light') {
    ref.read(brightnessProvider.notifier).state = Brightness.light;
  }
});

/// Cached GoRouter instance, recreated only when onboarding state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final isOnboarded = ref.watch(onboardedProvider);
  return createRouter(isOnboarded);
});

class SerenityApp extends ConsumerWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wait for startup initialization before rendering the app
    final initAsync = ref.watch(appInitProvider);

    // Auto-sync on app open when a couple is linked
    ref.listen(coupleStatusProvider, (prev, next) {
      final prevCouple = prev?.valueOrNull;
      final nextCouple = next.valueOrNull;
      if (prevCouple == null && nextCouple != null) {
        ref.read(syncStateProvider.notifier).triggerSync();
      }
    });

    return initAsync.when(
      loading: () => _buildSplash(context),
      error: (err, _) => _buildSplash(context),
      data: (_) {
        final theme = ref.watch(themeModeProvider);
        final brightness = ref.watch(brightnessProvider);
        final router = ref.watch(routerProvider);

        return MaterialApp.router(
          title: 'Serenity',
          debugShowCheckedModeBanner: false,
          theme: AppThemeData.getTheme(theme: theme, brightness: brightness),
          darkTheme:
              AppThemeData.getTheme(theme: theme, brightness: Brightness.dark),
          themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: router,
        );
      },
    );
  }

  Widget _buildSplash(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.heart,
              size: 48,
              color: const Color(0xFFB76E79),
            ),
            const SizedBox(height: 16),
            Text(
              'Serenity',
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 28,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
