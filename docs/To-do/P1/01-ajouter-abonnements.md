# Ajouter les abonnements dans l'application

## Problème actuel

L'app donne actuellement accès à l'ensemble des fonctionnalités premium sans paiement. Il faut mettre en place un système d'abonnement clair, cohérent et techniquement fiable.

## Objectif

- Identifier les fonctionnalités à placer derrière un abonnement
- Définir un modèle freemium pertinent pour l'app
- Mettre en place l'achat et la gestion des abonnements
- Vérifier que l'expérience utilisateur reste claire et attractive

## Portée

### Inclus

- Définition du périmètre gratuit vs premium
- Conception du parcours d'abonnement
- Intégration technique du système de paiement / validation
- Gestion de l'état d'abonnement dans l'app

### Exclu pour l'instant

- Refonte marketing complète de l'offre
- Multiplication avancée des offres et promotions complexes
- Expérimentations de pricing non prioritaires

## Décisions produit à cadrer (défaut proposé)

> Ces décisions peuvent être ajustées plus tard, mais on doit en figer une version v1
> pour rendre l’implémentation testable et cohérente.

- **Entitlement v1**: `Movi Premium` (un seul niveau), débloquant toutes les `PremiumFeature`.
- **Offres**: mensuel + annuel (IDs existants côté catalog).
- **Essai**: géré par les stores (ex: “7 jours d’essai” affiché côté UI), sans logique custom dans l’app.
- **Freemium**: les écrans premium restent visibles mais “bloqués” avec un upsell clair (sheet/page), sauf cas où la feature serait inutilisable sans premium (hard-block).

### Fonctionnalités premium

Source: `lib/src/core/subscription/domain/entities/premium_feature.dart`

| PremiumFeature | Ce que ça débloque (v1) | Écrans / points d’entrée | Type de verrouillage | Message / CTA | Statut actuel |
|---|---|---|---|---|---|
| `cloudLibrarySync` | Sync bibliothèque cloud + synchro “maintenant” + auto-sync | `SettingsPage` section cloud sync + bootstrapper cloud sync | **Action-gate** (bouton/switch) + **bootstrap gate** | Sheet “Cette fonctionnalité nécessite Movi Premium” + CTA “Voir Movi Premium” | **Déjà protégé** (provider + UI + bootstrap) |
| `cloudLibraryRestore` | Restauration bibliothèque depuis cloud (si écran dédié) | À raccorder quand l’UI existe | Action-gate | Sheet + CTA | Non câblé |
| `cloudPlaylistSync` | Sync playlists cloud | À identifier (Library playlists) | Action-gate | Sheet + CTA | Non câblé |
| `cloudPlaybackSync` | Sync progression / historique multi-device | À identifier (player/history) | Background-gate | Pas d’upsell agressif; activer uniquement si premium | Non câblé |
| `cloudFavoritesSync` | Sync favoris cloud | À identifier (favorites) | Background-gate | Idem | Non câblé |
| `localContinueWatching` | Continuer à regarder local (section Home) | `HomeContinueWatchingSection` | **View-gate** (afficher card upsell à la place) | Upsell + CTA | **Déjà protégé** |
| `localProfiles` | Profils locaux | `SettingsPage` add/manage profile | Action-gate | Sheet + CTA | **Déjà protégé** |
| `localParentalControls` | Contrôle parental local “premium” | À raccorder si feature existe | Action-gate | Sheet + CTA | Non câblé |
| `extendedDiscoveryDetails` | Fiches enrichies (acteur/saga) | `PersonDetailPage`, `SagaDetailPage` | **Hard-gate** (vue verrouillée) | Page verrouillée + CTA “Voir Movi Premium” | **Déjà protégé** |

Décisions restantes à figer:
- **Quota vs hard-block**: pour v1, privilégier l’upsell léger (sheet) sauf discovery pages (hard-gate déjà en place).
- **Offline**: voir section “Règles d’accès” + “Risques”.

### Expérience freemium

- **Reste gratuit (v1)**: navigation, recherche/découverte de base, lecture (hors features premium), gestion locale basique.
- **Devient payant (v1)**: toutes les `PremiumFeature` listées ci-dessus.
- **Frictions acceptables**:
  - 1 interaction (sheet) quand l’utilisateur tente une action premium.
  - 0 interaction quand la feature premium est “background” (ex: sync auto), on ne fait juste rien si non premium.
- **Décision**: un seul paywall (`MoviPremiumPage`) + un seul pattern d’upsell (sheet) pour les locks contextuels.

### Offre d'abonnement

- **Type d’offre**: abonnement “Movi Premium”.
- **Mensuel / annuel**: oui (IDs existants: `movi_premium_monthly`, `movi_premium_annual`).
- **Essai**: store trial (affiché UI, pas géré côté app).
- **Argumentaire principal**: cloud sync + profils + découverte enrichie.
- **Décision**: l’app ne gère pas de promotions complexes en v1.

## Parcours utilisateur à définir

### Découverte de l'offre

- **Où présenter l’abonnement**:
  - settings (tile Movi Premium)
  - library (banner)
  - locks contextuels (sheet)
- **Déclencheurs**:
  - tentative d’action premium (switch/bouton)
  - ouverture d’un écran premium (hard-gate)
- **Écrans concernés**:
  - `MoviPremiumPage`
  - `premium_feature_locked_sheet`
  - bannières contextuelles (Home/Library)

### Souscription

- **Étapes**:
  - ouvrir `MoviPremiumPage`
  - charger l’état abonnement + offres
  - sélectionner une offre → lancer achat
  - succès → refresh snapshot → UI “Premium actif”
- **Données / états**:
  - `SubscriptionSnapshot` (hasActiveSubscription, entitlements)
  - `BillingAvailability` (available / restoreOnly / unavailable)
  - erreurs catégorisées (network, cancelled, billing unavailable, technical)
- **Cas d’erreur**:
  - achat annulé
  - réseau indisponible
  - billing indisponible / restore-only
  - produit inconnu (catalog)

### Restauration / gestion d'abonnement

- **Cas à couvrir**:
  - restauration trouvée et active
  - restauration trouvée mais inactive/expirée
  - aucune restauration trouvée
  - billing restore-only
- **Comportement attendu**:
  - bouton “Restaurer” visible si possible
  - après restore: refresh subscription + refresh offers
- **Messages UI**: via `MoviPremiumLocalizer.feedback(...)` (unifié)

## Tâches et réflexions

- Analyser les fonctionnalités de l'app
- Identifier ce qui relève du premium
- Définir un modèle freemium cohérent
- Concevoir un parcours d'abonnement simple et crédible
- Proposer une implémentation propre et organisée
- Implémenter la solution retenue
- Tester les scénarios de souscription et de restauration

## Checklist d'exécution

- [ ] Lister les fonctionnalités premium
- [ ] Valider la séparation gratuit / payant
- [ ] Définir les offres et règles d'accès
- [ ] Concevoir les écrans ou points d'entrée liés à l'abonnement
- [ ] Implémenter la logique d'achat et de restauration
- [ ] Gérer l'état d'abonnement dans l'app
- [ ] Tester les parcours principaux

## Critères de validation

- Les fonctionnalités premium sont correctement protégées
- Le parcours d'abonnement est compréhensible
- L'achat, la restauration et la vérification d'état fonctionnent
- L'expérience freemium reste attractive sans bloquer inutilement l'utilisateur

## Règles d’accès (source of truth)

- **Règle centrale**: `canAccessPremiumFeatureProvider(feature)` (use case `CanAccessPremiumFeature`) est la vérité pour tout gating.
- **Pas de logique métier dans l’UI**: l’UI orchestre l’upsell, mais ne décide pas “premium ou pas” autrement.
- **Background features** (ex: auto-sync playback): si pas premium, on n’active pas la feature sans bloquer l’utilisateur.

### Offline / état inconnu (v1)

- Si le snapshot est **en cache**: l’app utilise le dernier snapshot (et expose “Premium actif” si c’était le cas).
- Si l’état est **inconnu** (premier lancement offline): comportement conservateur
  - les features premium sont considérées **non accessibles** tant qu’on n’a pas un snapshot validé.
  - upsell uniquement lors d’une action premium (pas de spam).

## Plan d'implémentation

### Étape 1 - Cadrage produit

- Valider la matrice `PremiumFeature` ci-dessus (scope v1)
- Confirmer l’approche “1 entitlement / 2 offers”
- Fixer la politique offline (conservatrice v1) + messages

### Étape 2 - Conception du parcours

- Définir le pattern unique d’upsell:
  - Sheet contextuelle (action-gate)
  - Page verrouillée (hard-gate)
  - Banner Library (découverte douce)

### Étape 3 - Implémentation technique

- Standardiser le gating UI (un seul pattern)
- Raccorder/ajouter les gates manquants pour les `PremiumFeature` non câblées
- Stabiliser refresh/cache (déclencheurs)

### Étape 4 - Tests et validation

- Tests unitaires: use case gating + catalog entitlements + cache/TTL
- Widget tests: verrous principaux (home/person/saga) + paywall états (billing)
- Tests manuels sandbox: purchase/restore/offline

## Risques / points d'attention

- **Contournement**: une feature premium accessible par un autre chemin (ex: un bouton secondaire non protégé).
- **Incohérences UX**: messages premium différents selon l’écran; CTA qui n’ouvre pas le bon paywall.
- **Offline**: faux négatifs (premium actif mais état non rafraîchi) ou faux positifs (premium “gratuit”).
- **Billing availability**: appareils non supportés (desktop/TV) → restaurer seulement ou indisponible.
- **Couplage**: logique premium dispersée dans l’UI (à éviter), doit rester derrière use cases/providers.

## Questions ouvertes

- Pour les features cloud “background” (ex: favorites/playback sync): veut-on un toggle UI premium, ou activation implicite quand premium actif ?
- Quelles features doivent être **hard-block** vs **action-gate** en v1 ?

## Notes complémentaires

- IDs d’offres attendus (catalog): `movi_premium_monthly`, `movi_premium_annual`.
- Entrées paywall existantes: settings tile + banner library + sheet premium.
