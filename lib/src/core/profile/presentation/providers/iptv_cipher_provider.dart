import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/iptv_credentials_cipher.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';

/// Provider pour le service de chiffrement des credentials IPTV.
///
/// Initialise automatiquement le cipher avec le profileId courant.
/// Retourne `null` si aucun profil n'est sélectionné.
///
/// Usage:
/// ```dart
/// final cipher = ref.watch(iptvCredentialsCipherProvider);
/// if (cipher != null && cipher.isInitialized) {
///   final encrypted = await cipher.encryptCredentials(...);
/// }
/// ```
final iptvCredentialsCipherProvider =
    FutureProvider<IptvCredentialsCipher?>((ref) async {
  final profileId = ref.watch(selectedProfileIdProvider);

  if (profileId == null || profileId.trim().isEmpty) {
    return null;
  }

  final vault = ref.watch(slProvider)<CredentialsVault>();
  final cipher = IptvCredentialsCipher(vault);

  try {
    await cipher.initialize(profileId.trim());
  } catch (e, st) {
    assert(() {
      debugPrint('[iptvCredentialsCipherProvider] init failed: $e\n$st');
      return true;
    }());
    throw StateError('Unable to initialize IPTV credentials cipher.');
  }

  return cipher;
});

