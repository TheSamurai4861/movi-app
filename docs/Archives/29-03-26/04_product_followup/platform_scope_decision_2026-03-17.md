# Decision de perimetre plateformes du 17 mars 2026

## But

Ce document realise le `Lot 3.1. Decision de perimetre`.

Il fixe une recommandation claire sur le statut des plateformes presentes dans le depot, afin de guider :

- la maintenance des dossiers natifs ;
- le choix des plugins ;
- la CI ;
- les futurs nettoyages de perimetre.

Date :

- 17 mars 2026

---

## Synthese

Recommandation de perimetre au 17 mars 2026 :

- `android` : supporte officiellement
- `windows` : supporte officiellement pour le developpement local
- `ios` : supporte conditionnellement
- `macos` : non supporte officiellement a ce stade
- `linux` : non supporte officiellement a ce stade
- `web` : non supporte officiellement a ce stade

Cette recommandation ne dit pas que `macos`, `linux` et `web` sont impossibles techniquement.

Elle dit simplement qu'il n'y a pas assez d'indices projet pour les maintenir comme cibles officielles sans creer de dette implicite.

---

## Base de decision

### Android

Indices forts :

- presence de flavors dans [android/app/build.gradle.kts](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/app/build.gradle.kts)
- documentation de signature Android :
  - [android/SIGNING_SETUP.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/SIGNING_SETUP.md)
  - [android/PLAY_CONSOLE_CHECKLIST.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/PLAY_CONSOLE_CHECKLIST.md)
- commandes de build Android documentees dans :
  - [commands.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/commands.md)
  - [README.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/README.md)
- code natif Android specifique pour le PiP dans [MainActivity.kt](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/android/app/src/main/kotlin/com/matteo/movi/MainActivity.kt)

Decision :

- Android est une plateforme officielle du produit

### Windows

Indices forts :

- la documentation recommande explicitement `flutter run -d windows --dart-define-from-file=.env`
- le quick start prend Windows comme base locale visible du projet
- le projet utilise `sqflite_common_ffi` pour le desktop Windows/Linux
- le build Windows a deja ete valide localement pendant le chantier

Decision :

- Windows est une plateforme officielle au moins pour le developpement local et les validations desktop

### iOS

Indices moyens a forts :

- presence d'un workflow CI iOS dans [codemagic.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/codemagic.yaml)
- commandes `flutter build ipa` documentees dans [commands.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/commands.md)
- code natif iOS specifique pour le PiP dans [AppDelegate.swift](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/ios/Runner/AppDelegate.swift)

Limites :

- la documentation presente surtout iOS comme une cible de CI ou de machine macOS configuree ;
- iOS n'apparait pas comme la base de developpement locale recommandee.

Decision :

- iOS doit etre traite comme plateforme supportee conditionnellement
- autrement dit : perimetre reel, mais secondaire par rapport a Android et Windows

### macOS

Indices faibles :

- dossier plateforme present
- configuration Flutter standard presente

Limites :

- aucun workflow CI dedie
- aucune commande de lancement ou de build mise en avant
- aucun besoin produit explicite dans la documentation

Decision :

- macOS ne doit pas etre considere comme support officiel a ce stade

### Linux

Indices faibles :

- dossier plateforme present
- support technique indirect via `sqflite_common_ffi`

Limites :

- aucune commande de lancement ou de build documentee
- aucun workflow CI dedie
- aucune priorite fonctionnelle visible dans la doc

Decision :

- Linux ne doit pas etre considere comme support officiel a ce stade

### Web

Indices faibles :

- quelques traces defensives `kIsWeb` ou `web-safe` visibles dans le code

Limites :

- aucune commande web documentee
- aucune CI web
- aucun packaging ou verification fonctionnelle web documentes
- plusieurs briques du projet sont surtout pensees mobile/desktop

Decision :

- Web ne doit pas etre considere comme support officiel a ce stade

---

## Statut recommande par plateforme

| Plateforme | Statut recommande | Justification courte |
| --- | --- | --- |
| Android | officielle | build, release, signature et code natif explicites |
| Windows | officielle | cible locale de developpement clairement documentee |
| iOS | supportee conditionnellement | workflow CI et code natif reels, mais cible secondaire |
| macOS | non officielle | aucun workflow ni maintenance projet retenus |
| Linux | non officielle | aucun workflow ni usage produit retenus |
| Web | non officielle | aucune maintenance ni support explicite retenus |

---

## Consequences recommandees

### Court terme

- garder `android/`, `windows/` et `ios/`
- ne pas presenter `macos/`, `linux/` ou `web/` comme cibles supportees dans la doc
- mettre a jour la documentation pour expliciter ce statut

### Moyen terme

- reevaluer `macos/`, `linux/` et `web/` seulement si un besoin produit apparait
- si besoin, reintroduire ces plateformes via un lot explicite et verifier alors plugins et workflows

### CI et qualite

- conserver les checks adaptes a Android, Windows et iOS
- ne pas investir dans une CI macOS/Linux/Web tant que ces plateformes restent hors perimetre officiel

---

## Decision de travail pour la suite

Pour les prochains lots, il faut raisonner avec cette convention :

- plateformes officielles : `android`, `windows`
- plateforme supportee conditionnellement : `ios`
- plateformes hors perimetre officiel : `macos`, `linux`, `web`

Cette convention est suffisante pour lancer le `Lot 3.2. Rationalisation technique`.
