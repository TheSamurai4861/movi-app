import 'dart:convert';

import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';

class RouteProfileCredentialsStore {
  RouteProfileCredentialsStore(this._vault);

  final CredentialsVault _vault;

  static const String _prefix = 'route_profile_proxy_';

  Future<void> save(
    String routeProfileId,
    RouteProfileCredentials credentials,
  ) async {
    final payload = jsonEncode(<String, String>{
      'username': credentials.username,
      'password': credentials.password,
    });
    await _vault.storePassword('$_prefix$routeProfileId', payload);
  }

  Future<RouteProfileCredentials?> read(String routeProfileId) async {
    final payload = await _vault.readPassword('$_prefix$routeProfileId');
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      final username = decoded['username']?.toString() ?? '';
      final password = decoded['password']?.toString() ?? '';
      if (username.isEmpty && password.isEmpty) return null;
      return RouteProfileCredentials(username: username, password: password);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String routeProfileId) async {
    await _vault.removePassword('$_prefix$routeProfileId');
  }
}
