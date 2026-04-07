import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePinEdgeService {
  const ProfilePinEdgeService(this._client);

  final SupabaseClient _client;

  static const String functionName = 'profile-pin';

  Future<PinRecoveryEdgeResponseDto> requestRecoveryCode({
    String? profileId,
  }) async {
    final data = await _invoke(<String, dynamic>{
      'action': 'request',
      if (profileId != null && profileId.trim().isNotEmpty)
        'profileId': profileId,
    });
    return PinRecoveryEdgeResponseDto.fromMap(data);
  }

  Future<PinRecoveryEdgeResponseDto> verifyRecoveryCode(String code) async {
    final data = await _invoke(<String, dynamic>{
      'action': 'verify',
      'code': code,
    });
    return PinRecoveryEdgeResponseDto.fromMap(data);
  }

  Future<PinRecoveryEdgeResponseDto> resetRecoveredPin({
    required String resetToken,
    required String newPin,
  }) async {
    final data = await _invoke(<String, dynamic>{
      'action': 'reset',
      'resetToken': resetToken,
      'pin': newPin,
    });
    return PinRecoveryEdgeResponseDto.fromMap(data);
  }

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

  Future<void> setPin({required String profileId, required String pin}) async {
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

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(functionName, body: body);
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw FormatException(
      'Unexpected edge function response: ${value.runtimeType}',
    );
  }
}

class PinRecoveryEdgeResponseDto {
  const PinRecoveryEdgeResponseDto({
    required this.status,
    this.resetToken,
    this.message,
  });

  final String status;
  final String? resetToken;
  final String? message;

  factory PinRecoveryEdgeResponseDto.fromMap(Map<String, dynamic> map) {
    final status = _resolveStatus(map);
    final resetToken = map['resetToken'] ?? map['reset_token'] ?? map['token'];
    return PinRecoveryEdgeResponseDto(
      status: status,
      resetToken: resetToken?.toString(),
      message: map['message']?.toString(),
    );
  }

  static String _resolveStatus(Map<String, dynamic> map) {
    final status = map['status'];
    if (status is String && status.trim().isNotEmpty) {
      return status;
    }
    final error = map['error'] ?? map['reason'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }
    final valid = map['valid'];
    if (valid == true) return 'ok';
    if (valid == false) return 'invalid';
    return 'unknown';
  }
}
