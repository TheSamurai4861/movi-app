import 'package:flutter/foundation.dart';

/// Public-facing metadata for an IPTV source (non-sensitive).
@immutable
class IptvSource {
  const IptvSource({
    required this.id,
    required this.alias,
    required this.endpoint,
    required this.username,
  });

  final String id;
  final String alias;
  final String endpoint;
  final String username;
}

/// Sensitive credentials associated with an [IptvSource].
///
/// These credentials must never be stored in clairtexte in a remote database.
@immutable
class IptvCredentials {
  const IptvCredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

/// Representation intended to be stored remotely (e.g. Supabase).
///
/// The [encryptedCredentials] field contains AES-256-CBC encrypted credentials.
/// Use [IptvCredentialsCipher] to encrypt/decrypt this field.
///
/// The encryption key is unique per user and stored securely on-device via
/// [CredentialsVault]. This ensures that:
/// - Credentials are encrypted before being sent to Supabase
/// - Even if the database is compromised, credentials remain protected
/// - Only devices with the user's key can decrypt the credentials
///
/// Example flow:
/// ```dart
/// // Before uploading to Supabase
/// final cipher = IptvCredentialsCipher(vault);
/// await cipher.initialize(userId);
/// final encrypted = await cipher.encryptCredentials(
///   IptvCredentialsPayload(username: 'x', password: 'y'),
/// );
/// final remoteSource = RemoteIptvSource(
///   id: '...',
///   alias: 'My IPTV',
///   endpoint: 'http://...',
///   encryptedCredentials: encrypted,
/// );
///
/// // After downloading from Supabase
/// final credentials = await cipher.decryptCredentials(
///   remoteSource.encryptedCredentials,
/// );
/// ```
@immutable
class RemoteIptvSource {
  const RemoteIptvSource({
    required this.id,
    required this.alias,
    required this.endpoint,
    required this.encryptedCredentials,
  });

  final String id;
  final String alias;
  final String endpoint;

  /// AES-256-CBC encrypted blob containing credentials.
  ///
  /// Formats supportés:
  /// - Legacy (v1): `base64(ciphertext)` (IV fixe stocké localement par utilisateur)
  /// - Nouveau (v2): `v2:` + `base64( iv(16) || ciphertextBytes )` (IV aléatoire par message)
  ///
  /// Use [IptvCredentialsCipher.encryptCredentials] to create this value,
  /// and [IptvCredentialsCipher.decryptCredentials] to read it.
  final String encryptedCredentials;

  /// Creates a [RemoteIptvSource] from a Supabase row.
  factory RemoteIptvSource.fromJson(Map<String, dynamic> json) {
    return RemoteIptvSource(
      id: json['id'] as String,
      alias: json['alias'] as String,
      endpoint: json['endpoint'] as String,
      encryptedCredentials: json['encrypted_credentials'] as String,
    );
  }

  /// Converts to a map suitable for Supabase upsert.
  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'endpoint': endpoint,
        'encrypted_credentials': encryptedCredentials,
      };
}
