# Choisir la bonne version d'un média au lancement

## Problème actuel

Un utilisateur ne peut actuellement pas sélectionner la version qu'il veut lancer pour un film ou un épisode.

## Objectif

- Permettre le choix d'une version adaptée au besoin utilisateur
- Définir une logique simple entre sélection automatique et choix manuel
- Gérer proprement la qualité, la langue et la source de lecture
- Éviter un lancement par défaut perçu comme arbitraire ou mauvais

## Portée

### Inclus

- Définition de la logique de sélection de version
- Ajout éventuel de préférences de lecture
- UX de choix manuel au lancement
- Gestion des fallbacks si la version idéale n'existe pas

### Exclu pour l'instant

- Moteur avancé de scoring multi-critères très complexe
- Paramétrage expert complet pour tous les profils d'usage
- Réécriture complète du player

## Décisions produit à cadrer

### Mode automatique

- Qualité prioritaire :
- Langue prioritaire :
- Source prioritaire :
- Fallback si indisponible :
- Notes :

### Mode manuel

- Quand afficher le choix manuel :
- Quelles informations montrer à l'utilisateur :
- Ordre d'affichage des versions :
- Action par défaut :
- Notes :

### Préférences utilisateur

- Lecture automatique activable :
- Préférence de qualité :
- Préférence de langue audio :
- Préférence de sous-titres :
- Préférence de source :
- Notes :

## Cas à couvrir

### Film avec plusieurs versions

- Qualités disponibles :
- Langues disponibles :
- Source préférée :
- Comportement attendu :
- Notes :

### Épisode avec plusieurs versions

- Variantes disponibles :
- Règle de choix attendue :
- Différence éventuelle avec les films :
- Notes :

### Aucune version idéale disponible

- Fallback attendu :
- Message utilisateur éventuel :
- Niveau d'automatisation acceptable :
- Notes :

### Choix manuel via bottom sheet

- Informations à afficher :
- Hauteur / largeur cible :
- Interaction attendue :
- Notes :

## Tâches et réflexions

- Définir la logique de sélection automatique
- Déterminer les paramètres de lecture nécessaires
- Concevoir l'UX de sélection manuelle
- Définir les règles de fallback entre qualité, langue et source
- Préparer une implémentation simple et maintenable
- Implémenter la solution retenue
- Vérifier les parcours de lancement réels

## Checklist d'exécution

- [ ] Lister les variantes de versions réellement disponibles dans les données
- [ ] Définir les préférences utilisateur pertinentes
- [ ] Choisir le comportement par défaut au clic sur `Regarder`
- [ ] Définir le contenu de la bottom sheet ou du sélecteur
- [ ] Préparer l'implémentation avec une approche propre
- [ ] Implémenter la logique de sélection
- [ ] Tester les cas automatiques et manuels

## Critères de validation

- L'utilisateur peut comprendre quelle version va être lancée
- Le mode automatique choisit une version cohérente
- Le mode manuel permet un choix rapide sans friction excessive
- Les fallbacks restent prévisibles quand la version souhaitée n'existe pas

## Plan d'implémentation

### Étape 1 - Cadrage produit

- À compléter

### Étape 2 - Définition des règles de sélection

- À compléter

### Étape 3 - Préparation d'implémentation

- À compléter

### Étape 4 - Implémentation

- À compléter

### Étape 5 - Vérification

- À compléter

## Risques / points d'attention

- À compléter

## Questions ouvertes

- À compléter

## Notes complémentaires

- À compléter
