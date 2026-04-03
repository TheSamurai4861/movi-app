# Matrice privilèges / accès externes / dépendances critiques — Phase 1

## Statut et conformité
- **Lot** : `PH1-LOT-003`
- **Référentiel** : `docs/rules_nasa.md` (§12, §19, §21, §25, §27)
- **But** : expliciter le **moindre privilège**, la surface d’accès externe, et les dépendances critiques.

## Acteurs (internes) — périmètre Phase 1
- Application Movi (client)
- Modules core : startup, auth/session, network, storage, parental
- Features : player, IPTV
- Observabilité : Sentry (si activé)

## Accès externes et dépendances critiques

### Tableau synthèse

| Dépendance | Type | Données | Auth/secret | Usage | Modes dégradés attendus | Observabilité minimale |
|---|---|---|---|---|---|---|
| Supabase | Backend (auth + data) | comptes, profils, bibliothèque (à préciser) | `SUPABASE_URL` + `SUPABASE_ANON_KEY` (public) | auth/session + repos | fail-closed sur auth incertaine ; messages actionnables ; retries contrôlés | taux d’échec auth/api, latence, erreurs catégorisées |
| TMDB | API metadata | metadata films/séries | `TMDB_API_KEY` | résolution metadata | fallback : cacher fonctionnalités metadata non critiques | taux d’échec + cache hit/miss (si présent) |
| Sentry | Observabilité | erreurs non fatales, crash, tags | `SENTRY_DSN` (secret) | monitoring | si absent : logs locaux structurés et corrélables | crash rate, erreurs catégorisées |
| Proxy système | Réseau | toutes requêtes | `HTTP_PROXY`/`HTTPS_PROXY` (config) | debugging/enterprise | respecter `NO_PROXY` ; désactivation si casse réseau | logs configuration proxy (sans secrets) |

## Matrice privilèges (moindre privilège)

### Supabase (client)
- **Lecture** : uniquement les tables/vues nécessaires au périmètre (à qualifier en Phase 1).
- **Écriture** : uniquement actions nécessaires (ex. sync bibliothèque) ; refuser tout accès “admin”.
- **Sécurité** : dépend fortement des policies RLS côté Supabase — à documenter dans le `threat_model`.

### Réseau (HTTP)
- **Sortant** : uniquement vers domaines attendus (Supabase, TMDB, IPTV endpoints utilisateur).
- **Timeouts / retries** : obligatoires sur chemins critiques ; éviter boucles infinies.

### Stockage local
- **Données sensibles** : ne jamais persister en clair (secrets, tokens, PII non nécessaire).
- **Logs** : jamais de token/PII en clair (redaction obligatoire).

## Points à qualifier (gaps de preuve)
- Liste exacte des endpoints externes réellement appelés par feature (IPTV, player sources).
- Nature exacte des données utilisateur stockées localement (PII ? tokens ?).
- Preuve que les logs ne contiennent pas de secrets (scan + tests).

## Preuves attendues (à indexer)
- Snapshot daté de ce document + entrée `PH1-EVD-XXX` dans `docs/quality/validation_evidence_index.md`.
- Entrée logbook associée : `PH1-LOT-003` dans `docs/traceability/change_logbook.md`.

