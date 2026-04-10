import 'package:dio/dio.dart';

class PublicIpEchoService {
  const PublicIpEchoService();

  static final Uri _ipifyUri = Uri.parse('https://api.ipify.org?format=json');

  Future<String?> resolvePublicIp(Dio dio) async {
    try {
      final response = await dio.getUri<dynamic>(
        _ipifyUri,
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final ip = data['ip']?.toString().trim();
        if (ip != null && ip.isNotEmpty) {
          return ip;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
