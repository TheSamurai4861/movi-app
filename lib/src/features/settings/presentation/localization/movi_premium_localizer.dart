import 'package:flutter/widgets.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/settings/presentation/services/movi_premium_feedback_resolver.dart';

class MoviPremiumLocalizer {
  MoviPremiumLocalizer._(this._strings);

  final _MoviPremiumStrings _strings;

  factory MoviPremiumLocalizer.fromBuildContext(BuildContext context) {
    final localeName = AppLocalizations.of(context)?.localeName ?? 'en';
    final languageCode = localeName.split('_').first.toLowerCase();

    switch (languageCode) {
      case 'fr':
        return MoviPremiumLocalizer._(_fr);
      default:
        return MoviPremiumLocalizer._(_en);
    }
  }

  String get entryTitle => _strings.entryTitle;
  String get entrySubtitle => _strings.entrySubtitle;
  String get entrySubtitleActive => _strings.entrySubtitleActive;
  String get pageTitle => _strings.pageTitle;
  String get pageSubtitle => _strings.pageSubtitle;
  String get currentPlanTitle => _strings.currentPlanTitle;
  String get currentPlanActiveLabel => _strings.currentPlanActiveLabel;
  String get currentPlanInactiveLabel => _strings.currentPlanInactiveLabel;
  String get annualHighlightedLabel => _strings.annualHighlightedLabel;
  String get trialBadgeLabel => _strings.trialBadgeLabel;
  String get restoreButtonLabel => _strings.restoreButtonLabel;
  String get signInButtonLabel => _strings.signInButtonLabel;
  String get retryButtonLabel => _strings.retryButtonLabel;
  String get accountRequiredHint => _strings.accountRequiredHint;
  String get activeSubscriptionHint => _strings.activeSubscriptionHint;
  String get billingUnavailableHint => _strings.billingUnavailableHint;
  String get restoreOnlyHint => _strings.restoreOnlyHint;
  String get cloudFeaturesTitle => _strings.cloudFeaturesTitle;
  String get localFeaturesTitle => _strings.localFeaturesTitle;
  String get discoveryFeaturesTitle => _strings.discoveryFeaturesTitle;
  String get offersTitle => _strings.offersTitle;
  String get contextualUpsellTitle => _strings.contextualUpsellTitle;
  String get contextualUpsellBody => _strings.contextualUpsellBody;
  String get contextualUpsellAction => _strings.contextualUpsellAction;
  String get contextualUpsellDismiss => _strings.contextualUpsellDismiss;
  String get libraryBannerTitle => _strings.libraryBannerTitle;
  String get libraryBannerBody => _strings.libraryBannerBody;
  String get libraryBannerAction => _strings.libraryBannerAction;

  List<String> get cloudFeatures => _strings.cloudFeatures;
  List<String> get localFeatures => _strings.localFeatures;
  List<String> get discoveryFeatures => _strings.discoveryFeatures;

  String activePlanLabel(String? planId) {
    final normalized = (planId ?? '').trim();
    if (normalized.isEmpty) {
      return currentPlanActiveLabel;
    }
    return '${_strings.currentPlanActiveLabel} · $normalized';
  }

  String offerBadge({required String offerId}) {
    final normalized = offerId.toLowerCase();
    if (normalized.contains('annual')) {
      return annualHighlightedLabel;
    }
    return trialBadgeLabel;
  }

  String offerCaption({required String offerId}) {
    final normalized = offerId.toLowerCase();
    if (normalized.contains('annual')) {
      return _strings.annualOfferCaption;
    }
    return _strings.monthlyOfferCaption;
  }

  String purchaseButtonLabel(String priceLabel) {
    return _strings.purchaseButtonLabel(priceLabel);
  }

  String feedback(MoviPremiumFeedbackKind kind) {
    switch (kind) {
      case MoviPremiumFeedbackKind.purchaseSucceeded:
        return _strings.purchaseSucceeded;
      case MoviPremiumFeedbackKind.restoreSucceeded:
        return _strings.restoreSucceeded;
      case MoviPremiumFeedbackKind.noPurchaseFound:
        return _strings.noPurchaseFound;
      case MoviPremiumFeedbackKind.billingUnavailable:
        return _strings.billingUnavailable;
      case MoviPremiumFeedbackKind.networkUnavailable:
        return _strings.networkUnavailable;
      case MoviPremiumFeedbackKind.accountRequired:
        return _strings.accountRequired;
      case MoviPremiumFeedbackKind.purchaseCancelled:
        return _strings.purchaseCancelled;
      case MoviPremiumFeedbackKind.technicalFailure:
        return _strings.technicalFailure;
    }
  }

  static const _en = _MoviPremiumStrings(
    entryTitle: 'Movi Premium',
    entrySubtitle: 'Cloud sync, premium profiles and richer discovery.',
    entrySubtitleActive: 'Premium is active on this account.',
    pageTitle: 'Movi Premium',
    pageSubtitle:
        'Unlock cloud sync, local premium organization and richer discovery pages.',
    currentPlanTitle: 'Current plan',
    currentPlanActiveLabel: 'Premium active',
    currentPlanInactiveLabel: 'No active premium plan',
    annualHighlightedLabel: 'Best value',
    trialBadgeLabel: '7-day free trial',
    restoreButtonLabel: 'Restore purchases',
    signInButtonLabel: 'Sign in',
    retryButtonLabel: 'Retry',
    accountRequiredHint:
        'You need to sign in before buying or restoring Movi Premium.',
    activeSubscriptionHint: 'Your premium access is already active.',
    billingUnavailableHint:
        'Billing is unavailable on this device. Local free features remain available.',
    restoreOnlyHint:
        'Purchases cannot be started here, but restoring an existing purchase is still available.',
    cloudFeaturesTitle: 'Cloud',
    localFeaturesTitle: 'Profiles & controls',
    discoveryFeaturesTitle: 'Discovery',
    offersTitle: 'Available offers',
    contextualUpsellTitle: 'This feature requires Movi Premium',
    contextualUpsellBody:
        'Unlock premium sync, local profiles, parental controls and richer discovery pages.',
    contextualUpsellAction: 'See Movi Premium',
    contextualUpsellDismiss: 'Not now',
    libraryBannerTitle: 'Take your library everywhere',
    libraryBannerBody:
        'Unlock cloud sync, restore your library on another device and access premium local organization.',
    libraryBannerAction: 'Discover Premium',
    annualOfferCaption: 'Best annual value · 7-day free trial · €39.99/year',
    monthlyOfferCaption:
        'Flexible monthly access · 7-day free trial · €4.99/month',
    purchaseSucceeded: 'Premium purchase completed successfully.',
    restoreSucceeded: 'Your premium purchase was restored successfully.',
    noPurchaseFound: 'No premium purchase was found for this account.',
    billingUnavailable:
        'Billing is unavailable here. Try another supported device.',
    networkUnavailable:
        'The network is unavailable. Check your connection and try again.',
    accountRequired: 'You need to sign in before using premium purchases.',
    purchaseCancelled: 'The purchase was cancelled.',
    technicalFailure:
        'Something went wrong while processing the premium action.',
    cloudFeatures: <String>[
      'Sync your library, playlists and favorites in the cloud.',
      'Restore your library on another device.',
      'Sync history and playback progression across devices.',
    ],
    localFeatures: <String>[
      'Unlock local continue watching.',
      'Unlock local profiles.',
      'Unlock local parental controls.',
    ],
    discoveryFeatures: <String>[
      'Unlock saga detail pages.',
      'Unlock actor detail pages.',
      'Keep a clearer premium organization flow in Movi.',
    ],
    purchaseButtonLabel: _purchaseLabelEn,
  );

  static const _fr = _MoviPremiumStrings(
    entryTitle: 'Movi Premium',
    entrySubtitle: 'Sync cloud, profils premium et découverte enrichie.',
    entrySubtitleActive: 'Premium est actif sur ce compte.',
    pageTitle: 'Movi Premium',
    pageSubtitle:
        'Débloque la synchronisation cloud, une meilleure organisation locale et des fiches enrichies.',
    currentPlanTitle: 'Offre actuelle',
    currentPlanActiveLabel: 'Premium actif',
    currentPlanInactiveLabel: 'Aucun abonnement premium actif',
    annualHighlightedLabel: 'Meilleur choix',
    trialBadgeLabel: '7 jours d’essai',
    restoreButtonLabel: 'Restaurer les achats',
    signInButtonLabel: 'Se connecter',
    retryButtonLabel: 'Réessayer',
    accountRequiredHint:
        'Un compte connecté est requis pour acheter ou restaurer Movi Premium.',
    activeSubscriptionHint: 'Ton accès premium est déjà actif.',
    billingUnavailableHint:
        'La facturation n’est pas disponible sur cet appareil. Les fonctions gratuites locales restent accessibles.',
    restoreOnlyHint:
        'L’achat ne peut pas démarrer ici, mais la restauration d’un achat existant reste disponible.',
    cloudFeaturesTitle: 'Cloud',
    localFeaturesTitle: 'Profils & contrôle',
    discoveryFeaturesTitle: 'Découverte',
    offersTitle: 'Offres disponibles',
    contextualUpsellTitle: 'Cette fonctionnalité nécessite Movi Premium',
    contextualUpsellBody:
        'Débloque la sync premium, les profils locaux, le contrôle parental et des fiches plus riches.',
    contextualUpsellAction: 'Voir Movi Premium',
    contextualUpsellDismiss: 'Plus tard',
    libraryBannerTitle: 'Emporte ta bibliothèque partout',
    libraryBannerBody:
        'Débloque la synchronisation cloud, restaure ta bibliothèque sur un autre appareil et accède à une organisation premium locale.',
    libraryBannerAction: 'Découvrir Premium',
    annualOfferCaption:
        'Meilleur rapport valeur · 7 jours d’essai · 39,99 €/an',
    monthlyOfferCaption:
        'Accès mensuel flexible · 7 jours d’essai · 4,99 €/mois',
    purchaseSucceeded: 'L’achat premium a été effectué avec succès.',
    restoreSucceeded: 'Ton achat premium a été restauré avec succès.',
    noPurchaseFound: 'Aucun achat premium n’a été trouvé pour ce compte.',
    billingUnavailable:
        'La facturation n’est pas disponible ici. Essaie sur un autre appareil compatible.',
    networkUnavailable:
        'Le réseau est indisponible. Vérifie ta connexion puis réessaie.',
    accountRequired:
        'Un compte connecté est requis avant d’utiliser les achats premium.',
    purchaseCancelled: 'L’achat a été annulé.',
    technicalFailure: 'Une erreur est survenue pendant l’action premium.',
    cloudFeatures: <String>[
      'Synchronise bibliothèque, playlists et favoris dans le cloud.',
      'Restaure ta bibliothèque sur un autre appareil.',
      'Synchronise l’historique et la progression entre appareils.',
    ],
    localFeatures: <String>[
      'Débloque le continuer à regarder local.',
      'Débloque les profils locaux.',
      'Débloque le contrôle parental local.',
    ],
    discoveryFeatures: <String>[
      'Débloque les fiches saga.',
      'Débloque les fiches acteur.',
      'Garde une organisation premium plus claire dans Movi.',
    ],
    purchaseButtonLabel: _purchaseLabelFr,
  );
}

class _MoviPremiumStrings {
  const _MoviPremiumStrings({
    required this.entryTitle,
    required this.entrySubtitle,
    required this.entrySubtitleActive,
    required this.pageTitle,
    required this.pageSubtitle,
    required this.currentPlanTitle,
    required this.currentPlanActiveLabel,
    required this.currentPlanInactiveLabel,
    required this.annualHighlightedLabel,
    required this.trialBadgeLabel,
    required this.restoreButtonLabel,
    required this.signInButtonLabel,
    required this.retryButtonLabel,
    required this.accountRequiredHint,
    required this.activeSubscriptionHint,
    required this.billingUnavailableHint,
    required this.restoreOnlyHint,
    required this.cloudFeaturesTitle,
    required this.localFeaturesTitle,
    required this.discoveryFeaturesTitle,
    required this.offersTitle,
    required this.contextualUpsellTitle,
    required this.contextualUpsellBody,
    required this.contextualUpsellAction,
    required this.contextualUpsellDismiss,
    required this.libraryBannerTitle,
    required this.libraryBannerBody,
    required this.libraryBannerAction,
    required this.annualOfferCaption,
    required this.monthlyOfferCaption,
    required this.purchaseSucceeded,
    required this.restoreSucceeded,
    required this.noPurchaseFound,
    required this.billingUnavailable,
    required this.networkUnavailable,
    required this.accountRequired,
    required this.purchaseCancelled,
    required this.technicalFailure,
    required this.cloudFeatures,
    required this.localFeatures,
    required this.discoveryFeatures,
    required this.purchaseButtonLabel,
  });

  final String entryTitle;
  final String entrySubtitle;
  final String entrySubtitleActive;
  final String pageTitle;
  final String pageSubtitle;
  final String currentPlanTitle;
  final String currentPlanActiveLabel;
  final String currentPlanInactiveLabel;
  final String annualHighlightedLabel;
  final String trialBadgeLabel;
  final String restoreButtonLabel;
  final String signInButtonLabel;
  final String retryButtonLabel;
  final String accountRequiredHint;
  final String activeSubscriptionHint;
  final String billingUnavailableHint;
  final String restoreOnlyHint;
  final String cloudFeaturesTitle;
  final String localFeaturesTitle;
  final String discoveryFeaturesTitle;
  final String offersTitle;
  final String contextualUpsellTitle;
  final String contextualUpsellBody;
  final String contextualUpsellAction;
  final String contextualUpsellDismiss;
  final String libraryBannerTitle;
  final String libraryBannerBody;
  final String libraryBannerAction;
  final String annualOfferCaption;
  final String monthlyOfferCaption;
  final String purchaseSucceeded;
  final String restoreSucceeded;
  final String noPurchaseFound;
  final String billingUnavailable;
  final String networkUnavailable;
  final String accountRequired;
  final String purchaseCancelled;
  final String technicalFailure;
  final List<String> cloudFeatures;
  final List<String> localFeatures;
  final List<String> discoveryFeatures;
  final String Function(String priceLabel) purchaseButtonLabel;
}

String _purchaseLabelEn(String priceLabel) => 'Subscribe · $priceLabel';
String _purchaseLabelFr(String priceLabel) => 'S’abonner · $priceLabel';
