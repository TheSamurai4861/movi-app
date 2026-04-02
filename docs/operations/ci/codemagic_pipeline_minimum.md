# Pipeline minimal CI — Codemagic (R4)

**Objectif** : satisfaire `docs/rules_nasa.md` §20 (pipeline minimal) et `§27` (“no green pipeline, no release”) via un pipeline **versionné** dans `codemagic.yaml`, avec **preuves** (logs + artefacts) et traçabilité.

---

## 1) Workflows retenus (baseline R4)

### 1.1 `ci-quality-proof` (sans secrets)

- **But** : fournir une preuve CI exécutable sans secrets applicatifs (analyse + tests).
- **Étapes** :
  - `flutter pub get` (preuve : `ci_proofs/flutter_pub_get.log`)
  - `flutter analyze` **bloquant** (preuve : `ci_proofs/flutter_analyze.log`)
  - `flutter test` (preuve : `ci_proofs/flutter_test.log`)
- **Artefacts** : `ci_proofs/*.log` + `ci_proofs/metadata.txt`

### 1.2 `android-closed-test` (AAB)

- **But** : prouver **build reproductible** + **packaging traçable** pour Android.
- **Étapes** : dépendances + analyse + tests + `flutter build appbundle --release ...`
- **Artefacts** :
  - `ci_proofs/*.log` + `ci_proofs/metadata.txt`
  - `build/app/outputs/bundle/release/*.aab`

### 1.3 `ios-dev-ipa` / `ios-prod-store` (IPA unsigned, macOS)

- **But** : prouver **build reproductible** + **packaging traçable** iOS via runner macOS Codemagic.
- **Artefacts** :
  - `ci_proofs/*.log` + `ci_proofs/metadata.txt`
  - `build/ios/ipa/*.ipa` + `build/ios/archive/*.xcarchive`

---

## 2) Triggers recommandés (discipline NASA-like)

> Remarque : la configuration des triggers se fait via l’UI Codemagic. Cette doc fixe la **décision** et la preuve attendue.

- **Sur PR** : exécuter `ci-quality-proof` (gates “analyze + tests”).
- **Sur merge vers `main`** :
  - exécuter `ci-quality-proof`
  - exécuter `android-closed-test`
  - exécuter `ios-dev-ipa` (ou `ios-prod-store` selon politique)

**Politique** :
- Pipeline **rouge** ⇒ merge/release interdits (`rules_nasa.md` §27).
- Les logs et artefacts doivent être conservés (au moins pour la campagne R4) et référencés dans `docs/quality/validation_evidence_index.md`.

---

## 3) Secrets et confidentialité

- Les workflows nécessitant l’API utilisent `groups: [api]` (Codemagic).
- Aucune valeur secrète ne doit être copiée dans les artefacts versionnés.
- Les preuves R4 versionnées dans le dépôt doivent contenir :
  - sorties de commandes,
  - métadonnées non sensibles (branch/commit),
  - et noms/tailles d’artefacts produits.

---

## 4) Preuves attendues (format)

Les preuves “exportées” depuis Codemagic doivent être archivées dans :
`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/`

Nom de fichiers recommandé :
- `r4_codemagic_ci_quality_<date>.txt`
- `r4_codemagic_android_aab_<date>.txt`
- `r4_codemagic_ios_ipa_unsigned_<date>.txt`

Chaque preuve contient :
- date (ISO),
- commit SHA + branch,
- commande(s) exécutée(s) et exit codes,
- liste des artefacts produits (paths, tailles).

