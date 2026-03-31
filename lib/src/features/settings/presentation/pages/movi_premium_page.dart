import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_pill.dart';
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
import 'package:movi/src/features/settings/presentation/providers/movi_premium_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class MoviPremiumPage extends ConsumerWidget {
  const MoviPremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localizer = MoviPremiumLocalizer.fromBuildContext(context);
    final pageState = ref.watch(moviPremiumPageStateProvider);
    final actionState = ref.watch(moviPremiumPageControllerProvider);
    final controller = ref.read(moviPremiumPageControllerProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;
    final useDesktopLayout = width >= 900;
    final accent = ref.watch(asp.currentAccentColorProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SettingsContentWidth(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _SourcesStyleHeaderBar(
                  title: localizer.pageTitle,
                  accent: accent,
                  onBack: () => context.pop(),
                ),
                const SizedBox(height: 12),
                _PremiumIntro(
                  accent: accent,
                  localizer: localizer,
                ),
                const SizedBox(height: 12),
                _BenefitsExpanded(localizer: localizer, accent: accent),
                const SizedBox(height: 16),
                if (pageState.hasActiveSubscription)
                  _CurrentPlanCompact(
                    title: localizer.currentPlanTitle,
                    value: localizer.activePlanLabel(pageState.activePlanId),
                    badgeLabel: localizer.currentPlanActiveLabel,
                  )
                else
                  _OffersCompact(
                    localizer: localizer,
                    accent: accent,
                    isInitialLoading: pageState.isInitialLoading,
                    isBillingUnavailable: pageState.isBillingUnavailable,
                    offers: pageState.offers,
                    enabled:
                        pageState.canPurchase &&
                        !pageState.isRestoreOnly &&
                        !actionState.isBusy,
                    billingLine: pageState.isBillingUnavailable
                        ? localizer.billingUnavailableHint
                        : _resolveOfferDisabledMessage(
                            localizer: localizer,
                            pageState: pageState,
                          ),
                    useDesktopLayout: useDesktopLayout,
                    onPurchase: (offerId) => controller.purchase(offerId),
                  ),
                if (pageState.canRestore) ...[
                  const SizedBox(height: 12),
                  _RestoreCard(
                    restoreLabel: localizer.restoreButtonLabel,
                    enabled: pageState.canRestore && !actionState.isBusy,
                    onRestore: controller.restore,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveOfferDisabledMessage({
    required MoviPremiumLocalizer localizer,
    required MoviPremiumPageState pageState,
  }) {
    if (!pageState.isAuthenticated) {
      return localizer.accountRequiredHint;
    }
    if (pageState.hasActiveSubscription) {
      return localizer.activeSubscriptionHint;
    }
    if (pageState.isBillingUnavailable) {
      return localizer.billingUnavailableHint;
    }
    if (pageState.isRestoreOnly) {
      return localizer.restoreOnlyHint;
    }
    return null;
  }
}

class _DesktopOffersPreview extends StatelessWidget {
  const _DesktopOffersPreview({
    required this.localizer,
    required this.accent,
    required this.twoColumns,
  });

  final MoviPremiumLocalizer localizer;
  final Color accent;
  final bool twoColumns;

  Widget _previewCard(
    BuildContext context, {
    required String title,
    required String badge,
    required String priceLabel,
    required String billingLabel,
    required bool highlighted,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final borderColor = highlighted
        ? cs.primary.withValues(alpha: 0.55)
        : cs.outline.withValues(alpha: 0.26);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionIcon(
                  icon: Icons.workspace_premium_rounded,
                  accent: accent,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                MoviPill(
                  badge,
                  color: highlighted
                      ? cs.primary.withValues(alpha: 0.65)
                      : cs.onSurface.withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Disponible sur mobile',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              priceLabel,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              billingLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: null,
                child: const Text('Choisir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final annual = _previewCard(
      context,
      title: 'Annuel',
      badge: 'Le plus avantageux',
      priceLabel: '—',
      billingLabel: localizer.billingUnavailableHint,
      highlighted: true,
    );
    final monthly = _previewCard(
      context,
      title: 'Mensuel',
      badge: 'Sans engagement',
      priceLabel: '—',
      billingLabel: localizer.billingUnavailableHint,
      highlighted: false,
    );

    if (twoColumns) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: annual),
          const SizedBox(width: 12),
          Expanded(child: monthly),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        annual,
        const SizedBox(height: 12),
        monthly,
      ],
    );
  }
}

class _PremiumIntro extends StatelessWidget {
  const _PremiumIntro({required this.accent, required this.localizer});

  final Color accent;
  final MoviPremiumLocalizer localizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MoviPill(
              localizer.trialBadgeLabel,
              color: accent.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 10),
            Text(localizer.entryTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              localizer.pageSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitsExpanded extends StatelessWidget {
  const _BenefitsExpanded({required this.localizer, required this.accent});

  final MoviPremiumLocalizer localizer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget section(String title, List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionIcon(
                  icon: Icons.stars_rounded,
                  accent: accent,
                ),
                const SizedBox(width: 10),
                Text('Avantages', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            section(localizer.cloudFeaturesTitle, localizer.cloudFeatures),
            const SizedBox(height: 12),
            section(localizer.localFeaturesTitle, localizer.localFeatures),
            const SizedBox(height: 12),
            section(
              localizer.discoveryFeaturesTitle,
              localizer.discoveryFeatures,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCompact extends StatelessWidget {
  const _CurrentPlanCompact({
    required this.title,
    required this.value,
    required this.badgeLabel,
  });

  final String title;
  final String value;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                MoviPill(badgeLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffersCompact extends StatelessWidget {
  const _OffersCompact({
    required this.localizer,
    required this.accent,
    required this.isInitialLoading,
    required this.isBillingUnavailable,
    required this.offers,
    required this.enabled,
    required this.billingLine,
    required this.useDesktopLayout,
    required this.onPurchase,
  });

  final MoviPremiumLocalizer localizer;
  final Color accent;
  final bool isInitialLoading;
  final bool isBillingUnavailable;
  final List<SubscriptionOffer> offers;
  final bool enabled;
  final String? billingLine;
  final bool useDesktopLayout;
  final void Function(String offerId) onPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <Widget>[
      Text(localizer.offersTitle, style: theme.textTheme.titleLarge),
      const SizedBox(height: 12),
    ];

    if (isInitialLoading) {
      items.add(const Center(child: CircularProgressIndicator()));
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
    }

    if (offers.isEmpty) {
      items.add(
        _DesktopOffersPreview(
          localizer: localizer,
          accent: accent,
          twoColumns: useDesktopLayout,
        ),
      );
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
    }

    items.addAll(
      offers.map(
        (offer) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OfferCompactCard(
            offer: offer,
            localizer: localizer,
            accent: accent,
            enabled: enabled && !isBillingUnavailable,
            billingLine: billingLine,
            onPurchase: () => onPurchase(offer.id),
          ),
        ),
      ),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }
}

class _OfferCompactCard extends StatelessWidget {
  const _OfferCompactCard({
    required this.offer,
    required this.localizer,
    required this.accent,
    required this.enabled,
    required this.billingLine,
    required this.onPurchase,
  });

  final SubscriptionOffer offer;
  final MoviPremiumLocalizer localizer;
  final Color accent;
  final bool enabled;
  final String? billingLine;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isAnnual = offer.id.toLowerCase().contains('annual');
    final badge = isAnnual ? 'Le plus avantageux' : 'Sans engagement';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SectionIcon(
                  icon: Icons.workspace_premium_rounded,
                  accent: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(offer.title, style: theme.textTheme.titleMedium),
                ),
                MoviPill(
                  badge,
                  color: isAnnual ? cs.primary.withValues(alpha: 0.65) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Disponible sur mobile',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              offer.displayPrice,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (offer.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                offer.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ] else if (billingLine != null && billingLine!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                billingLine!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: enabled ? onPurchase : null,
                child: Text(localizer.purchaseButtonLabel(offer.displayPrice)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: accent, size: 18),
    );
  }
}

class _SourcesStyleHeaderBar extends StatelessWidget {
  const _SourcesStyleHeaderBar({
    required this.title,
    required this.accent,
    required this.onBack,
  });

  final String title;
  final Color accent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // Mimic Settings → “Sources” header bar style (`IptvSourcesPage._HeaderBar`).
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 35,
              height: 35,
              child: MoviFocusableAction(
                onPressed: onBack,
                semanticLabel: 'Retour',
                builder: (context, state) {
                  return MoviFocusFrame(
                    scale: state.focused ? 1.04 : 1,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: state.focused
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    child: const SizedBox(
                      width: 35,
                      height: 35,
                      child: MoviAssetIcon(
                        AppAssets.iconBack,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: const SizedBox(width: 35, height: 35),
          ),
        ],
      ),
    );
  }
}

class _RestoreCard extends StatelessWidget {
  const _RestoreCard({
    required this.restoreLabel,
    required this.enabled,
    required this.onRestore,
  });

  final String restoreLabel;
  final bool enabled;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: enabled ? onRestore : null,
            icon: const Icon(Icons.restore),
            label: Text(restoreLabel),
          ),
        ),
      ),
    );
  }
}
