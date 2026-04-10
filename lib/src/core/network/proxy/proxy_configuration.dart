class DioProxyConfiguration {
  const DioProxyConfiguration({
    this.httpProxy,
    this.httpsProxy,
    this.noProxy = const <String>[],
  });

  final Uri? httpProxy;
  final Uri? httpsProxy;
  final List<String> noProxy;

  bool get isConfigured => httpProxy != null || httpsProxy != null;
}
