# Nettoyage des dossiers racine non produit du 17 mars 2026

## But

Ce document realise le `Lot 2.1. Nettoyage des dossiers non produit`.

Il clarifie quels dossiers racine :

- font partie du produit ;
- relevent du workflow local ;
- sont des artefacts generes ;
- doivent etre ignores par Git.

Documents lies :

- [roadmap.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/roadmap.md)
- [modernization_plan.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/modernization_plan.md)

Date :

- 17 mars 2026

---

## Synthese

Le depot etait deja partiellement sain sur les artefacts generes majeurs :

- `build/` etait deja ignore ;
- `.dart_tool/` etait deja ignore ;
- `.idea/` etait deja ignore.

Le lot a surtout permis de verrouiller deux decisions qui n'etaient pas encore formalisees dans `.gitignore` :

- `.cursor/` est traite comme local au workflow ;
- `output/` est traite comme repertoire temporaire / d'export.

---

## Etat observe a la racine

Dossiers observes localement :

- `.dart_tool/`
- `.git/`
- `.idea/`
- `android/`
- `assets/`
- `build/`
- `docs/`
- `ios/`
- `lib/`
- `linux/`
- `macos/`
- `tool/`
- `web/`
- `windows/`

Elements versionnes dans l'historique Git mais absents localement au moment du lot :

- `.cursor/`
- `output/`
- `scripts/`
- `test/`

Interpretation :

- `.cursor/` et `output/` relevent du non-produit ;
- `scripts/` et `test/` ne doivent pas etre classes comme "inutiles" par defaut, meme s'ils sont absents localement dans l'etat courant ;
- `scripts/` et `test/` restent des zones projet valides si elles reviennent dans le depot.

---

## Decisions prises

### 1. `.cursor/`

Decision :

- ignorer ce dossier dans Git

Raison :

- il releve d'un workflow local d'outillage ;
- il n'est pas requis pour builder ni executer l'application ;
- son contenu est par nature fluctuant et peu utile au produit.

### 2. `output/`

Decision :

- ignorer ce dossier dans Git

Raison :

- il correspond a des exports temporaires ;
- ce n'est pas une source de verite du projet ;
- il genere du bruit si des dumps sont recrees.

### 3. `build/`

Decision :

- conserver ignore

Raison :

- dossier genere Flutter standard ;
- ne doit jamais servir de source versionnee.

### 4. `.dart_tool/`

Decision :

- conserver ignore

Raison :

- dossier genere Flutter/Dart standard ;
- ne doit pas etre versionne.

### 5. `.idea/`

Decision :

- conserver ignore

Raison :

- configuration locale IDE ;
- ne doit pas etre imposee au depot.

### 6. `scripts/`

Decision :

- ne pas ignorer
- ne pas supprimer de la politique projet sur la seule base de l'etat local courant

Raison :

- un dossier `scripts/` peut rester utile au projet si son role est documente ;
- son absence locale au moment du lot ne suffit pas a le classer en artefact.

### 7. `test/`

Decision :

- ne pas ignorer
- ne pas supprimer de la politique projet sur la seule base de l'etat local courant

Raison :

- `test/` fait partie du socle qualite d'un projet Flutter pro ;
- ce dossier reste structurellement legitime meme s'il est absent de l'etat local observe.

---

## Modifications appliquees

Fichier mis a jour :

- [`.gitignore`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/.gitignore)

Ajouts :

- `.cursor/`
- `output/`

---

## Resultat du lot

Ce lot est considere realise au niveau gouvernance depot.

Etat obtenu :

- les artefacts locaux majeurs restent hors Git ;
- les exports temporaires sont explicitement exclus ;
- les dossiers de workflow local Cursor sont explicitement exclus ;
- aucun dossier projet potentiellement utile n'a ete ignore par erreur.

---

## Point d'attention

Le lot n'a pas pour role de supprimer arbitrairement des dossiers absents localement dans un worktree potentiellement en cours de reorganisation.

En particulier :

- `scripts/`
- `test/`

doivent etre traites comme des zones projet tant qu'une decision produit ou technique explicite ne dit pas le contraire.
