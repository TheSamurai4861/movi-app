# Cahier des charges Figma - Ecrans de boot

## Objectif

Designer les surfaces utilisateur necessaires au refactor du lancement de
l'application.

Les maquettes doivent permettre de distinguer clairement :

- une attente normale ;
- une preparation longue mais saine ;
- une erreur recuperable ;
- une action obligatoire de l'utilisateur ;
- une ouverture de Home avec contenu partiel.

Le but n'est pas de refaire toute l'identite visuelle de l'app. Les ecrans
doivent rester coherents avec Movi : interface sombre, media-first, compatible
telecommande/clavier, messages courts et actions explicites.

## Plateformes a couvrir

Chaque ecran important doit etre pense pour :

- Mobile portrait ;
- Desktop ;
- TV / grand ecran avec navigation focus.

Les maquettes finales peuvent etre livrees avec une frame principale TV/desktop
et une frame mobile pour les etats critiques. Les etats simples peuvent etre
declines sous forme de composants variants.

## Principes UX

- Toujours dire ce que l'app fait actuellement.
- Ne pas afficher une erreur technique brute a l'utilisateur.
- Proposer une action principale quand l'utilisateur peut agir.
- Garder une action secondaire seulement si elle aide vraiment.
- Ne pas bloquer Home pour une section non critique.
- Sur TV, l'action principale doit etre focusable immediatement.
- Eviter les longs paragraphes.
- Utiliser des reason states comprehensibles, pas des codes internes.

## Composants communs a prevoir

### Boot status surface

Surface generique pour les etats de chargement.

Elements attendus :

- logo ou marque Movi ;
- titre court ;
- message de statut ;
- indicateur de progression indetermine ou etape courante ;
- optionnel : sous-message discret pour les operations longues.

### Recovery action panel

Surface generique pour une erreur recuperable.

Elements attendus :

- titre d'erreur comprehensible ;
- explication courte ;
- action principale ;
- action secondaire optionnelle ;
- lien/action diagnostic optionnelle, par exemple exporter les logs ;
- etat focus TV.

### Source preparation panel

Surface dediee a la preparation ou resynchronisation de source IPTV.

Elements attendus :

- nom ou type de source si disponible ;
- etat de preparation ;
- indication que l'operation peut prendre du temps ;
- action secondaire prudente, par exemple changer de source, si applicable.

### Home partial banner

Banniere compacte affichee dans Home quand une section non critique echoue.

Elements attendus :

- message court ;
- action principale ;
- action secondaire optionnelle ;
- comportement focus TV ;
- version mobile compacte.

## Ecrans / etats a designer

### 1. Demarrage technique

Etat : l'app initialise sa configuration et ses dependances.

Message attendu :

- titre : `Demarrage de Movi`
- intention : l'app se prepare.

Actions :

- aucune action utilisateur pendant le chargement normal.

Notes :

- cet ecran doit etre bref ;
- ne pas afficher de details techniques.

### 2. Verification de session

Etat : l'app verifie si l'utilisateur est connecte.

Message attendu :

- titre : `Verification de la session`
- intention : controle du compte en cours.

Actions :

- aucune en chargement normal.

Etat alternatif :

- session absente ou expiree : redirection vers auth, pas besoin d'un ecran
  d'erreur lourd.

### 3. Resolution du profil

Etat : l'app cherche le profil actif.

Message attendu :

- titre : `Chargement du profil`
- intention : preparation de l'espace utilisateur.

Actions :

- si aucun profil : action `Creer un profil` ;
- si selection invalide : action `Choisir un profil`.

### 4. Resolution de la source IPTV

Etat : l'app restaure ou valide la source selectionnee.

Message attendu :

- titre : `Verification de la source`
- intention : controle de la source active.

Actions :

- si aucune source : `Ajouter une source` ;
- si plusieurs sources sans selection valide : `Choisir une source` ;
- si source invalide : `Choisir une autre source`.

### 5. Preparation du catalogue

Etat : aucun snapshot local exploitable n'est disponible et l'app doit preparer
la source avant Home.

Message attendu :

- titre : `Preparation du catalogue`
- message : `Nous synchronisons votre source pour ouvrir l'accueil.`
- sous-message : `Cette operation peut prendre un moment selon la taille de la source.`

Actions :

- chargement normal : aucune action principale immediate ;
- option secondaire possible apres un delai : `Changer de source`.

Notes :

- c'est l'ecran le plus important du chantier ;
- il remplace l'attente opaque observee dans les logs.

### 6. Catalogue pret en cache

Etat : un snapshot local est exploitable, mais il peut etre ancien ou en cache.

Message attendu :

- titre : `Ouverture de l'accueil`
- message : `Vos contenus locaux sont prets.`

Actions :

- aucune action requise ;
- Home doit s'ouvrir rapidement.

Notes :

- cet etat peut etre tres bref ;
- il peut aussi ne pas avoir d'ecran dedie si la transition est instantanee.

### 7. Source indisponible - timeout

Etat : la preparation de la source n'a pas repondu a temps.

Message attendu :

- titre : `La source ne repond pas`
- message : `La synchronisation a pris trop de temps.`

Actions :

- principale : `Reessayer`
- secondaire : `Choisir une autre source`

### 8. Source indisponible - erreur fournisseur

Etat : le fournisseur IPTV retourne une erreur ou la connexion echoue.

Message attendu :

- titre : `Impossible de charger la source`
- message : `La source semble temporairement indisponible.`

Actions :

- principale : `Reessayer`
- secondaire : `Choisir une autre source`

### 9. Identifiants source invalides

Etat : la source existe, mais les credentials sont invalides ou expires.

Message attendu :

- titre : `Connexion a la source impossible`
- message : `Les informations de connexion doivent etre verifiees.`

Actions :

- principale : `Reconnecter la source`
- secondaire : `Choisir une autre source`

### 10. Catalogue vide

Etat : la source est joignable mais aucun contenu exploitable n'a ete trouve.

Message attendu :

- titre : `Aucun contenu trouve`
- message : `La source a ete synchronisee, mais aucun contenu lisible n'a ete trouve.`

Actions :

- principale : `Resynchroniser`
- secondaire : `Choisir une autre source`

### 11. Erreur technique de boot

Etat : config, dependances, stockage ou initialisation critique en echec.

Message attendu :

- titre : `Movi n'a pas pu demarrer`
- message : `Un probleme technique empeche l'ouverture de l'application.`

Actions :

- principale : `Reessayer`
- secondaire : `Exporter les logs`

Notes :

- ne pas mentionner les erreurs internes dans le message principal ;
- les details techniques peuvent etre accessibles seulement via logs.

### 12. Home partiel - sections Home en erreur

Etat : Home est accessible, mais une ou plusieurs sections ne sont pas chargees.

Message attendu :

- banniere : `Certaines sections n'ont pas pu etre chargees.`

Actions :

- principale : `Recharger`

### 13. Home partiel - reprise indisponible

Etat : Home est accessible, mais la reprise de lecture/bibliotheque est
indisponible.

Message attendu :

- banniere : `La reprise de lecture n'a pas pu etre chargee.`

Actions :

- principale : `Recharger la reprise`

### 14. Home partiel - sections IPTV vides

Etat : Home est accessible, mais les sections IPTV ne sont pas disponibles alors
que le catalogue minimum permet d'ouvrir Home.

Message attendu :

- banniere : `Les sections IPTV sont indisponibles.`

Actions :

- principale : `Recharger`
- secondaire : `Resynchroniser`

## Variants de composants Figma attendus

### Boot screen variant

Variants :

- `technical_startup`
- `session_check`
- `profile_check`
- `source_check`
- `catalog_preparing`
- `opening_home`

### Recovery screen variant

Variants :

- `technical_failure`
- `source_timeout`
- `provider_error`
- `credentials_invalid`
- `catalog_empty`
- `profile_required`
- `source_required`
- `source_selection_required`

### Home partial banner variant

Variants :

- `home_sections_failed`
- `library_failed`
- `iptv_sections_empty`
- `multiple_degradations`

## Contraintes TV / focus

Pour chaque ecran avec action :

- l'action principale doit avoir un etat focus visible ;
- la navigation haut/bas/gauche/droite doit etre evidente ;
- les actions ne doivent pas etre trop proches ;
- le focus initial doit etre sur l'action principale quand une action est
  attendue ;
- les textes doivent rester lisibles a distance.

## Contenus a eviter

- `Erreur inconnue`
- `Impossible de preparer la page d'accueil`
- codes internes visibles comme `catalog_snapshot_missing`
- details reseau bruts ;
- messages longs ou anxiogenes ;
- promesses fausses comme `Cela ne prendra que quelques secondes`.

## Livrables attendus

- Frames desktop/TV pour tous les etats principaux.
- Frames mobile pour les etats critiques :
  - preparation catalogue ;
  - timeout source ;
  - credentials invalides ;
  - catalogue vide ;
  - erreur technique ;
  - Home partial banner.
- Composants variants pour :
  - boot status ;
  - recovery action panel ;
  - Home partial banner.
- Notes Figma sur le focus initial et les actions disponibles.

## Validation

Un ecran est considere valide si :

- l'utilisateur comprend l'etat sans connaitre IPTV ou TMDB ;
- une action claire existe quand l'utilisateur peut agir ;
- le meme etat peut etre mappe a un reason code technique ;
- la version TV est utilisable au clavier/telecommande ;
- le texte tient dans les contraintes mobile.
