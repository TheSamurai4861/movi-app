import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Client for the Supabase Edge Function responsible for IPTV credentials
/// encryption/decryption (multi-device).
///
/// The function must be deployed as `iptv-credentials`.
class IptvCredentialsEdgeService {
  const IptvCredentialsEdgeService(this._client);

  final SupabaseClient _client;

  static const String functionName = 'iptv-credentials';

  Future<String> encrypt({
    required String username,
    required String password,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'op': 'encrypt',
        'username': username,
        'password': password,
      },
    );

    final data = _asMap(response.data);
    final ciphertext = data['ciphertext'];
    if (ciphertext is String && ciphertext.trim().isNotEmpty) {
      return ciphertext;
    }
    throw const FormatException('Edge function response missing ciphertext.');
  }

  Future<({String username, String password})> decrypt({
    required String ciphertext,
  }) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: <String, dynamic>{
          'op': 'decrypt',
          'ciphertext': ciphertext,
        },
      );

      // Check if the response contains an error
      final data = _asMap(response.data);
      if (data.containsKey('error')) {
        final error = data['error'];
        final details = data['details'];
        final errorMessage = details != null 
            ? '$error: $details'
            : error.toString();
        throw FormatException('Edge function error: $errorMessage');
      }

      final username = data['username'];
      final password = data['password'];
      if (username is String && password is String) {
        return (username: username, password: password);
      }
      throw FormatException('Edge function response missing credentials.');
    } on FormatException {
      rethrow;
    } catch (e) {
      // Wrap other exceptions with more context
      throw FormatException('Failed to decrypt credentials: $e');
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw FormatException('Unexpected edge function response: ${value.runtimeType}');
  }
}

