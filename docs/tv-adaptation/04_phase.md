# Phase 4 — Pages détail

## 1. Objet de la phase

La phase 4 a pour objectif d’unifier le comportement TV des pages de détail.

Après la stabilisation du shell en phase 3, cette phase doit rendre les écrans de détail :
- cohérents entre eux
- prévisibles au remote
- lisibles dans leur logique de focus
- compatibles avec la restauration du focus et le retour arrière

La phase 4 ne consiste pas à “faire du focus partout” au hasard.  
Elle consiste à définir et implémenter une **grammaire commune des pages détail**.

---

## 2. Pages couvertes

La phase 4 couvre :

- `MovieDetailPage`
- `TvDetailPage`
- `SagaDetailPage`
- `PersonDetailPage`

Ces pages peuvent garder leurs spécificités métier, mais elles doivent partager les mêmes principes de navigation.

---

## 3. Résultat attendu

À la fin de la phase 4 :

- chaque page détail a un **point d’entrée explicite**
- chaque page détail a une **zone hero structurée**
- chaque page détail a des **sections basses navigables de façon uniforme**
- le retour depuis les sections vers le hero est homogène
- les carrousels et rangées respectent les mêmes conventions
- le `back` et les sorties de page sont cohérents
- le focus est restauré correctement au retour depuis une page liée
- les états `loading`, `error`, `empty` sont couverts

Le résultat attendu n’est pas encore le traitement complet des pages listes/résultats.  
Le résultat attendu est : **les pages détail deviennent un ensemble cohérent et stable**.

---

## 4. Périmètre

## 4.1 Inclus

La phase 4 couvre :

- le focus initial des pages détail
- la structuration du hero
- les actions principales et secondaires
- la navigation entre hero et sections
- les rangées / carrousels situés dans les pages détail
- la restauration du focus lors du retour
- la sortie vers la page précédente
- les états `loading/error/empty`

## 4.2 Exclus

La phase 4 ne couvre pas encore :

- la correction complète des pages de résultats
- la refonte globale des grilles catalogue
- les overlays complexes
- le player
- les formulaires secondaires
- les pages shell hors besoin direct d’intégration

---

## 5. Grammaire commune des pages détail

## 5.1 Structure logique cible

Chaque page détail doit être pensée comme trois zones :

### Zone 1 — Header / Back
- bouton retour si présent
- éventuellement actions système

### Zone 2 — Hero
- action principale
- actions secondaires
- métadonnées principales
- éventuellement sélecteur de saison ou de mode

### Zone 3 — Sections basses
- synopsis / biographie / résumé
- casting / contenus liés / épisodes / filmographie / recommandations
- carrousels ou listes associées

La navigation doit suivre une logique lisible entre ces zones.

---

## 5.2 Point d’entrée

Règle générale :
- le point d’entrée est l’**action principale**

Exceptions déjà validées :
- `PersonDetailPage` : entrée sur l’action principale
- `MovieDetailPage` : entrée sur `Regarder`
- `TvDetailPage` : entrée sur lecture / reprise
- `SagaDetailPage` : entrée sur l’action principale

Si l’action principale n’existe pas ou n’est pas disponible :
- fallback vers première action secondaire fiable
- sinon bouton retour
- sinon premier élément interactif du hero

---

## 5.3 Règles horizontales dans le hero

Dans le hero :
- `right` : action suivante de la même ligne
- `left` : action précédente de la même ligne
- fin de ligne à droite : **stop**
- début de ligne à gauche :
  - retour bouton back si présent
  - sinon stop

Aucun wrap implicite.

---

## 5.4 Règles verticales entre zones

- `down` depuis le hero : première section basse pertinente
- `up` depuis les sections : remonte au hero
- `up` depuis le hero :
  - va au bouton back si présent
  - sinon stop
- `down` dans les sections :
  - section suivante
  - ou élément cohérent de la zone inférieure

La descente et la remontée doivent être **symétriques autant que possible**.

---

## 5.5 Carrousels et rangées dans les détails

Tous les carrousels/rangées situés dans les pages détail doivent suivre les mêmes conventions :

- `right` : élément suivant de la même ligne
- `left` : élément précédent de la même ligne
- fin de ligne à droite : **stop**
- début de ligne à gauche : **stop** ou retour logique à l’en-tête de section si explicitement prévu
- `down` : section suivante
- `up` : section précédente ou hero selon position

Pas de wrap implicite.  
Pas de saut automatique vers une autre ligne en fin de rangée.

---

## 6. Contrat par page

## 6.1 MovieDetailPage

### Point d’entrée
- bouton principal `Regarder`

### Structure cible
- back/header
- hero avec CTA principal + actions secondaires
- sections basses :
  - synopsis / informations
  - saga si présente
  - casting
  - recommandations / contenus liés

### Navigation attendue
- `right` dans le hero : autres actions
- `left` dans le hero : action précédente ou back
- `down` depuis hero : première section basse
- `up` depuis sections : hero
- carrousels : stop en bord, pas de wrap

### Restauration
- retour depuis une page liée : restaurer le dernier élément focusé si valide
- sinon `Regarder`
- si CTA indisponible, fallback sur action secondaire ou back

### États
- `loading` : focus neutre ou CTA si page partiellement prête
- `error` : focus sur retour ou action de reprise
- `empty` : focus sur retour ou action principale restante

---

## 6.2 TvDetailPage

### Point d’entrée
- action principale lecture / reprise

### Structure cible
- back/header
- hero avec actions
- zones spécifiques :
  - sélecteur saison
  - liste / rangée d’épisodes
  - recommandations / contenus liés

### Navigation attendue
- hero :
  - `right` : autres actions
  - `down` : sélecteur saison ou épisodes
- saisons/épisodes :
  - navigation explicite
  - stop en bord
  - aucun wrap implicite
- `up` depuis contenu : remonte au hero ou au sélecteur supérieur logique

### Restauration
- restaurer dernier focus de la page si valide
- sinon CTA principal
- fallback fiable si la saison/épisode précédemment focusé n’existe plus

### États
- `loading` : pas de focus sur des épisodes non montés
- `error` : focus sur reprise / retour
- `empty` : focus sur retour ou CTA disponible

---

## 6.3 PersonDetailPage

### Point d’entrée
- action principale

### Structure cible
- back/header
- hero avec action principale
- biographie
- filmographie / séries / contenus liés

### Navigation attendue
- `right` : autre action du header/hero si présente
- `down` : biographie puis sections associées
- `up` : retour hero
- rangées de contenus : même contrat que les autres pages détail

### Restauration
- dernier focus si valide
- sinon action principale
- fallback vers back si nécessaire

### États
- `loading` : focus neutre ou hero si prêt
- `error` : retour / reprise
- `empty` : retour

---

## 6.4 SagaDetailPage

### Point d’entrée
- action principale

### Structure cible
- back/header
- hero avec CTA/action principale
- liste/rangée des contenus de la saga
- éventuellement recommandations associées

### Navigation attendue
- `right` : autres actions hero
- `down` : contenus de la saga
- `up` : retour hero
- rangées : stop en bord, pas de wrap

### Restauration
- dernier focus si valide
- sinon action principale
- fallback sur retour si nécessaire

### États
- `loading` : focus neutre
- `error` : focus sur retour / reprise
- `empty` : retour

---

## 7. Règles de sortie

## 7.1 Retour arrière

Sur toutes les pages détail :

- `back` système : retour page précédente
- bouton back focusable si présent : même comportement
- pas de retour shell direct depuis une page détail poussée hors shell

## 7.2 Retour depuis une page liée

Quand on ouvre une page liée depuis :
- casting
- recommandations
- saga
- personne
- contenu apparenté

alors au retour :
- restaurer le focus sur l’élément déclencheur si toujours valide
- sinon fallback de la section
- sinon fallback page (action principale)
- sinon bouton back

---

## 8. Cas limites à traiter

## 8.1 Section absente
Si une section n’existe pas :
- la navigation verticale saute proprement à la prochaine section valide
- aucun focus mort

## 8.2 CTA principal indisponible
Si l’action principale n’est pas affichée :
- fallback sur action secondaire
- sinon back

## 8.3 Reconstruction de contenu
Si recommandations/casting changent après refresh :
- tenter de restaurer le focus équivalent
- sinon fallback section
- sinon fallback page

## 8.4 Contenu très long
Les zones scrollables doivent :
- garder un comportement de focus stable
- ne pas perdre le focus lors du scroll automatique
- maintenir la lisibilité du parcours

---

## 9. Travail concret à réaliser

## 9.1 Standardiser le hero
Pour chaque page détail :
- identifier le CTA principal
- identifier les actions secondaires
- clarifier le bouton retour
- rendre l’ordre gauche/droite explicite

## 9.2 Standardiser le passage hero -> sections
- `down` depuis hero vers première section
- `up` depuis section haute vers hero
- même logique pour toutes les pages

## 9.3 Standardiser les rangées
- stop en bord
- pas de wrap
- navigation verticale claire entre rangées/sections

## 9.4 Standardiser la restauration
- dernier focus si valide
- sinon fallback section
- sinon action principale
- sinon back

---

## 10. Ce qu’il ne faut pas faire en phase 4

- ne pas traiter les pages de résultats comme si elles faisaient partie de cette phase
- ne pas créer une abstraction générique lourde pour toutes les pages détail
- ne pas déplacer tout le focus dans un manager global
- ne pas casser les comportements déjà corrects de `TvDetailPage` si elle est déjà plus avancée
- ne pas mélanger détails et overlays dans cette phase

---

## 11. Critères de sortie

La phase 4 est terminée uniquement si :

- les 4 pages détail ont un point d’entrée officiel
- leurs héros respectent la même grammaire
- les sections basses ont une navigation homogène
- les carrousels/rangées respectent stop en bord + pas de wrap
- le retour arrière est cohérent
- la restauration après retour depuis une page liée est fiable
- les états `loading/error/empty` ont un fallback défini
- le code reste local, lisible et sans abstraction inutile

---

## 12. Tests minimums

À vérifier pour chaque page détail :

- focus initial
- `left/right` dans le hero
- `down` vers la première section
- `up` vers le hero
- navigation dans les rangées
- stop en bord de ligne
- retour arrière
- restauration après ouverture d’une page liée
- comportement correct en `loading/error/empty`

---

## 13. Conclusion

La phase 4 consiste à rendre les pages détail **uniformes, prévisibles et robustes en usage TV**.

La version courte initiale donnait la bonne direction, mais elle n’était pas assez complète pour l’exécution.  
La version ci-dessus est suffisamment complète pour servir de base d’implémentation.