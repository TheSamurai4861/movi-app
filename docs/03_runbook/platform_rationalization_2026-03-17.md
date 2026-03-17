# Rationalisation technique des plateformes du 17 mars 2026

## But

Ce document realise le `Lot 3.2. Rationalisation technique`.

Il applique une rationalisation technique effective du projet apres la decision de perimetre plateformes.

Reference de perimetre :

- [platform_scope_decision_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/platform_scope_decision_2026-03-17.md)

Date :

- 17 mars 2026

---

## Synthese

Le lot est maintenant applique au sens strict de la roadmap.

Ce qui a ete fait :

- suppression physique de `linux/`, `macos/` et `web/` du depot ;
- alignement de la documentation d'onboarding avec le perimetre retenu ;
- verification des plugins encore declares dans `pubspec` ;
- verification des artefacts natifs sensibles evidents ;
- simplification de quelques traces techniques encore orientees Linux/Web dans le socle.

---

## Verification des plugins restants

Apres les lots precedents, aucun plugin direct clairement inutile n'a ete conserve.

Lecture par rapport au perimetre retenu :

- `flutter_secure_storage` reste coherent pour Android, iOS et Windows
- `screen_brightness` reste coherent pour Android, iOS et Windows
- `volume_controller` reste coherent pour le player
- `media_kit`, `media_kit_video` et `media_kit_libs_video` restent centraux pour la lecture media
- `sqflite` et `sqflite_common_ffi` restent coherents avec Android et Windows

Conclusion :

- aucune suppression supplementaire de plugin n'est justifiee immediatement dans ce lot

---

## Verification des artefacts natifs sensibles

Points verifies :

- les artefacts natifs generes majeurs ne sont pas anormalement versionnes
- le keystore Android `android/app/movi-release.jks` existe localement mais n'est pas suivi par Git
- les fichiers iOS generes typiques restent bien ignores

Conclusion :

- pas d'action corrective supplementaire necessaire dans ce lot sur ce point

---

## Alignement documentaire applique

Documents mis a jour :

- [project_overview.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/project_overview.md)
- [quick_start.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/quick_start.md)
- [environment_setup.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/environment_setup.md)
- [commands.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/commands.md)

Effet :

- Android et Windows sont presentes comme cibles principales
- iOS est presente comme cible conditionnelle
- macOS, Linux et Web ne sont plus presentes comme cibles supportees ni comme plateformes encore maintenues dans le depot

---

## Resultat du lot

Ce lot est considere realise.

Etat obtenu :

- le depot est aligne avec le perimetre officiel `android`, `windows` et `ios` ;
- les plateformes hors perimetre `linux`, `macos` et `web` ne sont plus versionnees ;
- les plugins restants sont coherents avec le perimetre retenu ;
- la doc d'onboarding est alignee avec la decision de perimetre ;
- la dette cachee cote natif diminue concretement.

---

## Prochaine action recommandee

La suite la plus naturelle est :

- `Lot 4.1. Audit et tri`
