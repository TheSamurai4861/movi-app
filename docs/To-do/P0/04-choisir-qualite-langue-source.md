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

- [x] Lister les variantes de versions réellement disponibles dans les données
- [x] Définir les préférences utilisateur pertinentes
- [x] Choisir le comportement par défaut au clic sur `Regarder`
- [x] Définir le contenu de la bottom sheet ou du sélecteur
- [x] Préparer l'implémentation avec une approche propre
- [x] Implémenter la logique de sélection
- [x] Tester les cas automatiques et manuels

## Critères de validation

- L'utilisateur peut comprendre quelle version va être lancée
- Le mode automatique choisit une version cohérente
- Le mode manuel permet un choix rapide sans friction excessive
- Les fallbacks restent prévisibles quand la version souhaitée n'existe pas

## Plan d'implémentation

### Étape 1 - Cadrage produit

- Cartographier les variantes réellement disponibles au lancement :
  - qualité détectable ou non
  - langue audio détectable ou non
  - sous-titres détectables ou non
  - source IPTV d'origine
  - type de média concerné :
    - film
    - épisode
- Définir 3 situations produit explicites :
  - une seule version :
    - lancer directement sans friction
  - plusieurs versions clairement comparables :
    - autoriser une sélection manuelle
  - plusieurs versions mais métadonnées partielles :
    - appliquer une règle automatique simple et explicable
- Acter le comportement du clic principal sur `Regarder` :
  - lancer directement la meilleure version si le choix est non ambigu
  - ouvrir un sélecteur si plusieurs versions restent crédibles
- Livrable :
  - une matrice courte `cas -> comportement attendu -> raison`
- Statut :
  - fait
- Sorties produites :
  - cartographie du lancement actuel
  - 3 situations produit retenues
  - matrice courte de comportement cible

#### Cartographie du lancement actuel

- Film
  - le clic `Regarder` appelle `buildMovieVideoSource`
  - le service de streaming récupère aujourd'hui une seule occurrence lisible via `XtreamLookupService`
  - la source active ou préférée filtre déjà les comptes IPTV avant ce choix
- Épisode
  - le clic sur un épisode cherche aujourd'hui le premier item série compatible dans les comptes IPTV actifs
  - l'URL de lecture est ensuite construite pour cet item unique
- Source IPTV d'origine
  - disponible avant lecture :
    - oui
  - niveau de fiabilité :
    - bon
  - état actuel :
    - exploitable pour prioriser ou départager
- Type de média
  - disponible avant lecture :
    - oui
  - état actuel :
    - exploitable pour distinguer film et épisode
- Qualité
  - disponible avant lecture :
    - non de manière fiable
  - état actuel :
    - non portée explicitement par `XtreamPlaylistItem`
    - au mieux parfois déductible du titre, donc trop fragile pour cadrer une règle P0 fiable
- Langue audio
  - disponible avant lecture :
    - non de manière fiable
  - état actuel :
    - la préférence existe déjà dans `PlayerPreferences`
    - la vraie sélection audio se fait après ouverture du média, via les pistes remontées par le player
- Sous-titres
  - disponibles avant lecture :
    - non de manière fiable
  - état actuel :
    - la préférence existe déjà dans `PlayerPreferences`
    - la vraie sélection sous-titres se fait après ouverture du média, via les pistes du player

#### Conclusion de cadrage

- En l'état du repo, le lancement peut être cadré proprement autour de :
  - la source IPTV
  - le type de média
  - l'existence d'une ou plusieurs variantes lisibles
- En revanche, la qualité, la langue audio et les sous-titres ne sont pas des critères fiables avant lecture pour cette étape 1
- Conséquence produit :
  - P0/04 doit d'abord choisir correctement entre variantes de source
  - les préférences audio et sous-titres restent appliquées dans le player après ouverture
  - la qualité ne doit pas piloter la décision automatique tant qu'un contrat de donnée explicite n'existe pas

#### 3 situations produit retenues

- Une seule version lisible
  - comportement :
    - lancer directement
  - raison :
    - aucun arbitrage utile à exposer
- Plusieurs versions clairement comparables
  - définition retenue pour P0 :
    - plusieurs variantes lisibles et distinctes principalement par source IPTV
  - comportement :
    - ouvrir un sélecteur manuel
  - raison :
    - la source est la seule différence fiable connue avant lecture
- Plusieurs versions mais métadonnées partielles
  - définition retenue pour P0 :
    - plusieurs variantes existent mais la qualité, la langue ou le détail utile ne sont pas assez fiables pour un vrai choix utilisateur
  - comportement :
    - lancer automatiquement la variante issue de la source active ou préférée si elle est unique
    - sinon lancer la première variante lisible selon un ordre déterministe
  - raison :
    - éviter un sélecteur trompeur fondé sur des labels incertains

#### Décision produit sur le clic `Regarder`

- Cas nominal
  - si une seule variante lisible existe dans la source active ou préférée :
    - lancer directement
- Cas multi-versions crédibles
  - si plusieurs variantes lisibles restent concurrentes après filtrage par source active ou préférée :
    - ouvrir un sélecteur
- Cas de données partielles
  - si plusieurs variantes existent mais qu'aucune information fiable ne permet de les différencier utilement côté utilisateur :
    - lancer automatiquement la meilleure variante déterministe
    - afficher ensuite les préférences audio / sous-titres dans le player comme aujourd'hui

#### Matrice courte

| Cas | Variantes observables avant lecture | Comportement attendu | Raison |
| --- | --- | --- | --- |
| `single_playable_movie` | un seul film lisible dans la source active | lancement direct | aucun choix utile |
| `single_playable_episode` | un seul épisode lisible dans la source active | lancement direct | aucun choix utile |
| `multi_source_same_media` | plusieurs variantes lisibles distinguées surtout par source IPTV | ouverture d'un sélecteur | la différence de source est fiable et compréhensible |
| `multi_source_partial_metadata` | plusieurs variantes lisibles mais qualité/langue incertaines | lancement automatique déterministe | ne pas exposer un faux choix |
| `no_ideal_variant` | aucune variante parfaite mais au moins une lisible | fallback sur la première variante lisible selon ordre stable | éviter un blocage |
| `no_playable_variant` | aucune URL construisible | ne pas lancer, afficher l'indisponibilité | pas de lecture possible |

### Étape 2 - Définition des règles de sélection

- Définir un contrat minimal pour comparer deux versions :
  - URL lisible obligatoire
  - type de contenu cohérent
  - identifiant de source stable
- Définir des critères explicites et ordonnés, pas un scoring opaque :
  - disponibilité de lecture
  - correspondance avec la source active ou préférée
  - correspondance avec la langue audio préférée
  - correspondance avec la présence ou la langue des sous-titres
  - qualité préférée si l'information est fiable
  - stabilité du fallback si l'information manque
- Prévoir des règles simples de dégradation :
  - si la qualité est inconnue :
    - ne pas exclure la version, mais la classer après une qualité connue équivalente
  - si la langue est inconnue :
    - garder la version candidate, mais la signaler comme incertaine
  - si aucune version ne matche les préférences :
    - prendre la première version lisible selon un ordre déterministe
- Séparer clairement :
  - préférence utilisateur
  - règle métier de classement
  - donnée brute fournie par la source
- Livrable :
  - une table de décision unique `préférences + variantes -> version retenue / ouverture du sélecteur`
- Statut :
  - fait
- Sorties produites :
  - contrat minimal de comparabilité
  - hiérarchie explicite de critères
  - règles de dégradation
  - table de décision unique

#### Contrat minimal retenu

- Une variante n'entre dans la comparaison que si les trois conditions suivantes sont vraies :
  - URL lisible construite ou constructible
  - type de contenu cohérent avec le lancement demandé :
    - film pour un film
    - épisode / série pour un épisode
  - identifiant de source stable :
    - `accountId` non vide
    - et identifiant de stream exploitable côté source
- Si ce contrat minimal échoue :
  - la variante est `non comparable`
  - elle ne doit pas être proposée comme option de lancement
- Ce contrat est volontairement minimal :
  - il protège la lecture
  - il ne suppose pas encore une qualité ou une langue fiables

#### Séparation des responsabilités actée

- Donnée brute fournie par la source
  - URL potentielle
  - `accountId`
  - type de média
  - éventuels indices de qualité ou de langue
- Préférence utilisateur
  - source active ou préférée
  - préférence audio persistée
  - préférence sous-titres persistée
  - préférence qualité seulement si une donnée fiable existe plus tard
- Règle métier de classement
  - décide si une variante est comparable
  - classe les variantes comparables
  - décide entre :
    - lancement automatique
    - ouverture du sélecteur
    - indisponibilité

#### Règle de sélection retenue

- La sélection ne repose pas sur un score global
- Elle repose sur une hiérarchie ordonnée de critères, appliqués dans cet ordre :
  1. variante comparable ou non
  2. correspondance avec la source active ou préférée
  3. présence d'une différence fiable et utile à exposer à l'utilisateur
  4. qualité explicite si elle existe vraiment dans le modèle métier
  5. langue audio explicite si elle existe vraiment avant lecture
  6. sous-titres explicites si l'information est fiable avant lecture
  7. tie-breaker déterministe final

#### Interprétation pratique des critères

- Disponibilité de lecture
  - critère éliminatoire
  - une variante non lisible sort de la comparaison
- Source active ou préférée
  - critère prioritaire pour P0
  - si une seule variante comparable appartient à la source active ou préférée :
    - elle gagne automatiquement
  - si plusieurs variantes comparables appartiennent à cette source :
    - elles restent concurrentes
- Langue audio préférée
  - critère non prioritaire avant lecture dans l'état actuel du repo
  - raison :
    - la préférence existe
    - mais la donnée fiable n'est disponible qu'après ouverture via les pistes du player
  - conséquence :
    - ne doit pas éliminer ni surclasser seule une variante avant lecture
    - reste appliquée après ouverture via `PlayerPreferences`
- Sous-titres
  - même règle que pour l'audio
  - la préférence existe déjà
  - elle ne doit pas piloter la comparaison avant lecture sans métadonnée fiable
- Qualité
  - critère optionnel
  - utilisable seulement si une qualité explicite est portée par le futur objet métier de variante
  - tant qu'elle est seulement déduite d'un titre bruité :
    - elle ne doit pas devenir un critère prioritaire de lancement
- Tie-breaker déterministe
  - si plusieurs variantes restent à égalité après les critères fiables :
    - ordre stable par source puis identifiant stable
  - objectif :
    - éviter un comportement perçu comme aléatoire

#### Règles de dégradation retenues

- Si la qualité est inconnue
  - la variante reste comparable
  - elle est classée après une variante équivalente avec qualité explicite fiable
  - elle ne déclenche pas seule l'ouverture du sélecteur
- Si la langue est inconnue
  - la variante reste comparable
  - elle est marquée comme incertaine dans le futur état UI si besoin
  - elle ne doit pas être exclue
- Si les sous-titres sont inconnus
  - même logique que la langue
  - pas d'exclusion automatique
- Si aucune variante ne matche les préférences
  - prendre la première variante comparable selon l'ordre déterministe
  - ne pas bloquer la lecture
- Si plusieurs variantes restent comparables mais qu'aucune différence fiable n'est exploitable
  - lancer automatiquement la première variante déterministe
  - ne pas ouvrir un sélecteur purement décoratif

#### Décision d'ouverture du sélecteur

- Le sélecteur manuel s'ouvre uniquement si les deux conditions suivantes sont vraies :
  - au moins deux variantes comparables existent
  - au moins une différence fiable et compréhensible peut être montrée :
    - source IPTV
    - qualité explicite
    - langue explicite
- Sinon :
  - lancement automatique

#### Table de décision unique

| Préférences + variantes | Décision | Variante retenue / comportement |
| --- | --- | --- |
| aucune variante comparable | `unavailable` | ne pas lancer, afficher l'indisponibilité |
| une seule variante comparable | `autoPlay` | lancer cette variante |
| plusieurs variantes comparables, une seule sur la source active ou préférée | `autoPlay` | lancer la variante de la source active ou préférée |
| plusieurs variantes comparables sur la source active ou préférée, sans différence fiable utile | `autoPlay` | lancer la première variante selon l'ordre déterministe |
| plusieurs variantes comparables avec différence fiable exposable | `manualChoice` | ouvrir le sélecteur avec liste triée |
| aucune variante ne matche les préférences mais au moins une reste comparable | `autoPlayFallback` | lancer la première variante comparable selon l'ordre déterministe |

#### Conséquence d'architecture retenue

- La sélection avant lecture choisit une `variante`
- Le player applique ensuite les préférences de pistes sur le média ouvert
- Donc :
  - la logique `avant lecture` ne doit pas dupliquer la logique `audio / sous-titres` déjà portée par le player
  - la logique `audio / sous-titres` ne doit pas devenir un faux critère de comparaison si la donnée n'existe pas encore

### Étape 3 - Préparation d'implémentation

- Garder les services de construction d'URL et de streaming centrés sur leur rôle :
  - ils construisent une source lisible
  - ils ne décident pas seuls quelle variante lancer
- Introduire un module métier dédié à la sélection de version :
  - responsabilité unique :
    - comparer
    - classer
    - choisir
  - entrée :
    - variantes candidates normalisées
    - préférences de lecture
    - contexte de lancement
  - sortie :
    - décision automatique ou besoin de choix manuel
    - raison de la décision
    - liste triée pour l'UI
- Réutiliser l'existant quand c'est déjà au bon niveau :
  - `PlayerPreferences` pour audio / sous-titres
  - source IPTV active ou préférée déjà persistée
  - `BuildMovieVideoSource` comme point d'intégration film si la sélection reste localisée en amont
- Prévoir des objets explicites plutôt que des booléens dispersés :
  - exemple :
    - `PlaybackVariant`
    - `PlaybackSelectionPreferences`
    - `PlaybackSelectionDecision`
- Livrable :
  - design court des responsabilités et points d'intégration UI / domaine / préférences
- Statut :
  - fait
- Sorties produites :
  - design court des responsabilités
  - points d'intégration retenus
  - objets métier explicites

#### Responsabilités retenues

- `MovieStreamingService` et `XtreamStreamUrlBuilder`
  - construisent une source lisible
  - ne comparent pas plusieurs variantes
  - ne portent pas les préférences utilisateur
- `BuildMovieVideoSource`
  - reste un point d'orchestration film
  - enrichit une source déjà choisie avec la position de reprise
  - ne doit pas contenir la logique de classement des variantes
- `NextEpisodeService`
  - reste responsable du calcul de l'épisode suivant et de la construction de la source
  - ne doit pas devenir le moteur générique de sélection de variantes
- Nouveau module métier dédié de sélection
  - responsabilité unique :
    - normaliser
    - comparer
    - classer
    - décider
  - il reçoit des variantes candidates déjà extraites
  - il renvoie une décision prête à être consommée par l'UI ou un use case applicatif

#### Objets explicites retenus

- `PlaybackVariant`
  - représente une variante candidate comparable avant lecture
  - champs utiles visés :
    - identifiant stable de variante
    - identifiant de source
    - type de média
    - capacité de lecture
    - qualité explicite éventuelle
    - langue audio explicite éventuelle
    - présence ou langue de sous-titres éventuelle
    - données d'affichage pour le futur sélecteur
- `PlaybackSelectionPreferences`
  - regroupe les préférences utiles à la décision
  - évite une signature avec trop de paramètres
  - porte au minimum :
    - source active ou préférée
    - préférence audio persistée
    - préférence sous-titres persistée
    - préférence qualité seulement si elle est réellement activée plus tard
- `PlaybackSelectionContext`
  - porte le contexte de lancement
  - exemple :
    - film ou épisode
    - mode automatique ou manuel
    - autorisation d'ouvrir un sélecteur
- `PlaybackSelectionDecision`
  - sortie unique de la comparaison
  - expose :
    - décision :
      - `autoPlay`
      - `manualChoice`
      - `unavailable`
    - variante retenue si applicable
    - raison de la décision
    - liste triée pour le sélecteur si besoin
- `PlaybackSelectionReason`
  - code métier stable pour éviter les chaînes libres dans les providers et widgets

#### Flux d'intégration retenu

1. Le point d'entrée film ou épisode collecte les variantes candidates
2. Un normaliseur les convertit en `PlaybackVariant`
3. Le module de sélection applique `PlaybackSelectionPreferences` et `PlaybackSelectionContext`
4. Le résultat produit un `PlaybackSelectionDecision`
5. Le point d'entrée :
   - lance directement la variante retenue
   - ou ouvre un sélecteur avec la liste triée
6. Une fois le média ouvert, le player applique ses propres préférences de pistes

#### Points d'intégration retenus

- Film
  - point d'entrée naturel :
    - `buildMovieVideoSourceProvider`
    - ou le use case `BuildMovieVideoSource` juste en amont de la construction finale
  - contrainte :
    - ne pas casser la logique actuelle de reprise
- Épisode
  - point d'entrée à isoler hors de la page si la sélection multi-variantes est introduite
  - le code actuellement dans `tv_detail_page.dart` doit à terme déléguer la sélection à un module dédié
  - contrainte :
    - ne pas mélanger sélection de variante et conversion TMDB/Xtream des numéros d'épisodes
- Préférences
  - `PlayerPreferences`
    - reste la source de vérité pour audio / sous-titres
  - source IPTV active ou préférée
    - reste lue via l'état applicatif existant
  - le nouveau module lit des préférences déjà préparées
    - il ne doit pas persister lui-même des valeurs

#### Réutilisation de l'existant confirmée

- À conserver tel quel
  - `PlayerPreferences` pour les préférences de pistes
  - `appStateControllerProvider.preferredIptvSourceIds` pour la source active ou préférée
  - `BuildMovieVideoSource` pour l'enrichissement final de la source film
  - `NextEpisodeService` pour le calcul d'épisode suivant
- À ne pas surcharger
  - `MovieStreamingServiceImpl`
  - `XtreamLookupService`
  - `XtreamStreamUrlBuilderImpl`
  - les pages détail film / série

#### Contraintes d'architecture confirmées

- Pas de logique de comparaison métier dans les widgets
- Pas de logique de persistance dans le module de sélection
- Pas de service unique mélangeant :
  - extraction des variantes
  - comparaison métier
  - construction d'URL
  - affichage du sélecteur
- Les pages et providers doivent consommer une décision déjà interprétée
- Les raisons de décision doivent être exposées via des objets ou enums stables, pas via du texte libre

### Étape 4 - Implémentation

- Implémenter par petits lots pour limiter le risque :
  - lot 1 :
    - normaliser les variantes disponibles dans un format métier commun
  - lot 2 :
    - appliquer le classement automatique et les fallbacks
  - lot 3 :
    - brancher le clic `Regarder` sur la décision automatique ou l'ouverture du sélecteur
  - lot 4 :
    - connecter les préférences utilisateur minimales utiles
- Garder l'UI passive :
  - la bottom sheet affiche des variantes déjà triées et qualifiées
  - elle ne reconstitue pas les règles de priorité
- Éviter une god class :
  - ne pas fusionner parsing source, persistance des préférences, sélection métier et rendu UI
- Ajouter seulement les logs utiles :
  - variante ignorée car non lisible
  - impossibilité de départager automatiquement un cas pourtant attendu comme simple
- Livrable :
  - flux de lancement déterministe et sélecteur manuel limité aux cas où il apporte une vraie valeur
- Statut :
  - fait sur le flux film
- Sorties produites :
  - variantes film normalisées dans un format métier commun
  - service de classement pur et réutilisable
  - décision de lancement branchée sur `Regarder`
  - bottom sheet passive pour les cas manuels
  - préférences minimales connectées :
    - source IPTV explicitement sélectionnée
    - langue audio
    - langue de sous-titres

#### Implémentation réalisée

- Lot 1 :
  - `MoviePlaybackVariantResolver` extrait les variantes film candidates depuis les playlists IPTV actives
  - chaque variante est normalisée en `PlaybackVariant` avec :
    - identifiant stable
    - source IPTV
    - `VideoSource`
    - indices légers de qualité / audio / sous-titres quand ils sont lisibles dans le titre
  - les variantes non lisibles sont écartées avec un log ciblé
- Lot 2 :
  - `PlaybackSelectionService` applique une hiérarchie explicite de critères :
    - source explicitement sélectionnée
    - langue audio préférée si la métadonnée existe
    - sous-titres préférés si la métadonnée existe
    - qualité préférée si disponible plus tard
    - fallback déterministe stable
  - la sortie est une `PlaybackSelectionDecision` avec :
    - `autoPlay`
    - `manualSelection`
    - `unavailable`
    - et une raison stable
- Lot 3 :
  - le clic `Regarder` du détail film consomme désormais une décision métier déjà interprétée
  - la page :
    - lance directement la variante retenue si le cas est non ambigu
    - ouvre une bottom sheet seulement quand plusieurs variantes restent crédibles
- Lot 4 :
  - les comptes IPTV actifs définissent le périmètre des variantes candidates
  - la source IPTV explicitement sélectionnée devient la vraie préférence de classement
  - `PlayerPreferences` est réutilisé pour audio / sous-titres sans dupliquer la logique de pistes du player

#### Répartition des responsabilités après câblage

- `MoviePlaybackVariantResolver`
  - responsabilité :
    - trouver et normaliser les variantes film lisibles
- `PlaybackSelectionService`
  - responsabilité :
    - classer
    - départager
    - décider auto / manuel / indisponible
- `ResolveMoviePlaybackSelection`
  - responsabilité :
    - orchestrer la résolution des variantes
    - réinjecter la reprise de lecture
    - produire la décision finale pour la présentation
- `MovieDetailPage`
  - responsabilité :
    - consommer la décision
    - afficher un sélecteur passif si nécessaire

#### Portée assumée pour ce lot

- Le flux film est câblé de bout en bout
- Le module de sélection reste réutilisable pour les épisodes, mais le branchement UI épisode peut être traité séparément pour éviter de durcir la grosse page série dans ce lot

### Étape 5 - Vérification

- Ajouter des tests unitaires sur les règles de classement :
  - source préférée
  - langue audio préférée
  - qualité préférée
  - fallback quand une métadonnée est absente
- Ajouter des tests de service sur les cas limites :
  - une seule version valide
  - plusieurs versions équivalentes
  - aucune version idéale
  - qualité inconnue
  - langue inconnue
- Ajouter quelques tests widget ciblés :
  - bouton `Regarder` qui lance directement
  - bouton `Regarder` qui ouvre le sélecteur
  - bottom sheet lisible avec données partielles
- Vérifier au minimum :
  - détail film
  - détail épisode / série si flux distinct
  - reprise de lecture avec source sélectionnée
  - respect des préférences audio / sous-titres persistées
- Critère de fin :
  - le lancement est prévisible, explicable et testé sans dépendre d'une logique UI implicite
- Statut :
  - fait pour le flux film implémenté
- Sorties produites :
  - tests unitaires sur les règles de classement
  - tests de service sur les cas limites de sélection
  - tests widget ciblés sur le bouton `Regarder` et la bottom sheet
  - vérification de la reprise de lecture et de la remontée des préférences persistées

#### Vérification réalisée

- Règles de classement
  - source préférée
  - langue audio préférée
  - fallback déterministe quand une métadonnée est absente
  - ambiguïté menant à un choix manuel
- Cas limites de service
  - une seule version valide
  - plusieurs versions équivalentes
  - qualité inconnue
  - langue inconnue
  - reprise de lecture réinjectée dans la variante retenue
- Widgets ciblés
  - `Regarder` lance directement quand la décision est `autoPlay`
  - `Regarder` ouvre le sélecteur quand la décision est `manualSelection`
  - la bottom sheet reste lisible avec des métadonnées partielles
- Préférences persistées
  - la source IPTV explicitement sélectionnée est bien transmise à la décision
  - les préférences audio / sous-titres persistées sont bien remontées au provider de sélection

#### Fichiers de test ajoutés ou complétés

- `test/features/player/application/services/playback_selection_service_test.dart`
- `test/features/movie/data/services/movie_playback_variant_resolver_impl_test.dart`
- `test/features/movie/domain/usecases/resolve_movie_playback_selection_test.dart`
- `test/features/movie/presentation/providers/movie_playback_selection_provider_test.dart`
- `test/features/movie/presentation/widgets/movie_playback_variant_sheet_test.dart`
- `test/features/movie/presentation/pages/movie_detail_page_playback_test.dart`

#### Vérifications exécutées

- `flutter test test/features/player/application/services/playback_selection_service_test.dart test/features/movie/data/services/movie_playback_variant_resolver_impl_test.dart test/features/movie/domain/usecases/resolve_movie_playback_selection_test.dart test/features/movie/presentation/providers/movie_playback_selection_provider_test.dart test/features/movie/presentation/widgets/movie_playback_variant_sheet_test.dart test/features/movie/presentation/pages/movie_detail_page_playback_test.dart`
- `flutter analyze`

#### Couverture minimum et point restant

- Couvert dans ce lot
  - détail film
  - reprise de lecture avec source sélectionnée
  - respect des préférences audio / sous-titres persistées côté décision de lancement
- Point restant explicite
  - le flux détail épisode / série reste distinct dans le repo actuel et n'a pas encore été recâblé sur le module commun de sélection
  - il conserve donc une dette de vérification dédiée pour un lot séparé

## Risques / points d'attention

- Introduire un scoring implicite impossible à expliquer en support ou en debug
- Mélanger préférences utilisateur, règles métier et contraintes techniques dans un même service
- Déduire trop agressivement la qualité ou la langue à partir de labels bruités
- Faire porter à la bottom sheet la logique de sélection au lieu de lui fournir un état déjà interprété
- Diverger entre le flux film et le flux épisode sans contrat métier partagé

## Questions ouvertes

- Quelles métadonnées de qualité et de langue sont réellement fiables dans les sources actuelles ?
- Le mode automatique doit-il privilégier la source active, ou seulement l'utiliser comme premier tie-breaker ?
- À partir de combien de variantes proches le choix manuel devient-il préférable au lancement automatique ?
- Faut-il mémoriser un dernier choix manuel par média, par source ou seulement des préférences globales ?

## Notes complémentaires

- Approche recommandée :
  - d'abord rendre la décision de lancement déterministe
  - ensuite enrichir les préférences si les données source le permettent
- Principe d'architecture :
  - variantes normalisées dans la couche métier
  - décision de sélection dans un service dédié
  - rendu et interaction dans une UI passive
- Point d'appui existant :
  - `PlayerPreferences` couvre déjà une partie des préférences audio / sous-titres, donc la to-do doit s'appuyer dessus avant d'ajouter de nouveaux stockages
  
## Seconde Roadmap

### Objectif

- Corriger le regroupement trop strict des variantes film
- Faire apparaître le sélecteur manuel quand plusieurs versions réelles du même film existent
- Exposer les préférences de lecture utiles dans les réglages
- Garder une architecture propre :
  - matching métier hors UI
  - préférences persistées hors widget
  - bottom sheet purement passive

### Étape A - Cadrer le matching réel des variantes

- Définir une hiérarchie de rapprochement explicite :
  - `streamId` identique
  - puis `tmdbId` identique
  - puis `titre nettoyé + année` compatibles
- Encadrer strictement le fallback par titre :
  - même type de contenu
  - titre nettoyé significatif
  - année cohérente si disponible
  - pas de matching flou trop permissif
- Livrable :
  - table de décision `source item -> groupe de variantes`

Statut : fait

Sorties produites :
- hiérarchie de rapprochement actée
- fallback par titre borné par des règles conservatrices
- table de décision `source item -> groupe de variantes` ajoutée

Principe retenu :
Le regroupement doit rester déterministe, explicable et prudent. Pour `P0`, on préfère manquer un regroupement valide plutôt que fusionner deux films différents. Le matching flou n'est donc pas retenu.

Hiérarchie de rapprochement retenue :

1. `streamId` identique
   - signal le plus fort
   - deux items avec le même `streamId` appartiennent au même groupe de variantes

2. `tmdbId` identique
   - utilisable seulement si le type de contenu est cohérent
   - deux items avec le même `tmdbId` et le même type appartiennent au même groupe, même si le `streamId` diffère

3. `titre nettoyé + année` compatibles
   - fallback seulement si `streamId` et `tmdbId` ne permettent pas de conclure
   - ce niveau reste strict et ne doit pas glisser vers une similarité approximative

Contrat strict du fallback par titre :
- même type de contenu obligatoire
- `titre nettoyé` significatif obligatoire
- comparaison par égalité stricte du titre nettoyé
- si les deux années sont connues, elles doivent être identiques
- si une seule année est connue, le rapprochement reste possible mais moins robuste
- si les deux années sont absentes, le rapprochement ne reste acceptable que pour un titre clairement discriminant

Cas explicitement refusés :
- type de contenu différent
- titre nettoyé vide, trop court ou non discriminant
- titres seulement proches mais non identiques après nettoyage
- années contradictoires quand elles sont toutes les deux disponibles
- rapprochement basé seulement sur la qualité, la langue, la source IPTV ou l'extension de l'URL

Table de décision `source item -> groupe de variantes` :

| Cas observé | Décision | Raison |
| --- | --- | --- |
| `streamId` identique | `same_group_strict` | identifiant source stable le plus fiable |
| `streamId` différent, `tmdbId` identique, type identique | `same_group_strict` | identifiant métier externe assez fiable |
| `tmdbId` absent ou inutilisable, titre nettoyé identique, année identique | `same_group_compatible` | fallback acceptable et explicable |
| `tmdbId` absent ou inutilisable, titre nettoyé identique, une seule année connue | `same_group_compatible` | fallback acceptable mais moins robuste |
| `tmdbId` absent ou inutilisable, titre nettoyé identique, deux années absentes | `same_group_compatible_low_confidence` | fallback faible, à n'utiliser que pour un titre discriminant |
| titre nettoyé identique mais années contradictoires | `different_group` | risque de fusion erronée trop élevé |
| `tmdbId` identique mais type différent | `different_group` | contradiction métier, le type prime |
| titres similaires mais non identiques après nettoyage | `different_group` | pas de matching flou en `P0` |
| métadonnées insuffisantes pour conclure | `different_group` | comportement sûr et prévisible par défaut |

Conséquence d'architecture retenue :
- le regroupement doit vivre dans un module métier dédié
- la bottom sheet ne doit afficher que des variantes déjà regroupées et triées
- les widgets, providers et services de streaming ne doivent pas reconstruire localement ces règles

### Étape B - Isoler le regroupement dans un module dédié

- Ne pas gonfler `MoviePlaybackVariantResolverImpl` avec tout le matching
- Extraire un composant métier dédié, par exemple :
  - `MovieVariantMatcher`
  - ou `MovieVariantGroupingService`
- Responsabilité unique :
  - dire si deux items appartiennent au même film de lecture
- Entrées :
  - item de référence
  - item candidat
- Sortie :
  - match strict
  - match compatible
  - pas de match
- Livrable :
  - contrat clair entre regroupement et résolution de variantes

Statut : fait

Sorties produites :
- responsabilité du module de regroupement clarifiée
- contrat d'entrée / sortie défini
- frontière claire entre regroupement métier et résolution de variantes actée

Principe retenu :
`MoviePlaybackVariantResolverImpl` doit rester un orchestrateur de résolution de variantes lisibles. Il peut filtrer, enrichir et transformer des items en variantes de lecture, mais il ne doit pas porter seul toute la logique de rapprochement métier entre films.

Module retenu :
- nom cible recommandé : `MovieVariantMatcher`
- alternative acceptable si la portée s'élargit plus tard : `MovieVariantGroupingService`

Choix retenu pour `P0` :
- commencer par un composant focalisé `MovieVariantMatcher`
- responsabilité unique : déterminer le niveau de rapprochement entre un item de référence et un item candidat

Responsabilité du module :
- comparer deux items déjà mappés
- appliquer la hiérarchie `streamId -> tmdbId -> titre nettoyé + année`
- retourner un résultat de matching explicite

Ce que le module ne doit pas faire :
- construire des URL de lecture
- charger des données externes
- trier les variantes pour l'UI
- appliquer les préférences utilisateur
- logger des événements de streaming

Entrées du module :
- `referenceItem`
- `candidateItem`

Préconditions :
- les deux items sont déjà dans un format métier exploitable
- le nettoyage de titre réutilise les services existants au bon niveau
- le matcher ne dépend ni de l'UI ni d'un repository

Sortie attendue :
- un objet explicite du type `MovieVariantMatchResult`
- cet objet porte :
  - `matchKind`
  - `reason`
  - éventuellement les éléments normalisés utiles au diagnostic

Valeurs métier recommandées :
- `strict`
  - même `streamId`
  - ou même `tmdbId` avec type cohérent
- `compatible`
  - fallback strict par `titre nettoyé + année`
- `none`
  - aucun rapprochement sûr

Raison de décision attendue :
- `sameStreamId`
- `sameTmdbId`
- `sameCleanTitleAndYear`
- `sameCleanTitleSingleKnownYear`
- `insufficientMetadata`
- `conflictingYear`
- `contentTypeMismatch`
- `cleanTitleMismatch`

Contrat entre regroupement et résolution de variantes :
- le matcher répond uniquement à la question : "ces deux items appartiennent-ils au même film de lecture ?"
- le résolveur consomme ce résultat pour :
  - inclure ou exclure un candidat
  - distinguer un rapprochement strict d'un rapprochement compatible
  - produire ensuite la liste de variantes lisibles
- le résolveur reste propriétaire :
  - du filtrage lecture possible / impossible
  - de la transformation vers `PlaybackVariant`
  - du classement final pour la sélection automatique ou manuelle

Point d'intégration retenu :
- `MoviePlaybackVariantResolverImpl` parcourt les items candidats
- il délègue le rapprochement au matcher
- il n'embarque plus localement les règles fines de comparaison

Conséquence d'architecture :
- la règle métier devient testable isolément
- le résolveur film reste lisible et spécialisé
- l'UI continue de consommer un état déjà interprété

### Étape C - Brancher le matching enrichi sur le flux film

- Faire consommer au résolveur film le nouveau matching hiérarchique
- Conserver les logs utiles uniquement :
  - variante écartée car non lisible
  - variante écartée car rapprochement trop faible
- Garder le classement inchangé tant que le vrai problème est l'identification des variantes
- Livrable :
  - bottom sheet affichée quand plusieurs variantes du même film sont enfin détectées

Statut : fait

Sorties produites :
- regroupement hiérarchique branché sur le flux film
- logs limités aux variantes non lisibles et aux rapprochements trop faibles
- classement de lecture conservé tel quel

Implémentation retenue :
- `MoviePlaybackVariantResolverImpl` délègue maintenant le rapprochement à `MovieVariantMatcher`
- le flux film utilise une référence explicite :
  - item IPTV réel si la page vient d'un `xtream:*`
  - référence synthétique `tmdbId + titre + année` si la page vient d'un film TMDB
- les variantes sont donc regroupées par :
  - `streamId` identique
  - puis `tmdbId` identique
  - puis `titre nettoyé + année` compatibles

Logs conservés :
- variante ignorée car URL de lecture absente
- variante ignorée car rapprochement jugé trop faible :
  - année contradictoire
  - `tmdbId` contradictoire

Point de stabilité retenu :
- le classement automatique ne change pas
- la bottom sheet s'ouvre seulement parce que l'identification des variantes est enfin plus juste

Validation réalisée :
- cas `xtream:*` avec variantes `VF` / `VOSTFR` et `streamId` différents
- cas TMDB avec une variante stricte et une variante compatible sans `tmdbId`
- vérification du flux page film, provider, use case, service et widget

### Étape D - Exposer les préférences dans les réglages

- Ajouter une section `Lecture` dans `Settings`
- Réutiliser l'existant avant d'ajouter de nouveaux stockages :
  - `SelectedIptvSourcePreferences` pour la source préférée
  - `PlayerPreferences` pour audio / sous-titres
- Ajouter une préférence de qualité seulement si son contrat métier est stabilisé
- Ne pas dupliquer dans `SettingsPage` la logique de sélection de variante
- Livrable :
  - entrées de réglages simples pour :
    - source préférée
    - langue audio préférée
    - langue de sous-titres préférée
    - qualité préférée si activée

Statut : fait

Sorties produites :
- section `Lecture` ajoutée dans `Settings`
- réutilisation de `SelectedIptvSourcePreferences` pour la source préférée
- réutilisation de `PlayerPreferences` pour audio et sous-titres
- aucun nouveau stockage introduit pour la qualité

Implémentation retenue :
- `SettingsPage` expose maintenant :
  - `Source préférée`
  - `Langue audio`
  - `Sous-titres`
- la sélection de source reste déléguée à la page dédiée de choix de source
- les préférences audio et sous-titres passent par des sélecteurs simples et persistés

Point d'architecture retenu :
- l'UI règle uniquement des préférences utilisateur
- elle ne décide ni du matching des variantes ni du classement de lecture
- la qualité préférée n'est pas exposée tant que le contrat métier reste partiel

Validation réalisée :
- compilation et analyse complètes
- test ciblé du provider réactif de source sélectionnée
- test existant de propagation des préférences vers le flux de sélection film

Statut : fait

Sorties produites :
- tests unitaires complétés sur le matching métier
- tests de service complétés sur les cas multi-source et mono-variante
- test widget ajouté sur les réglages `Lecture`
- test widget film conservé pour l'ouverture de la bottom sheet quand plusieurs variantes restent en concurrence

Validation réalisée :
- matching :
  - même `tmdbId`
  - même titre nettoyé
  - année absente
  - faux positifs refusés
- service :
  - variantes multi-source avec `tmdbId` partagé
  - variantes multi-source sans `tmdbId` mais avec titre cohérent
  - film unique sans bottom sheet
- widget :
  - `SettingsPage` sur la section `Lecture`
  - page film avec ouverture du sélecteur manuel quand plusieurs variantes restent crédibles

Livrable atteint :
- comportement visible cohérent entre playlists réelles, bouton `Regarder` et réglages
- zones dégradées localisées dans des modules clairs :
  - matcher métier
  - résolveur film
  - préférences persistées
  - UI passive

### Étape E - Vérifier les régressions et cas réels

- Ajouter des tests unitaires sur le matching :
  - même `tmdbId`
  - même titre nettoyé
  - année absente
  - faux positifs refusés
- Ajouter des tests de service :
  - variantes multi-source avec `tmdbId` partagé
  - variantes multi-source sans `tmdbId` mais avec titre cohérent
  - film unique sans bottom sheet
- Ajouter des tests widget ciblés :
  - réglages `Lecture`
  - bottom sheet présente quand le regroupement par titre fonctionne
- Livrable :
  - comportement visible cohérent entre playlists réelles, bouton `Regarder` et réglages

### Risques à éviter sur cette seconde roadmap

- Introduire un matching approximatif qui groupe de faux films
- Mettre la logique de rapprochement directement dans le widget ou le provider UI
- Mélanger réglages de lecture avant lancement et réglages de pistes du player
- Ajouter une préférence de qualité avant d'avoir un contrat de donnée suffisamment fiable

### Priorité recommandée

1. regroupement de variantes par `tmdbId` ou `titre nettoyé + année`
2. validation widget sur la bottom sheet réelle
3. section `Lecture` dans les réglages
4. qualité préférée seulement si les données réelles sont assez stables

## Troisième Roadmap

### Constat réel après implémentation

- Le matching film est meilleur, mais le clic principal sur `Regarder` reste piloté par une logique de classement automatique.
- Conséquence :
  - si une variante est classée première sans ambiguïté stricte, la lecture démarre directement
  - la bottom sheet n'apparaît donc pas, même si l'utilisateur s'attend à choisir entre `4K`, `HDR10`, `VF`, `VO` ou `VOST`
- Les préférences audio et sous-titres existent dans `PlayerPreferences`, mais leur effet au démarrage du player n'est pas encore assez fiable ni assez visible pour être perçu comme "directement appliqué".
- La qualité préférée n'est pas encore un vrai réglage utilisateur :
  - le modèle métier accepte déjà `preferredQualityRank`
  - mais aucun stockage ni écran de réglage propre ne l'expose
- Le réglage `Source préférée` influence aujourd'hui trop fortement l'expérience de lancement par rapport à la qualité, ce qui crée un décalage produit.

### Objectif de cette 3e roadmap

- Rendre explicite la différence entre :
  - lancement automatique rapide
  - choix manuel volontaire d'une version
  - préférences de pistes appliquées dans le player
- Ajouter une préférence qualité propre sans détourner `Source préférée`
- Vérifier le comportement visible de bout en bout sur des cas réels

### Étape F - Requalifier le comportement du clic `Regarder`

- Définir explicitement le contrat produit du bouton principal :
  - soit `Regarder` lance la meilleure variante automatiquement
  - soit `Regarder` devient un vrai point d'entrée de choix manuel dès qu'il existe plusieurs variantes utiles
- Si les deux usages doivent coexister :
  - garder `Regarder` pour l'auto-play déterministe
  - ajouter une action distincte du type `Versions` ou `Choisir une version`
- Ne pas laisser la bottom sheet dépendre uniquement d'une ambiguïté technique interne du ranking
- Livrable :
  - matrice courte `contexte -> action principale -> ouverture sheet ou non`

Statut : fait

Sorties produites :
- contrat produit explicite entre `Regarder` et choix manuel
- décision de coexistence retenue
- matrice courte `contexte -> action principale -> ouverture sheet ou non`

Décision produit retenue :

- `Regarder` reste l'action principale de lancement rapide
- `Regarder` doit lancer la meilleure variante automatiquement quand le but principal est de démarrer vite
- le choix manuel de version ne doit plus dépendre uniquement d'une ambiguïté technique du ranking
- dès qu'il existe plusieurs variantes utiles à comparer pour l'utilisateur, une action distincte doit être disponible :
  - `Versions`
  - ou `Choisir une version`

Pourquoi ce choix est retenu :

- il respecte le besoin de lancement rapide sans friction
- il répond au besoin réel de choisir entre `4K`, `HDR10`, `VF`, `VO` ou `VOST`
- il évite de détourner `Regarder` en comportement instable selon des détails internes de classement
- il garde une architecture propre :
  - le service métier décide si un choix manuel utile existe
  - l'UI expose ensuite soit une action simple, soit une action supplémentaire

Contrat produit explicite du bouton principal :

- `Regarder`
  - rôle :
    - lancer immédiatement la meilleure variante déterministe
  - ne doit pas :
    - ouvrir parfois une sheet uniquement parce que deux scores internes sont à égalité
- `Versions` ou `Choisir une version`
  - rôle :
    - ouvrir la liste triée des variantes quand plusieurs versions utiles existent
  - ne doit apparaître que si :
    - plusieurs variantes lisibles existent
    - et qu'au moins une différence utile peut être montrée :
      - qualité
      - langue
      - sous-titres
      - source
      - plage dynamique ou autre label fiable

Conséquence d'architecture retenue :

- le service de sélection doit produire deux informations distinctes :
  - quelle variante gagne en auto-play
  - si un choix manuel utile doit être proposé
- la bottom sheet devient une capacité d'UI explicitement déclenchable
- `MovieDetailPage` ne doit plus inférer ce comportement à partir du seul `requiresManualSelection`

Matrice courte `contexte -> action principale -> ouverture sheet ou non` :

| Contexte | Action principale | Ouvrir la sheet ? | Raison |
| --- | --- | --- | --- |
| une seule variante lisible | `Regarder` lance directement | non | aucun choix utile |
| plusieurs variantes, mais une seule différence technique non visible ou non fiable | `Regarder` lance directement | non | ne pas exposer un faux choix |
| plusieurs variantes, avec une meilleure variante claire selon les préférences, et d'autres variantes utiles à comparer | `Regarder` lance directement | non via le bouton principal | l'auto-play reste rapide, le choix manuel passe par `Versions` |
| plusieurs variantes utiles à comparer (`4K`, `VF`, `VO`, `HDR10`, source différente) | `Regarder` lance la meilleure variante et `Versions` ouvre la liste | oui via action dédiée | l'utilisateur peut choisir sans perdre le démarrage rapide |
| plusieurs variantes réellement indiscernables même après normalisation | `Regarder` lance la variante déterministe | non | aucun bénéfice produit à ouvrir la sheet |
| aucune variante lisible | `Regarder` n'ouvre pas le player | non | indisponibilité explicite |

Décision complémentaire :

- la bottom sheet reste utile, mais elle n'est plus le prolongement implicite du bouton `Regarder`
- elle devient l'interface du choix manuel volontaire
- l'ambiguïté de ranking reste une information métier interne :
  - elle peut encore forcer un choix manuel dans certains cas
  - mais elle ne doit plus être le seul déclencheur du choix utilisateur visible

### Étape G - Isoler la notion de variante "utile à choisir"

- Compléter le module de sélection avec une notion explicite différente de l'ambiguïté pure :
  - exemple :
    - `hasMultiplePlayableVariants`
    - `hasMeaningfulVariantChoice`
    - `requiresManualSelection`
- Distinguer clairement :
  - plusieurs variantes classables
  - plusieurs variantes réellement différentes pour l'utilisateur
  - vraie égalité de ranking
- Ne pas faire porter cette logique à la bottom sheet ni à `MovieDetailPage`
- Livrable :
  - contrat métier clair `variants -> autoPlay / manualChoiceAvailable / manualChoiceRequired`

Statut : fait

Sorties produites :
- contrat métier explicite de sélection enrichi
- distinction claire entre variants classables, variants utiles à choisir et ambiguïté réelle
- règle d'intégration clarifiée entre service de sélection et UI

Principe retenu :

- le module de sélection doit répondre à trois questions différentes :
  - existe-t-il plusieurs variantes lisibles ?
  - existe-t-il plusieurs variantes réellement utiles à comparer pour l'utilisateur ?
  - le choix manuel est-il obligatoire pour éviter une décision arbitraire ?
- ces trois questions ne doivent plus être écrasées dans un seul booléen du type `requiresManualSelection`

Contrat métier retenu :

- `hasMultiplePlayableVariants`
  - vrai si au moins deux variantes lisibles et classables existent
  - rôle :
    - information structurelle
  - ne suffit pas à elle seule pour afficher une action manuelle
- `hasMeaningfulVariantChoice`
  - vrai si au moins deux variantes présentent une différence visible et utile pour l'utilisateur
  - différences recevables :
    - qualité
    - langue audio
    - sous-titres
    - source
    - plage dynamique
    - autre label fiable et compréhensible
  - rôle :
    - dire si une action `Versions` a une vraie valeur produit
- `requiresManualSelection`
  - vrai seulement si le service ne peut pas trancher proprement sans imposer une décision arbitraire
  - rôle :
    - signaler un cas où la décision manuelle est nécessaire

Distinction métier actée :

- plusieurs variantes classables
  - signifie :
    - plusieurs candidats techniques existent
  - ne signifie pas automatiquement :
    - qu'un choix utilisateur utile existe
- plusieurs variantes réellement différentes pour l'utilisateur
  - signifie :
    - les labels portés par les variantes justifient un affichage manuel
  - n'implique pas nécessairement :
    - que l'auto-play devienne impossible
- vraie égalité de ranking
  - signifie :
    - le service ne peut pas justifier proprement une variante gagnante
  - peut imposer :
    - un choix manuel obligatoire

Disposition métier recommandée :

- `autoPlay`
  - une variante gagnante est retenue
  - le flux peut lancer directement
- `manualChoiceAvailable`
  - une variante gagnante existe
  - mais plusieurs variantes utiles à comparer existent aussi
  - l'UI peut exposer `Versions` sans bloquer `Regarder`
- `manualChoiceRequired`
  - aucune variante ne peut être retenue sans arbitraire excessif
  - l'UI doit demander un choix manuel
- `unavailable`
  - aucune variante lisible

Règle d'intégration retenue :

- le service de sélection doit produire :
  - la variante gagnante éventuelle
  - la liste triée des variantes
  - la disposition métier finale
  - la raison de cette disposition
- `MovieDetailPage` ne décide pas elle-même :
  - si plusieurs variantes sont "utiles"
  - ni si le choix manuel est seulement disponible ou réellement requis
- la bottom sheet ne contient aucune règle métier :
  - elle affiche des variantes déjà triées et déjà qualifiées

Table de lecture du contrat `variants -> disposition` :

| Situation métier | `hasMultiplePlayableVariants` | `hasMeaningfulVariantChoice` | `requiresManualSelection` | Disposition |
| --- | --- | --- | --- | --- |
| aucune variante lisible | non | non | non | `unavailable` |
| une seule variante lisible | non | non | non | `autoPlay` |
| plusieurs variantes lisibles mais sans différence utile visible | oui | non | non | `autoPlay` |
| plusieurs variantes lisibles avec une gagnante claire et plusieurs variantes utiles à comparer | oui | oui | non | `manualChoiceAvailable` |
| plusieurs variantes utiles mais impossibles à départager proprement | oui | oui | oui | `manualChoiceRequired` |

Conséquence d'architecture retenue :

- il faut enrichir le contrat de sortie du service de sélection au lieu d'ajouter des conditions ad hoc dans l'UI
- si une évolution de modèle est faite plus tard, elle doit rester concentrée dans le module métier de sélection
- cette structuration garde la logique testable, réutilisable et compatible avec d'autres écrans que la page film

### Étape H - Fiabiliser l'application immédiate des préférences audio / sous-titres

- Auditer le flux réel du player au premier chargement :
  - arrivée des pistes
  - moment d'appel de la sélection préférée
  - retour visuel de la piste effectivement activée
- Centraliser la sélection initiale des pistes dans un service dédié si le code est aujourd'hui dispersé entre page et repository
- Différencier clairement :
  - préférence persistée
  - piste demandée
  - piste réellement activée par le player
- Ajouter un log utile seulement si :
  - une préférence existe
  - des pistes sont présentes
  - aucune piste correspondante n'a pu être activée
- Livrable :
  - application fiable et observable des préférences de pistes au premier chargement

Statut : fait

Sorties produites :
- audit du flux réel du player au premier chargement
- centralisation de la sélection initiale des pistes dans un service dédié
- séparation clarifiée entre préférence persistée, piste demandée et piste réellement active
- log utile limité au cas de préférence non applicable malgré des pistes disponibles

Audit retenu du flux réel :

- arrivée des pistes
  - les pistes arrivent via `tracksStream`
  - l'état local du widget était mis à jour directement dans la page player
- moment d'appel de la sélection préférée
  - la sélection était déclenchée au premier lot de pistes
  - puis à chaque changement de préférence persistée
- problème constaté
  - la logique de matching de langue était recalculée dans `VideoPlayerPage`
  - elle dupliquait le rôle d'un service déjà présent
  - le code mélangeait :
    - préférence persistée
    - piste demandée au moteur
    - piste supposée active côté UI

Décision d'implémentation retenue :

- la sélection initiale des pistes est maintenant centralisée dans un service dédié
- ce service ne parle plus au moteur ni au widget :
  - il lit des pistes normalisées
  - il lit des préférences persistées
  - il retourne un résultat explicite de sélection
- la page player garde seulement deux responsabilités :
  - synchroniser l'état réel remonté par le moteur
  - appliquer la demande de sélection calculée par le service

Contrat métier retenu pour les pistes :

- préférence persistée
  - code langue normalisé lu depuis `PlayerPreferences`
- piste demandée
  - piste calculée par `PreferredTracksSelector`
  - peut être absente si aucun match n'existe
- piste réellement activée
  - piste active remontée ensuite par `tracksStream`
  - elle reste la source de vérité pour l'UI

Statuts explicites retenus :

- `noPreference`
- `noTracksAvailable`
- `matchFound`
- `noMatchFound`
- `disableRequested`

Règle de log retenue :

- log `warn` uniquement si les trois conditions suivantes sont réunies :
  - une préférence persistée existe
  - des pistes correspondantes sont bien exposées par le player
  - aucune piste compatible n'a pu être demandée
- aucun log ajouté pour :
  - absence de préférence
  - absence totale de pistes
  - désactivation volontaire des sous-titres

Vérification réalisée :

- test unitaire du service de sélection des pistes préférées
  - match audio normalisé
  - match sous-titres détecté via label
  - absence de match malgré pistes présentes
  - absence de pistes malgré préférence
  - désactivation explicite des sous-titres sans préférence
- analyse statique complète du repo

### Étape I - Exposer une vraie préférence de qualité

- Stabiliser un contrat métier simple pour la qualité :
  - valeur normalisée
  - ordre de préférence déterministe
  - fallback si qualité inconnue
- Réutiliser l'architecture existante :
  - stockage dans `PlayerPreferences` ou dans un objet dédié si cela évite de le transformer en fourre-tout
  - injection dans `PlaybackSelectionPreferences`
- Ajouter un réglage explicite dans `Lecture` :
  - `Auto`
  - `SD`
  - `HD`
  - `Full HD`
  - `4K`
  - ou équivalent selon le contrat retenu
- Ne plus faire porter implicitement ce rôle à `Source préférée`
- Livrable :
  - préférence qualité persistée, visible et branchée sur la sélection de variantes

Statut : fait

Sorties produites :
- contrat métier de qualité stabilisé
- préférence qualité persistée dans les préférences lecteur
- injection de la qualité préférée dans la sélection de variantes
- entrée explicite `Qualité préférée` ajoutée dans `Lecture`

Contrat métier retenu :

- valeurs normalisées retenues :
  - `SD`
  - `HD`
  - `Full HD`
  - `4K`
- `Auto` reste l'absence de préférence explicite
- ordre de préférence déterministe retenu :
  - `SD -> 1`
  - `HD -> 2`
  - `Full HD -> 3`
  - `4K -> 4`
- fallback retenu :
  - si la qualité d'une variante est inconnue, elle reste candidate
  - mais elle est classée après une variante équivalente avec qualité connue

Décision d'architecture retenue :

- la préférence qualité est stockée dans `PlayerPreferences`
- ce choix reste acceptable ici car la préférence fait partie du contrat global de lecture
- la valeur persistée est un type métier explicite, pas un `int` brut d'UI
- la traduction en `preferredQualityRank` ne se fait qu'au moment d'alimenter `PlaybackSelectionPreferences`

Implémentation retenue :

- ajout d'un type métier normalisé pour la qualité préférée
- persistance et flux réactif ajoutés dans `PlayerPreferences`
- provider courant ajouté dans l'état applicatif
- `moviePlaybackSelectionProvider` transmet maintenant `preferredQualityRank`
- `SettingsPage` expose une entrée `Qualité préférée` :
  - `Auto`
  - `SD`
  - `HD`
  - `Full HD`
  - `4K`

Effet produit recherché :

- `Source préférée` ne porte plus implicitement le rôle de préférence qualité
- la qualité devient un réglage visible et compréhensible
- le service de sélection reste propriétaire du classement final

Vérification réalisée :

- test métier du service de sélection :
  - la préférence qualité fait gagner une variante `4K` sur une variante `720p`
- test provider :
  - la qualité préférée persistée est bien propagée vers `PlaybackSelectionPreferences`
- test widget :
  - la section `Lecture` affiche `Qualité préférée`
  - le changement vers `4K` est bien persisté
- analyse statique complète

### Étape J - Vérifier le flux visible de bout en bout

- Ajouter des tests métier et service sur :
  - film avec plusieurs variantes `4K / HD / VF / VO`
  - film avec plusieurs variantes utiles mais ranking non ambigu
  - qualité préférée connue ou absente
  - audio / sous-titres préférés appliqués à l'ouverture
- Ajouter des tests widget ciblés sur :
  - bouton principal qui lance directement
  - action manuelle `Versions` ou équivalent si retenue
  - section `Lecture` avec qualité, audio et sous-titres
- Vérifier au minimum :
  - page détail film
  - ouverture du player
  - état initial des pistes audio / sous-titres
  - cohérence entre réglages et comportement observé
- Livrable :
  - expérience cohérente entre sélection de version, réglages et lecteur

Statut : fait

Sorties produites :
- couverture renforcée sur le classement métier des variantes
- vérification widget du flux film pour lancement direct et choix manuel
- vérification widget de la section `Lecture` avec qualité, audio et sous-titres
- vérification de l'état initial des pistes au niveau du service dédié de sélection

Vérification retenue :

- page détail film
  - `Regarder` lance directement quand la décision de lecture est non ambiguë
  - `Regarder` ouvre bien le sélecteur quand plusieurs variantes restent à choisir
  - la bottom sheet affiche des labels utiles lisibles :
    - qualité
    - langue audio
    - sous-titres
- réglages
  - la section `Lecture` expose maintenant :
    - qualité
    - langue audio
    - sous-titres
  - les changements sont bien persistés
- lecteur
  - l'ouverture initiale et l'application des préférences audio / sous-titres sont vérifiées via le service de sélection des pistes
  - ce niveau de test est retenu ici pour garder la vérification stable et découplée du backend vidéo

Cas explicitement couverts :

- film avec plusieurs variantes `4K / HD / VF / VO`
- film avec plusieurs variantes utiles mais classement non ambigu
- qualité préférée connue ou absente
- audio / sous-titres préférés appliqués sur le premier lot de pistes exposé
- cohérence entre réglages persistés et données injectées dans la sélection film

Tests ajoutés ou renforcés :

- `test/features/player/application/services/playback_selection_service_test.dart`
- `test/features/player/application/services/preferred_tracks_selector_test.dart`
- `test/features/movie/presentation/pages/movie_detail_page_playback_test.dart`
- `test/features/settings/presentation/pages/settings_page_playback_preferences_test.dart`
- `test/features/movie/presentation/providers/movie_playback_selection_provider_test.dart`

Vérifications exécutées :

- `flutter test test/features/player/application/services/playback_selection_service_test.dart test/features/player/application/services/preferred_tracks_selector_test.dart test/features/movie/presentation/pages/movie_detail_page_playback_test.dart test/features/settings/presentation/pages/settings_page_playback_preferences_test.dart test/features/movie/presentation/providers/movie_playback_selection_provider_test.dart`
- `flutter analyze`

Livrable atteint :

- le flux visible est cohérent sur le périmètre réellement implémenté :
  - page film
  - choix de variante manuel existant
  - réglages `Lecture`
  - application initiale des préférences de pistes

### Risques à éviter sur cette 3e roadmap

- Confondre `cas ambigu` et `cas où l'utilisateur veut choisir`
- Rajouter des booléens épars au lieu d'un contrat métier explicite
- Dupliquer la logique de pistes dans la page film et dans le player
- Ajouter une préférence qualité sans normalisation fiable des labels
- Transformer `PlayerPreferences` en objet fourre-tout sans frontière claire

### Priorité recommandée

1. recadrer le comportement produit de `Regarder` et du choix manuel
2. isoler la notion de variante utile à choisir
3. fiabiliser l'application initiale des préférences audio / sous-titres
4. ajouter une vraie préférence qualité
5. verrouiller le tout par des tests bout en bout ciblés

### Roadmap corrective en 4 étapes

Objectif :

- corriger la perte d'information entre titre brut, titre normalisé et libellé utilisateur
- rendre les descriptions de variantes réellement utiles pour choisir entre `4K`, `FHD`, `HD`, `VF`, `VO`, `VOST` ou une source différente
- garder une séparation propre entre :
  - matching métier
  - ranking métier
  - affichage UI

### Étape 1 - Fiabiliser l'extraction des métadonnées brutes

- Étendre l'extraction légère à partir du titre brut pour couvrir les formats réellement rencontrés :
  - langues en pipes ou séparateurs :
    - `|FR|`
    - `|EN|`
    - `|VOST|`
    - autres formes courtes cohérentes
  - qualités fréquentes :
    - `UHD`
    - `4K`
    - `FHD`
    - `HD`
    - `SD`
- Ne pas faire reposer cette détection sur le `normalizedTitle`
- Garder le titre normalisé uniquement pour :
  - regrouper
  - comparer
  - matcher
- Livrable :
  - extraction fiable et centralisée des indices qualité / langue / sous-titres / plage dynamique depuis le titre brut

### Étape 2 - Stabiliser un contrat métier unique pour les labels de variante

- Introduire un contrat explicite pour ce qui est montré à l'utilisateur
- Normaliser les qualités affichées avec un vocabulaire cohérent :
  - `SD`
  - `HD`
  - `Full HD`
  - `4K`
- Mapper explicitement :
  - `2160p` et `UHD` vers `4K`
  - `1080p` et `FHD` vers `Full HD`
  - `720p` et `HD` vers `HD`
- Conserver séparément :
  - la valeur d'affichage
  - le rang de qualité pour le ranking
  - les indices audio / sous-titres
- Prévoir un fallback descriptif minimal si aucun tag fiable n'est extrait, pour éviter une ligne réduite à `Version 1`
- Livrable :
  - un descripteur de variante stable, lisible et indépendant du titre normalisé

### Étape 3 - Rebrancher l'UI sur ce descripteur métier

- Faire consommer à la bottom sheet et aux actions `Regarder` / `Versions` le descripteur métier, pas des fragments ad hoc
- Afficher uniquement des différences utiles et compréhensibles :
  - qualité
  - langue audio
  - sous-titres
  - plage dynamique
  - source si elle aide réellement à départager
- Vérifier que l'UI ne dépend plus d'une disparition accidentelle d'information dans le titre nettoyé
- Harmoniser les libellés visibles avec les réglages utilisateur :
  - `4K`
  - `Full HD`
  - `HD`
  - `SD`
- Livrable :
  - descriptions de variantes convaincantes, cohérentes entre réglages, ranking et sheet de choix manuel

### Étape 4 - Verrouiller les cas réels par tests ciblés

- Ajouter des tests unitaires sur les cas actuellement fragiles :
  - `|FR|`
  - `|EN|`
  - `|VOST|`
  - `UHD`
  - `FHD`
  - `HD`
  - variantes sans `2160p` mais clairement `FHD`
- Ajouter des tests widget vérifiant les labels réellement affichés :
  - `4K`
  - `Full HD`
  - `HD`
  - `VF`
  - `VO`
  - `ST FR`
- Vérifier aussi l'impact métier :
  - une qualité détectée doit alimenter le ranking
  - une langue détectée doit rester visible même si le titre normalisé la retire
- Livrable :
  - couverture de régression sur extraction, normalisation d'affichage et rendu UI

### État actuel des épisodes

Constat :

- non, les épisodes n'ont pas aujourd'hui le même système que les films
- le flux film passe par :
  - un resolver dédié de variantes
  - une `PlaybackSelectionDecision`
  - un provider `moviePlaybackSelectionProvider`
  - une UI de choix manuel via bottom sheet
- le flux épisode repose encore sur une ouverture directe depuis `TvDetailPage` :
  - conversion TMDB -> Xtream du numéro d'épisode
  - recherche impérative de la première série compatible dans les comptes actifs
  - construction immédiate de l'URL de lecture
  - ouverture du player sans `PlaybackSelectionDecision`
  - aucun choix manuel de variantes utile pour un épisode

Conséquence produit :

- si plusieurs versions d'un même épisode existent :
  - source différente
  - qualité différente
  - langue différente
  - titre brut différent
- l'utilisateur ne bénéficie pas aujourd'hui du même comportement que sur un film :
  - pas de ranking métier explicite
  - pas de choix manuel de variante
  - pas de contrat unique entre résolution, décision et UI

### Roadmap épisodes

Objectif :

- aligner le lancement d'un épisode sur le même contrat métier que les films
- garder la conversion TMDB/Xtream isolée du choix de variante
- éviter de recopier la logique de sélection dans `TvDetailPage`

### Étape 1 - Isoler la résolution des variantes d'épisode OK 

- Extraire la partie métier actuellement portée par `_openEpisodePlayer`
- Introduire un resolver dédié du type :
  - `EpisodePlaybackVariantResolver`
- Responsabilités du resolver :
  - recevoir :
    - `seriesId`
    - `seasonNumber`
    - `episodeNumber`
    - `candidateSourceIds`
  - convertir proprement le numéro d'épisode TMDB vers la numérotation Xtream si nécessaire
  - retrouver toutes les occurrences lisibles de l'épisode dans les sources actives
  - transformer chaque occurrence en `PlaybackVariant`
- Ne pas lui faire porter :
  - l'ouverture du player
  - l'affichage UI
  - la récupération de la position de reprise
- Livrable :
  - un contrat unique `épisode -> variantes candidates`

### Étape 2 - Réutiliser la décision métier commune OK

- Ajouter un use case dédié du type :
  - `ResolveEpisodePlaybackSelection`
- Réutiliser :
  - `PlaybackVariant`
  - `PlaybackSelectionPreferences`
  - `PlaybackSelectionDecision`
  - `PlaybackSelectionService`
- Contexte attendu :
  - `contentType: ContentType.series`
- But :
  - obtenir pour un épisode les mêmes sorties que pour un film :
    - `autoPlay`
    - `manualSelection`
    - `unavailable`
- Livrable :
  - une décision métier homogène entre film et épisode

### Étape 3 - Rebrancher `TvDetailPage` sur ce contrat

- Ajouter un provider dédié du type :
  - `episodePlaybackSelectionProvider`
- Faire de `TvDetailPage` une simple orchestration UI :
  - charger la décision
  - lancer directement si le cas est non ambigu
  - ouvrir un sélecteur manuel si plusieurs variantes restent crédibles
- Prévoir une UI cohérente avec le flux film :
  - soit réutilisation directe de la bottom sheet existante
  - soit extraction d'une sheet générique de variantes de lecture
- Ne plus choisir implicitement la première occurrence trouvée dans la page
- Livrable :
  - même expérience visible pour film et épisode

### Étape 4 - Gérer les spécificités épisode sans polluer le contrat commun

- Conserver hors du service de sélection commun :
  - la conversion TMDB -> Xtream
  - la logique de fallback si la série est mal catégorisée dans une playlist
  - le titre final `SxxExx`
  - la position de reprise
- Vérifier la compatibilité avec :
  - `NextEpisodeService`
  - l'historique de lecture
  - l'ouverture du player sur séries
- Éviter :
  - de dupliquer le code film dans `tv`
  - de mélanger logique de matching épisode et logique UI
- Livrable :
  - un flux épisode propre, spécialisé là où il faut, commun là où c'est possible

### Étape 5 - Verrouiller par tests ciblés

- Ajouter des tests métier sur :
  - épisode unique disponible
  - plusieurs variantes du même épisode
  - conversion TMDB -> Xtream correcte
  - absence d'épisode malgré série présente
  - préférences qualité / audio / sous-titres appliquées au ranking
- Ajouter des tests provider sur :
  - transmission des préférences persistées
  - filtrage par sources IPTV actives
- Ajouter des tests widget sur :
  - clic sur un épisode qui lance directement
  - clic sur un épisode qui ouvre le sélecteur
  - choix manuel d'une variante d'épisode
- Livrable :
  - couverture de régression sur le flux épisode complet

### Priorité recommandée pour les épisodes

1. extraire la résolution de variantes hors de `TvDetailPage`
2. brancher un vrai `PlaybackSelectionDecision` pour les épisodes
3. réutiliser une bottom sheet de choix manuel
4. sécuriser la conversion TMDB/Xtream et `NextEpisodeService`
5. verrouiller le tout par tests métier, provider et widget
