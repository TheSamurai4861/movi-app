import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';

abstract class SourceProbeService {
  Future<SourceProbeResult> probeXtream({
    required String serverUrl,
    required String username,
    required String password,
    String preferredRouteProfileId,
    List<String> fallbackRouteProfileIds,
    String? accountId,
    bool includePublicIp,
  });
}
