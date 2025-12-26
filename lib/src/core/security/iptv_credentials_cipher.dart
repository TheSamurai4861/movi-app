import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart' show immutable;

import 'package:movi/src/core/security/credentials_vault.dart';

/// Service pour chiffrer/déchiffrer les credentials IPTV avant synchronisation.
///
/// ⚠️ Important:
/// - Legacy (v1): AES-256-CBC avec IV fixe stocké (faible).
/// - Nouveau (v2): AES-256-CBC avec IV aléatoire par message, encodé avec le ciphertext.
///   Format: "v2:" + base64( iv(16) || ciphertextBytes )
///
/// Le déchiffrement reste rétro-compatible :
/// - si préfixe "v2:" -> unpack iv+ciphertext
/// - sinon -> fallback legacy (IV stocké)
class IptvCredentialsCipher {
  IptvCredentialsCipher(this._vault);

  final CredentialsVault _vault;

  static const _keyPrefix = 'iptv_cipher_key_';
  static const _ivPrefix = 'iptv_cipher_iv_';

  static const _v2Prefix = 'v2:';
  static const _cbcIvLen = 16;

  encrypt.Key? _key;
  encrypt.IV? _legacyIv;
  String? _userId;

  /// Initialise le cipher pour un utilisateur donné.
  ///
  /// Génère une clé de chiffrement si elle n'existe pas encore.
  Future<void> initialize(String userId) async {
    _userId = userId;

    final storedKey = await _vault.readPassword('$_keyPrefix$userId');
    final storedIv = await _vault.readPassword('$_ivPrefix$userId');

    if (storedKey != null && storedKey.isNotEmpty) {
      _key = encrypt.Key.fromBase64(storedKey);
    } else {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      _key = encrypt.Key(Uint8List.fromList(keyBytes));
      await _vault.storePassword('$_keyPrefix$userId', _key!.base64);
    }

    // Legacy IV (v1) conservé uniquement pour déchiffrer l'existant sans préfixe.
    if (storedIv != null && storedIv.isNotEmpty) {
      _legacyIv = encrypt.IV.fromBase64(storedIv);
    } else {
      final random = Random.secure();
      final ivBytes = List<int>.generate(_cbcIvLen, (_) => random.nextInt(256));
      _legacyIv = encrypt.IV(Uint8List.fromList(ivBytes));
      await _vault.storePassword('$_ivPrefix$userId', _legacyIv!.base64);
    }
  }

  /// Vérifie si le cipher est initialisé.
  bool get isInitialized => _key != null;

  /// Chiffre une chaîne JSON contenant les credentials.
  ///
  /// Retourne une chaîne base64 qui peut être stockée dans Supabase.
  Future<String> encryptString(String plaintext) async {
    _ensureInitialized();

    // v2: IV aléatoire par chiffrement
    final random = Random.secure();
    final ivBytes = Uint8List.fromList(
      List<int>.generate(_cbcIvLen, (_) => random.nextInt(256)),
    );
    final iv = encrypt.IV(ivBytes);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    // Pack: iv || ciphertextBytes
    final packed = Uint8List(ivBytes.length + encrypted.bytes.length)
      ..setRange(0, ivBytes.length, ivBytes)
      ..setRange(
        ivBytes.length,
        ivBytes.length + encrypted.bytes.length,
        encrypted.bytes,
      );

    return '$_v2Prefix${base64Encode(packed)}';
  }

  /// Déchiffre une chaîne base64 récupérée depuis Supabase.
  ///
  /// Retourne la chaîne JSON originale contenant les credentials.
  Future<String> decryptString(String ciphertext) async {
    _ensureInitialized();

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );

    // v2
    if (ciphertext.startsWith(_v2Prefix)) {
      final b64 = ciphertext.substring(_v2Prefix.length);
      final packed = base64Decode(b64);

      if (packed.length <= _cbcIvLen) {
        throw StateError('Invalid v2 ciphertext payload (too short).');
      }

      final ivBytes = packed.sublist(0, _cbcIvLen);
      final cipherBytes = packed.sublist(_cbcIvLen);

      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      final enc = encrypt.Encrypted(Uint8List.fromList(cipherBytes));

      return encrypter.decrypt(enc, iv: iv);
    }

    // legacy v1 (sans préfixe) -> utilise l'IV stocké (faible mais rétro-compatible)
    final legacyIv = _legacyIv;
    if (legacyIv == null) {
      throw StateError('Legacy IV missing: cannot decrypt legacy ciphertext.');
    }
    return encrypter.decrypt64(ciphertext, iv: legacyIv);
  }

  /// Chiffre un objet [IptvCredentialsPayload] en chaîne base64.
  Future<String> encryptCredentials(IptvCredentialsPayload credentials) async {
    final json = jsonEncode(credentials.toJson());
    return encryptString(json);
  }

  /// Déchiffre une chaîne base64 en [IptvCredentialsPayload].
  Future<IptvCredentialsPayload> decryptCredentials(String ciphertext) async {
    final json = await decryptString(ciphertext);
    final map = jsonDecode(json) as Map<String, dynamic>;
    return IptvCredentialsPayload.fromJson(map);
  }

  /// Supprime la clé de chiffrement pour cet utilisateur.
  ///
  /// ⚠️ Attention : après cette opération, les données chiffrées ne pourront
  /// plus être déchiffrées !
  Future<void> deleteKey() async {
    if (_userId == null) return;

    await _vault.removePassword('$_keyPrefix$_userId');
    await _vault.removePassword('$_ivPrefix$_userId');

    _key = null;
    _legacyIv = null;
  }

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
        'IptvCredentialsCipher not initialized. Call initialize(userId) first.',
      );
    }
  }
}

/// Payload des credentials IPTV à chiffrer/déchiffrer.
@immutable
class IptvCredentialsPayload {
  const IptvCredentialsPayload({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  factory IptvCredentialsPayload.fromJson(Map<String, dynamic> json) {
    return IptvCredentialsPayload(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

