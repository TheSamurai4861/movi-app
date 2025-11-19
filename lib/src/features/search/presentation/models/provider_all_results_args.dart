// lib/src/features/search/presentation/models/provider_all_results_args.dart
import 'package:movi/src/core/models/models.dart';

class ProviderAllResultsArgs {
  const ProviderAllResultsArgs({
    required this.providerId,
    required this.providerName,
    required this.type,
  });

  final int providerId;
  final String providerName;
  final MoviMediaType type; // movie ou series
}

