# Documentation `docs/`

## Objectif

Ce dossier contient uniquement la documentation encore utile pour :

- comprendre rapidement le projet ;
- installer et lancer l'application ;
- appliquer les conventions actuellement retenues ;
- suivre les chantiers encore ouverts.

Les audits ponctuels devenus redondants avec l'etat actuel du depot ont ete supprimes pour limiter le bruit.

---

## Structure retenue

```text
docs/
  README.md
  01_onboarding/
    project_overview.md
    quick_start.md
    environment_setup.md
    commands.md
  02_architecture/
    codebase_map.md
    dependency_rules.md
    core_audit.md
  03_runbook/
    modernization_plan.md
    versioning_strategy.md
    package_upgrade_plan_2026-03-17.md
    assets_reorganization_2026-03-17.md
  04_product_followup/
    platform_scope_decision_2026-03-17.md
    roadmap.md
```

---

## Documents a lire en premier

- [project_overview.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/project_overview.md)
  Vue d'ensemble du produit, de la stack et des plateformes supportees.
- [quick_start.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/quick_start.md)
  Chemin le plus court pour lancer le projet.
- [environment_setup.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/environment_setup.md)
  Prerequis machine, Flutter, variables d'environnement et outils.
- [commands.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/01_onboarding/commands.md)
  Commandes validees du projet.

---

## Runbook utile

- [modernization_plan.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/modernization_plan.md)
  Methode d'analyse dossier par dossier pour faire evoluer le projet proprement.
- [versioning_strategy.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/versioning_strategy.md)
  Source de verite et regles d'incrementation de version.
- [package_upgrade_plan_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/package_upgrade_plan_2026-03-17.md)
  Plan d'upgrade des packages par niveau de risque.
- [assets_reorganization_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/assets_reorganization_2026-03-17.md)
  Convention actuelle de rangement et de nommage des assets.

---

## Architecture

- [codebase_map.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/02_architecture/codebase_map.md)
  Cartographie de travail du depot, points d'entree, zones sensibles et lecture recommandee.
- [dependency_rules.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/02_architecture/dependency_rules.md)
  Regles de dependances entre `core`, `shared`, `features` et entre couches internes.
- [core_audit.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/02_architecture/core_audit.md)
  Audit cible de `lib/src/core`, zones saines, zones denses et priorites de clarification.

---

## Pilotage

- [platform_scope_decision_2026-03-17.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/platform_scope_decision_2026-03-17.md)
  Decision de perimetre sur les plateformes officiellement supportees.
- [roadmap.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/roadmap.md)
  Vision des chantiers menes et des suites recommandees.

---

## Regles simples

- un document doit avoir un role clair et actuel ;
- on evite les snapshots d'analyse si leur contenu est deja absorbe par l'etat reel du projet ;
- si un sujet redevient actif, on prefere mettre a jour un document de reference existant plutot qu'ajouter un audit jetable.
