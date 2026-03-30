# Vision d'adaptation TV / clavier

## Intention générale

L'objectif n'est pas seulement de rendre l'app "compatible télécommande", mais de lui donner un vrai langage de focus TV/PC :

- le focus doit être visible immédiatement ;
- il doit rester élégant et cohérent selon le type d'élément ;
- il doit guider la lecture de l'écran sans surcharger l'UI ;
- les déplacements doivent paraître naturels, prévisibles et continus.

Le focus doit donc être animé avec douceur, en gardant une sensation légère et premium.

## Règles visuelles du focus

### Animation

- Tous les éléments focusés s'agrandissent légèrement sauf textes.
- L'agrandissement doit être animé avec une transition douce.

### Médias et cartes

- Dans une liste horizontale de médias, seul le visuel est mis en avant.
- Le focus agrandit légèrement la carte.
- Le contour bleu doit entourer uniquement l'image, pas le texte.

- Les contenus "À continuer" suivent la même logique, avec un léger agrandissement et un contour accentué.

- Les épisodes doivent agrandir légèrement leur vignette et afficher un contour accent.

### Barre latérale

- Le focus dans la barre latérale doit reprendre le même langage visuel que le hover souris actuel.
- Cet effet doit s'appliquer à tous les items de navigation.

### Boutons et actions

- Le bouton primaire doit légèrement s'agrandir.
- Il doit afficher un contour bleu accent un peu plus clair que son fond.

- Le bouton favoris doit afficher un fond semi-transparent derrière l'icône lorsqu'il est focusé.

- Les icônes de recherche, d'ajout dans la librairie et d'ajout de source doivent aussi utiliser un fond semi-transparent derrière l'icône au focus.

- Le bouton de déconnexion doit avoir un traitement d'alerte clair : fond rouge et bordure rouge.

- Le bouton "changer de source active" doit afficher une bordure blanche.

### Filtres et éléments de structure

- Les filtres Home "Films" et "Séries" doivent prendre un fond accent et légèrement s'agrandir au focus.

- Les catégories et fournisseurs doivent afficher une bordure blanche au focus.

- Les playlists de la librairie doivent afficher une bordure blanche autour de l'image.

- Les filtres de la librairie doivent utiliser un fond un peu plus clair que le fond général de l'app.

- Les sections dans les paramètres doivent prendre un fond basé sur la couleur accent, mais beaucoup plus foncé.

- Les profils doivent afficher une bordure blanche autour de l'image ou de l'avatar.

## Règles de circulation du focus

### Listes horizontales

- Dans une liste horizontale, le focus doit pouvoir circuler du premier au dernier élément.
- Quand on se déplace vers la droite ou vers la gauche, la liste doit se décaler pour garder l'élément focusé visible à l'écran.

### Passage entre sections

- On doit pouvoir passer d'une liste à l'autre avec les flèches haut et bas.

### Barre latérale

- Une fois dans la barre latérale, la navigation doit se faire naturellement de haut en bas et de bas en haut.

- Depuis certains menus ou sous-contextes de l'accueil, la touche `Esc` doit ramener le focus vers l'entrée concernée dans la barre latérale.

### Hero Home

- Dans le hero, la navigation gauche/droite doit circuler entre les boutons et les icônes.
- Un appui vers le bas depuis le hero doit envoyer le focus vers le premier élément de la première liste horizontale.

### Recherche

- Dans la recherche, la navigation doit fonctionner normalement dans les grilles.
- L'historique de recherche doit être atteignable avec la flèche bas quand le focus est sur l'input.

### Librairie

- Dans la librairie, si le focus est sur une playlist de la première ligne, un appui vers le haut doit renvoyer vers les filtres de playlists.
- Depuis cette zone haute, un déplacement vers la droite doit permettre d'enchaîner les autres filtres puis les actions comme recherche et ajout.
- Un appui vers le bas depuis cette zone doit ramener vers les playlists.

## Résumé de la vision

Je comprends ta vision comme ceci :

- le focus doit devenir un vrai outil de lecture visuelle, pas juste un état technique ;
- chaque famille de composant doit avoir son propre traitement de focus, tout en restant cohérente avec le reste de l'app ;
- la navigation télécommande/clavier doit être pensée comme un parcours naturel entre zones, pas comme une simple succession de widgets focusables ;
- les listes horizontales, le hero, la barre latérale, la recherche et la librairie sont les zones les plus critiques à rendre fluides.
