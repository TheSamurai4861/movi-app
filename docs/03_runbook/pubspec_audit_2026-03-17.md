# Audit de `pubspec.yaml` du 17 mars 2026

## Scope

Ce document analyse rigoureusement le fichier `pubspec.yaml` du projet `Movi`.

Il sert de base de travail pour une future roadmap de modernisation.

L'analyse s'appuie sur :

- le contenu actuel de `pubspec.yaml` ;
- l'usage reel des dependances dans le code du projet ;
- les plateformes presentes dans le depot ;
- les versions detectees via `flutter pub outdated` ;
- la documentation officielle Flutter et les pages officielles des packages sur `pub.dev`.

Date de l'analyse :

- 17 mars 2026

Contexte technique observe :

- Flutter `3.38.5`
- Dart `3.10.4`

---

## Synthese executive

Le `pubspec.yaml` est globalement fonctionnel, mais il n'est pas encore au niveau d'un projet Flutter "pro" sur quatre points importants :

1. plusieurs dependances directes semblent inutiles ou residuelles ;
2. certaines dependances sont vieillissantes ou bloquees sur des branches anciennes ;
3. la partie metadata et gouvernance du projet est trop generique ;
4. la gestion des assets et des icones melange encore des responsabilites distinctes.

Le point le plus rentable a court terme est le nettoyage des dependances directes inutilisees, car il reduira :

- le bruit technique ;
- les plugins embarques inutilement ;
- la maintenance multi-plateforme implicite ;
- la complexite du futur travail de mise a jour.

---

## Snapshot actuel du `pubspec.yaml`

Points positifs observes :

- `publish_to: "none"` est coherent pour une application non publiee sur `pub.dev`.
- l'activation `flutter.generate: true` est coherente avec l'usage de `flutter_localizations`.
- la declaration des assets est simple et facile a lire.
- `flutter_launcher_icons` est configure pour Android et iOS.
- la version applicative `1.0.1+4` existe deja et peut servir de point de depart a une vraie strategie de versioning.

Points faibles observes :

- `description: "A new Flutter project."` est une valeur par defaut non professionnelle.
- le fichier ne declare pas de contrainte Flutter explicite, seulement une contrainte Dart.
- plusieurs dependances directes n'ont pas d'usage Dart detecte dans le projet.
- les dependances directes melangent besoins reels, essais anciens et restes de plugins desktop.

---

## Constat 1. Metadata trop generique

### Observation

Le projet conserve encore une description de template :

```yaml
description: "A new Flutter project."
```

### Impact

Ce point ne casse rien techniquement, mais il signale que le socle n'a pas encore ete professionnalise.

Dans un projet mature, la metadata doit aider a comprendre :

- ce qu'est l'application ;
- son perimetre ;
- son positionnement dans l'ecosysteme du depot.

### Recommandation

Remplacer la description par une phrase courte, precise et stable.

Exemple de direction :

```yaml
description: "Application Flutter de streaming et de gestion de bibliotheque media."
```

Priorite :

- faible

---

## Constat 2. Dependances directes inutilisees ou tres suspectes

### Conclusion

Les dependances suivantes sont les meilleurs candidats a suppression ou a verification immediate.

### Tableau d'audit

| Package | Usage Dart observe | Statut recommande | Commentaire |
| --- | --- | --- | --- |
| `path_provider_platform_interface` | aucun | supprimer | dependance de bas niveau non importee par le projet |
| `pool` | aucun | supprimer | aucun usage detecte dans `lib/`, `tool/`, `scripts/` |
| `pip` | aucun | supprimer | le projet gere deja le PiP via `MethodChannel` natif |
| `desktop_multi_window` | aucun usage Dart | supprimer ou justifier | present seulement dans les registrants generes desktop |
| `window_manager` | aucun usage Dart | supprimer ou justifier | present seulement dans les registrants generes desktop |
| `platform` | aucun | supprimer | aucun import `package:platform`, le code utilise deja `dart:io` et `defaultTargetPlatform` |

### Preuves locales

- `pip` n'est pas utilise, alors que le projet implemente deja son propre service natif dans `lib/src/features/player/data/services/native_pip_service.dart`.
- `desktop_multi_window` et `window_manager` n'apparaissent que dans les fichiers generes de plateformes desktop, ce qui est typique d'un plugin encore declare mais non consomme dans le code applicatif.
- `path_provider_platform_interface`, `pool` et `platform` n'ont aucun import Dart detecte.

### Risque

Conserver des dependances inutilisees dans `pubspec.yaml` :

- augmente la surface de maintenance ;
- rajoute des plugins natifs generes ;
- brouille l'intention architecturale ;
- complique les futures migrations de versions.

### Recommandation

Traiter cette liste avant toute grosse vague de mise a jour.

Ordre suggere :

1. supprimer `pip`
2. supprimer `platform`
3. supprimer `pool`
4. supprimer `path_provider_platform_interface`
5. verifier puis supprimer `desktop_multi_window`
6. verifier puis supprimer `window_manager`

Priorite :

- forte

---

## Constat 3. Une dependance legacy a isoler : `state_notifier`

### Observation

`state_notifier` est encore utilise, mais de maniere tres limitee :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`

Le projet importe aussi `flutter_riverpod/legacy.dart` pour `StateNotifierProvider`.

### Analyse

Ce n'est pas une dependance inutile aujourd'hui, mais c'est une dependance legacy dans un projet deja centre sur Riverpod 3.

Cela cree un signal de dette technique :

- une partie du state management suit encore un ancien modele ;
- le futur nettoyage du code devra probablement aligner ce segment sur les primitives Riverpod modernes.

### Recommandation

Ne pas supprimer `state_notifier` tout de suite.

Le bon traitement est :

1. isoler les usages exacts ;
2. decider si la migration vers `Notifier` ou `AsyncNotifier` est souhaitable ;
3. supprimer `state_notifier` seulement apres migration.

Priorite :

- moyenne

---

## Constat 4. Les mises a jour de dependances sont reelles, mais doivent etre decoupees

### Verification effectuee

La commande `flutter pub outdated` a confirme que plusieurs dependances directes sont en retard, avec deux cas distincts :

- mises a jour compatibles dans la branche actuelle ;
- nouvelles versions majeures qui impliquent une verification de compatibilite.

### Dependances avec mises a jour compatibles interessantes

Ces packages peuvent etre candidats a une vague de mise a jour "safe" apres nettoyage :

- `dio`
- `equatable`
- `flutter_riverpod`
- `flutter_svg`
- `get_it`
- `media_kit`
- `media_kit_video`
- `sqflite_common_ffi`

### Dependances a traiter avec prudence

Ces packages ont une nouvelle branche resolvable ou latest plus importante et meritent une analyse dediee avant upgrade :

- `flutter_secure_storage`
- `go_router`
- `google_fonts`
- `screen_brightness`
- `volume_controller`
- `window_manager`
- `desktop_multi_window`
- `flutter_lints`

### Lecture a retenir

Le projet n'a pas un probleme unique de "packages trop vieux".

Il a en realite trois chantiers differents :

1. suppression des dependances mortes ;
2. upgrades compatibles a faible risque ;
3. migrations majeures a risque fonctionnel ou multi-plateforme.

### Recommandation

Pour la future roadmap, ne pas melanger ces trois types de travaux dans une seule tache.

Priorite :

- forte

---

## Constat 5. `media_kit_libs_video` doit probablement etre conserve

### Observation

Le package `media_kit_libs_video` n'est pas importe directement dans le code Dart.

### Analyse

Ce point pourrait faire croire a une dependance inutile, mais la documentation officielle du package indique qu'il fournit les dependances natives pour `media_kit_video`.

Le fait qu'il n'apparaisse pas dans les imports Dart n'est donc pas un signal suffisant pour le supprimer.

### Recommandation

Conserver `media_kit_libs_video` tant que la stack player repose sur `media_kit_video`.

Si un nettoyage est entrepris, cette dependance ne doit etre retiree qu'apres verification explicite du mode d'installation recommande par la documentation officielle de `media_kit`.

Priorite :

- faible

---

## Constat 6. La strategie plateformes/plugins est plus large que l'usage confirme

### Observation

Le `pubspec.yaml` declare plusieurs plugins qui embarquent des integrations multi-plateformes :

- `flutter_secure_storage`
- `screen_brightness`
- `volume_controller`
- `media_kit`
- `media_kit_video`
- `desktop_multi_window`
- `window_manager`

Le depot contient aussi :

- `android/`
- `ios/`
- `windows/`
- `macos/`
- `linux/`
- `web/`

### Analyse

Le `pubspec.yaml` doit refleter les plateformes officiellement supportees, pas seulement celles qui existent encore par heritage Flutter.

Dans l'etat actuel :

- Android est clairement cible ;
- Windows est clairement utilise dans la documentation ;
- iOS semble envisage ;
- Linux, macOS et Web restent plus ambigus au niveau du besoin produit reel.

Conserver des plugins desktop non utilises entretient une maintenance invisible sur Windows, Linux et macOS.

### Recommandation

Avant de stabiliser le `pubspec`, acter une liste de plateformes supportees officiellement.

Ensuite :

- supprimer les plugins sans usage sur les plateformes non retenues ;
- garder les plugins multiplateformes strictement necessaires au produit ;
- documenter les exceptions volontaires.

Priorite :

- forte

---

## Constat 7. Gestion des icones et assets encore melangee

### Observation

Le `pubspec.yaml` declare :

```yaml
flutter:
  assets:
    - assets/icons/
```

et :

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/icons/app_icon.png
```

Le fichier `assets/icons/app_icon.png` existe bien et a une taille de `1024 x 1024`, ce qui est correct pour un asset source de launcher icon.

### Analyse

Le point faible n'est pas le format du fichier source, mais l'organisation.

Le dossier `assets/icons/` melange actuellement :

- l'icone source du launcher ;
- des icones UI raster ;
- des icones UI en `svg`.

Pour un projet pro, il est preferable de distinguer :

- les assets utilises dans l'application ;
- les assets utilises pour le packaging de l'application.

### Recommandation

A terme, separer :

- `assets/icons/` pour les icones UI ;
- `assets/branding/` ou `assets/app_icons/` pour les icones d'application et variantes de marque.

Ce changement n'est pas urgent techniquement, mais il est utile pour garder un depot lisible.

Priorite :

- moyenne

---

## Constat 8. Contrainte SDK Dart declaree, contrainte Flutter non explicite

### Observation

Le fichier declare :

```yaml
environment:
  sdk: ^3.9.2
```

L'environnement local utilise pourtant :

- Flutter `3.38.5`
- Dart `3.10.4`

### Analyse

La contrainte Dart est valide, mais elle ne fixe pas explicitement un minimum Flutter.

Dans une application d'equipe, ajouter une contrainte Flutter explicite peut ameliorer :

- la reproductibilite ;
- la comprehension des prerequis ;
- la coherence CI / local / release.

### Recommandation

Etudier l'ajout d'une contrainte Flutter minimale si l'equipe veut verrouiller davantage son environnement.

Exemple de direction a discuter :

```yaml
environment:
  sdk: ^3.9.2
  flutter: ">=3.38.0"
```

Ce point est une recommandation de gouvernance, pas une correction urgente.

Priorite :

- moyenne

---

## Constat 9. Icones de lancement configurees seulement pour Android et iOS

### Observation

`flutter_launcher_icons` est configure pour :

- Android
- iOS

Alors que le projet contient aussi des cibles desktop et web.

### Analyse

Ce n'est pas forcement un probleme.

En revanche, il faut que ce soit un choix explicite :

- soit Android/iOS sont les seules plateformes ou l'icone est geree par ce workflow ;
- soit le projet a besoin d'une strategie d'icones plus large pour desktop et web.

### Recommandation

Documenter la strategie de branding par plateforme :

- launcher mobile ;
- icone Windows ;
- icone web ;
- icones macOS si la plateforme est retenue.

Priorite :

- faible a moyenne

---

## Dependances a conserver sans reserve immediate

Ces dependances ont un usage clair ou une raison d'etre visible dans le code :

- `equatable`
- `flutter`
- `flutter_localizations`
- `intl`
- `flutter_riverpod`
- `get_it`
- `go_router`
- `dio`
- `supabase_flutter`
- `google_fonts`
- `sqflite`
- `path`
- `path_provider`
- `sqflite_common_ffi`
- `flutter_secure_storage`
- `encrypt`
- `clock`
- `flutter_svg`
- `media_kit`
- `media_kit_video`
- `media_kit_libs_video`
- `screen_brightness`
- `volume_controller`

Remarque :

Les conserver "sans reserve immediate" ne signifie pas qu'ils ne devront jamais etre reevalues.
Cela signifie simplement qu'un usage concret a ete observe.

---

## Recommandations structurees pour la future roadmap

### Lot 1. Nettoyage du `pubspec`

Objectif :

- retirer les dependances manifestement inutiles.

Packages candidats :

- `pip`
- `platform`
- `pool`
- `path_provider_platform_interface`

Puis audit de confirmation :

- `desktop_multi_window`
- `window_manager`

### Lot 2. Rationalisation du state management

Objectif :

- evaluer la sortie de `state_notifier` legacy.

Packages concernes :

- `state_notifier`
- usage `flutter_riverpod/legacy.dart`

### Lot 3. Vague d'upgrades compatibles

Objectif :

- moderniser les versions sans ouvrir un chantier trop risqu.

Cibles naturelles :

- `dio`
- `equatable`
- `flutter_riverpod`
- `flutter_svg`
- `get_it`
- `media_kit`
- `media_kit_video`
- `sqflite_common_ffi`

### Lot 4. Migrations majeures a cadrer

Objectif :

- traiter separement les packages a fort risque de compatibilite.

Cibles :

- `flutter_secure_storage`
- `go_router`
- `google_fonts`
- `screen_brightness`
- `volume_controller`
- `flutter_lints`

### Lot 5. Gouvernance et lisibilite

Objectif :

- rendre le `pubspec.yaml` plus professionnel et plus explicite.

Actions candidates :

- reecrire `description`
- decider d'une contrainte Flutter minimale
- documenter la politique de plateformes supportees
- separer branding et icones UI dans les assets

---

## Sources officielles consultees

- Flutter docs, `pubspec.yaml` :
  https://docs.flutter.dev/tools/pubspec
- `media_kit_video` :
  https://pub.dev/packages/media_kit_video
- `media_kit_libs_video` :
  https://pub.dev/packages/media_kit_libs_video
- `flutter_secure_storage` :
  https://pub.dev/packages/flutter_secure_storage
- `screen_brightness` :
  https://pub.dev/packages/screen_brightness
- `volume_controller` :
  https://pub.dev/packages/volume_controller
- `window_manager` :
  https://pub.dev/packages/window_manager
- `desktop_multi_window` :
  https://pub.dev/packages/desktop_multi_window
- `flutter_launcher_icons` :
  https://pub.dev/packages/flutter_launcher_icons
- `path_provider_platform_interface` :
  https://pub.dev/packages/path_provider_platform_interface

---

## Statut final de cette analyse

Le `pubspec.yaml` est exploitable, mais il n'est pas encore nettoye ni suffisamment gouverne pour servir de socle durable a un projet Flutter pro.

Le meilleur prochain pas n'est pas un upgrade massif.

Le meilleur prochain pas est :

1. nettoyer les dependances residuelles ;
2. confirmer les plateformes supportees ;
3. decouper les mises a jour par niveau de risque ;
4. seulement ensuite lancer les migrations de versions.

---

## Mise a jour apres execution du lot 1.2

Date :

- 17 mars 2026

Actions realisees :

- remplacement de la description generique par une description produit explicite ;
- ajout d'une contrainte Flutter minimale dans `environment` ;
- verification du statut de la version `1.0.1+4`.

Etat obtenu :

- `description` n'est plus une valeur de template ;
- `environment` declare maintenant un minimum Flutter aligne sur l'environnement valide localement ;
- la version `1.0.1+4` est conservee comme identifiant applicatif courant au format Flutter standard `build-name+build-number`.

Conclusion sur le versioning :

- il existe bien une version applicative exploitable dans `pubspec.yaml` ;
- cette version est correctement relayee vers Android via `flutter.versionName` et `flutter.versionCode` ;
- cette version est aussi prise en charge cote Apple via les variables Flutter de build ;
- en revanche, aucune strategie de versioning formelle n'est encore documentee dans le projet.

Interpretation retenue :

- `1.0.1+4` doit etre traitee comme la version courante du produit ;
- elle ne prouve pas a elle seule l'existence d'une politique de versioning formalisee ;
- une future roadmap devra definir explicitement les regles d'incrementation de version et de build.
