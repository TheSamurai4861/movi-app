# Finaliser l'UI avant la mise en production

## Problème actuel

L'UI de l'app est déjà bien avancée, mais certaines pages doivent encore être revues pour garantir un rendu propre, cohérent et prêt pour une sortie en production.

## Objectif

- Auditer l'interface actuelle
- Identifier les pages et composants à améliorer
- Appliquer les corrections UI de manière propre et homogène
- Vérifier le rendu final avant livraison

## Portée

### Inclus

- Relecture visuelle des écrans existants
- Ajustements de mise en page, espacements, hiérarchie visuelle et cohérence globale
- Corrections des incohérences évidentes dans les composants UI

### Exclu pour l'instant

- Refonte fonctionnelle complète
- Ajout de nouvelles fonctionnalités non liées à la finition UI
- Optimisations techniques non bloquantes pour la sortie

## Audit UI réalisé

### Contexte d'audit

- Plateforme auditée : PC
- Nombre d'écrans relus : 11
- État global : la majorité de l'UI est validée, seuls les écrans nécessitant une correction sont listés ci-dessous

### Écran 6 - Fournisseur

- Statut : à ajuster
- Problèmes observés :
  - Le bouton texte `Voir tout` ne doit plus être utilisé
- Ajustements à prévoir :
  - Supprimer le bouton texte `Voir tout`
  - Utiliser une carte dédiée de type `Voir tout` dans le rail pour ouvrir la page en grid des contenus du fournisseur
- Priorité : haute

### Écran 9 - Settings

- Statut : à ajuster
- Problèmes observés :
  - La bottom sheet de saisie du code PIN prend toute la hauteur de l'écran
  - Une barre de scroll apparaît alors qu'elle doit être masquée
- Ajustements à prévoir :
  - Limiter la bottom sheet à la hauteur nécessaire au contenu
  - Ajouter un padding vertical intérieur cohérent
  - Supprimer la barre de scroll visible
- Priorité : haute

### Écran 10 - Page récupérer le code PIN

- Statut : à ajuster
- Problèmes observés :
  - Le bouton `Envoyer le code` est trop large
  - Les champs `Code de récupération`, `Nouveau code PIN` et `Confirmation` sont trop larges
  - Le header n'a pas le même padding que la page `Sources`
- Ajustements à prévoir :
  - Limiter la largeur du bouton principal
  - Limiter la largeur des champs du formulaire
  - Aligner le spacing du header sur celui de la page `Sources`
- Priorité : haute

### Écran 11 - Organiser sources

- Statut : à ajuster
- Problèmes observés :
  - Une barre de scroll est visible à droite du contenu
- Ajustements à prévoir :
  - Supprimer la barre de scroll visible
- Priorité : moyenne

## Tâches et réflexions

- Finaliser l'analyse UI PC
- Consolider la liste des écrans à corriger
- Définir précisément les corrections UI retenues
- Préparer une manière simple et propre d'implémenter les corrections
- Implémenter les ajustements proprement
- Vérifier le résultat en situation réelle

## Checklist d'exécution

- [x] Faire un audit global des écrans
- [x] Lister les incohérences UI par page
- [x] Prioriser les corrections bloquantes pour la sortie
- [x] Préparer l'implémentation avec une approche simple et propre
- [ ] Implémenter les correctifs
- [ ] Vérifier sur les devices / formats cibles
- [ ] Faire une passe finale de validation visuelle

## Critères de validation

- L'interface est cohérente d'un écran à l'autre
- Les espacements, tailles, alignements et styles sont homogènes
- Aucun écran clé ne donne une impression de travail inachevé
- Les parcours principaux sont visuellement propres et compréhensibles

## Plan d'implémentation

### Étape 1 - Audit

- Audit UI PC terminé
- 11 écrans relus
- 4 écrans nécessitent des corrections avant sortie : fournisseur, settings, récupération du code PIN, organiser sources

### Étape 2 - Priorisation

- P0 UI retenus :
  - Remplacer le bouton texte `Voir tout` de la page fournisseur par une carte dédiée
  - Corriger la bottom sheet PIN dans les settings
  - Corriger les largeurs et le header de la page de récupération du code PIN
  - Supprimer la scrollbar visible sur la page organiser sources

### Étape 3 - Préparation d'implémentation

- Statut : préparée

#### Principes retenus

- Réutiliser au maximum les patterns déjà présents dans le projet
- Limiter les changements globaux et corriger localement les écrans concernés
- Mutualiser uniquement ce qui apporte une vraie cohérence
- Éviter les dépendances d'architecture incorrectes entre `core` et `features`

#### Décisions d'implémentation par écran

##### Écran 6 - Fournisseur

- Fichiers pressentis :
  - `lib/src/features/search/presentation/pages/provider_results_page.dart`
  - `lib/src/core/widgets/movi_see_all_card.dart`
  - `lib/src/features/home/presentation/widgets/home_iptv_section.dart`
- Approche retenue :
  - Supprimer le `TextButton` `Voir tout` utilisé dans le header des sections films / séries
  - Ajouter une carte `Voir tout` en dernier item du rail horizontal lorsque le provider possède plus de résultats que le preview affiché
- Préparation technique :
  - Rendre la carte `SeeAllCard` plus générique pour qu'elle puisse être réutilisée hors du contexte IPTV
  - Remplacer le callback actuellement couplé à `CategoryPageArgs` par une action plus simple de type `VoidCallback`
  - Adapter ensuite l'écran Home IPTV pour continuer à utiliser cette même carte avec le nouveau contrat
- Bénéfice attendu :
  - Un seul pattern visuel `Voir tout` dans l'app
  - Une intégration propre sans logique spécifique ou contournement dans la page fournisseur

##### Écran 9 - Settings

- Fichier principal :
  - `lib/src/core/parental/presentation/widgets/restricted_content_sheet.dart`
- Approche retenue :
  - Conserver `showModalBottomSheet`
  - Supprimer le wrapper de layout qui pousse visuellement la sheet à occuper toute la hauteur
  - Faire reposer la feuille sur un contenu dimensionné à sa hauteur utile, avec scroll uniquement si l'espace disponible devient insuffisant
- Préparation technique :
  - Garder `ModalContentWidth(maxWidth: 520)` comme contrainte de largeur
  - Remplacer l'agencement actuel par une structure plus compacte avec `mainAxisSize: MainAxisSize.min`
  - Prévoir un `SingleChildScrollView` uniquement comme sécurité pour petits écrans / clavier ouvert
  - Masquer localement la scrollbar si elle apparaît, sans modifier le comportement global du `MaterialApp`
- Bénéfice attendu :
  - Bottom sheet plus naturelle visuellement
  - Pas de régression potentielle sur les autres scrollables desktop de l'application

##### Écran 10 - Page récupérer le code PIN

- Fichier principal :
  - `lib/src/core/parental/presentation/pages/pin_recovery_page.dart`
- Approche retenue :
  - Limiter toute la zone formulaire à une largeur maximale unique
  - Laisser les champs et boutons remplir cette largeur contrainte au lieu de s'étendre sur toute la page
  - Réaligner le header sur le spacing de la page `Sources`
- Préparation technique :
  - Introduire des constantes locales simples pour :
    - le padding du header
    - la largeur maximale du formulaire
    - les espacements verticaux principaux
  - Utiliser un `ConstrainedBox` ou un `SizedBox` centré pour le formulaire
  - Reprendre les mêmes valeurs de padding que la page `Sources` pour le header
  - Ne pas mutualiser le widget de header entre `features/settings` et `core` pour éviter une dépendance `core -> features`
- Bénéfice attendu :
  - Correction visuelle nette avec un patch limité
  - Cohérence renforcée avec l'univers settings sans casser l'architecture du projet

##### Écran 11 - Organiser sources

- Fichier principal :
  - `lib/src/features/settings/presentation/pages/iptv_source_organize_page.dart`
- Approche retenue :
  - Conserver la `ReorderableListView.builder`
  - Masquer uniquement la scrollbar visible sur desktop
- Préparation technique :
  - Envelopper localement la liste dans une configuration de scroll sans scrollbar visible
  - Ne pas toucher au comportement de scroll global de l'application
- Bénéfice attendu :
  - Correction ciblée sans impact de bord sur les autres écrans

#### Éléments mutualisables retenus

- Le pattern de carte `Voir tout`
- La méthode locale de masquage des scrollbars desktop
- Les règles de spacing de header inspirées de la page `Sources`

#### Éléments volontairement non mutualisés

- Le header de la page PIN avec les pages settings
  - Même rendu visuel visé, mais pas de widget partagé pour éviter un couplage `core -> features`
- La gestion globale des scrollbars
  - Correction locale préférée pour éviter des effets de bord sur les autres pages desktop

#### Ordre d'implémentation recommandé

- 1. Rendre `SeeAllCard` générique
- 2. Mettre à jour la page fournisseur pour remplacer le bouton texte par la carte
- 3. Corriger la bottom sheet PIN des settings
- 4. Corriger la page de récupération du code PIN
- 5. Masquer la scrollbar sur la page organiser sources

### Étape 4 - Implémentation

- À exécuter

### Étape 5 - Vérification finale

- Vérifier le rendu final sur PC
- Vérifier l'absence de scrollbars visuellement parasites
- Vérifier la cohérence de spacing entre pages settings / sources / PIN

## Risques / points d'attention

- Éviter les régressions de layout entre desktop, TV et formats intermédiaires
- Vérifier que la suppression des scrollbars visibles ne dégrade pas la navigabilité
- Maintenir une cohérence visuelle entre les pages de l'univers settings

## Questions ouvertes

- Aucune pour l'instant

## Notes complémentaires

- Audit validé côté PC
- Le reste des écrans audités est considéré comme conforme à ce stade

 
