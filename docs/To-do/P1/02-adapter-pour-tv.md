# Adapter l'app pour une utilisation sur TV avec télécommande

## Problème actuel

Le système de focus est déjà en place, mais il peut encore être perdu ou adopter un comportement incohérent selon les pages et les widgets.

## Objectif

- Cartographier les déplacements du focus dans l'app
- Définir des règles de navigation robustes pour la télécommande
- Uniformiser la gestion du focus sur les écrans TV
- Vérifier que les parcours principaux restent fluides et prévisibles

## Portée

### Inclus

- Audit des écrans navigables à la télécommande
- Définition des règles de focus par page et par composant
- Harmonisation de la logique de navigation
- Validation des parcours principaux sur environnement TV

### Exclu pour l'instant

- Refonte visuelle complète spécifique TV
- Support d'interactions avancées non prioritaires
- Optimisations hors sujet avec la navigation télécommande

## Pages et composants à auditer

### Template page TV

- Nom de la page :
- Widgets focusables :
- Entrée de focus :
- Sorties de focus :
- Cas problématiques :
- Priorité :
- Notes :

### Template composant focusable

- Nom du composant :
- Comportement attendu :
- Voisins haut / bas / gauche / droite :
- Cas limites :
- Notes :

## Règles de navigation à définir

### Règles globales

- Convention de focus initial :
- Convention de retour arrière :
- Gestion des bords d'écran :
- Gestion des listes et carrousels :
- Notes :

### Règles spécifiques par écran

- Écran concerné :
- Comportement particulier :
- Dérogations aux règles globales :
- Notes :

## Tâches et réflexions

- Cartographier les déplacements possibles pour chaque widget et chaque page
- Établir des règles de déplacement du focus selon l'élément actuel
- Définir une structure propre pour centraliser ces règles
- Implémenter la logique de navigation TV dans le projet
- Tester la robustesse du focus lors d'un run complet

## Checklist d'exécution

- [ ] Lister les pages concernées par l'usage TV
- [ ] Cartographier les éléments focusables par écran
- [ ] Définir les règles globales de navigation
- [ ] Identifier les exceptions par page
- [ ] Implémenter les règles de focus
- [ ] Tester les parcours principaux à la télécommande
- [ ] Corriger les pertes ou sauts de focus

## Critères de validation

- Le focus n'est jamais perdu dans les parcours principaux
- Les déplacements à la télécommande sont cohérents et prévisibles
- Chaque écran possède une entrée de focus claire
- Les retours arrière et changements de section restent fiables

## Plan d'implémentation

### Étape 1 - Audit des écrans

- À compléter

### Étape 2 - Définition des règles

- À compléter

### Étape 3 - Implémentation

- À compléter

### Étape 4 - Tests TV

- À compléter

## Risques / points d'attention

- À compléter

## Questions ouvertes

- À compléter

## Notes complémentaires

- À compléter
