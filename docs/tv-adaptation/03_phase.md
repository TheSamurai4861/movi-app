# Phase 3 — Shell first

## 1. Objet de la phase

La phase 3 a pour objectif de rendre le **shell TV entièrement cohérent et prévisible** avant d’étendre le travail aux pages de détail, listes et résultats.

Cette phase doit garantir que :

* la sidebar est toujours navigable proprement
* l’entrée dans un onglet est déterministe
* la sortie d’un onglet vers la sidebar est uniforme
* le retour sur un onglet restaure le bon focus
* les transitions shell ↔ contenu ne dépendent plus de comportements implicites ou variables selon la page

La phase 3 est la phase où l’on transforme le shell en **contrat de navigation global stable**.

---

## 2. Résultat attendu

À la fin de la phase 3 :

* chaque onglet shell a un **point d’entrée focus officiel**
* chaque onglet shell a une **règle de restauration officielle**
* la sidebar peut toujours reprendre le focus depuis le contenu
* le passage `sidebar -> contenu` est homogène
* le passage `contenu -> sidebar` est homogène
* les états courants du shell sont couverts :

  * arrivée initiale
  * changement d’onglet
  * retour depuis une page poussée
  * retour depuis une page détail
  * retour après perte du nœud restauré

Le résultat attendu n’est pas encore la perfection de tous les écrans internes.
Le résultat attendu est : **le shell devient fiable et stable comme colonne vertébrale TV**.

---

## 3. Périmètre

## 3.1 Inclus

La phase 3 couvre :

* `AppShellPage`
* la sidebar shell
* `HomePage`
* `SearchPage`
* `LibraryPage`
* `SettingsPage`
* les bindings focus par onglet
* la logique de mémorisation/restauration par onglet
* la logique d’entrée/sortie shell ↔ contenu
* la gestion du focus quand un onglet n’a pas encore de contenu focusable prêt

## 3.2 Exclus

La phase 3 ne couvre pas encore :

* les détails complets de `MovieDetailPage`, `TvDetailPage`, `PersonDetailPage`, `SagaDetailPage`
* la correction approfondie des grilles de résultats
* les overlays complets
* le player complet
* les formulaires secondaires hors shell
* la correction détaillée de toutes les règles internes des pages

---

## 4. Pages et zones concernées

## 4.1 Sidebar shell

La sidebar doit être considérée comme une zone de navigation autonome, avec :

* ordre vertical stable des destinations
* focus visible clair
* conservation de l’élément sélectionné
* sélection et activation distinctes si nécessaire

## 4.2 Onglets shell

Les onglets à traiter sont :

* `Home`
* `Search`
* `Library`
* `Settings`

Chaque onglet doit disposer d’un contrat minimum :

* `initialFocusNode`
* `fallbackFocusNode`
* règle de sortie gauche vers sidebar
* restauration du dernier focus si valide

---

## 5. Règles de navigation shell

## 5.1 Entrée initiale dans le shell

Cas à traiter :

### Cas A — arrivée fraîche dans le shell

* focus initial sur la sidebar
* destination active visible et focusable

### Cas B — arrivée dans un shell déjà monté

* si un état shell existe déjà, on peut restaurer soit :

  * la sidebar
  * soit le dernier focus du contenu selon la stratégie retenue
* cette stratégie doit être unique et constante

### Règle recommandée

Par défaut :

* **arrivée fraîche** → sidebar
* **retour interne contrôlé** → restauration du contenu si le retour vient d’un parcours utilisateur cohérent

---

## 5.2 Passage sidebar -> contenu

Quand l’utilisateur presse `right` depuis la sidebar :

* on tente d’entrer dans l’onglet actif
* priorité :

  1. dernier focus mémorisé de l’onglet si valide
  2. `initialFocusNode`
  3. `fallbackFocusNode`
  4. rester sur la sidebar si aucun nœud valide n’existe

Ce comportement doit être identique pour tous les onglets shell.

---

## 5.3 Passage contenu -> sidebar

Quand l’utilisateur presse `left` depuis le contenu :

* la page tente d’abord un déplacement local
* si aucun déplacement local pertinent n’est possible :

  * retour de focus à la sidebar
* ce retour ne doit pas être redéfini différemment dans chaque page shell

Conséquence :

* le shell garde la responsabilité de la sortie globale
* la page garde la responsabilité de ses déplacements internes

---

## 5.4 Changement d’onglet depuis la sidebar

Quand l’utilisateur change d’onglet :

* la sidebar garde le focus tant que l’utilisateur navigue entre destinations
* l’onglet actif change visuellement
* le contenu n’est focusé qu’au `right` explicite
* on ne “saute” pas automatiquement dans le contenu lors d’un changement d’onglet

Cette règle est importante pour la prévisibilité TV.

---

## 5.5 Retour depuis une page poussée

Quand l’utilisateur ouvre une page depuis un onglet shell, puis revient :

* le shell doit restaurer le focus dans le bon onglet
* priorité :

  1. dernier focus mémorisé de l’onglet si encore valide
  2. `initialFocusNode`
  3. `fallbackFocusNode`

Le retour ne doit pas envoyer l’utilisateur sur un autre onglet ni sur un élément arbitraire.

---

## 5.6 Perte du nœud restauré

Si le dernier nœud mémorisé n’existe plus :

* suppression d’une carte
* filtre changé
* liste vide
* refresh ayant reconstruit le contenu

alors :

* on utilise le `initialFocusNode`
* sinon le `fallbackFocusNode`
* sinon retour sidebar

Ce fallback doit être unique pour tous les onglets shell.

---

## 6. Contrat attendu par onglet

## 6.1 Home

* entrée : action principale du hero
* fallback : premier élément fiable du hero
* sortie gauche : sidebar si aucun mouvement local
* restauration : dernier focus du contenu Home si valide

## 6.2 Search

* entrée : champ de recherche ou premier contrôle de recherche
* fallback : premier contrôle de recherche
* sortie gauche : sidebar si aucun mouvement local
* restauration : dernier focus Search si valide
* contrainte : ne pas casser la saisie si le champ a le focus

## 6.3 Library

* entrée : image première playlist
* fallback : premier filtre
* sortie gauche : sidebar si aucun mouvement local
* restauration : dernier focus Library si valide

## 6.4 Settings

* entrée : premier item interactif
* fallback : premier item fiable du niveau racine
* sortie gauche : sidebar si page settings racine
* restauration : dernier focus Settings si valide

---

## 7. Cas limites à traiter explicitement

## 7.1 Onglet vide

Si l’onglet n’a aucun contenu focusable :

* `right` depuis sidebar ne doit pas envoyer vers un état invalide
* soit focus sur un CTA utile
* soit rester sidebar

## 7.2 Onglet en loading

Si le contenu n’est pas prêt :

* ne pas envoyer le focus vers un nœud non monté
* sidebar reste stable
* ou focus vers un élément d’attente si explicitement prévu

## 7.3 Onglet en erreur

Si l’onglet a une action de reprise :

* `right` doit pouvoir cibler cette action
* sinon rester sidebar

## 7.4 Changement d’état pendant le focus

Si l’utilisateur focus un élément puis que la liste se reconstruit :

* tenter de conserver le focus sur l’élément équivalent si possible
* sinon fallback officiel
* jamais perte silencieuse du focus

## 7.5 Sidebar masquée ou adaptée au layout

Si le shell a des variantes layout :

* la règle shell doit rester explicite
* toute variante doit définir qui remplace la sidebar comme zone d’entrée principale

---

## 8. Ce qu’il ne faut pas faire en phase 3

* ne pas traiter les grilles complexes de résultats en détail
* ne pas multiplier les règles propres à chaque page shell
* ne pas introduire un nouveau gestionnaire global opaque
* ne pas déplacer la logique métier interne des pages dans le shell
* ne pas mélanger shell et overlays dans la même phase

---

## 9. Travail concret à réaliser dans cette phase

## 9.1 Sidebar

* verrouiller l’ordre des destinations
* verrouiller le focus initial sidebar
* verrouiller le `right` vers contenu
* verrouiller le `up/down` interne

## 9.2 Coordinator shell

* finaliser la mémoire du dernier focus par onglet
* finaliser les fallbacks
* finaliser la reprise focus après retour

## 9.3 Bindings onglets

Pour chaque onglet :

* binding officiel `initialFocusNode`
* binding officiel `fallbackFocusNode`
* stratégie de restauration

## 9.4 Pages pilotes shell

Valider le contrat sur :

* `Home`
* `Search`
* `Library`
* `Settings`

Même si leurs règles internes complètes viendront après, leur intégration shell doit déjà être stable.

---

## 10. Critères de sortie

La phase 3 est terminée uniquement si :

* la sidebar a un comportement TV stable
* tous les onglets shell ont un binding focus officiel
* `sidebar -> contenu` fonctionne de manière homogène
* `contenu -> sidebar` fonctionne de manière homogène
* le changement d’onglet ne provoque pas de saut de focus incohérent
* le retour depuis une page poussée restaure le bon onglet et le bon focus
* les cas `empty/loading/error` des onglets shell ont un fallback défini
* le code reste simple, lisible et localisé

---

## 11. Tests minimums de validation

À vérifier au minimum :

### Sidebar

* `up/down` entre destinations
* `select` change d’onglet
* `right` entre dans le contenu

### Home

* entrée depuis sidebar
* retour sidebar avec `left`
* retour sur dernier focus après ouverture/retour détail

### Search

* entrée depuis sidebar
* focus sur contrôle initial
* pas de conflit avec saisie
* retour sidebar avec `left`

### Library

* entrée image première playlist sinon premier filtre
* retour sidebar avec `left`
* restauration après navigation interne

### Settings

* entrée premier item
* retour sidebar depuis racine
* restauration du dernier réglage focusé

---

## 12. Conclusion

La phase 3 consiste à **verrouiller le shell comme système de navigation TV global**.

Avant enrichissement des pages détaillées :

* le shell doit devenir fiable
* les transitions doivent être uniformes
* les fallbacks doivent être explicites
* la restauration doit être prévisible

Dans sa forme courte initiale, la phase 3 n’était pas assez complète.
La version ci-dessus est suffisamment complète pour servir de base d’exécution.
