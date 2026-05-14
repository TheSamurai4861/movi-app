# Decision catalogue cached/stale

## Decision

Un snapshot catalogue exploitable ouvre Home rapidement.

Les modes suivants sont consideres ouvrables :

- `CatalogMode.fresh` ;
- `CatalogMode.cached` ;
- `CatalogMode.stale`.

`cached` et `stale` ne sont pas des erreurs source. Ils peuvent produire un
signal log-safe et, si necessaire, une notice non bloquante ou une resync de
fond, mais ils ne doivent pas afficher un ecran recovery avant Home.

## Regle produit

| cas | decision produit | UI boot | Home | action autorisee |
| --- | --- | --- | --- | --- |
| `catalogSnapshotCached` | Ouvrir Home rapidement. | Afficher au maximum `opening_home` tres bref. Pas de warning bloquant. | Home ouverte. | Resync en fond ou action secondaire apres Home si necessaire. |
| `catalogSnapshotStale` | Ouvrir Home rapidement avec contenu local. | Afficher au maximum `opening_home` tres bref. Pas de warning bloquant. | Home ouverte. | Resync en fond ou notice discrete apres Home si le produit la retient. |
| Refresh echoue mais snapshot cached/stale existe | Ouvrir Home quand meme. | Ne pas afficher `source_timeout` ou `provider_error` avant Home. | Home ouverte avec contenu local. | Log de refresh en echec, sync/retry non bloquant. |

## Regle technique

La regle canonique reste :

```text
CatalogMode.fresh.canOpenHome == true
CatalogMode.cached.canOpenHome == true
CatalogMode.stale.canOpenHome == true
```

Le mapping UI doit consommer cette regle au lieu de dupliquer la logique.

Le comportement actuel de `ResolveCatalogReadiness` est acceptable comme base :

- `fresh` retourne `HomeReady(catalogSnapshotFresh)` ;
- `cached` retourne `HomePartial(catalogSnapshotCached, openHomeCached, resyncSource)` ;
- `stale` retourne `HomePartial(catalogSnapshotStale, openHomeCached, resyncSource)` ;
- un refresh failure n'ecrase pas un snapshot ouvrable.

Pour l'UI finale, `HomePartial` lie a `catalogSnapshotCached` ou
`catalogSnapshotStale` ne doit pas etre rendu comme une recovery source. Il doit
etre interprete comme "Home ouvrable avec cache local".

## UI attendue

| etat runtime | type d'ecran | texte utilisateur | interaction |
| --- | --- | --- | --- |
| Snapshot cached/stale detecte avant preload | `opening_home` | Texte court de type "Ouverture de l'accueil". | Aucune action. |
| Home ouverte avec cache local | Pas d'ecran boot. Notice Home optionnelle seulement si decision produit ulterieure. | Aucun message bloquant. | Resync non bloquante si exposee. |
| Refresh de fond echoue apres Home | Notice Home partiel seulement si l'echec impacte une section visible. | Message court non technique. | Action limitee a resync/retry section. |

Decision actuelle : ne pas afficher de warning boot dedie pour `cached/stale`.
Le seul affichage autorise avant Home est `opening_home`, bref et non
interactif.

## Ce qui reste une erreur source

Les ecrans recovery source avant Home sont reserves aux cas non ouvrables :

- `CatalogMode.missing` sans refresh reussi ;
- `CatalogMode.empty` ;
- `CatalogMode.unavailable` ;
- `CatalogRefreshOutcome.timedOut` sans snapshot ouvrable ;
- `CatalogRefreshOutcome.providerError` sans snapshot ouvrable ;
- `CatalogRefreshOutcome.credentialsInvalid` sans snapshot ouvrable.

Ces cas se mappent vers `SourceRecoveryRequired`, pas vers `HomePartial`.

## Logs attendus

Le boot doit conserver des logs structurants qui permettent de diagnostiquer le
choix sans afficher les reason codes a l'utilisateur.

| moment | log attendu | champs utiles |
| --- | --- | --- |
| Lecture snapshot | `[Startup] action=catalog_snapshot result=success` | `code=catalog_snapshot_cached` ou `catalog_snapshot_stale`, `mode`, `exists`, `hasPlaylists`, `hasItems`, `reason`. |
| Decision readiness | `catalog_minimal_ready` ou equivalent entry journey | `runId`, `reasonCode`, `catalogMode`, `destination=home`. |
| Ouverture Home | `entry_journey_stage_completed` / `entry_journey_completed` | `runId`, `reasonCode=home_ready` ou `preload_complete`, `destination=home`. |
| Refresh de fond echoue | Log sync/refresh non bloquant | `runId` si disponible, provider, reason code technique, sans bloquer Home. |

Les logs doivent rester log-safe :

- ne pas inclure `sourceId` ou identifiants bruts dans les reason codes ;
- ne pas afficher les reason codes dans l'UI ;
- ne pas transformer `catalog_snapshot_cached` ou `catalog_snapshot_stale` en
  message utilisateur.

## Tests a conserver ou renforcer

| comportement | test existant | test a ajouter ou adapter |
| --- | --- | --- |
| `cached` ouvre Home | `catalog_snapshot_test.dart`, `resolve_catalog_readiness_test.dart`, `resolve_entry_decision_test.dart`, `app_launch_orchestrator_local_mode_test.dart`. | `boot_ui_state_mapper_test.dart` : `catalogSnapshotCached` produit `opening_home` ou Home, jamais recovery. |
| `stale` ouvre Home | `catalog_snapshot_test.dart`, `resolve_catalog_readiness_test.dart`. | Test mapper UI : `catalogSnapshotStale` produit un etat non bloquant. |
| Refresh failure ignore si snapshot ouvrable | `resolve_catalog_readiness_test.dart` couvre timeout/provider avec `cached/stale`. | Test orchestrateur si necessaire pour verifier Home rapide avec refresh de fond en echec. |
| Aucun reason code brut en UI | Aucun test dedie aujourd'hui. | `boot_no_generic_messages_test.dart` ou assertion dans `boot_ui_state_mapper_test.dart`. |

## Consequences pour les phases suivantes

- Le futur `BootScreenModel` doit traiter `catalogSnapshotCached` et
  `catalogSnapshotStale` comme etats ouvrables.
- `RecoveryAction.openHomeCached` ne doit pas devenir un bouton obligatoire
  avant Home. Il sert d'intention technique ou de compatibilite avec le
  resolver actuel.
- `catalog_cached_ready` peut rester un etat interne ou un signal de mapping,
  mais ne doit pas etre une page recovery.
- La phase catalogue peut lancer une resync de fond apres Home, mais ne doit pas
  bloquer l'utilisateur tant que le snapshot est exploitable.

## Definition de fini - etape 3

- La decision `cached/stale` est explicite.
- Home rapide reste l'invariant principal.
- Les erreurs source restent reservees aux snapshots non exploitables ou aux
  refreshs en echec.
