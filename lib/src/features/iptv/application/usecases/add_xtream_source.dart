import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

class AddXtreamSource {
  const AddXtreamSource(this._repository);

  final IptvRepository _repository;

  Future<Result<XtreamAccount, Failure>> call({
    required String serverUrl,
    required String username,
    required String password,
    String? alias,
  }) async {
    final rawUrl = serverUrl.trim();
    final rawUser = username.trim();
    final rawPass = password.trim();
    final rawAlias = (alias ?? '').trim();

    try {
      final endpoint = XtreamEndpoint.tryParse(rawUrl);
      if (endpoint == null) {
        return Err(
          const InvalidEndpointFailure('URL du serveur Xtream invalide.'),
        );
      }

      if (rawUser.isEmpty || rawPass.isEmpty) {
        return Err(
          const AuthFailure('Identifiants Xtream invalides.'),
        );
      }

      final resolvedAlias = rawAlias.isNotEmpty ? rawAlias : endpoint.host;

      final account = await _repository.addSource(
        endpoint: endpoint,
        username: rawUser,
        password: rawPass,
        alias: resolvedAlias,
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
          context: {'serverUrl': rawUrl},
        ),
      );
    }
  }
}
