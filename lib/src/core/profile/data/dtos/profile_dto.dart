import 'package:movi/src/core/profile/domain/entities/profile.dart';

/// DTO Supabase (parsing DB/JSON).
/// TolÃƒÆ’Ã‚Â©rant ÃƒÆ’Ã‚Â  la lecture (legacy payloads), strict en ÃƒÆ’Ã‚Â©criture cÃƒÆ’Ã‚Â´tÃƒÆ’Ã‚Â© repo.
class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.accountId,
    required this.name,
    required this.color,
    this.avatarUrl,
    this.createdAt,
    this.isKid = false,
    this.pegiLimit,
    this.hasPin = false,
  });

  final String id;
  final String accountId;
  final String name;
  final int color;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool isKid;
  final int? pegiLimit;
  final bool hasPin;

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId == null) {
      throw const FormatException('Missing profiles.id');
    }

    // IMPORTANT:
    // - Source of truth: profiles.account_id = auth.uid()
    // - TolÃƒÆ’Ã‚Â©rance lecture legacy; ÃƒÆ’Ã‚Â©criture/filtre restent stricts sur account_id.
    final rawAccountId = json['account_id'] ??
        json['accountId'] ??
        json['user_id'] ??
        json['userId'];

    if (rawAccountId == null) {
      throw const FormatException('Missing profiles.account_id');
    }

    return ProfileDto(
      id: rawId.toString(),
      accountId: rawAccountId.toString(),
      name: (json['name'] as String?)?.trim() ?? '',
      // TolÃƒÆ’Ã‚Â©rant: si colonne absente en DB -> dÃƒÆ’Ã‚Â©faut
      color: _parseInt(json['color']) ?? 0xFF2160AB,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      isKid: _parseBool(json['is_kid'] ?? json['isKid']) ?? false,
      pegiLimit: _parseInt(json['pegi_limit'] ?? json['pegiLimit']),
      hasPin: _parseBool(json['has_pin'] ?? json['hasPin']) ?? false,
    );
  }

  /// JSON pour UPDATE (et ÃƒÆ’Ã‚Â©ventuellement pour SELECT client-side).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'account_id': accountId,
        'name': name,
        'color': color,
        'avatar_url': avatarUrl,
        'is_kid': isKid,
        'pegi_limit': pegiLimit,
        'has_pin': hasPin,
      };

  Profile toEntity() => Profile(
        id: id,
        accountId: accountId,
        name: name,
        color: color,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
        isKid: isKid,
        pegiLimit: pegiLimit,
        hasPin: hasPin,
      );

  static ProfileDto fromEntity(Profile e) => ProfileDto(
        id: e.id,
        accountId: e.accountId,
        name: e.name,
        color: e.color,
        avatarUrl: e.avatarUrl,
        createdAt: e.createdAt,
        isKid: e.isKid,
        pegiLimit: e.pegiLimit,
        hasPin: e.hasPin,
      );
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool? _parseBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
  }
  return null;
}
