# Plan de correction — Continue Watching et pages fournisseurs

## Contexte et symptômes
- Les médias « En cours » (`Continue Watching`) ne s’affichent pas sur la page d’accueil.
- Les pages fournisseurs (« Watch providers ») restent en chargement infini après clic.

## Analyse technique
- La section CW consomme `homeInProgressProvider` qui renvoie un `Future<List<InProgressMedia>>` et masque l’UI pendant le chargement.
  - `lib/src/features/home/presentation/widgets/home_continue_watching_section.dart:33–56`
- Ce provider agrège l’historique puis enrichit via TMDB (backdrops, année, épisodes).
  - `lib/src/features/home/presentation/providers/home_providers.dart:181–187`
  - Service d’enrichissement séquentiel: `lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:35–144`
- Les pages fournisseurs déclenchent 2 appels TMDB concurrents au mount (films + séries) sans annulation/timeout explicites.
  - `lib/src/features/search/presentation/pages/provider_results_page.dart:42–52, 60–115, 117–172`
- Le client réseau central applique un timeout par défaut de 30s si non configuré.
  - `lib/src/core/network/network_executor.dart:278–284`
- Configuration actuelle des timeouts via `Dio` est pilotée par `AppConfig`.
  - `lib/src/core/network/http_client_factory.dart:21–58`

## Causes probables
- CW:
  - Enrichissement TMDB de chaque entrée effectué en série (images, épisodes) → latences cumulées et « perçues » comme un blocage, donc rien ne s’affiche (état `loading`).
  - Absence de politique de timeout/grâce sur chaque sous‑appel (images, épisodes) → attente longue si TMDB lent.
  - Pas de limite explicite de **N** éléments enrichis → trop de travail au premier rendu.
- Providers:
  - Deux requêtes `discover/movie` et `discover/tv` lancées en parallèle à l’init sans `CancelToken` ni timeout court → spinner qui ne s’arrête pas si le réseau est lent/bloqué.
  - `_hasMore*` reste vrai si la réponse ne revient pas → état « chargement » persistant.

## Plan de correction
- Continue Watching (CW):
  - Limiter l’enrichissement initial à un nombre borné d’entrées (ex: 8–10) pour le premier rendu, puis charger le reste en tâche de fond.
  - Introduire un **pool de concurrence** (ex: 3) pour les appels TMDB, avec `Future.wait` et timeouts par sous‑appel (images/épisodes: 1.5–2s). Tout appel qui timeout tombe en fallback (poster local).
  - Court‑circuit: si aucune entrée d’historique valide (progress entre seuils), renvoyer immédiatement une liste vide.
  - Dégrader les épisodes: si la récupération d’épisodes (durée + titre) échoue ou timeout, ignorer ces champs pour ne pas bloquer.
  - Conserver l’ordre par `lastPlayedAt` pour stabilité visuelle.
- Pages fournisseurs:
  - Passer un `CancelToken` aux appels `discover/*` et l’annuler au `dispose` de la page.
  - Utiliser des timeouts réseau plus courts via `AppConfig` (ex: `receiveTimeout` 8s) et `retries=0` pour la première page afin d’éviter la perception de boucle infinie.
  - Rendre `_hasMore*` faux si la page renvoyée est vide ou en cas d’erreur, et éteindre les flags `_isLoading*` de façon robuste.
  - Afficher un message d’état (« Aucun résultat » ou « Problème réseau ») plutôt que spinner seul en cas d’erreur/timeout.

## Modifications ciblées (fichiers)
- `lib/src/features/home/presentation/providers/home_providers.dart`
  - Adapter `homeInProgressProvider` pour orchestrer un enrichissement borné/concurrent avec timeouts.
  - Option: déléguer au use case `LoadContinueWatchingMedia` la stratégie de pooling et fallback.
- `lib/src/features/home/domain/services/continue_watching_enrichment_service.dart`
  - Paralleliser l’enrichissement avec un plafond (ex: 3) et appliquer des timeouts par sous‑appel.
  - Limiter le nombre d’items traités sur la première passe.
- `lib/src/features/search/presentation/pages/provider_results_page.dart`
  - Injecter `CancelToken` pour `_loadMovies` et `_loadShows`; annuler au `dispose`.
  - Forcer `_isLoading* = false` dans `finally` + définir `_hasMore* = false` si résultats vides/erreurs.
  - Enrichir l’UI d’un état « aucun résultat / problème réseau ».
- `lib/src/core/network/http_client_factory.dart`
  - Abaisser `receiveTimeout` (ex: 8s) dans `AppConfig.network.timeouts` pour des retours plus rapides en cas de blocage.

## Validation
- Tests unitaires (Domain/Data):
  - `continue_watching_enrichment_service_test.dart`: cas success + timeout + fallback poster; tri par `lastPlayedAt`.
  - Provider results: simuler erreurs/timeout avec `FakeTmdbClient` et vérifier extinction de `_isLoading*` et message d’état.
- Tests widget:
  - `home_continue_watching_section_test.dart`: vérifie rendu vide, rendu avec 1–n items, et non‑blocage quand TMDB est lent.
  - `provider_results_page_test.dart`: vérifie rendu des 2 sections, état « aucun résultat », et annulation au `dispose`.
- Vérification manuelle:
  - Ouvrir Home et constater affichage immédiat (hero + iptv), puis apparition progressive de CW en ≤ 2s.
  - Ouvrir une page provider; vérifier que spinner disparaît en ≤ 8s avec message en cas d’erreur.

## Risques & mitigations
- Latence TMDB variable: timeouts courts + fallback poster assurent une UX stable.
- Charge réseau accrue: pool de concurrence borné (cap=3) et mini‑cache mémoire limitent l’impact.
- États UI incohérents: centraliser extinction des flags de chargement dans `finally` et couvrir via tests.

## Références de code
- CW section: `lib/src/features/home/presentation/widgets/home_continue_watching_section.dart:33–56`
- Provider page (init + loaders): `lib/src/features/search/presentation/pages/provider_results_page.dart:42–52, 60–115, 117–172`
- Provider CW: `lib/src/features/home/presentation/providers/home_providers.dart:181–187`
- Service CW: `lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:35–144`
- Timeout réseau: `lib/src/core/network/network_executor.dart:278–284`
- Client HTTP: `lib/src/core/network/http_client_factory.dart:21–58`

## Checklist d’implémentation
- Limiter et paralléliser l’enrichissement CW avec timeouts/fallbacks.
- Annuler les appels providers au `dispose` et réduire le timeout réseau effectif.
- Gérer les états `_isLoading*`/`_hasMore*` de manière sûre et afficher un état utilisateur clair.