// lib/src/features/search/presentation/models/provider_results_args.dart

class ProviderResultsArgs {
  const ProviderResultsArgs({
    required this.providerId,
    required this.providerName,
  });

  final int providerId;
  final String providerName;
}
