# Audit et recommandations — core/logging

## Contexte & Objectif
- Dossier à analyser: `lib/src/core/logging/` contenant `logging.dart` et `logging_service.dart`.
- But: proposer une analyse fichier par fichier et des optimisations/réorganisations/corrections professionnelles, alignées avec les règles Clean Architecture, sécurité, qualité et DX du projet.

## Vue d’ensemble
- Le dossier expose un service de logging simple, principalement orienté écriture fichier dans le répertoire Documents, via API statique.
- Il coexiste avec une abstraction `AppLogger` ailleurs (`lib/src/core/utils/logger.dart`), utilisée notamment dans le réseau.
- Objectif stratégique: unifier la politique de logs (console + fichier), garantir des niveaux, éviter les fuites de secrets, gérer la rotation/retention et l’intégration DI.

## Analyse fichier par fichier

### logging.dart
- Rôle: fichier d’agrégation qui ré-exporte `logging_service.dart`.
- Avantages: point d’entrée minimal pour importer le service.
- Limites: ne documente pas l’intention (pas d’interface), renforce le couplage au service concret et à ses APIs statiques.
- Recommandations:
  - Introduire une interface (`LoggerRepository` ou `LogSink`), et faire de ce fichier un export d’API publique (interfaces + implémentations), afin d’éviter le couplage direct aux statiques.
  - Regrouper ici les types (p.ex. `LogLevel`, `LogEvent`) si on sépare les fichiers en sous-modules.

### logging_service.dart
- Référence: `lib/src/core/logging/logging_service.dart:1–59`.
- Responsabilités observées:
  - Initialisation d’un fichier de log dans Documents via `path_provider`.
  - Écriture append avec `IOSink`, flush systématique après chaque write.
  - API statique (`init`, `log`, `dispose`) et détection de plateforme (`kIsWeb`, `Platform.isX`).
- Points forts:
  - Simplicité d’usage; écriture fichier cross-platform (hors Web) avec directory géré.
  - Sécurise l’app contre les exceptions de logging (try/catch silencieux).
- Points faibles / risques:
  - API statique → difficile à tester/mocker; pas d’injection DI; état global `_sink` / `_initialized`.
  - Pas de niveaux de logs (debug/info/warn/error), ni de structure (`LogEvent`).
  - `flush` systématique peut dégrader les performances (I/O fréquents).
  - Pas de rotation/retention (taille illimitée), pas de TTL, pas de limites.
  - `path_provider` indisponible sur Web; `kIsWeb` renvoie "web" mais l’init fichier échouerait; il faut une stratégie spécifique.
  - Sécurité: pas de filtrage/sanitization des messages; risque de fuite d’informations sensibles si appelant logge du payload.
  - Concurrence: si appels multiples parallèles, `IOSink` reste généralement sûr mais pas de file d’attente ni backpressure; un buffer/queue serait plus robuste.
- Corrections/optimisations proposées:
  - Remplacer l’API statique par un service injecté (`AppLogger` backend fichier), via DI (`sl<AppLogger>`), pour unifier avec `lib/src/core/utils/logger.dart:1–30`.
  - Ajouter `LogLevel` et méthodes dédiées (`debug/info/warn/error`), avec un format homogène.
  - Implémenter une file interne avec lot (batch) et `flush` périodique (p.ex. toutes 500 ms ou N messages), réduisant la pression disque.
  - Rotation/retention: taille max (p.ex. 5 MB) et nombre de fichiers (p.ex. 5), avec horodatage et suppression des anciens.
  - Politique de sécurité: filtre/sanitize de messages connus (éviter tokens/mots de passe), et bannir tout dump de payloads sensibles.
  - Stratégie Web: sur Web, désactiver l’écriture fichier; basculer vers `console.log` ou stockage mémoire volatil (optionnel) avec export manuel.
  - Hooks d’erreurs globales: intégration avec `FlutterError.onError` et `Zone.current.handleUncaughtError` pour capter les exceptions non interceptées.

## Alignement Clean Architecture
- Interfaces dans `domain` (contrat de logging); implémentations fichier/console dans `data`.
- `AppLogger` devient l’interface principale; `LoggingService` devient un adapter (file sink) en data.
- Respect des dépendances: `presentation` → `domain` (interfaces) → `data` (impl.). Pas d’accès direct aux libs IO depuis `domain`.

## Sécurité & conformité
- Masquer systématiquement credentials, tokens, headers sensibles.
- Pas de logs de payloads réseau (bodies) en clair.
- Possibilité d’un niveau "trace" désactivé en production, activé seulement en debug.
- Ajout d’un identifiant de session et de corrélation (traceId simple) pour relier les événements sans exposer de données sensibles.

## Performance & DX
- Batch + flush périodique pour réduire I/O.
- Rotation automatique et taille bornée pour éviter la croissance illimitée.
- Format message sobre et court; niveaux clairs.
- Paramétrage via config (p.ex. `AppConfig`) pour activer/désactiver file logging, définir TTL/rotation.

## Proposition de réorganisation
- `lib/src/core/logging/`
  - `logger.dart` (interface `AppLogger`, `LogLevel`, `LogEvent`).
  - `adapters/console_logger.dart` (impl console).
  - `adapters/file_logger.dart` (impl fichier avec rotation, batch).
  - `logging_module.dart` (enregistrement DI des impls selon plateforme/config).
  - `formatters/` (optionnel: format de sortie).
- `logging.dart` redevient un export structuré de l’API publique (interfaces + adapters).
- `lib/src/core/utils/logger_utils.dart` peut se limiter à helpers fins ou être supprimé si DI ubiquitaire.

## API cible (exemple de contrat)
- `abstract class AppLogger { void log(LogLevel level, String message, {Object? error, StackTrace? stack}); void debug(...); void info(...); void warn(...); void error(...); }`
- `enum LogLevel { debug, info, warn, error }`
- Impl fichier: constructeur avec options (`path`, rotation, maxSize, flushInterval`), méthode `dispose()`.
- Impl console: mappe vers `print` ou `debugPrint` et peut enrichir avec tags.

## Plan d’action suggéré
- Introduire l’interface et les niveaux; migrer les appels existants vers `AppLogger` (déjà présent) et brancher une impl fichier comme backend.
- Remplacer les statiques par DI; fournir une config (activer/désactiver file logging).
- Ajouter rotation et batch; interdire le logging de payloads sensibles.
- Implémenter les hooks d’erreurs globales.

## Références code
- Export actuel: `lib/src/core/logging/logging.dart:1`.
- Service actuel: `lib/src/core/logging/logging_service.dart:1–59`.
- Logger utilisé par le réseau: `lib/src/core/utils/logger.dart:1–30`.

## Conclusion
- Le système actuel fonctionne mais reste basique et statique. En l’unifiant avec `AppLogger`, en ajoutant niveaux, rotation, batch et DI, on gagne en robustesse, performance, testabilité et conformité aux règles du projet.