# Phase 2 — Stabilisation de l’infrastructure focus

## 1. Objet de la phase

La phase 2 a pour objectif de fournir un **socle technique commun** pour le focus TV, afin que les phases suivantes puissent corriger les pages sans réinventer la logique à chaque écran.

Cette phase ne doit pas :
- réécrire toute la navigation
- introduire un framework interne complexe
- déplacer inutilement la logique métier des pages vers le core

Cette phase doit :
- clarifier les responsabilités
- réduire la duplication technique
- rendre le focus plus prévisible
- préparer une implémentation page par page propre et testable

---

## 2. Résultat attendu

À la fin de la phase 2, le projet doit disposer d’un socle minimal stable permettant à chaque page de déclarer clairement :

- son point d’entrée focus
- sa règle de restauration
- ses zones de navigation principales
- sa sortie vers shell, retour ou overlay
- ses cas standards de focus TV sans logique ad hoc dispersée

Le résultat attendu n’est pas “tout fonctionne partout”.  
Le résultat attendu est : **les fondations sont prêtes pour corriger les pages proprement**.

---

## 3. Périmètre de la phase 2

## 3.1 Inclus

La phase 2 couvre :

- le contrat minimal de focus d’une route/page
- le contrat minimal de restauration du focus
- le support minimal des groupes directionnels simples
- l’intégration propre avec le shell existant
- les helpers nécessaires pour éviter la duplication locale
- les conventions d’usage pour les pages futures

## 3.2 Exclus

La phase 2 ne couvre pas encore :

- la correction complète de toutes les pages
- l’harmonisation détaillée des pages détail
- la refonte complète des grilles et résultats
- les overlays complets
- le player complet
- les tests exhaustifs de toutes les routes

Ces éléments appartiennent aux phases suivantes.

---

## 4. Problème à résoudre

Aujourd’hui, le projet dispose déjà de plusieurs briques utiles :
- navigation remote globale
- composants focusables réutilisables
- coordination shell
- logiques locales sur certaines pages

Le problème n’est pas l’absence de focus.  
Le problème est le **manque d’un contrat commun lisible**.

Conséquences actuelles :
- logique de focus dispersée
- pages inégales en robustesse
- restauration hétérogène
- comportements de bord différents selon les écrans
- risque de duplication croissante à chaque correction

La phase 2 corrige ce problème structurel.

---

## 5. Principes d’architecture à respecter

## 5.1 Simplicité

Le socle doit rester petit.  
On ajoute uniquement ce qui réduit réellement la duplication ou clarifie les responsabilités.

## 5.2 Responsabilités nettes

- le **shell** gère la navigation shell
- la **page** garde ses règles métier locales
- l’**infra focus** fournit seulement le cadre commun

## 5.3 Pas d’abstraction spéculative

On ne crée pas :
- de moteur générique de navigation TV
- de DSL de focus
- de graphe universel de focus
- de système de configuration déclarative trop abstrait

## 5.4 Testabilité

Chaque brique ajoutée doit être testable isolément.

## 5.5 Intégration progressive

La phase 2 doit pouvoir être adoptée page par page, sans migration big-bang.

---

## 6. Briques à introduire

## 6.1 `MoviRouteFocusBoundary`

### Rôle
Widget de niveau page qui formalise le contrat minimum de focus d’un écran.

### Responsabilités
- porter le point d’entrée de focus de la page
- porter la politique de restauration
- exposer une frontière claire entre la page et l’extérieur
- servir de point d’intégration avec le shell ou le navigator

### Responsabilités interdites
- ne pas contenir la navigation métier détaillée de la page
- ne pas remplacer les `FocusNode` locaux
- ne pas gérer à lui seul les grilles complexes
- ne pas décider des règles internes d’un carrousel métier

### API cible minimale
- `initialFocusNode`
- `restoreFocusOnPop`
- `fallbackFocusNode`
- éventuellement `debugLabel`

### Usage
Une page l’utilise comme conteneur racine focus.

---

## 6.2 Contrat de restauration du focus

### Forme
Petit contrat explicite du type :

- `initialFocusNode`
- `restoreFocusOnPop`
- `fallbackFocusNode`

### Rôle
Permettre un comportement uniforme au retour sur une page.

### Règles
- si un dernier focus valide existe et `restoreFocusOnPop = true`, on tente de le restaurer
- sinon on prend `initialFocusNode`
- si ce nœud n’est plus valide, on utilise `fallbackFocusNode`

### Objectif
Éviter que chaque page réimplémente sa propre logique de retour.

---

## 6.3 Helper de groupe directionnel simple

### Rôle
Support minimal pour les cas simples :
- rangée horizontale
- colonne verticale
- petit groupe d’actions
- header d’actions
- hero buttons

### Responsabilités
- gérer les voisins locaux simples
- appliquer la règle de stop en bord
- éviter la duplication de code directionnel

### Responsabilités interdites
- ne pas essayer de gérer toutes les grilles complexes
- ne pas encapsuler la logique métier du contenu
- ne pas masquer les règles de navigation sous une abstraction opaque

### Cas d’usage typiques
- actions d’un hero
- ligne de filtres
- boutons d’un panneau settings
- actions d’une playlist

---

## 6.4 Convention de sortie shell

### Rôle
Formaliser le contrat entre :
- le contenu d’un onglet
- la sidebar
- le coordinateur de focus shell existant

### Règles
- depuis le contenu, `left` tente d’abord un mouvement local
- si aucun mouvement local n’est possible, la page autorise le retour shell
- la sidebar reprend le focus
- depuis la sidebar, `right` entre dans le `initialFocusNode` ou le dernier focus restaurable de l’onglet

### Objectif
Éviter les divergences entre pages shell.

---

## 6.5 Convention overlay return

### Rôle
Définir une règle uniforme pour les overlays.

### Règles
- l’ouverture d’un overlay mémorise le déclencheur
- l’overlay prend le focus
- à la fermeture, le focus revient au déclencheur si toujours valide
- sinon fallback de la page

### Remarque
L’implémentation complète est en phase 7, mais la convention doit exister dès la phase 2.

---

## 7. Ce qu’il ne faut pas créer

Pour garder le système lisible et maintenable, la phase 2 interdit explicitement :

- un gestionnaire global de tous les `FocusNode` de l’application
- une base de données centrale des liens entre nœuds
- un “focus router” parallèle au router de navigation
- un moteur déclaratif universel de navigation directionnelle
- des abstractions génériques vagues de type `FocusManagerService` sans responsabilité précise
- des helpers fourre-tout mélangeant shell, overlay, page et widget

---

## 8. Intégration dans le projet

## 8.1 Emplacement recommandé

Créer un sous-ensemble limité dans une zone technique claire, par exemple :

- `lib/src/core/focus/`

avec uniquement les éléments nécessaires.

## 8.2 Contenu attendu

Exemples de fichiers cibles :

- `movi_route_focus_boundary.dart`
- `movi_focus_restore_policy.dart`
- `movi_directional_focus_group.dart`
- `movi_focus_scope_helpers.dart`

Le nom exact pourra être ajusté, mais chaque fichier doit avoir une responsabilité claire.

## 8.3 Ce qui reste dans les pages

Les pages gardent :
- leurs `FocusNode`
- leurs règles de navigation métier
- leurs décisions locales sur sections, carrousels, saisons, filtres, etc.

Le core focus ne fait pas à leur place ce qui relève de leur structure.

---

## 9. Règles d’intégration page par page

À partir de la phase 2, toute nouvelle page ou page refactorée devra respecter ce minimum :

### 9.1 Contrat minimum
La page déclare :
- un `initialFocusNode`
- un `fallbackFocusNode` si nécessaire
- si elle restaure ou non le focus au retour

### 9.2 Sortie
La page définit explicitement :
- si `left` en bord retourne au shell
- si `back` revient à la page précédente
- si un overlay doit restituer le focus au déclencheur

### 9.3 Groupes simples
Les groupes d’actions simples utilisent le helper commun au lieu de recoder les voisins à la main si cela apporte vraiment de la clarté.

### 9.4 Cas complexes
Les grilles complexes, carrousels riches et listes virtuelles gardent leur logique locale si cela reste plus lisible.

---

## 10. Ordre d’exécution interne de la phase 2

### Étape 1
Formaliser le contrat de route :
- point d’entrée
- restauration
- fallback

### Étape 2
Introduire `MoviRouteFocusBoundary`

### Étape 3
Formaliser le contrat shell ↔ contenu

### Étape 4
Introduire le helper de groupes directionnels simples

### Étape 5
Appliquer ce socle sur un petit nombre d’écrans pilotes :
- shell
- home
- settings ou search

### Étape 6
Valider que l’infra reste simple avant de l’étendre aux phases suivantes

---

## 11. Risques à contrôler

## 11.1 Sur-abstraction
Risque principal : créer un système trop générique, difficile à comprendre.

### Réponse
Limiter la phase 2 à un contrat minimal et à 2 ou 3 briques maximum.

## 11.2 Déplacement excessif de logique
Risque : déplacer des règles métier de pages dans le core.

### Réponse
Le core focus ne gère que le cadre commun.

## 11.3 Régression shell
Risque : casser une navigation shell déjà fonctionnelle.

### Réponse
Le shell doit être la première intégration pilote et la référence de validation.

## 11.4 Faux gain de déduplication
Risque : factoriser des comportements qui ne sont pas réellement stables.

### Réponse
Ne mutualiser que les cas simples, répétés et homogènes.

---

## 12. Critères de sortie de la phase 2

La phase 2 est terminée uniquement si :

- un conteneur de route focus commun existe
- la politique de restauration est explicite et réutilisable
- la convention shell ↔ contenu est formalisée
- un helper de groupe directionnel simple existe pour les cas vraiment répétitifs
- au moins quelques écrans pilotes utilisent ce socle sans complexifier leur code
- aucune abstraction lourde ou spéculative n’a été introduite
- le socle est compréhensible sans explication orale longue

---

## 13. Conclusion

La phase 2 ne consiste pas à “faire le focus partout”.  
Elle consiste à **préparer proprement le terrain** pour que les phases 3 à 7 puissent corriger les écrans avec une base commune, simple, lisible et stable.

Elle est maintenant **complète au niveau de la définition** et peut être exécutée.