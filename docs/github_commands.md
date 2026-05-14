# Guide pratique Git & GitHub — Commandes et utilisations

## Initialiser ou récupérer un projet

### `git init`
**Utilisation :** démarrer Git dans un dossier de projet existant.

### `git clone <url>`
**Utilisation :** télécharger un dépôt GitHub sur ton ordinateur.

### `git remote add origin <url>`
**Utilisation :** relier un dépôt local à un dépôt GitHub distant.

### `git remote -v`
**Utilisation :** vérifier l'adresse du dépôt distant configuré.

---

## Vérifier l'état du projet

### `git status`
**Utilisation :** voir les fichiers modifiés, non suivis, ou prêts à être commit.

### `git diff`
**Utilisation :** voir les changements non indexés ligne par ligne.

### `git diff --staged`
**Utilisation :** voir les changements déjà ajoutés au prochain commit.

### `git log`
**Utilisation :** voir l'historique des commits.

### `git log --oneline`
**Utilisation :** voir un historique compact des commits.

---

## Ajouter et enregistrer des changements

### `git add <fichier>`
**Utilisation :** préparer un fichier précis pour le prochain commit.

### `git add .`
**Utilisation :** préparer tous les fichiers modifiés et nouveaux du dossier courant.

### `git commit -m "message"`
**Utilisation :** enregistrer une version du projet avec un message clair.

### `git commit -am "message"`
**Utilisation :** commit directement les fichiers déjà suivis et modifiés.

---

## Envoyer et récupérer les changements avec GitHub

### `git push`
**Utilisation :** envoyer les commits locaux vers GitHub.

### `git push -u origin main`
**Utilisation :** envoyer la branche `main` pour la première fois et créer le lien de suivi.

### `git pull`
**Utilisation :** récupérer et fusionner les changements du dépôt distant.

### `git fetch`
**Utilisation :** récupérer les changements distants sans les fusionner tout de suite.

---

## Travailler avec des branches

### `git branch`
**Utilisation :** afficher les branches locales.

### `git branch <nom-branche>`
**Utilisation :** créer une nouvelle branche.

### `git checkout <nom-branche>`
**Utilisation :** changer de branche.

### `git checkout -b <nom-branche>`
**Utilisation :** créer une branche et s'y placer directement.

### `git switch <nom-branche>`
**Utilisation :** changer de branche avec une commande plus moderne.

### `git switch -c <nom-branche>`
**Utilisation :** créer une branche et s'y placer directement avec une commande plus moderne.

### `git merge <nom-branche>`
**Utilisation :** fusionner une branche dans la branche actuelle.

### `git branch -d <nom-branche>`
**Utilisation :** supprimer une branche locale déjà fusionnée.

---

## Corriger ou annuler localement

### `git restore <fichier>`
**Utilisation :** annuler les modifications non commit d'un fichier.

### `git restore --staged <fichier>`
**Utilisation :** retirer un fichier de la zone de préparation sans supprimer ses modifications.

### `git reset --soft HEAD~1`
**Utilisation :** annuler le dernier commit en gardant les changements préparés.

### `git reset --mixed HEAD~1`
**Utilisation :** annuler le dernier commit en gardant les changements dans les fichiers mais plus dans la zone de préparation.

### `git reset --hard HEAD~1`
**Utilisation :** annuler le dernier commit et supprimer les changements locaux associés.

---

## Mettre de côté temporairement

### `git stash`
**Utilisation :** mettre de côté des changements non commit pour nettoyer temporairement le dossier.

### `git stash pop`
**Utilisation :** récupérer les changements précédemment mis de côté.

### `git stash list`
**Utilisation :** voir les changements temporairement stockés.

---

## Cas utiles de diagnostic

### `git show`
**Utilisation :** afficher le détail du dernier commit.

### `git show <hash>`
**Utilisation :** afficher le détail d'un commit précis.

### `git blame <fichier>`
**Utilisation :** voir qui a modifié chaque ligne d'un fichier.

### `git reflog`
**Utilisation :** retrouver des actions récentes, même après un reset ou un changement de branche.

---

## Workflow minimal conseillé

### Nouveau projet local puis GitHub
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <url>
git push -u origin main
```
**Utilisation :** démarrer un projet local et l'envoyer sur GitHub.

### Projet GitHub existant
```bash
git clone <url>
```
**Utilisation :** récupérer un projet existant depuis GitHub.

### Travail quotidien simple
```bash
git status
git add .
git commit -m "message clair"
git push
```
**Utilisation :** vérifier, enregistrer, puis envoyer ton travail.

### Travail sur une fonctionnalité
```bash
git switch -c feature/nom
git add .
git commit -m "Ajout de ..."
git push -u origin feature/nom
```
**Utilisation :** développer une fonctionnalité sur une branche dédiée puis l'envoyer sur GitHub.
