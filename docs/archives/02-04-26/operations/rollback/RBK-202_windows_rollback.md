# Runbook rollback — Windows

**Runbook ID** : `RBK-202`  
**Plateforme** : Windows  
**Statut** : `draft` (R3)  
**Références** : `docs/operations/rollback/rollback_strategy.md`, `docs/rules_nasa.md` §20.1, §27.

---

## 1) Hypothèses de distribution

Phase 0 n’atteste pas une chaîne de distribution Windows “production-grade” (store/installer signé/repo artefacts).  
Ce runbook décrit un rollback via **réinstallation d’un artefact N-1** (zip/installer).

---

## 2) Prérequis

- Disposer de l’artefact Windows N-1 (zip/installer) et de son identifiant de version.
- Disposer d’une procédure de vérification post-rollback (startup/playback).

---

## 3) Procédure opératoire

1. Identifier la version N en incident (version app + date de build).
2. Sélectionner l’artefact N-1 stable.
3. Désinstaller la version N (si nécessaire).
4. Installer N-1.
5. Lancer l’app et vérifier flux critiques minimum.

---

## 4) Validation post-rollback (minimum)

- Lancement OK
- Lecture vidéo OK (source de test)
- Crash/erreurs : vérifier Sentry/logs si activés

---

## 5) Risques

- Données locales : une migration locale peut rendre le downgrade difficile (prévoir procédure de backup/clear).
- Dépendances natives : variations runtime (VC++ redistribuables, etc.).

