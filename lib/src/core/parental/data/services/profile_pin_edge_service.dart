import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePinEdgeService {
  const ProfilePinEdgeService(this._client);

  final SupabaseClient _client;

  static const String functionName = 'profile-pin';

  Future<bool> verifyPin({
    required String profileId,
    required String pin,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'action': 'verify',
        'profileId': profileId,
        'pin': pin,
      },
    );
    final data = _asMap(response.data);
    return data['valid'] == true;
  }

  Future<void> setPin({
    required String profileId,
    required String pin,
  }) async {
    await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'action': 'set',
        'profileId': profileId,
        'pin': pin,
      },
    );
  }

  Future<bool> clearPin({
    required String profileId,
    required String pin,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'action': 'clear',
        'profileId': profileId,
        'pin': pin,
      },
    );
    final data = _asMap(response.data);
    return data['cleared'] == true;
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

