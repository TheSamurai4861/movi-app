import 'package:dio/dio.dart';

typedef LocaleCodeProvider = String? Function();

class LocaleInterceptor extends Interceptor {
  LocaleInterceptor({LocaleCodeProvider? localeProvider})
    : _localeProvider = localeProvider;

  final LocaleCodeProvider? _localeProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final locale = _localeProvider?.call();
    if (locale != null && locale.isNotEmpty) {
      options.headers['Accept-Language'] = locale;
    }
    handler.next(options);
  }
}
