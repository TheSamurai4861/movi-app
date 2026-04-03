# État courant du dépôt — baseline phase 0

**Document** : synthèse opposable produite dans le cadre du plan [`docs/Refactor/movi_nasa_refactor_plan_v3.md`](../Refactor/movi_nasa_refactor_plan_v3.md) (phase 0 — photographie structurelle, étape 2).

**Référentiel** : [`docs/rules_nasa.md`](../rules_nasa.md) (portée §1, preuves §25, dérogations §26).

**Dernière mise à jour substantielle** : `2026-04-02` (baseline Phase 0 + levées réserves **R1–R4** ; voir §1.1).

---

## 1. Synthèse

Ce document est la **porte d’entrée** de la baseline structurelle phase 0 : il résume ce qui a été observé et **renvoie** vers les artefacts bruts ou annexes. Il ne remplace pas l’exécution des étapes ultérieures du programme (dépendances, CI, analyse statique, matrice C/L, etc.).

| Sous-étape roadmap | Contenu dans ce fichier | Statut |
|--------------------|-------------------------|--------|
| **2.1** Capture d’arborescence | §2 + artefacts liste de fichiers | Réalisé |
| **2.2** Cartographie `lib/` | §3 | Réalisé |
| **2.3** Synthèse, liens, hypothèses / limites | §1 (ci-dessous + §1.1), §4 | Réalisé |

### 1.1 Index des artefacts et documents liés (bruts ou gouvernance)

| Artefact / document | Chemin relatif racine dépôt | Rôle |
|---------------------|----------------------------|------|
| Liste fichiers photographiés (export daté) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/repo_tree_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/repo_tree_2026-04-02.txt) | Preuve brute périmètre §2.1 |
| Script de régénération de la liste | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/generate_repo_tree.ps1`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/generate_repo_tree.ps1) | Reproductibilité |
| Roadmap phase 0 (séquencement) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md) | Source opératoire des étapes |
| Décision de gel phase 0 | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/01_decision_de_gel_phase_0.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/01_decision_de_gel_phase_0.md) | Gouvernance merge / release |
| Qualification entrées documentaires | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/02_qualification_entrees_documentaires_phase_0.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/02_qualification_entrees_documentaires_phase_0.md) | Corpus doc / lacunes (incidents, README, etc.) |
| Inventaire dépendances Dart/Flutter (étape 3.1) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/03_inventaire_dependances_dart_flutter.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/03_inventaire_dependances_dart_flutter.md) | Directes, transitives, stratégie versions ; artefact [`pub_deps_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/pub_deps_2026-04-02.txt) |
| Inventaire natif / tooling (étape 3.2) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/04_inventaire_dependances_natives_tooling.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/04_inventaire_dependances_natives_tooling.md) | Gradle, iOS, Windows, Flutter/Dart/JDK/CMake ; [`native_tooling_snapshot_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/native_tooling_snapshot_2026-04-02.txt) |
| Inventaire processus / scripts (étape 3.3) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/05_inventaire_dependances_processus.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/05_inventaire_dependances_processus.md) | `tool/`, `scripts/`, `analysis_options.yaml` ; clôture lot `PH0-LOT-005` |
| Matrice plateformes / reproduction (étapes 4.1–4.2) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/06_matrice_plateformes_et_environnements.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/06_matrice_plateformes_et_environnements.md) | Plateformes, environnements, commandes analyze/test/build, écarts CI ; artefacts [`flutter_android_defaults_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_android_defaults_2026-04-02.txt), [`reproduce_commands_baseline_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/reproduce_commands_baseline_2026-04-02.txt) |
| Baseline analyse statique (étape 5.1) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/07_baseline_analyse_statique.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/07_baseline_analyse_statique.md) | `dart analyze` ; 0 issue ; exclusions YAML et inventaire suppressions ; artefact [`dart_analyze_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/dart_analyze_2026-04-02.txt) |
| Baseline tests automatisés (étape 5.2) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/08_baseline_tests_automatises.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/08_baseline_tests_automatises.md) | `flutter test` : **197** pass, **3** fail ; carte domaines / zones sans preuve ; artefact [`flutter_test_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_test_2026-04-02.txt) |
| Baseline build / packaging (étape 5.3) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/09_baseline_build_packaging.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/09_baseline_build_packaging.md) | APK dev debug + Windows Release OK ; iOS non exécuté (hôte Windows) ; logs [`flutter_build_android_dev_debug_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_android_dev_debug_2026-04-02.txt), [`flutter_build_windows_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_windows_2026-04-02.txt), constat iOS [`flutter_build_ios_non_execute_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_ios_non_execute_2026-04-02.txt) |
| Index des preuves de validation (étape 5.4 + 9.3) | [`docs/quality/validation_evidence_index.md`](../quality/validation_evidence_index.md) | Regroupement Phase 0 baseline (PH0-BL-Q-5xx) + consolidation étape 9.3 (observabilité/runbooks, PH0-BL-GAP-015 à PH0-BL-GAP-017), renvois artefacts et journal |
| Criticité C/L (étapes 6.1–6.3) | [`docs/risk/component_criticality.md`](../risk/component_criticality.md) | Définitions NASA C1–C4 / L1–L4 + mapping domaine puis tableau granulaire “composant / zone / L” + alignement P0/P1 |
| Inventaire CI/CD (étape 7.1) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/10_inventaire_ci_cd_pipelines.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/10_inventaire_ci_cd_pipelines.md) | Codemagic **versionné** (`codemagic.yaml`) + inventaire workflows ; pas de GitHub Actions |
| Écart pipeline minimal NASA (étape 7.2) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/11_ecart_pipeline_minimal_nasa_7_2.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/11_ecart_pipeline_minimal_nasa_7_2.md) | Écart traité via R4 : pipeline minimal “preuves” + artefacts + index preuves |
| Constat release & rollback (étape 7.3) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/12_constat_release_rollback_7_3.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/12_constat_release_rollback_7_3.md) | Tags de release absents ; `README.md`/`CHANGELOG.md` racine absents ; rollback runbook absent |
| Règles d’architecture bloquantes cibles (étape 8.1) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/13_rappels_regles_architecture_cibles_8_1.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/13_rappels_regles_architecture_cibles_8_1.md) | Cibles issues de `movi_nasa_refactor_plan_v3.md` §4.3 (à vérifier en 8.2) |
| Inventaire violations d’architecture (étape 8.2) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/14_inventaire_violations_architecture_8_2.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/14_inventaire_violations_architecture_8_2.md) | Heuristiques V1–V4 vs règles bloquantes ; liste brute classée (C/coût) |
| Couverture tests / observabilité / runbook (étape 9.1) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md) | Flux critiques présumés ; runbooks absents ; logs structurés minimaux ; baseline non-verte sur 3 tests liés |
| Secrets et configuration (étape 9.2) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/16_constat_secrets_configuration_9_2.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/16_constat_secrets_configuration_9_2.md) | Constat : injection via `--dart-define` et `SecretStore` (+ fallback `.env`) ; logs sanitization ; pas d’indices de secrets versionnés |
| Revue croisée documentaire (étape 10.1) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/17_revue_croisee_10_1.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/17_revue_croisee_10_1.md) | Existence livrables + checklist Annexe A adaptée à la livraison documentaire |
| Verdict sortie phase 0 (étape 10.2) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/18_verdict_sortie_phase_0_10_2.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/18_verdict_sortie_phase_0_10_2.md) | Verdict “Bloqué” ; réserves R1–R4 pour lever les gaps avant phase 1 |
| Registre risques système Phase 1 (étape 10.3) | [`docs/risk/system_risk_register.md`](../risk/system_risk_register.md) | Registre initial Phase 1 : risques résiduels + familles violations (transmission) |
| Journal changements programme | [`docs/traceability/change_logbook.md`](../traceability/change_logbook.md) | Traçabilité lots `PH0-*` |
| Plan directeur v3 | [`docs/Refactor/movi_nasa_refactor_plan_v3.md`](../Refactor/movi_nasa_refactor_plan_v3.md) | Cadrage global (dont §1.4) |
| Règles NASA | [`docs/rules_nasa.md`](../rules_nasa.md) | Exigences haute assurance |

---

## 2. Photographie d’arborescence (étape 2.1)

### 2.1.1 Périmètre inclus

Liste exhaustive des **fichiers** (chemins relatifs à la racine du dépôt) pour :

| Zone | Rôle |
|------|------|
| `lib/` | code applicatif Dart/Flutter |
| `test/` | tests automatisés |
| `android/`, `ios/`, `windows/` | couches plateforme présentes à la racine |
| `assets/` | ressources versionnées |
| `docs/` | documentation du dépôt |
| `tool/`, `scripts/` | outillage et scripts |
| `supabase/` | fonctions / migrations liées au backend Supabase |

Fichiers à la racine inclus s’ils existent : `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `README.md`, `CHANGELOG.md`.

**Constat** : le répertoire `integration_test/` est **absent** à la racine du dépôt au moment de la baseline.

### 2.1.2 Exclusions explicites (non photographiées)

Ces éléments ne sont **pas** des sources de vérité pour la baseline structurelle ou sont générés / locaux :

| Exclusion | Motif |
|-----------|--------|
| `.dart_tool/` | cache et outillage Dart généré |
| `build/` | sorties de build |
| `.git/` | métadonnées VCS |
| `.cursor/` | configuration éditeur locale |
| `output/` | sortie potentiellement générée — **non incluse par défaut** ; à réintégrer au périmètre si le projet en fait une source de vérité documentée |

### 2.1.3 Artefacts datés et reproduction

| Artefact | Description |
|----------|-------------|
| [repo_tree_2026-04-02.txt](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/repo_tree_2026-04-02.txt) | Export texte unique : en-tête (périmètre, exclusions), puis liste triée des chemins relatifs |
| [generate_repo_tree.ps1](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/generate_repo_tree.ps1) | Script de régénération ; produit `repo_tree_YYYY-MM-DD.txt` dans le même dossier |

Pour reproduire une photographie ultérieure :

```text
powershell -ExecutionPolicy Bypass -File docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/generate_repo_tree.ps1
```

---

## 3. Cartographie des modules applicatifs (étape 2.2)

Photographie au **2026-04-02** : structure observée dans le code, pas la cible architecture du plan v3.

### 3.1 Domaines fonctionnels et frontières réelles (2.2.1)

#### `lib/l10n/`

- Fichiers ARB, délégués et **fichiers `app_localizations_*.dart` volumineux** (générés / dérivés des traductions) : hors logique métier, mais pèsent sur la lisibilité du dépôt.

#### `lib/src/core/` — transversal produit

Grands blocs observés (non exhaustif) :

| Zone | Rôle apparent |
|------|----------------|
| `auth/` | Auth domaine / données / présentation côté **noyau** |
| `config/`, `di/`, `logging/`, `error/`, `theme/`, `widgets/`, `responsive/` | infrastructure, DI, UI transverse |
| `network/` | client HTTP, interceptors, proxy |
| `storage/`, `security/` | persistance locale, coffre / chiffrement |
| `parental/`, `profile/`, `subscription/`, `preferences/` | règles et état transverses utilisateur |
| `startup/` | bootstrap, orchestration de lancement |
| `state/` | état global, bus d’événements |
| `router/` | GoRouter, garde de redirection, routes |
| `supabase/` | point d’accès client Supabase |
| `diagnostics/`, `reporting/`, `performance/` | diagnostic et perf |
| `playback/` | logique playback transverse récente |
| `shared/` | utilitaires / types partagés (ex. échecs) — **pas** un dossier `shared/` au même niveau que `features` |

**Frontières notables (constat)** :

- **Duplication de nom** `auth` : `core/auth` et `features/auth` coexistent ; la frontière réelle se lit fichier par fichier (imports), pas seulement par dossier.
- **Couplage observable** : `app_launch_orchestrator.dart` importe des modules sous `features/` (`home`, `library`, `iptv`, `welcome`). Le noyau **dépend** donc explicitement de features pour le lancement — écart typique par rapport à une règle stricte « core ne dépend pas des features ».
- **DI** : `GetIt` (`sl`, `slProvider` dans `lib/src/core/di/di.dart`) **et** Riverpod ; les deux sont en usage (barrel `router.dart` exporte la couche route).

#### `lib/src/features/` — parcours métier

Modules présents (dossiers racine sous `features/`) :

`auth`, `category_browser`, `home`, `iptv`, `library`, `movie`, `person`, `player`, `playlist`, `saga`, `search`, `settings`, `shell`, `tv`, `welcome`.

Sous-structure la plus fréquente : `data/`, `domain/`, `presentation/` ; quelques modules ajoutent `application/` (ex. `iptv`, `library`, `player`, `playlist`). **Hétérogénéité** : toutes les features ne suivent pas le même découpage.

**Frontière features ↔ core** : nombreux imports `package:movi/src/core/...` depuis les features ; le sens inverse existe au moins via l’orchestrateur de lancement (voir ci-dessus).

---

### 3.2 Points d’entrée, routeur et démarrage (2.2.2)

| Élément | Fichier / mécanisme | Rôle |
|---------|---------------------|------|
| Point d’entrée processus | `lib/main.dart` | `WidgetsFlutterBinding`, erreurs globales, `MediaKit`, proxy HTTP optionnel, `runApp` |
| Enrobage racine | `AppRestart` → `ProviderScope` → `AppStartupGate` → `MyApp` | Redémarrage, DI Riverpod, **gate** avant UI principale |
| Gate de bootstrap | `lib/src/core/startup/app_startup_gate.dart` | Attend `appStartupProvider` ; écran chargement / erreur / puis enfant `MyApp` |
| Application shell | `lib/src/app.dart` (`MyApp`) | `MaterialApp.router`, thème, locale, `appRouterProvider`, bootstrap subscription / sync dans le `builder` |
| Routeur | `lib/src/core/router/app_router.dart`, `app_routes.dart`, `launch_redirect_guard.dart` | `GoRouter`, `LaunchRedirectGuard`, `refreshListenable`, `redirect` ; `AppLaunchStateRegistry` pour la cohérence avec le lancement |
| Orchestration lancement | `lib/src/core/startup/app_launch_orchestrator.dart` | Phases (`AppLaunchPhase`), état (`AppLaunchState`), enchaînement auth / profils / sources IPTV / préchargements — **fichier très volumineux** |
| Barrel routeur | `lib/src/core/router/router.dart` | Réexport public des symboles route |

**Cheminement de démarrage résumé** : `main` → initialisations natives / globales → `AppStartupGate` (startup async) → `MyApp` → routeur GoRouter ; la logique métier de séquence est concentrée dans l’orchestrateur et les providers de startup associés (`app_startup_provider.dart`, non détaillé ligne à ligne ici).

**Variable d’environnement** : `MOVI_INITIAL_ROUTE` peut surcharger la route initiale du routeur (`AppRoutePaths.launch` par défaut).

---

### 3.3 Zones monolithiques ou surdimensionnées (2.2.3)

Indicateur utilisé : **nombre de lignes** (approximatif, fichier `.dart` sous `lib/`, hors jugement de qualité intrinsèque). Les très gros fichiers **générés / l10n** sont signalés à part.

#### Code applicatif (priorité maintenabilité / phase 6)

| Lignes (ordre de grandeur) | Fichier | Commentaire |
|----------------------------|---------|-------------|
| ~2970 | `lib/src/features/tv/presentation/pages/tv_detail_page.dart` | Page détail très large |
| ~2340 | `lib/src/features/home/presentation/widgets/home_hero_carousel.dart` | Widget home très large |
| ~1570 | `lib/src/features/settings/presentation/pages/settings_page.dart` | Paramètres agrégés |
| ~1560 | `lib/src/features/library/presentation/pages/library_playlist_detail_page.dart` | Détail playlist |
| ~1470 | `lib/src/features/player/presentation/pages/video_player_page.dart` | Lecteur (déjà cité plan v3) |
| ~1400 | `lib/src/features/tv/presentation/providers/tv_detail_providers.dart` | Providers TV denses |
| ~1340 | `lib/src/features/movie/presentation/pages/movie_detail_page.dart` | Page film (plan v3) |
| ~1130 | `lib/src/features/search/presentation/pages/search_page.dart` | Recherche |
| ~1125 | `lib/src/core/startup/app_launch_orchestrator.dart` | Orchestration centrale (plan v3) |

#### Localisation (volume élevé, nature différente)

| Lignes (ordre de grandeur) | Fichier |
|----------------------------|---------|
| ~2550 | `lib/l10n/app_localizations.dart` |
| ~2080 | `lib/l10n/app_localizations_zh.dart` |
| multiples ~1050–1100 | autres `app_localizations_*.dart` |

Ces fichiers reflètent surtout la **surface de traduction** ; le risque est davantage outillage / revue que logique métier dans un seul fichier manuel.

**Aucun refactor** n’est prescrit ici : il s’agit d’un **registre de risque** pour la phase 6 du plan directeur.

---

## 4. Hypothèses et limites de la baseline

Cette section matérialise l’exigence **plan v3 §1.4** (*Hypothèses minimales prudentes*) et l’aligne sur **`docs/rules_nasa.md`** (principe : absence de preuve suffisante ⇒ état **non validé** ; toute réduction de contrôle ⇒ **dérogation formelle** §26).

### 4.1 Principes directeurs (plan v3 §1.4)

Tant que la preuve n’est pas complète sur l’ensemble du périmètre du programme (dépôt racine, CI, release, etc.), la stratégie retient par défaut :

1. **Exposition élevée aux régressions structurelles** — toute modification large est traitée comme à risque jusqu’à preuve de non-régression adaptée à la criticité.
2. **Niveau de contrôle renforcé** — revue, tests et quality gates attendus au niveau C/L du composant, sans assouplissement implicite.
3. **Absence de preuve = non validé** — une affirmation sur l’état du système (sécurité, architecture, comportement) n’est pas considérée comme établie sans artefact ou mesure opposable.
4. **Toute réduction de contrôle = dérogation formelle** — règle contournée, justification, risque accepté, périmètre, responsable, date d’expiration, plan de retour en conformité (`rules_nasa.md` §26).

### 4.2 Limites de ce document (`current_state.md`)

| Limite | Conséquence |
|--------|-------------|
| Photographie **structurelle** (arborescence + lecture de `lib/`) | Ne constitue **pas** une analyse automatique du graphe d’imports, des cycles, ni une preuve de respect des règles d’architecture cibles du plan v3 §4.3. |
| Comptage de lignes pour les « monolithes » | Indicateur **grossier** ; pas de seuil officiel de complexité cyclomatique ni de politique statique exécutée ici. |
| Date de l’export `repo_tree_2026-04-02.txt` | Instantané ; le dépôt peut diverger immédiatement après ; toute décision critique doit s’appuyer sur un **nouvel export** ou un SHA Git documenté. |
| `integration_test/` absent à la racine | Aucune preuve E2E n’est inférée depuis cet état documentaire. |
| Exclusion de `output/` du fichier arbre (§2.1.2) | Si `output/` devient une source de vérité, le périmètre doit être **révisé** explicitement. |

### 4.3 Lacunes de preuve déjà référencées ailleurs

Sans dupliquer tout le détail : le document [`02_qualification_entrees_documentaires_phase_0.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/02_qualification_entrees_documentaires_phase_0.md) et [`change_logbook.md`](../traceability/change_logbook.md) (section *Lacunes déjà visibles*) consignent notamment :

- absence de **corpus incidents / anomalies / postmortems** exploitable dans le dépôt ;
- absence de **`README.md` / `CHANGELOG.md`** à la racine au moment de la qualification ;
- **index de preuves** `docs/quality/validation_evidence_index.md` non encore initialisé.

Ces points restent des **dettes de preuve** jusqu’à traitement en phase 0 (étapes ultérieures) ou dérogation.

### 4.4 Hypothèses de travail pour la suite du programme

- Les zones **L1 / L2** du plan v3 §1.3 restent des **présomptions** tant que `docs/risk/component_criticality.md` n’est pas produit et approuvé (étape roadmap ultérieure).
- Le **gel** et les règles de merge pendant la phase 0 restent celles de [`01_decision_de_gel_phase_0.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/01_decision_de_gel_phase_0.md), sauf décision contraire tracée.

### 4.5 Évolution de ce fichier

Tout changement de périmètre photographié, d’exclusion ou de conclusion sur l’état courant doit :

- mettre à jour les sections concernées ;
- ajouter ou pointer vers une entrée dans [`change_logbook.md`](../traceability/change_logbook.md) ;
- produire une **dérogation** si l’on réduit un contrôle ou une exigence du référentiel sans la compenser.
