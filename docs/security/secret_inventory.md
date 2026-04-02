# Inventaire secrets / tokens / sessions / PII — Phase 1

## Statut et conformité
- **Lot** : `PH1-LOT-002`
- **Référentiel** : `docs/rules_nasa.md` (§12, §13, §25, §26, §27)
- **Règle** : aucun secret dans le code, config versionnée, logs/traces, ou historique Git.
- **Attention** : ce document ne doit **jamais** contenir de valeurs de secrets (uniquement des emplacements/clefs/types).

## Découvertes immédiates (2026-04-02)

### Alerte — secrets en clair versionnés
- **Fichier** : `.env`
- **Constat** : présence de valeurs pour :
  - `TMDB_API_KEY` (token type JWT)
  - `TMDB_API_KEY_PROD`
  - `SUPABASE_URL` (URL projet)
  - `SUPABASE_ANON_KEY` (clé “anon” — publique par design, mais à traiter comme donnée sensible opérationnelle)
  - `SUPABASE_PROJECT_REF`
  - flags debug (`PREMIUM_DEBUG`, `FORCE_PREMIUM`, `ALLOW_FORCE_PREMIUM_IN_RELEASE`)
- **Criticité** : `C1` (exposition potentielle, gouvernance)
- **Décision requise (immédiate)** :
  - **Stop** si aucune décision n’est prise (règle Phase 1 “critères d’arrêt” + `docs/rules_nasa.md` §12).
  - Stratégie attendue : retrait du fichier versionné / rotation si nécessaire / bascule sur injection approuvée.

## Sources de configuration et mécanismes d’injection

### `.env.example`
- **Rôle** : gabarit sans valeurs (attendu OK).
- **Champs** :
  - `APP_ENV`
  - `TMDB_API_KEY`
  - `TMDB_API_KEY_PROD`
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_PROJECT_REF`
  - `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY`

### `--dart-define` (Flutter/Dart)
- **Loader** : `lib/src/core/config/env/environment_loader.dart`
- **Clés** :
  - `APP_ENV` / `FLUTTER_APP_ENV` (sélection d’environnement)
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_PROJECT_REF` (via `lib/src/core/config/models/supabase_config.dart`)
- **Risques** :
  - valeurs injectées à la compilation : risque de fuite si logs/erreurs imprudentes ;
  - divergence d’environnement si valeurs non contrôlées.

## Inventaire (sans valeurs) — secrets/tokens

| ID | Type | Clé / nom | Emplacement | Portée | Données | Traitement attendu | Owner | Statut |
|---|---|---|---|---|---|---|---|---|
| `PH1-SEC-001` | API token | `TMDB_API_KEY` | `.env` (actuel) / `--dart-define` (cible) | dev | API TMDB | **Retirer du repo**, injecter par mécanisme approuvé, rotation si compromis | Security owner | `ouvert` |
| `PH1-SEC-002` | API token | `TMDB_API_KEY_PROD` | `.env` (actuel) / secrets CI (cible) | prod | API TMDB | **Retirer du repo**, injecter via CI/secret store, rotation | Security owner | `ouvert` |
| `PH1-SEC-003` | Endpoint | `SUPABASE_URL` | `.env` / `--dart-define` | multi-env | URL backend | Traiter comme config sensible (pas dans repo si cible prod) | Core owner | `ouvert` |
| `PH1-SEC-004` | Key (public) | `SUPABASE_ANON_KEY` | `.env` / `--dart-define` | multi-env | accès anon Supabase | Garder hors repo si possible ; vérifier RLS côté Supabase | Data owner | `ouvert` |
| `PH1-SEC-005` | Identifiant projet | `SUPABASE_PROJECT_REF` | `.env` / `--dart-define` | multi-env | diagnostic | OK si sans secret ; ne pas utiliser pour auth | Core owner | `ouvert` |

## Inventaire — données personnelles / sensibles (PII)

| ID | Catégorie | Donnée | Où est-elle manipulée ? | Stockage | Logs/Traces | Mesures minimales | Owner | Statut |
|---|---|---|---|---|---|---|---|---|
| `PH1-PII-001` | Identité | Identifiants utilisateur (Supabase) | Flux auth/session | backend + cache local (à qualifier) | doit être redacted | minimisation + redaction + accès moindre privilège | Data owner | `à_qualifier` |

## Décisions / dérogations
- **Dérogations** : aucune (toute dérogation doit être formalisée `PH1-WVR-XXX`).

## Preuves attendues (à indexer)
- Snapshot daté de cet inventaire (révision Git) + entrée `PH1-EVD-XXX` dans `docs/quality/validation_evidence_index.md`.
- Entrée logbook associée : `PH1-LOT-002` dans `docs/traceability/change_logbook.md`.

