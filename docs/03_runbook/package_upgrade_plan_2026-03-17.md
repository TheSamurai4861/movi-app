# Plan d'upgrade des packages du 17 mars 2026

## But

Ce document operationalise le `Lot 1.3. Segmentation des mises a jour de packages`.

Il decoupe les upgrades en vagues courtes et testables afin de :

- limiter les regressions ;
- eviter les migrations trop larges ;
- traiter separement les packages compatibles et les packages a risque ;
- garder une trace claire de l'ordre de travail.

Documents sources :

- [pubspec_audit_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/pubspec_audit_2026-03-17.md)
- [roadmap.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/roadmap.md)

Contexte observe au 17 mars 2026 :

- Flutter `3.38.5`
- Dart `3.10.4`
- dependances mortes deja retirees du `pubspec`

---

## Principe de segmentation

Les upgrades ne doivent pas etre traites comme un seul lot.

Ils sont separes en 4 categories :

1. upgrades compatibles et a faible risque ;
2. upgrades majeurs avec impact API probable ;
3. upgrades majors avec impact multi-plateforme probable ;
4. dette transitive a surveiller mais non prioritaire.

---

## Vague A. Upgrades compatibles a faible risque

### Objectif

Mettre a niveau les packages qui ont une version resolvable plus recente sans ouvrir un chantier de migration lourd.

### Packages inclus

- `dio` : `5.9.0` -> `5.9.2`
- `equatable` : `2.0.7` -> `2.0.8`
- `flutter_riverpod` : `3.0.3` -> `3.3.1`
- `flutter_svg` : `2.2.2` -> `2.2.4`
- `get_it` : `9.0.5` -> `9.2.1`
- `media_kit` : `1.2.2` -> `1.2.6`
- `media_kit_video` : `2.0.0` -> `2.0.1`
- `sqflite_common_ffi` : `2.3.6` -> `2.4.0+2`

### Pourquoi cette vague est raisonnable

- les versions resolvables sont plus recentes sans imposer de saut majeur ;
- ces packages ont tous un usage concret dans le projet ;
- cette vague permet de reduire une partie du retard sans reouvrir tout le socle.

### Commande de travail suggeree

Approche prudente :

```bash
flutter pub upgrade dio equatable flutter_riverpod flutter_svg get_it media_kit media_kit_video sqflite_common_ffi
```

### Validation minimale

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- build Windows debug
- lancement Android debug si possible

### Risque

- faible a modere

### Decision

- cette vague est la prochaine candidate naturelle a l'execution

---

## Vague B. Upgrades majeurs avec impact API probable

### Objectif

Isoler les packages qui peuvent demander des adaptations de code ou des changements de conventions.

### Packages inclus

- `go_router` : `16.3.0` -> `17.1.0`
- `google_fonts` : `6.3.2` -> `8.0.2`
- `flutter_lints` : `5.0.0` -> `6.0.0`

### Raisons de prudence

- `go_router` peut impacter la navigation, les redirections et certains comportements de route ;
- `google_fonts` peut modifier des conventions ou des comportements autour du chargement et des API ;
- `flutter_lints` peut faire apparaitre un nouveau lot de warnings ou d'infos bloquants pour le workflow.

### Strategie recommandee

Ne pas traiter ces packages ensemble.

Ordre recommande :

1. `flutter_lints`
2. `go_router`
3. `google_fonts`

### Validation minimale

- `flutter analyze`
- verification des routes principales
- verification du bootstrap visuel et des fonts

### Risque

- modere a fort

---

## Vague C. Upgrades majeurs avec impact multi-plateforme probable

### Objectif

Traiter separement les plugins qui touchent le stockage securise ou le controle systeme.

### Packages inclus

- `flutter_secure_storage` : `9.2.4` -> `10.0.0`
- `screen_brightness` : `0.2.2+1` -> `2.1.7`
- `volume_controller` : `2.0.8` -> `3.4.3`

### Raisons de prudence

- ces packages touchent des comportements dependants de la plateforme ;
- ils peuvent changer des APIs, options de configuration, implementations natives ou comportements runtime ;
- ils meritent des tests reels sur les plateformes conservees par le projet.

### Strategie recommandee

Ne pas les upgrader avant la decision officielle sur les plateformes supportees.

Ordre recommande apres decision de perimetre :

1. `flutter_secure_storage`
2. `screen_brightness`
3. `volume_controller`

### Validation minimale

- lecture / ecriture secure storage
- comportement player sur luminosite
- comportement player sur volume
- verification Windows
- verification Android
- verification iOS si la plateforme est maintenue

### Risque

- fort

---

## Vague D. Dette transitive et veille technique

### Objectif

Suivre ce qui merite surveillance sans l'inclure immediatement dans un lot de travail.

### Points a surveiller

- `js` est signale comme package discontinue ;
- plusieurs dependances transitives sont anciennes ;
- certaines transitive upgrades suivront automatiquement les vagues A, B et C ;
- les plugins de plateforme pourront faire evoluer les registrants et les exigences natives.

### Decision

Ne pas traiter la dette transitive maintenant comme un chantier autonome.

La reevaluer :

- apres la vague A ;
- apres la decision de plateformes ;
- apres la vague C.

---

## Ordre d'execution recommande

1. executer la Vague A
2. auditer `analysis_options.yaml`
3. trancher les plateformes supportees
4. executer `flutter_lints`
5. executer `go_router`
6. executer `google_fonts`
7. executer `flutter_secure_storage`
8. executer `screen_brightness`
9. executer `volume_controller`

Cet ordre evite de migrer des plugins multiplateformes avant d'avoir defini le perimetre produit reel.

---

## Politique de validation par vague

Chaque vague doit etre fermee avant la suivante.

Definition de fini minimale pour une vague :

- `pubspec.yaml` propre et coherent ;
- `pubspec.lock` regenere ;
- `flutter analyze` execute ;
- `flutter test` execute ;
- au moins un build de reference execute ;
- les ecarts constates sont notes dans la doc.

---

## Decision de ce lot

Le `Lot 1.3` est considere realise quand :

- la segmentation des upgrades est documentee ;
- les packages sont classes par niveau de risque ;
- l'ordre de traitement est fixe ;
- aucun upgrade majeur n'est lance sans cadrage prealable.

Ce lot est donc un lot de cadrage technique, pas encore un lot de migration de code.
