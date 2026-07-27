import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/database_provider.dart';

/// Service for couple linking via invite codes.
class CoupleService {
  final SupabaseClient _supabase;

  CoupleService(this._supabase);

  /// Returns the current Supabase user ID or throws.
  String _userId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return user.id;
  }

  /// Generates a 6-character alphanumeric invite code, inserts a row in the
  /// couples table with a 24-hour expiry, and returns a map with the code
  /// and the created couple's id.
  Future<Map<String, dynamic>> createInviteCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;
    // Generate until we get a unique code (collision is extremely unlikely
    // with 36^6 combinations, but guard against it).
    int attempts = 0;
    Object? existing;
    do {
      code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      existing = await _supabase
          .from('couples')
          .select('id')
          .eq('invite_code', code)
          .maybeSingle();
      attempts++;
      if (attempts > 10) {
        throw Exception('Could not generate a unique invite code');
      }
    } while (existing != null);

    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    await _supabase.from('couples').insert({
      'invite_code': code,
      'code_expires_at': expiresAt.toIso8601String(),
      'partner_a_id': _userId(),
    });

    // Fetch the created couple to get its id
    final couple = await _supabase
        .from('couples')
        .select('id')
        .eq('invite_code', code)
        .maybeSingle();

    return {'code': code, 'id': couple?['id']};
  }

  /// Finds a couple by invite code, validates it is not expired and still
  /// available, then links the current user as partner B.
  /// Returns the updated couple row.
  Future<Map<String, dynamic>> joinWithCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.length != 6) {
      throw Exception('Invite code must be 6 characters');
    }

    final couple = await _supabase
        .from('couples')
        .select()
        .eq('invite_code', trimmed)
        .maybeSingle();

    if (couple == null) {
      throw Exception('Invalid invite code');
    }

    final expiresAt = DateTime.parse(couple['code_expires_at'] as String);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Invite code has expired');
    }

    if (couple['partner_b_id'] != null) {
      throw Exception('This invite code has already been used');
    }

    // Prevent linking with yourself
    final userId = _userId();
    if (couple['partner_a_id'] == userId) {
      throw Exception('You cannot join your own invite code');
    }

    await _supabase
        .from('couples')
        .update({
          'partner_b_id': userId,
          'linked_at': DateTime.now().toIso8601String(),
        })
        .eq('id', couple['id']);

    // Fetch the updated couple (now with partner_b_id set)
    final updated = await _supabase
        .from('couples')
        .select()
        .eq('id', couple['id'])
        .single();

    return updated;
  }

  /// Returns the active couple for the current user, or null if not linked.
  ///
  /// An active couple is one where the user is either partner_a or partner_b
  /// and partner_b_id is not null (meaning linking is complete).
  /// Also fetches the partner's display name from the profiles table.
  Future<Map<String, dynamic>?> getCoupleStatus() async {
    final userId = _userId();

    final couple = await _supabase
        .from('couples')
        .select()
        .or(
          'partner_a_id.eq.$userId,partner_b_id.eq.$userId',
        )
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (couple == null) return null;

    // Only return if fully linked
    if (couple['partner_b_id'] == null) return null;

    // Fetch partner's display name from profiles table
    final partnerUserId = couple['partner_a_id'] == userId
        ? couple['partner_b_id'] as String
        : couple['partner_a_id'] as String;

    final partnerProfile = await _supabase
        .from('profiles')
        .select('display_name')
        .eq('id', partnerUserId)
        .maybeSingle();

    couple['partner_name'] = partnerProfile?['display_name'] as String?;

    return couple;
  }

  /// Removes the current user from the active couple.
  ///
  /// If the user is partner_a, the entire couple record is deleted. If the user
  /// is partner_b, only their partner_b link is cleared.
  Future<void> unlink() async {
    final userId = _userId();
    final couple = await getCoupleStatus();
    if (couple == null) return;

    final coupleId = couple['id'];

    if (couple['partner_a_id'] == userId) {
      // Partner A (inviter) leaves: delete the couple entirely
      await _supabase.from('couples').delete().eq('id', coupleId);
    } else {
      // Partner B leaves: just clear their link
      await _supabase.from('couples').update({
        'partner_b_id': null,
        'linked_at': null,
      }).eq('id', coupleId);
    }
  }

  /// Fetches the partner's profile data given their user ID.
  Future<Map<String, dynamic>?> getPartnerProfile(String partnerId) async {
    return _supabase
        .from('profiles')
        .select('display_name, partner_name, profile_photo_url')
        .eq('id', partnerId)
        .maybeSingle();
  }

  /// Fetches the current user's profile from Supabase.
  Future<Map<String, dynamic>?> getMyProfile() async {
    return _supabase
        .from('profiles')
        .select('display_name, partner_name, profile_photo_url')
        .eq('id', _userId())
        .maybeSingle();
  }
}

final coupleServiceProvider = Provider<CoupleService>((ref) {
  return CoupleService(Supabase.instance.client);
});

/// Watches the current user's couple status.
///
/// Returns a map with couple data (id, invite_code, partner_a_id, partner_b_id,
/// linked_at) when fully linked, or null when there is no active couple.
final coupleStatusProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.watch(coupleServiceProvider);
  return service.getCoupleStatus();
});

/// Tracks whether the user has temporarily skipped couple linking.
/// When true, the auth gate shows SerenityApp even without a linked couple.
/// Persisted in SyncMetadata so the choice survives app restarts.
final coupleSkippedProvider = FutureProvider<bool>((ref) async {
  final dao = ref.watch(syncMetadataDaoProvider);
  final value = await dao.get('couple_skipped');
  return value == 'true';
});
