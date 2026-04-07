# Phase 7 — Overlays et player

## 1. Objet de la phase

La phase 7 a pour objectif d’unifier le comportement TV des éléments qui se superposent au contenu principal ou qui changent radicalement le mode d’interaction :

* dialogs,
* bottom sheets,
* sheets plein écran ou semi-plein écran,
* menus d’action,
* menus contextuels,
* overlays du player,
* contrôles du player.

Après le shell, les pages détail, les listes/résultats, puis les settings/formulaires, cette phase doit rendre ces surfaces :

* prévisibles au remote,
* totalement étanches du point de vue du focus,
* cohérentes dans leur ouverture et leur fermeture,
* homogènes sur `back`,
* robustes sur la restitution du focus.

La phase 7 ne consiste pas à “rajouter du focus aux modales”.
Elle consiste à définir et implémenter une **grammaire commune des surfaces superposées et du player**.

## 2. Pages et surfaces couvertes

La phase 7 couvre :

* dialogs de confirmation en bibliothèque,
* dialogs de confirmation dans settings/IPTV,
* bottom sheet `mark_as_unwatched`,
* éventuelles sheets de contenu restreint,
* éventuelles sheets premium lock,
* `MoviPremiumPage` si elle est utilisée comme surface poussée/overlay depuis l’UI,
* menus contextuels,
* menus d’action,
* overlays de contrôles du player,
* `VideoPlayerPage` sur sa logique focus TV.

Elle couvre aussi toutes les variantes d’ouverture depuis :

* page shell,
* page détail,
* page liste,
* settings/formulaire,
* player lui-même.

## 3. Résultat attendu

À la fin de la phase 7 :

* tout overlay a un déclencheur clairement identifié,
* tout overlay prend immédiatement le focus à l’ouverture,
* le focus reste enfermé dans le scope de l’overlay tant qu’il est ouvert,
* aucun élément de l’écran sous-jacent n’est focusable pendant ce temps,
* `back` ferme d’abord l’overlay courant avant toute autre sortie,
* à la fermeture, le focus revient au déclencheur si ce déclencheur est encore valide,
* sinon le focus revient au fallback local de la page,
* le player a un mode sans overlay et un mode avec overlay clairement séparés,
* les contrôles du player ont une navigation directionnelle stable,
* l’ouverture/fermeture des contrôles du player ne provoque pas de perte de focus.

C’est exactement la continuité des objectifs de roadmap et de la convention overlay posée en phase 2.

## 4. Périmètre

### 4.1 Inclus

La phase 7 couvre :

* l’ouverture des overlays,
* la capture de focus,
* le piégeage du focus,
* la navigation interne de l’overlay,
* le comportement de `back`,
* la fermeture,
* la restitution du focus,
* les cas `loading/error/empty` si un overlay ou le player les expose,
* la logique player sans contrôles visibles,
* la logique player avec contrôles visibles.

### 4.2 Exclus

La phase 7 ne couvre pas :

* la refonte du shell,
* les pages détail hors intégration avec overlays,
* les grilles catalogue hors surface overlay,
* les formulaires classiques déjà traités en phase 6,
* la batterie complète de tests de non-régression, qui relève de la phase 8. 

## 5. Grammaire commune des overlays

## 5.1 Structure logique cible

Tout overlay doit être pensé comme une mini-page temporaire avec :

* un déclencheur d’origine,
* un scope de focus autonome,
* un point d’entrée explicite,
* un parcours directionnel local,
* une règle de fermeture explicite,
* une cible de restitution explicite.

Autrement dit, un overlay n’est pas “juste un widget affiché au-dessus”.
C’est une **frontière de focus temporaire**.

## 5.2 Déclencheur

Avant ouverture, le système doit connaître le déclencheur :

* bouton,
* carte,
* ligne d’action,
* item de menu,
* contrôle player,
* CTA premium,
* action contextuelle.

Ce déclencheur est la cible de restitution prioritaire à la fermeture. C’est la règle centrale définie dès la phase 2. 

## 5.3 Point d’entrée

Tout overlay doit avoir un point d’entrée unique :

* dialog de confirmation : CTA principal ou bouton le plus sûr selon le cas,
* bottom sheet d’actions : première action utile,
* menu contextuel : première action du menu,
* premium lock sheet : CTA principal,
* overlay player : contrôle principal visible.

Si la restitution future échoue, c’est ce point d’entrée qui sert de fallback interne.

## 5.4 Capture et piégeage du focus

À l’ouverture :

* l’overlay reçoit le focus,
* le contenu derrière ne doit plus être atteignable,
* la navigation reste bornée à l’overlay,
* aucune flèche ne doit “passer à travers” vers la page sous-jacente.

La roadmap parle de capture du focus et d’absence de fuite vers l’écran sous-jacent ; le diagnostic amont parlait aussi de “piéger le focus localement”.

## 5.5 Sortie

Tant que l’overlay est ouvert :

* `back` ferme l’overlay courant,
* `select` active l’action focusée,
* si une action ferme l’overlay, la restitution se déclenche immédiatement,
* on ne sort jamais directement vers une autre couche sans d’abord fermer la couche supérieure active.

## 5.6 Restitution

À la fermeture :

1. restituer le focus au déclencheur si toujours monté et valide,
2. sinon fallback local de la page d’origine,
3. sinon point d’entrée officiel de la page d’origine,
4. sinon fallback plus sûr comme bouton retour.

Cette hiérarchie doit être identique sur tous les overlays. Elle prolonge la convention de phase 2 et la logique générale de restauration des phases 3 à 6.

## 6. Familles d’overlays à traiter

## 6.1 Dialogs de confirmation

Exemples :

* suppression,
* désactivation,
* confirmation d’action destructive,
* confirmation en bibliothèque,
* confirmation settings/IPTV. 

### Point d’entrée

* bouton principal le plus sûr selon le contexte,
* ou bouton d’annulation si la règle UX veut minimiser les erreurs.

### Navigation

* si deux boutons sur une ligne : `left/right` entre eux, stop en bord,
* `up/down` seulement si plusieurs zones sont réellement séparées,
* aucun débordement implicite.

### Sortie

* `back` = annuler/fermer,
* validation = exécuter puis fermer,
* fermeture = restitution au déclencheur.

## 6.2 Bottom sheets et action sheets

Exemples :

* `mark_as_unwatched`,
* sheet de contenu restreint,
* premium lock sheet,
* sheet d’actions rapides. 

### Point d’entrée

* première action utile ou CTA principal.

### Navigation

* verticale simple si liste d’actions,
* horizontale seulement dans une ligne de boutons,
* `back` ferme la sheet.

### Restitution

* retour au bouton ou à la carte qui a ouvert la sheet,
* sinon fallback de page.

## 6.3 Menus contextuels

Exemples :

* menu “plus d’actions”,
* menu d’item média,
* menu contextuel player.

### Point d’entrée

* première action du menu.

### Navigation

* verticale stricte,
* pas de fuite,
* `select` exécute l’action,
* `back` ferme.

### Particularité

Un menu contextuel doit être considéré comme un overlay léger, pas comme un simple `PopupMenuButton` laissé au comportement implicite.

## 6.4 Premium et lock surfaces

Si `MoviPremiumPage` ou des écrans premium lock/restricted sont effectivement montrés comme surfaces intermédiaires :

* ils suivent le contrat overlay,
* CTA principal en entrée,
* `back` ferme ou revient au déclencheur,
* fermeture = restitution au déclencheur. 

## 7. Grammaire commune du player

## 7.1 Deux états majeurs

Le player doit être pensé comme deux modes de focus distincts, déjà identifiés en phase 1 :

### Mode A — sans overlay

* focus sur la surface player ou état “contrôle principal invisible”
* `select` affiche les contrôles
* `back` ferme l’état courant ou sort du player

### Mode B — avec overlay

* focus sur le contrôle principal visible
* `left/right` : seek ou navigation entre contrôles selon le groupe actif
* `up/down` : changement de groupe de contrôles
* `back` ferme d’abord l’overlay de contrôles, puis seulement ensuite sort du player. 

## 7.2 Structure logique cible du player

Le player doit être structuré en zones :

* zone 1 : surface vidéo,
* zone 2 : barre principale de lecture,
* zone 3 : groupes secondaires éventuels,
* zone 4 : overlays spécialisés éventuels, comme audio/subtitles/options.

Chaque zone doit avoir :

* un point d’entrée,
* des voisins explicites,
* une règle de fermeture,
* une restitution claire.

## 7.3 Point d’entrée du player

Conformément à la phase 1 :

* entrée sur la surface player ou le contrôle principal visible,
* si les contrôles s’ouvrent, le focus va sur le contrôle principal pertinent,
* si un sous-overlay se ferme, retour au contrôle principal pertinent. 

## 7.4 Navigation dans les contrôles du player

Règles cibles :

* `left/right` :

  * soit seek direct,
  * soit navigation latérale entre boutons,
  * mais jamais les deux à la fois dans un même sous-mode sans règle explicite
* `up/down` :

  * changement de groupe,
  * ou ouverture d’un sous-panneau si documenté
* stop en bord,
* pas de wrap implicite.

Le point important ici est la lisibilité : chaque sous-mode du player doit être reconnaissable par l’utilisateur.

## 7.5 Sous-overlays du player

Exemples :

* sous-titres,
* pistes audio,
* qualité,
* vitesse,
* épisodes,
* options.

Chacun doit suivre le contrat overlay :

* ouverture mémorise le déclencheur,
* prise de focus,
* piégeage,
* `back` ferme le sous-overlay,
* restitution au contrôle déclencheur dans l’overlay principal du player,
* puis seulement, en fermeture suivante, retour à la surface ou sortie du player.

## 8. Cas limites à traiter explicitement

## 8.1 Déclencheur disparu

Si l’élément qui a ouvert l’overlay n’existe plus à la fermeture :

* suppression d’item,
* refresh,
* changement de liste,
* fermeture d’un état player,

alors :

* on utilise le fallback de page ou de zone,
* jamais de perte silencieuse du focus.

## 8.2 Overlay empilé sur overlay

Si un overlay ouvre un autre overlay :

* le focus appartient toujours à la couche la plus haute,
* `back` ferme d’abord la dernière couche ouverte,
* à la fermeture, restitution à l’overlay parent,
* pas de saut direct vers la page sous-jacente.

## 8.3 Loading dans un overlay

Si un overlay passe en chargement :

* pas de focus sur des éléments non montés,
* focus neutre ou maintien local si un contrôle reste valide,
* `back` doit rester cohérent si l’UX l’autorise.

## 8.4 Error dans un overlay

Si un overlay affiche une erreur :

* focus sur `Réessayer`, `Fermer`, ou l’action corrective principale,
* jamais sur un élément inactif.

## 8.5 Disparition/reconstruction des contrôles player

Quand le player masque puis réaffiche ses contrôles :

* le système doit tenter de revenir au contrôle principal pertinent ou au dernier contrôle valide,
* pas de réinitialisation incohérente à chaque affichage.

## 8.6 Scroll interne d’une sheet ou d’un menu long

Si la surface est scrollable :

* le focus doit rester stable,
* le scroll automatique ne doit pas faire perdre le focus,
* la navigation verticale doit rester lisible.

Ces exigences sont cohérentes avec les cas limites déjà identifiés sur les pages détail : reconstruction de contenu, zones scrollables, fallback clair. 

## 9. Travail concret à réaliser

## 9.1 Standardiser un contrat minimal d’overlay

Il faut un petit cadre commun, pas une usine à gaz :

* déclencheur mémorisé,
* point d’entrée overlay,
* fermeture standard,
* restitution standard.

Cela peut rester une petite brique technique dans `core/focus` ou `core/widgets`, sans absorber les règles métier de chaque overlay. C’est exactement le type de sous-ensemble limité recommandé par la phase 2.

## 9.2 Normaliser les surfaces overlay prioritaires

Ordre naturel :

* dialogs de confirmation,
* bottom sheets d’action,
* menus contextuels,
* premium/restricted sheets,
* overlays du player.

## 9.3 Verrouiller le `back` uniforme

Il faut fixer une hiérarchie claire :

1. fermer le sous-overlay actif,
2. sinon fermer l’overlay courant,
3. sinon revenir à la page précédente,
4. dans le player, sortir seulement après fermeture des contrôles/états intermédiaires.

## 9.4 Faire du player une référence locale

Comme `TvDetailPage` a servi de référence pour les pages détail, `VideoPlayerPage` doit devenir la référence des surfaces “mode-switching” :

* sans contrôles,
* avec contrôles,
* avec sous-overlays,
* avec restitution stable.

La phase 1 le plaçait déjà parmi les pages critiques visibles.

## 10. Ce qu’il ne faut pas faire en phase 7

* ne pas créer un gestionnaire global de tous les `FocusNode`,
* ne pas créer un routeur de focus parallèle,
* ne pas écrire un moteur universel de navigation pour toutes les modales et tous les players,
* ne pas mélanger shell, overlay et widget dans un helper unique,
* ne pas laisser les `PopupMenu`, dialogs ou sheets dépendre uniquement du comportement implicite Flutter,
* ne pas casser les contrats déjà stabilisés des pages sous-jacentes.

Ces interdictions sont directement dictées par la phase 2 et par tes règles de simplicité, clarté et responsabilité locale.

## 11. Critères de sortie

La phase 7 est terminée uniquement si :

* tout overlay prioritaire a un point d’entrée officiel,
* tout overlay capture le focus à l’ouverture,
* aucun overlay ne laisse fuiter le focus vers l’écran sous-jacent,
* `back` ferme toujours la couche active la plus haute,
* la restitution au déclencheur est fiable,
* un fallback sûr existe si le déclencheur a disparu,
* le player a des règles stables sans overlay et avec overlay,
* les sous-overlays du player ferment et restituent correctement,
* aucune abstraction lourde ou spéculative n’a été introduite,
* le code reste lisible et local.

## 12. Tests minimums

À vérifier au minimum :

Pour chaque dialog/sheet/menu :

* ouverture,
* focus initial,
* navigation interne,
* absence de fuite vers l’arrière-plan,
* `back`,
* fermeture,
* restitution au déclencheur,
* fallback si déclencheur disparu.

Pour le player :

* entrée dans `VideoPlayerPage`,
* `select` pour afficher/masquer les contrôles,
* navigation des contrôles,
* ouverture/fermeture d’un sous-overlay,
* `back` avec contrôles visibles,
* `back` depuis le player,
* restitution sur contrôle principal pertinent.

## 13. Ordre d’exécution recommandé

Je te conseille cet ordre :

1. dialogs de confirmation simples
2. bottom sheets d’action
3. menus contextuels
4. premium/restricted sheets
5. `VideoPlayerPage`
6. sous-overlays du player

Pourquoi :

* les overlays simples permettent de verrouiller rapidement le contrat capture/restitution,
* le player vient ensuite comme cas le plus riche,
* ses sous-overlays doivent être traités en dernier une fois la grammaire de base stabilisée.

## 14. Conclusion

La phase 7 doit transformer overlays et player en surfaces TV pleinement contrôlées :

* focus capturé,
* focus piégé,
* `back` uniforme,
* restitution fiable,
* aucune fuite.

En une phrase : après avoir standardisé les pages, la phase 7 standardise les **surfaces temporaires et les modes d’interaction superposés**. C’est la dernière grande brique fonctionnelle avant la phase 8 dédiée à la couverture de tests.
