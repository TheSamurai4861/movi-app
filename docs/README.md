# Documentation `docs/`

## But

Ce dossier doit devenir la source de verite documentaire du projet `Movi`.

Il doit etre utile a deux publics :

- un humain qui doit installer, lancer, debugger, maintenir et faire evoluer le projet ;
- une IA qui doit comprendre rapidement le contexte, l'architecture, les conventions, les points sensibles et l'historique de travail.

Ce fichier definit la nouvelle architecture cible du dossier `docs/`.

---

## Objectifs du dossier

Le dossier `docs/` doit repondre a 4 besoins :

1. Comprendre le projet rapidement
2. Lancer le projet sans perdre de temps
3. Savoir comment travailler dedans sans casser l'architecture
4. Suivre les chantiers, decisions et problemes ouverts

Chaque document doit avoir un role clair.
On evite les notes temporaires, les brouillons perdus, les doublons et les fichiers "perso" sans contexte.

---

## Resume rapide du projet

Projet : `Movi`

Type :

- application Flutter
- navigation avec `go_router`
- state management avec `flutter_riverpod`
- DI avec `get_it`
- backend avec `supabase_flutter`
- stockage local avec `sqflite`
- lecture video avec `media_kit`

Structure code actuelle observee :

- `lib/main.dart` : point d'entree
- `lib/src/app.dart` : `MaterialApp.router`
- `lib/src/core/` : infrastructure transverse
- `lib/src/features/` : fonctionnalites produit
- `lib/src/shared/` : briques partagees
- `lib/l10n/` : localisation

Le projet semble utiliser des variables d'environnement via `--dart-define` et potentiellement `.env`.

---

## Commandes de base a documenter

Ces commandes doivent vivre ensuite dans une doc dediee, mais elles sont listees ici pour poser le socle.

Installation :

```bash
flutter pub get
```

Execution locale basique :

```bash
flutter run
```

Execution Windows avec fichier d'environnement :

```bash
flutter run -d windows --dart-define-from-file=.env
```

Execution flavor dev :

```bash
flutter run --flavor dev -t lib/main.dart --dart-define-from-file=.env
```

Execution flavor prod :

```bash
flutter run --profile --flavor prod -t lib/main.dart --dart-define-from-file=.env
```

Build Android prod :

```bash
flutter build appbundle --release --flavor prod -t lib/main.dart
```

Checks utiles :

```bash
flutter analyze
flutter test
```

Remarque :

- la doc finale devra preciser les cles attendues dans `.env` et les prerequis Flutter/SDK.

---

## Nouvelle architecture cible pour `docs/`

Le dossier doit etre organise par usage, pas par accumulation historique.

Arborescence cible :

```text
docs/
  README.md
  01_onboarding/
    project_overview.md
    quick_start.md
    environment_setup.md
    commands.md
  02_architecture/
    codebase_map.md
    app_flow.md
    state_management.md
    data_flow.md
    dependency_rules.md
    feature_inventory.md
  03_runbook/
    debug_guide.md
    build_release.md
    testing_strategy.md
    known_issues.md
  04_product_followup/
    roadmap.md
    changelog_internal.md
    backlog.md
    decisions.md
  05_ai_context/
    ai_project_brief.md
    ai_editing_rules.md
    ai_file_index.md
    ai_active_work.md
  archive/
```

---

## Detail de chaque zone

### `docs/README.md`

Role :

- page d'entree unique ;
- sommaire du dossier ;
- vue rapide du projet ;
- liens vers les documents importants.

Doit contenir :

- le but du projet ;
- la stack ;
- les liens vers `quick_start`, `codebase_map`, `commands`, `known_issues`, `ai_project_brief`.

### `docs/01_onboarding/`

Role :

- permettre a un humain ou a une IA de devenir operationnel vite.

Fichiers attendus :

- `project_overview.md`
  Resume fonctionnel du projet, objectifs, plateformes cibles, dependances externes, modules majeurs.
- `quick_start.md`
  Etapes minimales pour lancer le projet proprement.
- `environment_setup.md`
  Version Flutter/Dart, outils requis, `.env`, comptes externes, prerequis OS.
- `commands.md`
  Commandes validees et maintenues du projet.

### `docs/02_architecture/`

Role :

- expliquer comment le projet est structure et comment il faut raisonner dedans.

Fichiers attendus :

- `codebase_map.md`
  Cartographie de `lib/`, `test/`, `scripts/`, plateformes natives.
- `app_flow.md`
  Startup, auth, routing, chargement initial, lecture media.
- `state_management.md`
  Riverpod, GetIt, responsabilites, source de verite.
- `data_flow.md`
  Flux API, Supabase, stockage local, cache, mappers, sync.
- `dependency_rules.md`
  Regles d'import, couches, conventions, interdits.
- `feature_inventory.md`
  Liste des features avec leur responsabilite.

### `docs/03_runbook/`

Role :

- centraliser l'operationnel quotidien.

Fichiers attendus :

- `modernization_plan.md`
  Ordre d'analyse et marche a suivre pour professionnaliser le projet dossier par dossier.
- `pubspec_audit_2026-03-17.md`
  Analyse detaillee du `pubspec.yaml` servant de base a la roadmap de modernisation.
- `versioning_strategy.md`
  Regle explicite de versioning du projet, avec source de verite et politique d'incrementation.
- `package_upgrade_plan_2026-03-17.md`
  Plan d'upgrade des packages par vagues de risque pour eviter les migrations trop larges.
- `riverpod_legacy_audit_2026-03-17.md`
  Audit cible des usages legacy de Riverpod et strategie de sortie de `state_notifier`.
- `root_non_product_cleanup_2026-03-17.md`
  Tri des dossiers racine non produit et decisions de versionnement associees.
- `root_governance_audit_2026-03-17.md`
  Audit des fichiers racine de gouvernance avec corrections de base sur lints, CI et secrets locaux.
- `platform_rationalization_2026-03-17.md`
  Rationalisation non destructive des plateformes et alignement de la doc avec le perimetre retenu.
- `assets_audit_2026-03-17.md`
  Inventaire, references et candidats au tri du dossier `assets/`.
- `assets_reorganization_2026-03-17.md`
  Reorganisation appliquee du dossier `assets` avec separation branding / UI et nettoyage des references.
- `debug_guide.md`
  Comment diagnostiquer un bug, quels logs lire, ou chercher selon le symptome.
- `build_release.md`
  Build Android/iOS/desktop, signatures, flavors, CI.
- `testing_strategy.md`
  Ce qui doit etre teste, comment lancer les tests, priorites.
- `known_issues.md`
  Bugs connus, dette technique active, contournements.

### `docs/04_product_followup/`

Role :

- garder la trace du pilotage produit/tech sans polluer la doc de base.

Fichiers attendus :

- `roadmap.md`
  Chantiers prevus a moyen terme.
- `platform_scope_decision_2026-03-17.md`
  Decision recommandee sur les plateformes officiellement supportees par le projet.
- `changelog_internal.md`
  Historique lisible des changements importants.
- `backlog.md`
  Liste d'actions ouvertes, priorisees, nettoyee regulierement.
- `decisions.md`
  Journal des choix importants et de leurs raisons.

### `docs/05_ai_context/`

Role :

- donner a une IA un contexte compact, stable et exploitable.

Fichiers attendus :

- `ai_project_brief.md`
  Resume du projet en 1 page : but, stack, architecture, zones sensibles.
- `ai_editing_rules.md`
  Regles de contribution, conventions, points a ne pas casser.
- `ai_file_index.md`
  Fichiers importants par sujet : auth, startup, player, IPTV, settings, l10n.
- `ai_active_work.md`
  Chantiers en cours, hypotheses, pieges connus, zones a surveiller.

### `docs/archive/`

Role :

- recevoir les documents obsoletes ou les snapshots de refactor ;
- ne jamais servir de base active.

Regle :

- tout document archive doit avoir une date et une raison d'archivage.

---

## Standards de qualite pour tous les docs

Chaque document doit respecter ces regles :

- un titre clair ;
- une date de mise a jour ;
- un objectif explicite ;
- une structure stable ;
- des commandes testees quand il y a des commandes ;
- des chemins de fichiers reels quand on parle du code ;
- pas de note temporaire brute ;
- pas de duplication forte entre deux fichiers ;
- si un document devient obsolete, il est archive ou supprime.

Template minimal recommande :

```md
# Titre

## Objectif

## Contexte

## Contenu principal

## Commandes / references

## Points ouverts

## Derniere mise a jour
```

---

## Ce qu'une IA doit trouver en moins de 2 minutes

L'IA doit pouvoir comprendre rapidement :

- ce que fait le projet ;
- comment il demarre ;
- ou sont les couches critiques ;
- quelles sont les regles de contribution ;
- quelles commandes lancer ;
- quels fichiers sont centraux ;
- quels problemes sont deja connus.

Pour cela, les documents prioritaires a creer apres ce reset sont :

1. `docs/01_onboarding/quick_start.md`
2. `docs/02_architecture/codebase_map.md`
3. `docs/02_architecture/dependency_rules.md`
4. `docs/03_runbook/known_issues.md`
5. `docs/05_ai_context/ai_project_brief.md`

---

## Ordre recommande pour reconstruire la documentation

1. Creer l'onboarding minimum
2. Documenter l'architecture reelle du code
3. Ajouter les commandes et prerequis d'environnement
4. Ecrire le runbook debug/build/test
5. Ajouter le suivi projet et le contexte IA

---

## Etat cible attendu

Quand `docs/` sera reconstruit correctement :

- un nouveau developpeur pourra lancer l'app sans te demander les commandes ;
- une IA pourra comprendre la structure du projet sans parcourir tout `lib/` ;
- les regles d'architecture seront explicites ;
- les decisions et problemes ouverts seront centralises ;
- les notes temporaires n'encombreront plus la documentation active.

---

## Prochaine etape conseillee

Le meilleur enchainement maintenant est :

1. creer les sous-dossiers de cette architecture ;
2. remplir au moins `quick_start.md`, `commands.md`, `codebase_map.md` et `ai_project_brief.md` ;
3. utiliser `README.md` comme portail unique.

Ce fichier est la fondation.
La suite consiste a produire les documents cibles, pas a remettre des notes en vrac dans `docs/`.
