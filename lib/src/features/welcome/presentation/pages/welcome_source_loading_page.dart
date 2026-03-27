import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

/// Startup page that waits for IPTV playlists to be fully loaded
/// before redirecting to home.
class WelcomeSourceLoadingPage extends ConsumerStatefulWidget {
  const WelcomeSourceLoadingPage({super.key});

  @override
  ConsumerState<WelcomeSourceLoadingPage> createState() =>
      _WelcomeSourceLoadingPageState();
}

class _WelcomeSourceLoadingPageState
    extends ConsumerState<WelcomeSourceLoadingPage> {
  String? _error;
  bool _isLoading = true;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadCatalog());
  }

  Future<void> _loadCatalog() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _statusMessage = 'Chargement de votre catalogue...';
    });

    try {
      final appStateController = ref.read(asp.appStateControllerProvider);
      final activeSources = appStateController.activeIptvSourceIds;

      if (activeSources.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'Aucune source active trouvée';
          _isLoading = false;
        });
        return;
      }

      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();

      final xtreamAccounts = await iptvLocal.getAccounts();
      final stalkerAccounts = await iptvLocal.getStalkerAccounts();

      final xtreamIds = xtreamAccounts.map((a) => a.id).toSet();
      final stalkerIds = stalkerAccounts.map((a) => a.id).toSet();

      final hasAnyItems = await iptvLocal.hasAnyPlaylistItems(
        accountIds: activeSources,
      );

      if (!hasAnyItems) {
        setState(() {
          _statusMessage = 'Téléchargement des playlists...';
        });

        final refreshXtream = locator<RefreshXtreamCatalog>();
        final refreshStalker = locator<RefreshStalkerCatalog>();

        for (final accountId in activeSources) {
          if (xtreamIds.contains(accountId)) {
            setState(() {
              _statusMessage = 'Chargement des films et séries...';
            });

            final result = await refreshXtream(accountId);
            result.fold(
              ok: (_) {
                unawaited(
                  LoggingService.log(
                    'WelcomeSourceLoading: Xtream catalog refreshed for $accountId',
                  ),
                );
              },
              err: (failure) {
                throw Exception(
                  'Erreur lors du chargement du catalogue: ${failure.message}',
                );
              },
            );
          } else if (stalkerIds.contains(accountId)) {
            setState(() {
              _statusMessage = 'Chargement des films et séries...';
            });

            final result = await refreshStalker(accountId);
            result.fold(
              ok: (_) {
                unawaited(
                  LoggingService.log(
                    'WelcomeSourceLoading: Stalker catalog refreshed for $accountId',
                  ),
                );
              },
              err: (failure) {
                throw Exception(
                  'Erreur lors du chargement du catalogue: ${failure.message}',
                );
              },
            );
          } else {
            throw Exception('Type de source inconnu pour $accountId');
          }
        }

        final hasItemsAfterRefresh = await iptvLocal.hasAnyPlaylistItems(
          accountIds: activeSources,
        );

        if (!hasItemsAfterRefresh) {
          throw Exception(
            'Le chargement semble avoir échoué. Aucune playlist trouvée.',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Préparation de l\'accueil...';
      });

      final homeController = ref.read(homeControllerProvider.notifier);
      await homeController.load(
        awaitIptv: true,
        reason: 'initial_load',
        force: true,
      );

      if (!mounted) return;
      context.go(AppRouteNames.home);
    } catch (e, stackTrace) {
      unawaited(
        LoggingService.log(
          'WelcomeSourceLoading: Error loading catalog: $e\n$stackTrace',
        ),
      );

      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Center(child: WelcomeSourceLoadingLogo()),
          WelcomeSourceLoadingContent(
            isLoading: _isLoading,
            statusMessage: _statusMessage,
            error: _error,
            onRetry: () {
              setState(() {
                _error = null;
              });
              unawaited(_loadCatalog());
            },
            onContinueAnyway: () => context.go(AppRouteNames.home),
            showHeader: false,
            mainAxisAlignment: MainAxisAlignment.end,
            bottomPadding: AppSpacing.lg,
          ),
        ],
      ),
    );
  }
}

class WelcomeSourceLoadingLogo extends ConsumerWidget {
  const WelcomeSourceLoadingLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    return SvgPicture.asset(
      AppAssets.iconAppLogoSvg,
      width: 100,
      height: 100,
      colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
    );
  }
}

class WelcomeSourceLoadingContent extends ConsumerWidget {
  const WelcomeSourceLoadingContent({
    super.key,
    required this.isLoading,
    required this.statusMessage,
    required this.error,
    this.onRetry,
    this.onContinueAnyway,
    this.showHeader = true,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.bottomPadding = AppSpacing.xl,
  });

  final bool isLoading;
  final String statusMessage;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onContinueAnyway;
  final bool showHeader;
  final MainAxisAlignment mainAxisAlignment;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              bottomPadding,
            ),
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              children: [
                if (showHeader) ...[
                  const WelcomeHeader(
                    title: 'Chargement',
                    subtitle: 'Préparation de votre bibliothèque',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  if (statusMessage.isNotEmpty)
                    Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                ] else if (error != null) ...[
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    error!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: onContinueAnyway,
                    child: const Text('Continuer quand même'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
