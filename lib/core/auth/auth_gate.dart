import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../features/auth/screens/couple_linking_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/couple/providers/couple_provider.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'auth_provider.dart';

/// Top-level routing gate that watches auth state and onboarded status.
///
/// - Supabase not initialized -> splash
/// - Not authenticated -> sign-in
/// - Authenticated, not onboarded -> onboarding
/// - Authenticated and onboarded -> full app ([SerenityApp])
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabaseAsync = ref.watch(supabaseInitProvider);

    return supabaseAsync.when(
      loading: () => _buildAppShell(ref, const _SplashContent()),
      error: (_, _) => _buildAppShell(ref, const SignInScreen()),
      data: (_) {
        return ref.watch(authStatusProvider).when(
              data: (status) => _buildForStatus(ref, status),
              loading: () => _buildAppShell(ref, const _SplashContent()),
      error: (_, _) => _buildAppShell(ref, const SignInScreen()),
            );
      },
    );
  }

  Widget _buildForStatus(WidgetRef ref, AuthStatus status) {
    switch (status) {
      case AuthStatus.unknown:
        return _buildAppShell(ref, const _SplashContent());
      case AuthStatus.unauthenticated:
        return _buildAppShell(ref, const SignInScreen());
      case AuthStatus.authenticated:
        // Check couple skip preference (persisted) before couple status.
        // If still loading the skip flag, show splash to avoid a flash.
        return ref.watch(coupleSkippedProvider).when(
          loading: () => _buildAppShell(ref, const _SplashContent()),
          data: (coupleSkipped) {
            return ref.watch(coupleStatusProvider).when(
              data: (couple) {
                if (couple == null && !coupleSkipped) {
                  return _buildAppShell(ref, const CoupleLinkingScreen());
                }
                return const SerenityApp();
              },
              loading: () => _buildAppShell(ref, const _SplashContent()),
              error: (_, _) => const SerenityApp(),
            );
          },
          error: (_, _) {
            // Can't read skip flag — default to showing couple linking
            return ref.watch(coupleStatusProvider).when(
              data: (couple) {
                if (couple == null) {
                  return _buildAppShell(ref, const CoupleLinkingScreen());
                }
                return const SerenityApp();
              },
              loading: () => _buildAppShell(ref, const _SplashContent()),
              error: (_, _) => const SerenityApp(),
            );
          },
        );
    }
  }

  /// Wraps auth-facing screens in a properly themed [MaterialApp].
  /// This is replaced by [SerenityApp] once the user is authenticated.
  Widget _buildAppShell(WidgetRef ref, Widget home) {
    final theme = ref.watch(themeModeProvider);
    final brightness = ref.watch(brightnessProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Serenity',
      theme: AppThemeData.getTheme(theme: theme, brightness: brightness),
      darkTheme:
          AppThemeData.getTheme(theme: theme, brightness: Brightness.dark),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
    );
  }
}

/// Minimal splash shown while Supabase or auth state resolves.
class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
