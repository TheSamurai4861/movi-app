import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class PinRecoveryRemoteDataSource {
  const PinRecoveryRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String functionName = 'pin-recovery';

  Future<PinRecoveryResponseDto> requestCode({String? profileId}) async {
    final response = await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'action': 'request',
        if (profileId != null && profileId.trim().isNotEmpty)
          'profileId': profileId,
      },
    );
    final data = _asMap(response.data);
    return PinRecoveryResponseDto.fromMap(data);
  }

  Future<PinRecoveryResponseDto> verifyCode(String code) async {
    final response = await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'action': 'verify',
        'code': code,
      },
    );
    final data = _asMap(response.data);
    return PinRecoveryResponseDto.fromMap(data);
  }

  Future<PinRecoveryResponseDto> resetPin({
    required String resetToken,
    required String newPin,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'action': 'reset',
        'resetToken': resetToken,
        'pin': newPin,
      },
    );
    final data = _asMap(response.data);
    return PinRecoveryResponseDto.fromMap(data);
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

class PinRecoveryResponseDto {
  const PinRecoveryResponseDto({
    required this.status,
    this.resetToken,
    this.message,
  });

  final String status;
  final String? resetToken;
  final String? message;

  factory PinRecoveryResponseDto.fromMap(Map<String, dynamic> map) {
    final status = _resolveStatus(map);
    final resetToken = map['resetToken'] ??
        map['reset_token'] ??
        map['token'];
    return PinRecoveryResponseDto(
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
