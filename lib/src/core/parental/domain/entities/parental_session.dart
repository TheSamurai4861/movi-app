import 'package:equatable/equatable.dart';

class ParentalSession extends Equatable {
  const ParentalSession({
    required this.profileId,
    required this.expiresAt,
  });

  final String profileId;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'profile_id': profileId,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory ParentalSession.fromJson(Map<String, dynamic> json) {
    final profileId = (json['profile_id'] ?? json['profileId'])?.toString().trim() ?? '';
    final expiresRaw = (json['expires_at'] ?? json['expiresAt'])?.toString();
    final expiresAt = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);
    if (profileId.isEmpty || expiresAt == null) {
      throw const FormatException('Invalid ParentalSession payload');
    }
    return ParentalSession(profileId: profileId, expiresAt: expiresAt);
  }

  @override
  List<Object?> get props => <Object?>[profileId, expiresAt];
}

