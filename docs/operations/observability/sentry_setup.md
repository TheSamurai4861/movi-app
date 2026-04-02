# Observabilité — Sentry (setup + preuve) — R2

**Document** : `OPS-OBS-SENTRY-001`  
**Statut** : `draft` (R2)  
**Références** : `docs/rules_nasa.md` §14 (observabilité), §13 (confidentialité), §25 (preuves).

---

## 1) Objectif

Ajouter une preuve “crash/error monitoring” exploitable, avec tags `release`/`environment`, sans PII, et compatible avec les contraintes NASA-like.

---

## 2) Dépendance

- `pubspec.yaml` : `sentry_flutter`

---

## 3) Configuration (compile-time)

Variables injectées via `--dart-define` :

- `SENTRY_DSN` : DSN Sentry (vide => Sentry désactivé)
- `SENTRY_ENV` : ex `dev|staging|prod`
- `SENTRY_RELEASE` : ex `movi@1.0.2+5` (ou hash/tag)

Le bootstrap est centralisé dans :

- `lib/src/core/observability/sentry_bootstrap.dart`
- `lib/main.dart` appelle `SentryBootstrap.init(...)`

---

## 4) Confidentialité / PII

- `sendDefaultPii=false` (par défaut) ;
- ne pas loguer tokens/PII (cf. `docs/rules_nasa.md` §13) ;
- les logs applicatifs restent sanitisés (`MessageSanitizer`).

---

## 5) Corrélation (operationId)

Si un `operationId` est présent dans la Zone (cf. `lib/src/core/logging/operation_context.dart`), alors :
- il est injecté dans les **tags** Sentry via `beforeSend`.

---

## 6) Preuve attendue (R2)

Preuve reproductible via test (sans réseau) :
- un test initialise Sentry avec un transport in-memory et vérifie :
  - qu’un événement non-fatal est capturé,
  - que `release` + `environment` sont renseignés,
  - que `operationId` est attaché.

Artefacts attendus dans `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/`.

