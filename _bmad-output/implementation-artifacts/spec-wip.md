---
title: 'Corriger la signature Android release Play'
type: 'bugfix'
created: '2026-04-03'
status: 'draft'
context: []
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** Google Play rejette le bundle Android parce que la signature release du projet ne pointe pas vers la cle d'upload attendue. L'etat courant confirme que `prodRelease` sort avec `Config: null`, que `devRelease` et `stageRelease` retombent sur la debug key, et que le certificat attendu par Play est celui de `android/upload_certificate.pem` avec le SHA1 `3A:40:0F:1B:1F:91:73:B6:D5:01:9A:DF:BD:31:40:C7:AE:C5:81:DC`.

**Approach:** Fiabiliser la resolution du keystore release pour la variante `prod`, interdire qu'un flux Play puisse continuer avec une signature debug ou absente, verifier que `prodRelease` expose bien l'empreinte attendue via `signingReport`, puis generer un bundle `prod` signe uniquement si cette verification passe.

## Boundaries & Constraints

**Always:** Utiliser uniquement la cle privee correspondant au certificat Play attendu; verifier l'empreinte de `prodRelease` avant toute generation de bundle; conserver le packaging Flutter release sur la sortie `prodRelease`; garder les secrets hors du code versionne et hors du compte-rendu final.

**Ask First:** Si aucun keystore prive present dans le workspace ne correspond a l'empreinte attendue; si les credentials locaux n'ouvrent pas le keystore cible ou si l'alias de signature attendu differe; si la correction impose de changer des secrets CI/CD ou des artefacts hors depot.

**Never:** Produire un bundle Play signe avec la debug key ou avec un keystore dont le SHA1 differe; masquer un `prodRelease` non signe par un fallback silencieux; modifier l'applicationId, les flavors ou le package Android sans besoin direct pour la signature.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| HAPPY_PATH | Le vrai keystore Play est present, accessible, et son certificat matche `android/upload_certificate.pem` | `prodRelease` affiche le SHA1 attendu dans `signingReport`, puis `flutter build appbundle --flavor prod --release` produit un AAB signe pret pour Play | N/A |
| WRONG_OR_MISSING_KEY | Le keystore cible est absent, invalide, non ouvrable, ou son empreinte ne matche pas le certificat Play attendu | La construction release Play s'arrete avant toute livraison et aucun bundle Play valide n'est annonce comme pret | Message explicite indiquant l'absence de signature `prodRelease` exploitable ou la divergence d'empreinte |

</frozen-after-approval>

## Code Map

- `android/app/build.gradle.kts` -- resolution du keystore, `signingConfigs`, affectation des flavors release, et alias des sorties Flutter release.
- `android/gradle.properties` -- reference locale du keystore release et des identifiants de signature a consommer par Gradle sans les exposer.
- `android/upload_certificate.pem` -- source de verite de l'empreinte de certificat attendue par Google Play.
- `android/upload-keystore-new.jks` -- candidat present dans le depot mais non exploitable en l'etat avec la configuration locale actuelle.
- `build/tmp/movi-release-zip/movi-release.jks` -- candidat extrait hors VCS deja observe avec une empreinte differente de celle attendue par Play; ne pas le brancher pour `prodRelease`.

## Tasks & Acceptance

**Execution:**
- [ ] `android/app/build.gradle.kts` -- rendre la resolution du keystore `prodRelease` explicite et fiable depuis le dossier Android ou un chemin absolu -- eviter le `Config: null` actuel et les diagnostics trompeurs.
- [ ] `android/app/build.gradle.kts` -- faire echouer proprement un flux release Play si la configuration de signature `prod` est incomplete ou indisponible -- empecher toute pseudo-reussite avec signature absente ou debug.
- [ ] `android/gradle.properties` -- aligner la reference `MOVI_KEYSTORE` sur le vrai JKS Play des qu'il est disponible, sans changer la convention de stockage des secrets -- faire pointer Gradle vers le bon fichier.
- [ ] `android/upload_certificate.pem` et keystore cible -- comparer l'empreinte du certificat attendu avec celle du keystore prive avant de lier la signature release -- empecher l'usage d'une mauvaise cle d'upload.
- [ ] `android/app/build.gradle.kts` -- conserver la compatibilite des sorties Flutter release avec `prodRelease` comme source de l'AAB par defaut -- garantir que le bundle final correspond bien a la variante Play.
- [ ] `android` build verification -- executer `signingReport`, construire le bundle `prod`, puis verifier la signature du fichier genere -- prouver que l'artefact final est bien signe par la cle attendue.

**Acceptance Criteria:**
- Given le vrai keystore d'upload Play est present et les credentials sont valides, when `./gradlew.bat signingReport` est execute dans `android`, then `prodRelease` affiche une configuration non nulle et le SHA1 `3A:40:0F:1B:1F:91:73:B6:D5:01:9A:DF:BD:31:40:C7:AE:C5:81:DC`.
- Given le keystore attendu est absent, invalide ou a mauvaise empreinte, when un flux `prodRelease` ou `appbundle` Play est lance, then le processus s'arrete sans generer ni presenter comme valable un bundle signe en debug ou avec une autre cle.
- Given `prodRelease` expose deja l'empreinte attendue, when `flutter build appbundle --flavor prod --release` est lance, then le bundle produit correspond a `prodRelease` et peut etre recontrole par inspection de signature avant upload.

## Spec Change Log

## Design Notes

Etat observe avant implementation:

- `keytool -printcert -file android/upload_certificate.pem` confirme le SHA1 attendu par Play: `3A:40:0F:1B:1F:91:73:B6:D5:01:9A:DF:BD:31:40:C7:AE:C5:81:DC`.
- `./gradlew.bat signingReport` confirme que `prodRelease` est actuellement a `Config: null`, tandis que `devRelease` et `stageRelease` utilisent la debug key `D0:2E:F7:C3:11:ED:9A:01:6B:A7:F9:4B:DB:52:3F:0D:B8:C1:6F:5A`.
- Le warning Gradle actuel pointe vers `android/app/movi-release.jks`, ce qui rend le diagnostic de chemin ambigu et doit etre clarifie si le vrai JKS est fourni dans `android/`.
- Le workspace ne contient pas encore de keystore prive clairement verifie avec l'empreinte Play attendue; la mise en conformite complete depend donc d'un vrai JKS exploitable.

## Verification

**Commands:**
- `keytool -printcert -file android/upload_certificate.pem` -- expected: le certificat affiche le SHA1 attendu par Play.
- `cd android && .\gradlew.bat signingReport` -- expected: `prodRelease` affiche une config de signature non nulle et le SHA1 attendu.
- `flutter build appbundle --flavor prod --release` -- expected: build reussi sans fallback debug et AAB `prod` genere.
- `keytool -printcert -jarfile build\app\outputs\bundle\prodRelease\app-prod-release.aab` -- expected: l'artefact final expose le meme certificat que celui attendu par Play.
