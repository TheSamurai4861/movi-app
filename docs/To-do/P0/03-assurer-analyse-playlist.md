# Assurer la compatibilité et l'analyse des playlists IPTV

## Problème actuel

Je ne sais pas si toutes les playlists IPTV qu'un client peut ajouter seront correctement acceptées par l'app et utilisables de manière agréable dans les différentes pages.

## Objectif

- Évaluer la robustesse de l'app face à des playlists variées
- Identifier les cas de données incomplètes, bruitées ou mal formatées
- Définir les fallbacks nécessaires pour garantir une expérience correcte
- S'assurer que l'app reste utile même quand la donnée IPTV est imparfaite

## Portée

### Inclus

- Analyse des playlists IPTV réelles ou représentatives
- Détection des limites de parsing, enrichissement et affichage
- Définition des placeholders, fallbacks et comportements dégradés
- Vérification du comportement dans les écrans principaux

### Exclu pour l'instant

- Refonte complète du pipeline IPTV
- Résolution parfaite de tous les cas d'enrichissement externe
- Nettoyage manuel playlist par playlist

## Cas à couvrir

### Métadonnées incomplètes

- Identifiant TMDB absent :
- Identifiant TMDB erroné :
- Images manquantes :
- Synopsis / informations absentes :
- Notes :

### Titres mal formatés

- Tags parasites dans le titre :
- Alias ou variantes de nom :
- Langue ou qualité intégrée au titre :
- Règles de nettoyage à prévoir :
- Notes :

### Données partiellement exploitables

- Média identifiable sans enrichissement complet :
- Données minimales nécessaires pour l'affichage :
- Fallback d'image :
- Fallback de texte :
- Notes :

### Cas non supportés

- Type de contenu problématique :
- Données incohérentes :
- Comportement attendu :
- Message utilisateur éventuel :
- Notes :

## Questions d'analyse

### Parsing et normalisation

- Quels champs sont indispensables ?
- Quels champs peuvent être reconstruits ?
- Quels nettoyages de titres doivent être centralisés ?

### Enrichissement

- Que faire sans TMDB ?
- Quels écrans dépendent trop fortement de l'enrichissement ?
- Quels niveaux de fallback sont acceptables ?

### Affichage

- Quels placeholders doivent être utilisés ?
- Quelles pages doivent rester utilisables même avec très peu de données ?
- Quels écrans doivent dégrader leur UI au lieu d'échouer ?

## Tâches et réflexions

- Analyser plusieurs playlists représentatives
- Lister les cas de données problématiques
- Identifier les points de casse dans le parsing, l'enrichissement et l'UI
- Définir une stratégie de fallback claire
- Préparer une implémentation simple et robuste
- Implémenter les adaptations nécessaires
- Vérifier le comportement avec des playlists hétérogènes

## Checklist d'exécution

- [ ] Rassembler des playlists ou cas de test représentatifs
- [ ] Identifier les champs réellement disponibles selon les sources
- [ ] Définir les fallbacks de données et d'affichage
- [ ] Prioriser les cas bloquants pour l'expérience utilisateur
- [ ] Préparer l'implémentation avec une approche propre
- [ ] Implémenter les correctifs ou renforcements nécessaires
- [ ] Tester les parcours avec données complètes et dégradées

## Critères de validation

- L'app accepte des playlists variées sans casser les parcours principaux
- Les médias sans enrichissement complet restent affichables de manière acceptable
- Les titres bruités ou partiellement mal formatés sont mieux tolérés
- Les placeholders et fallbacks évitent une sensation d'app cassée

## Plan d'implémentation

### Étape 1 - Analyse des playlists

- À compléter

### Étape 2 - Définition des fallbacks

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
