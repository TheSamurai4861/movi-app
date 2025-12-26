import 'package:flutter/foundation.dart';

import 'package:movi/src/core/parental/domain/entities/parental_session.dart';
import 'package:movi/src/core/storage/storage.dart';

/// Stores a short-lived "unlock session" for parental controls.
///
/// - In-memory cache for fast checks
/// - Optional persistence via [SecureStorageRepository] (best-effort)
class ParentalSessionService {
  ParentalSessionService(
    this._storage, {
    this.persistToSecureStorage = true,
    this.storageKeyPrefix = 'parental.unlock_session.',
  });

  final SecureStorageRepository _storage;
  final bool persistToSecureStorage;
  final String storageKeyPrefix;

  final Map<String, ParentalSession> _memory = <String, ParentalSession>{};

  String _key(String profileId) => '$storageKeyPrefix$profileId';

  Future<ParentalSession?> getSession(String profileId) async {
    final id = profileId.trim();
    if (id.isEmpty) return null;

    final mem = _memory[id];
    if (mem != null) {
      if (mem.isExpired) {
        _memory.remove(id);
        if (persistToSecureStorage) {
          await _safeRemove(id);
        }
        return null;
      }
      return mem;
    }

    if (!persistToSecureStorage) return null;

    final payload = await _storage.get(_key(id));
    if (payload == null) return null;

    try {
      final session = ParentalSession.fromJson(payload);
      if (session.isExpired) {
        await _safeRemove(id);
        return null;
      }
      _memory[id] = session;
      return session;
    } catch (e) {
      await _safeRemove(id);
      return null;
    }
  }

  Future<bool> isUnlocked(String profileId) async {
    final session = await getSession(profileId);
    return session != null && !session.isExpired;
  }

  Future<void> unlock({
    required String profileId,
    Duration ttl = const Duration(minutes: 10),
  }) async {
    final id = profileId.trim();
    if (id.isEmpty) return;

    final session = ParentalSession(
      profileId: id,
      expiresAt: DateTime.now().add(ttl),
    );
    _memory[id] = session;

    if (!persistToSecureStorage) return;
    try {
      await _storage.put(key: _key(id), payload: session.toJson());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ParentalSessionService] persist unlock failed: $e');
      }
    }
  }

  Future<void> lock(String profileId) async {
    final id = profileId.trim();
    if (id.isEmpty) return;
    _memory.remove(id);
    if (!persistToSecureStorage) return;
    await _safeRemove(id);
  }

  Future<void> _safeRemove(String profileId) async {
    try {
      await _storage.remove(_key(profileId));
    } catch (_) {}
  }
}

