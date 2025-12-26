import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/domain/repositories/stalker_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';

class AddStalkerSource {
  const AddStalkerSource(this._repository);

  final StalkerRepository _repository;

  Future<Result<StalkerAccount, Failure>> call({
    required String serverUrl,
    required String macAddress,
    String? username,
    String? password,
  }) async {
    final rawUrl = serverUrl.trim();
    final rawMac = macAddress.trim();

    try {
      // Valide l'URL
      final endpoint = StalkerEndpoint.tryParse(rawUrl);
      if (endpoint == null) {
        return Err(
          const InvalidEndpointFailure('URL du serveur Stalker invalide.'),
        );
      }

      // Valide la MAC address (format XX:XX:XX:XX:XX:XX)
      if (!_isValidMacAddress(rawMac)) {
        return Err(
          const AuthFailure('Format de MAC address invalide. Format attendu: XX:XX:XX:XX:XX:XX'),
        );
      }

      final account = await _repository.addSource(
        endpoint: endpoint,
        macAddress: rawMac,
        username: username?.trim().isEmpty == true ? null : username?.trim(),
        password: password?.isEmpty == true ? null : password,
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
          code: 'stalker_add_source',
          context: {'serverUrl': rawUrl, 'macAddress': rawMac},
        ),
      );
    }
  }

  /// Valide le format d'une MAC address (XX:XX:XX:XX:XX:XX)
  bool _isValidMacAddress(String mac) {
    if (mac.isEmpty) return false;
    final parts = mac.split(':');
    if (parts.length != 6) return false;
    for (final part in parts) {
      if (part.length != 2) return false;
      if (int.tryParse(part, radix: 16) == null) return false;
    }
    return true;
  }
}

