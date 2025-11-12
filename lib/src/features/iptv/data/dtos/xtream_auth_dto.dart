class XtreamAuthDto {
  XtreamAuthDto({
    required this.status,
    required this.message,
    required this.expiration,
  });

  factory XtreamAuthDto.fromJson(Map<String, dynamic> json) {
    final userInfo = json['user_info'] as Map<String, dynamic>? ?? const {};
    return XtreamAuthDto(
      status: userInfo['status']?.toString() ?? 'Unknown',
      message: userInfo['message']?.toString() ?? '',
      expiration: _parseDate(userInfo['exp_date']),
    );
  }

  final String status;
  final String message;
  final DateTime? expiration;

  bool get isAuthorized => status.toLowerCase() == 'active';

  static DateTime? _parseDate(dynamic timestamp) {
    if (timestamp == null) return null;
    final value = int.tryParse('$timestamp');
    if (value == null || value == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      value * 1000,
      isUtc: true,
    ).toLocal();
  }
}
