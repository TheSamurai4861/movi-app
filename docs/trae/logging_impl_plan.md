# Plan d’implémentation — Module de logging

## Objectifs & Portée
- Unifier et renforcer le logging selon Clean Architecture.
- Priorités couvertes: masquage, capture globale d’erreurs, niveaux configurables, rotation/rétention, buffer/backpressure, rate limiting/sampling, catégories par module.
- Ne pas logguer de payloads sensibles; conserver des messages sobres et exploitables.

## Architecture Cible
- Interface unique `AppLogger` et types (`LogLevel`, `LogEvent`) — déjà présents: `lib/src/core/logging/logger.dart:19`.
- Adapters spécialisés (console, fichier) — présents: `lib/src/core/logging/adapters/*.dart`.
- Module DI sélectionnant l’impl selon plateforme — présent: `lib/src/core/logging/logging_module.dart:9` et enregistré via `lib/src/core/di/injector.dart:55`.
- Ajout d’un orchestrateur léger (manager) pour: pipeline de sanitization, rate limiting/sampling, catégories et sélection des sinks.

## Exigences Non‑fonctionnelles
- Sécurité: masquage automatique de secrets (password, token, Authorization, cookies).
- Performance: buffer avec flush périodique, rotation bornée, sampling configurable.
- DX: niveaux par environnement et par catégorie; reconfiguration sans rebuild.

## Spécifications par Priorité

### 1) Masquage automatique des données sensibles
- Introduire un `MessageSanitizer`:
  - API: `String sanitize(String input)`, `Map<String, Object?> sanitizeMap(Map<String, Object?>)`.
  - Règles: masquer clés connues (`password`, `token`, `authorization`, `cookie`, `set-cookie`, `apikey`) et motifs (Bearer, JWT, clés hex/base64).
- Intégration:
  - Pipeline avant écriture: `AppLogger.log(...)` passe par `sanitizer`.
  - Ne jamais sérialiser corps de requêtes/réponses; uniquement métadonnées (méthode, chemin, code HTTP, latence).

### 2) Capture globale des erreurs
- Brancher au bootstrap application:
  - `FlutterError.onError = (FlutterErrorDetails d) { sl<AppLogger>().error('FlutterError', d.exception, d.stack); }`.
  - `runZonedGuarded(() => runApp(...), (error, stack) { sl<AppLogger>().error('Uncaught', error, stack); });`.
- Journaliser en niveau `error` avec contexte minimal.

### 3) Niveaux configurables par environnement
- Étendre `AppConfig.featureFlags` (ou `LoggingConfig`) pour:
  - `minLevel` par environnement (`trace/debug/info/warn/error`).
  - Activation des sinks (console, fichier).
  - Paramètres de rotation/flush/sampling.
- `LoggingModule.register()` lit la configuration et instancie l’impl adaptée.

### 4) Rotation et rétention paramétrables
- Paramètres:
  - Taille max (ex: 5–10 MB), nombre de fichiers (ex: 5–7), option rotation par date (journalier).
  - Rétention: supprimer au‑delà de N fichiers/J.
- Implémentation:
  - Étendre `FileLogger` (déjà présent) pour support par date en plus de par taille.
  - Ajout compression (optionnel) pour anciens fichiers.

### 5) Buffer avec backpressure + flush périodique
- File interne bornée (ex: `Queue<String>` max 2–5k entrées).
- Stratégie de drop: `drop-oldest` ou `drop-new` si saturation; compteur `droppedEvents`.
- Flush périodique (ex: 250–500 ms) et flush forcé à l’arrêt.

### 6) Rate limiting / sampling
- Sampling par niveau/catégorie (ex: ne garder qu’1/10 `debug` en prod).
- Rate limiting par fenêtre (ex: max 100 événements/min par catégorie).
- Compteurs exposés via logs `info` périodiques.

### 7) Catégories/modules de logging
- Ajouter champ `category` à `LogEvent`.
- API pratique: `logger.log(level, msg, category: 'network')`, helpers: `networkLogger.debug(...)`.
- Niveaux indépendants par catégorie (ex: `network=debug`, `ui=info`).

## Design Technique
- Nouveau type `LoggingConfig` lu depuis `AppConfig` (`lib/src/core/config/models/app_config.dart:32`).
- Orchestrateur `LoggerManager` (dans `core/logging/`) appliquant:
  - Filtrage par niveau/catégorie, sanitization, sampling, envoi aux sinks.
- Sinks:
  - Console: `ConsoleLogger` (déjà en place).
  - Fichier: `FileLogger` (déjà en place, à étendre rotation/date, backpressure bornée).
- Intercepteurs réseau: conserver uniquement métadonnées (latence déjà en place): `lib/src/core/network/interceptors/telemetry_interceptor.dart:28`.

## Étapes de Livraison
- Phase A: Sanitizer + hooks globaux d’erreurs + config minLevel.
- Phase B: Catégories et niveaux par catégorie; adaptation `TelemetryInterceptor`.
- Phase C: Buffer/backpressure et rotation/rétention avancées (taille/date).
- Phase D: Sampling/rate limiting; métriques de drop/flush.
- Phase E: Documentation et guides d’usage.

## Modifications Ciblées (fichiers)
- `lib/src/core/logging/logger.dart`: ajouter `category` à `LogEvent`, éventuellement `trace` à `LogLevel`.
- `lib/src/core/logging/logging_module.dart`: lire `LoggingConfig` depuis `AppConfig`; instancier orchestrateur.
- `lib/src/core/di/injector.dart:55`: garder l’appel au module de logging.
- `lib/src/core/network/http_client_factory.dart:16`: passer `AppConfig` au logger via module (déjà DI).
- `lib/src/core/network/interceptors/telemetry_interceptor.dart:28`: s’assurer de ne pas logguer de bodies.

## Critères d’Acceptation
- Aucun secret visible dans les logs (tests manuels avec chaînes de type token/password).
- Latences HTTP visibles sans bodies; catégories actives et filtrables par niveau.
- Fichiers tournent proprement; rétention respectée; pas de croissance illimitée.
- En charge, pas de blocage UI; drops mesurés et tracés.

## Risques & Mitigations
- Risque de perte d’événements sous backpressure: exposer compteurs et permettre escalade de niveau.
- Mauvaise configuration en prod: valeurs par défaut sûres; fallback console seul si `path_provider` indisponible.
- Surcharge CPU/IO: sampling et rate limiting activables, flush périodique borné.

## Effort & Planning
- Phase A: ~0.5–1 j
- Phase B: ~0.5 j
- Phase C: ~1 j
- Phase D: ~0.5 j
- Phase E: ~0.5 j