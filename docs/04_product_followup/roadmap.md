# Roadmap de modernisation

## But

Cette roadmap transforme les analyses deja realisees en plan d'execution progressif.

Elle vise a faire evoluer `Movi` vers un projet Flutter plus professionnel sur les axes suivants :

- lisibilite du depot ;
- hygiene des dependances ;
- clarte des plateformes supportees ;
- qualite du code ;
- robustesse des assets ;
- stabilite des tests et de la livraison.

Document source de cette roadmap :

- [modernization_plan.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/modernization_plan.md)

---

## Principes d'execution

Regles a suivre pendant toute la modernisation :

1. ne pas melanger nettoyage, upgrade et refactoring dans une seule tache ;
2. traiter d'abord ce qui reduit le bruit et les ambiguitees ;
3. verrouiller les plateformes supportees avant de stabiliser les plugins ;
4. faire des lots petits, testables et revertables ;
5. documenter toute decision qui change le perimetre du projet.

---

## Vue d'ensemble

Ordre recommande :

1. socle `pubspec` et dependances
2. gouvernance racine et hygiene du depot
3. perimetre plateformes
4. assets et branding
5. architecture applicative
6. tests et livraison

---

## Phase 1. Stabiliser `pubspec.yaml`

### Objectif

Rendre le socle du projet lisible, intentionnel et plus simple a maintenir.

### Lot 1.1. Nettoyage des dependances mortes

Actions :

- supprimer `pip`
- supprimer `platform`
- supprimer `pool`
- supprimer `path_provider_platform_interface`
- verifier l'usage reel de `desktop_multi_window`
- verifier l'usage reel de `window_manager`
- supprimer `desktop_multi_window` et `window_manager` s'ils ne correspondent a aucun besoin produit explicite

Resultat attendu :

- `pubspec.yaml` ne contient plus de package sans raison d'etre claire ;
- les registrants natifs generes sont simplifies ;
- la maintenance multi-plateforme implicite diminue.

Critere de validation :

- `flutter pub get` passe ;
- `flutter analyze` passe ;
- l'application demarre toujours sur les plateformes officiellement supportees.

Priorite :

- critique

### Lot 1.2. Clarification des metadata

Actions :

- remplacer la description generique du projet ;
- verifier si une contrainte Flutter minimale doit etre ajoutee dans `environment` ;
- confirmer si la version `1.0.1+4` suit une vraie strategie de versioning.

Resultat attendu :

- un `pubspec.yaml` qui ressemble a un vrai socle de projet et non a un template.

Priorite :

- moyenne

Livrable associe :

- [versioning_strategy.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/versioning_strategy.md)

### Lot 1.3. Segmentation des mises a jour de packages

Actions :

- creer une vague d'upgrade compatible a faible risque ;
- isoler les upgrades majeurs dans des lots separes ;
- ne pas lancer d'upgrade majeur avant nettoyage du `pubspec`.

Sous-lot "upgrade compatible" suggere :

- `dio`
- `equatable`
- `flutter_riverpod`
- `flutter_svg`
- `get_it`
- `google_fonts` pour le patch compatible `6.3.2 -> 6.3.3`
- `media_kit`
- `media_kit_video`
- `sqflite_common_ffi`

Sous-lot "upgrade majeur a cadrer" :

- `flutter_secure_storage`
- `go_router`
- `google_fonts` pour la migration majeure `6.x -> 8.x`
- `screen_brightness`
- `volume_controller`
- `flutter_lints`

Resultat attendu :

- une politique de mise a jour par niveau de risque ;
- moins de regressions liees a des migrations trop larges.

Priorite :

- forte

Livrable associe :

- [package_upgrade_plan_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/package_upgrade_plan_2026-03-17.md)

### Lot 1.4. Dette legacy Riverpod

Actions :

- isoler les usages de `state_notifier` ;
- evaluer la migration vers `Notifier` ou `AsyncNotifier` ;
- supprimer `flutter_riverpod/legacy.dart` si possible apres migration.

Resultat attendu :

- un state management plus coherent ;
- moins de mix entre ancien et nouveau modele.

Priorite :

- moyenne

---

## Phase 2. Assainir la racine du depot

### Objectif

Differencier clairement ce qui releve du produit, du local et du genere.

### Lot 2.1. Nettoyage des dossiers non produit

Actions :

- sortir `output/` du perimetre versionne si son contenu reste purement temporaire ;
- confirmer la politique de versionnement de `.cursor/` ;
- ignorer ou supprimer les artefacts locaux non indispensables ;
- verifier que `build/`, `.dart_tool/` et `.idea/` restent hors versionnement.

Resultat attendu :

- une racine plus lisible ;
- moins de bruit pour les futures analyses et revues.

Priorite :

- forte

### Lot 2.2. Gouvernance des fichiers racine

Actions :

- auditer `analysis_options.yaml`
- auditer `.gitignore`
- auditer `codemagic.yaml`
- auditer `l10n.yaml`
- auditer `devtools_options.yaml`

Resultat attendu :

- regles de lint plus solides ;
- depot mieux maitrise ;
- meilleure reproductibilite locale et CI.

Priorite :

- forte

---

## Phase 3. Acter les plateformes supportees

### Objectif

Faire correspondre le depot, les plugins et les workflows aux vraies plateformes du produit.

### Lot 3.1. Decision de perimetre

Actions :

- confirmer officiellement le statut de `android/`
- confirmer officiellement le statut de `windows/`
- confirmer officiellement le statut de `ios/`
- decider si `macos/`, `linux/` et `web/` sont supportes, experimentaux ou hors perimetre

Resultat attendu :

- une liste explicite de plateformes supportees.

Priorite :

- critique

Livrable associe :

- [platform_scope_decision_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/platform_scope_decision_2026-03-17.md)

### Lot 3.2. Rationalisation technique

Actions :

- supprimer les plateformes hors perimetre si elles ne sont pas maintenues ;
- verifier les plugins encore declares apres cette decision ;
- aligner noms d'application, permissions, branding et release config par plateforme.

Resultat attendu :

- moins de dette cachee cote natif ;
- un projet plus simple a maintenir.

Priorite :

- forte

---

## Phase 4. Normaliser `assets/`

### Objectif

Rendre la gestion des icones, images et fichiers graphiques plus propre et plus durable.

### Lot 4.1. Audit et tri

Actions :

- inventorier les fichiers sous `assets/`
- detecter les doublons ;
- detecter les assets non references ;
- verifier les formats ;
- verifier les poids et dimensions ;
- distinguer assets UI et assets de branding/app icon.

Resultat attendu :

- une vue propre de l'existant ;
- moins d'assets ambigus ou redondants.

Priorite :

- forte

### Lot 4.2. Reorganisation

Actions :

- separer les icones UI des icones de packaging ;
- normaliser le nommage ;
- documenter la convention de rangement ;
- aligner `pubspec.yaml` sur la nouvelle structure.

Structure cible indicative :

```text
assets/
  icons/
  images/
  illustrations/
  branding/
```

Resultat attendu :

- un dossier `assets/` plus lisible ;
- moins de confusion entre usage produit et packaging.

Priorite :

- moyenne

Livrable associe :

- [assets_reorganization_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/assets_reorganization_2026-03-17.md)

---

## Backlog ordonne a court terme

Ordre d'execution recommande pour commencer :

1. nettoyer les dependances mortes de `pubspec.yaml`
2. decider du sort de `desktop_multi_window` et `window_manager`
3. stabiliser metadata et politique d'upgrade du `pubspec`
4. auditer `analysis_options.yaml`
5. auditer `.gitignore`
6. auditer `codemagic.yaml`
7. trancher officiellement les plateformes supportees
8. nettoyer les dossiers racine non produit
9. auditer et reorganiser `assets/`

---

## Definition de fini

La roadmap pourra etre consideree comme correctement executee lorsque :

- `pubspec.yaml` ne contient plus de dependances residuelles ;
- les plateformes supportees sont explicites et alignees avec les plugins ;
- la racine du depot est nettoyee ;
- `assets/` est structure et documente ;
- la documentation est alignee avec l'etat reel du projet.

---

## Prochaine etape recommandee

Le prochain chantier a lancer est :

`Lot 1.1. Nettoyage des dependances mortes`

C'est le meilleur point d'entree car il simplifie la suite sans demander encore de gros refactorings applicatifs.
