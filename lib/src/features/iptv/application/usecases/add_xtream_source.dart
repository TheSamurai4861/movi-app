import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';

class AddXtreamSource {
  const AddXtreamSource(this._repository);

  final IptvRepository _repository;

  Future<Result<XtreamAccount, Failure>> call({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    final endpoint = XtreamEndpoint.parse(serverUrl);
    return _repository
        .addSource(
          endpoint: endpoint,
          username: username.trim(),
          password: password.trim(),
          alias: endpoint.host,
        )
        .then<Result<XtreamAccount, Failure>>((value) => Ok(value))
        .catchError((error) => Err<XtreamAccount, Failure>(error as Failure));
  }
}
