import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/domain/user_profile_repository.dart';
import '../storage/app_storage_keys.dart';

/// A5.5 — Resolves the single, stable guest identity of this device.
///
/// The contract requires reusing the existing `anonymousInstallId` and forbids
/// a second competing guest identity system. Resolution order therefore is:
/// 1. the [LocalUserProfile.anonymousInstallId] (the pre-existing identity)
///    when a local profile exists and its id is non-empty;
/// 2. otherwise a persisted install-scoped id under
///    [AppStorageKeys.anonymousInstallId], created once lazily and reused for
///    every subsequent resolution.
///
/// Both sources are device-scoped and singular, so a device has exactly ONE
/// guest identity for ownership purposes. Guests who never ran profile setup
/// still get a deterministic id so the claim lifecycle is retry-safe.
class GuestInstallIdentity {
  GuestInstallIdentity({required UserProfileRepository userProfileRepository})
    : _userProfileRepository = userProfileRepository;

  final UserProfileRepository _userProfileRepository;

  /// The device's stable guest identity, resolving the profile-based id first
  /// and lazily creating (and persisting) the install-scoped fallback.
  Future<String> resolveGuestId() async {
    final profile = await _userProfileRepository.loadProfile();
    final profileId = profile?.anonymousInstallId;
    if (profileId != null && profileId.isNotEmpty) return profileId;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(AppStorageKeys.anonymousInstallId);
    if (stored != null && stored.isNotEmpty) return stored;

    final generated = _generateInstallId();
    await prefs.setString(AppStorageKeys.anonymousInstallId, generated);
    return generated;
  }

  static String _generateInstallId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(99999);
    return 'guest_${timestamp}_$suffix';
  }
}