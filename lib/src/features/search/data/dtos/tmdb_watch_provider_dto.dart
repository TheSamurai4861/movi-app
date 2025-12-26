// lib/src/features/search/data/dtos/tmdb_watch_provider_dto.dart

class TmdbWatchProviderDto {
  TmdbWatchProviderDto({
    required this.providerId,
    required this.providerName,
    this.logoPath,
    this.displayPriority,
  });

  final int providerId;
  final String providerName;
  final String? logoPath;
  final int? displayPriority;

  factory TmdbWatchProviderDto.fromJson(Map<String, dynamic> json) {
    return TmdbWatchProviderDto(
      providerId: _asInt(json['provider_id']) ?? 0,
      providerName: _stringOr(json['provider_name'], '') ?? '',
      logoPath: _stringOr(json['logo_path']),
      displayPriority: _asInt(json['display_priority']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'provider_name': providerName,
      'logo_path': logoPath,
      'display_priority': displayPriority,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _stringOr(dynamic value, [String? fallback]) {
    if (value == null) return fallback;
    if (value is String) return value.isEmpty ? fallback : value;
    return value.toString();
  }
}
