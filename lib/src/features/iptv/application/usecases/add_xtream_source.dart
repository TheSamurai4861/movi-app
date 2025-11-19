import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
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
  }) async {
    try {
      final endpoint = XtreamEndpoint.tryParse(serverUrl);
      if (endpoint == null) {
        return Err(
          const InvalidEndpointFailure('URL du serveur Xtream invalide.'),
        );
      }

      final account = await _repository.addSource(
        endpoint: endpoint,
        username: username.trim(),
        password: password.trim(),
        alias: endpoint.host,
      );
      return Ok(account);
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error, stack) {
      return Err(
        Failure.fromException(
          error,
          stackTrace: stack,
          code: 'iptv_add_source',
          context: {'serverUrl': serverUrl},
        ),
      );
    }
  }
}
