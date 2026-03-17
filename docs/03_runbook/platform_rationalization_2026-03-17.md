# Rationalisation technique des plateformes du 17 mars 2026

## But

Ce document realise le `Lot 3.2. Rationalisation technique`.

Il applique une rationalisation non destructive du projet apres la decision de perimetre plateformes.

Reference de perimetre :

- [platform_scope_decision_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/platform_scope_decision_2026-03-17.md)

Date :

- 17 mars 2026

---

## Synthese

Le lot a ete traite avec une approche prudente.

Ce qui a ete fait :

- alignement de la documentation d'onboarding avec le perimetre retenu ;
- verification des plugins encore declares dans `pubspec` ;
- verification des artefacts natifs sensibles evidents ;
- formalisation d'une strategie de maintenance par plateforme.

Ce qui n'a pas ete fait volontairement :

- suppression physique de `macos/`, `linux/` ou `web/`

Raison :

- cette suppression est irreversible a l'echelle du depot et depasse un simple ajustement de gouvernance ;
- le projet garde encore quelques compatibilites techniques passives sur ces plateformes ;
- une suppression nette doit idealement etre executee dans un lot explicite de reduction de perimetre.

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
- macOS, Linux et Web ne sont plus implicites comme cibles "naturellement supportees"

---

## Resultat du lot

Ce lot est considere realise dans une version non destructive.

Etat obtenu :

- le projet ne pretend plus supporter tacitement toutes les plateformes Flutter presentes dans le depot ;
- les plugins restants sont coherents avec le perimetre retenu ;
- la doc d'onboarding est alignee avec la decision de perimetre ;
- la suppression physique des plateformes hors perimetre est explicitement repoussee a un lot dedie si elle est confirmee.

---

## Prochaine action recommandee

Deux suites logiques sont possibles :

1. ouvrir un lot explicite de suppression technique de `macos/`, `linux/` et `web/` si vous voulez vraiment reduire le depot
2. passer a la `Phase 4. Normaliser assets`

Pour garder un bon rythme sans operation destructive, la suite la plus naturelle est :

- `Lot 4.1. Audit et tri`
