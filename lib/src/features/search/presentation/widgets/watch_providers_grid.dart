// lib/src/features/search/presentation/widgets/watch_providers_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/search/presentation/models/provider_results_args.dart';

/// Widget affichant une grille verticale de providers (2 colonnes).
class WatchProvidersGrid extends ConsumerWidget {
  const WatchProvidersGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(watchProvidersProvider);

    return providersAsync.when(
      data: (providers) {
        if (providers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                AppLocalizations.of(context)!.searchByProvidersTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.0, // Rectangle plus large que haut
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: providers.length,
                itemBuilder: (context, index) {
                  return _WatchProviderCard(provider: providers[index]);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Carte représentant un provider.
class _WatchProviderCard extends ConsumerWidget {
  const _WatchProviderCard({required this.provider});

  final WatchProvider provider;

  Color _getProviderColor(int providerId) {
    // Palette de couleurs par défaut pour les providers connus
    final colorMap = <int, Color>{
      8: const Color(0xFFE50914), // Netflix (rouge)
      337: const Color(0xFF113CCF), // Disney+ (bleu)
      119: const Color(0xFF87CEEB), // Amazon Prime Video (bleu clair)
      350: const Color(0xFF4A4A4A), // Apple TV+ (gris moins foncé)
      1899: const Color(0xFF4A4A4A), // HBO Max (gris moins foncé)
      283: const Color(0xFFF47521), // Crunchyroll (orange)
    };

    return colorMap[providerId] ?? const Color(0xFF2C2C2E);
  }

  /// Génère une couleur plus foncée à partir d'une couleur de base
  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    // Réduire la luminosité à environ 60-70% de la valeur originale
    return hsl.withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = _getProviderColor(provider.providerId);
    final popularMediaAsync = ref.watch(
      providerPopularMediaProvider(provider.providerId),
    );

    return InkWell(
      onTap: () {
        context.push(
          AppRouteNames.providerResults,
          extra: ProviderResultsArgs(
            providerId: provider.providerId,
            providerName: provider.providerName,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              backgroundColor, // Couleur de base en bas gauche
              _darkenColor(
                backgroundColor,
              ), // Couleur plus foncée en haut droite
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop horizontale du média en arrière-plan
              popularMediaAsync.when(
                data: (popularMedia) {
                  if (popularMedia?.backdropUrl == null) {
                    return const SizedBox.shrink();
                  }
                  return Positioned.fill(
                    child: Image.network(
                      popularMedia!.backdropUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // Overlay avec la couleur du provider à 50% d'opacité
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Texte du provider en bas à gauche
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    provider.providerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
