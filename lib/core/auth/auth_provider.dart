import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';

/// Tracks the status of authentication state.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Initializes Supabase once on app startup.
final supabaseInitProvider = FutureProvider<void>((ref) async {
  await SupabaseConfig.initialize();
});

/// Streams authentication state changes from Supabase.
/// Emits [AuthStatus.authenticated] when a valid session exists,
/// [AuthStatus.unauthenticated] otherwise, and
/// [AuthStatus.unknown] before the first emission.
final authStatusProvider = StreamProvider<AuthStatus>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((response) {
    if (response.session?.user != null) {
      return AuthStatus.authenticated;
    }
    return AuthStatus.unauthenticated;
  });
});

/// Provides the currently authenticated [User], or null if not signed in.
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Wraps Supabase auth actions (sign-in, sign-up, sign-out) for use with Riverpod.
class AuthProvider {
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}

final authProvider = Provider<AuthProvider>((ref) {
  return AuthProvider();
});
