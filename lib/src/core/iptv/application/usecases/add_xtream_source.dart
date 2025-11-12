import '../../domain/entities/xtream_account.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../../domain/value_objects/xtream_endpoint.dart';

class AddXtreamSource {
  const AddXtreamSource(this._repository);

  final IptvRepository _repository;

  Future<XtreamAccount> call({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    final endpoint = XtreamEndpoint.parse(serverUrl);
    return _repository.addSource(
      endpoint: endpoint,
      username: username.trim(),
      password: password.trim(),
      alias: endpoint.host,
    );
  }
}
