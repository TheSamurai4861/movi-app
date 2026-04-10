import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';

abstract class SourceConnectionPolicyRepository {
  Future<SourceConnectionPolicy?> getPolicy({
    required String accountId,
    required SourceKind sourceKind,
  });

  Future<SourceConnectionPolicy> savePolicy(SourceConnectionPolicy policy);

  Future<void> deletePolicy({
    required String accountId,
    required SourceKind sourceKind,
  });
}
