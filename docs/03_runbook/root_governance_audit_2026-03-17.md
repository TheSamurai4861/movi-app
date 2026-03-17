# Audit de gouvernance des fichiers racine du 17 mars 2026

## But

Ce document realise le `Lot 2.2. Gouvernance des fichiers racine`.

Perimetre :

- `analysis_options.yaml`
- `.gitignore`
- `codemagic.yaml`
- `l10n.yaml`
- `devtools_options.yaml`

Documents lies :

- [roadmap.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/roadmap.md)
- [root_non_product_cleanup_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/root_non_product_cleanup_2026-03-17.md)

Date :

- 17 mars 2026

---

## Synthese

Le socle de gouvernance etait fonctionnel mais trop minimal.

Les principaux ecarts observes etaient :

- un `analysis_options.yaml` trop leger ;
- un `.env` versionne avec de vraies valeurs sensibles ;
- une CI Codemagic qui buildait sans verifier la qualite minimale du code ;
- une documentation d'environnement qui supposait la presence d'un `.env` versionne.

Le lot a corrige les points les plus critiques a faible risque.

---

## Decisions et actions appliquees

### 1. `analysis_options.yaml`

Etat initial :

- base `flutter_lints`
- seulement deux regles ajoutees
- exclusion de `docs/**` uniquement

Action :

- ajout des exclusions :
  - `build/**`
  - `.dart_tool/**`
  - `output/**`

Raison :

- eviter du bruit d'analyse sur les repertoires generes ou temporaires ;
- garder l'analyse centree sur le code source utile.

Fichier :

- [analysis_options.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/analysis_options.yaml)

### 2. `.gitignore`

Etat initial :

- artefacts Flutter majeurs deja ignores ;
- `.env` pas ignore ;
- `.cursor/` et `output/` deja couverts par le lot precedent

Actions :

- ajout de `.env`
- ajout de `.env.*`
- ajout de `!.env.example`

Raison :

- garder les secrets locaux hors Git ;
- permettre un gabarit de configuration versionne.

Fichier :

- [`.gitignore`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/.gitignore)

### 3. `.env`

Etat initial :

- le fichier etait versionne ;
- il contenait des valeurs reelles de configuration sensible.

Actions :

- creation de [`.env.example`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/.env.example)
- retrait de `.env` du suivi Git

Raison :

- aligner le depot avec la bonne pratique deja decrite dans la documentation ;
- eviter de versionner des secrets ou quasi-secrets de projet.

Point d'attention critique :

- le retrait du suivi Git ne purge pas l'historique existant ;
- si ces valeurs ont deja ete poussees sur un depot distant, il faut considerer une rotation des cles concernees.

### 4. `codemagic.yaml`

Etat initial :

- les workflows installaient les dependances puis buildaient ;
- aucun check explicite de qualite n'etait lance avant build.

Actions :

- ajout d'un step `flutter analyze --no-fatal-infos`
- ajout d'un step `flutter test` conditionnel si le dossier `test/` existe

Raison :

- ajouter un minimum de garde-fous CI sans bloquer immediatement sur les `info` deja connus ;
- garder un comportement robuste meme si le dossier `test/` est absent dans l'etat courant.

Fichier :

- [codemagic.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/codemagic.yaml)

### 5. `l10n.yaml`

Etat observe :

- configuration simple, lisible et coherente avec `flutter generate`

Decision :

- pas de modification immediate

Fichier :

- [l10n.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/l10n.yaml)

### 6. `devtools_options.yaml`

Etat observe :

- fichier standard DevTools ;
- aucun besoin de durcissement immediat

Decision :

- pas de modification immediate

Fichier :

- [devtools_options.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/devtools_options.yaml)

### 7. Documentation d'onboarding

Action :

- mise a jour de [environment_setup.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/environment_setup.md)

Changements :

- le document ne suppose plus qu'un vrai `.env` versionne existe ;
- il renvoie vers `.env.example` comme gabarit ;
- il rappelle explicitement que `.env` doit rester local.

---

## Resultat du lot

Ce lot est considere realise.

Etat obtenu :

- l'analyse statique ignore mieux les repertoires non pertinents ;
- le depot ne doit plus versionner de fichier `.env` local ;
- un gabarit `.env.example` existe pour l'onboarding ;
- la CI execute des checks minimum avant build ;
- la documentation est alignee avec la pratique attendue.

---

## Risques residuels

### Secrets deja presents dans l'historique

Risque :

- des valeurs deja versionnees peuvent exister dans l'historique Git.

Action recommandee :

- auditer l'historique distant si le depot a deja ete pousse ;
- faire tourner les cles si necessaire.

### Baseline lint encore faible

Risque :

- `analysis_options.yaml` reste volontairement prudent ;
- le depot n'a pas encore une politique de lints "forte".

Action recommandee :

- traiter cela dans un lot dedie apres stabilisation de la base.
