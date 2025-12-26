class XtreamAuthDto {
  XtreamAuthDto({
    required this.status,
    required this.message,
    required this.expiration,
  });

  factory XtreamAuthDto.fromJson(Map<String, dynamic> json) {
    final userInfoDynamic = json['user_info'];
    final userInfo = userInfoDynamic is Map<String, dynamic>
        ? userInfoDynamic
        : const <String, dynamic>{};

    final statusRaw =
        userInfo['status'] ?? json['status'] ?? json['result'] ?? 'Unknown';
    var messageRaw =
        userInfo['message'] ?? json['message'] ?? json['error'] ?? '';

    var message = messageRaw?.toString() ?? '';
    if (message.trim().isEmpty && userInfo.isEmpty) {
      message = 'Invalid Xtream response: missing user_info';
    }

    return XtreamAuthDto(
      status: statusRaw?.toString() ?? 'Unknown',
      message: message,
      expiration: _parseDate(userInfo['exp_date'] ?? json['exp_date']),
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
