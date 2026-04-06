# Sous-phase 1.4 - Decisions de fusion, suppression et conversion inline

## Objectif

Transformer les conclusions des sous-phases `1.0` a `1.3` en decisions structurelles explicites.

Ce document repond a trois questions:
- quels ecrans existants sont conserves
- quels ecrans existants sont fusionnes ou absorbes
- quels etats doivent devenir inline plutot que rester des pages dediees

## Principe directeur

Une surface reste un ecran autonome seulement si elle remplit ces conditions:
- elle porte un objectif utilisateur unique
- elle impose une action utilisateur explicite
- elle apporte une clarte que l'inline ne peut pas offrir

Sinon:
- elle est fusionnee dans une surface existante
- ou convertie en etat inline
- ou supprimee comme artefact UX autonome

## Decision log

## D1 - `launch` n'est pas un ecran produit

Decision:
- `launch` est supprime comme surface UX autonome

Raison UX / produit:
- pure route technique
- zero valeur utilisateur
- cree un niveau de navigation de trop

Impact mobile:
- moins de transitions inutiles

Impact TV:
- moins de flashs et de changements de contexte

Impact architecture:
- la route peut rester technique, mais ne doit plus etre pensee comme un ecran

## D2 - `bootstrap` est absorbe dans `Preparation systeme`

Decision:
- `bootstrap` n'est plus pense comme ecran distinct
- il est absorbe dans une surface UX unifiee `Preparation systeme`

Raison UX / produit:
- l'utilisateur percoit une seule phase de preparation
- evite l'impression d'empilement `launch -> bootstrap -> autre chose`

Impact mobile:
- experience plus lisse

Impact TV:
- meilleure comprehension a distance

Impact architecture:
- la logique bootstrap reste, mais son exposition UX devient une seule surface

## D3 - `welcome/user` est supprime comme ecran hybride de reference

Decision:
- `welcome/user` est supprime en tant que contrat UX final
- ses responsabilites sont redistribuees entre:
  - `Auth`
  - `Creation profil`
  - `Choix profil`

Raison UX / produit:
- cet ecran cumule trop de roles
- il cree une ambiguite entre accueil, auth et profil
- il rend le parcours plus difficile a raisonner

Impact mobile:
- parcours plus lineaire

Impact TV:
- moins de densite et moins de confusion

Impact architecture:
- decouplage plus clair entre auth et profil

## D4 - `auth/otp` est conserve comme etape cible, pas necessairement comme route finale

Decision:
- `Auth` reste une vraie etape produit
- l'ecran OTP est conserve conceptuellement
- son integration technique peut ensuite rester dediee ou etre encapsulee dans une experience d'auth plus large

Raison UX / produit:
- l'auth porte un objectif unique
- elle est legitime comme etape visible

Impact mobile:
- bonne lisibilite

Impact TV:
- a terme, flow QR preferable

Impact architecture:
- peut rester un module dedie

## D5 - `welcome/sources` devient le hub source cible

Decision:
- `welcome/sources` est conserve comme base du futur `Choix / ajout source`
- son role est simplifie et clarifie

Raison UX / produit:
- la source est une vraie precondition avant `home`
- il faut une surface claire pour choisir ou ajouter une source

Impact mobile:
- hub task-oriented

Impact TV:
- surface unique plus facile a piloter

Impact architecture:
- centraliser les etats source dans un seul module UX

## D6 - `welcome/sources/select` est fusionne dans le hub source

Decision:
- `welcome/sources/select` est supprime comme ecran autonome cible
- la selection de source est absorbee dans `Choix / ajout source`

Raison UX / produit:
- cette page est redondante avec le besoin reel
- l'utilisateur veut obtenir une source valide, pas comprendre deux surfaces differentes
- un hub source unique suffit a la majorite des cas

Impact mobile:
- moins d'allers-retours

Impact TV:
- moins de changements de focus et de contexte

Impact architecture:
- simplifie le mapping `existant -> cible`

## D7 - `welcome/sources/loading` devient `Chargement medias`

Decision:
- `welcome/sources/loading` n'est pas conserve tel quel
- il est remplace par une surface cible `Chargement medias`
- cette surface peut rester ecran dedie ou devenir transition inline selon la duree reelle

Raison UX / produit:
- ce qui compte n'est pas "la source charge", mais "votre experience se prepare"
- le nom et le role doivent suivre l'intention utilisateur, pas l'etape technique

Impact mobile:
- message plus clair

Impact TV:
- meilleur pouvoir de reassurance

Impact architecture:
- autorise une implementation unifiee de preload

## D8 - Les erreurs source deviennent inline dans le hub source

Decision:
- les erreurs de source ne meritent pas un ecran dedie
- elles deviennent un etat inline sous l'action principale

Raison UX / produit:
- la correction se fait dans la meme surface
- un nouvel ecran ne ferait qu'ajouter de la friction

Impact mobile:
- correction immediate

Impact TV:
- garde le contexte visible

Impact architecture:
- logique d'erreur rattachee au module source

## D9 - Les recoveries simples restent dans la surface courante

Decision:
- les recoveries `retry`, `chargement long`, `sync partielle` ne deviennent pas des pages supplementaires
- ils restent des variantes de la surface en cours

Raison UX / produit:
- l'utilisateur ne doit pas changer de page pour comprendre un simple contretemps

Impact mobile:
- moins de fragmentation

Impact TV:
- moins de sauts de focus

Impact architecture:
- favorise des etats plutot que des routes

## D10 - `Home vide` reste une variante d'arrivee, pas une route intermediaire

Decision:
- `Home vide` est traite comme etat de `Home`
- pas comme une nouvelle etape du tunnel

Raison UX / produit:
- l'utilisateur a atteint son objectif structurel
- le systeme doit expliquer l'absence de contenu sans re-ouvrir un nouveau tunnel

Impact mobile:
- continute du parcours

Impact TV:
- comprehension simple

Impact architecture:
- gere comme empty state de `Home`

## Mapping existant -> cible

| Existant | Cible | Decision |
| --- | --- | --- |
| `/launch` | aucune surface UX autonome | supprime comme ecran produit |
| `/bootstrap` | `Preparation systeme` | fusion / absorption |
| `/welcome/user` | `Auth` + `Creation profil` + `Choix profil` | supprime comme ecran hybride |
| `/auth/otp` | `Auth` | conserve conceptuellement |
| `/welcome/sources` | `Choix / ajout source` | conserve et simplifie |
| `/welcome/sources/select` | `Choix / ajout source` | fusionne |
| `/welcome/sources/loading` | `Chargement medias` | remplace / renomme |
| `/` | `Home` ou `Home vide` | conserve comme destination finale |

## Ecrans a conserver

- `Auth`
- `Choix / ajout source` comme hub simplifie
- `Chargement medias` comme surface ou variante utile seulement si necessaire

## Ecrans a fusionner

- `bootstrap` dans `Preparation systeme`
- `welcome/sources/select` dans `Choix / ajout source`

## Ecrans a supprimer

- `launch` comme ecran produit
- `welcome/user` comme ecran cible final

## Etats a convertir en inline

- erreur source
- chargement long
- sync Supabase partiellement indisponible
- information contextuelle sur source active invalide
- `Home vide` comme etat de destination

## Impact global de ces decisions

Le tunnel cible devient:
- plus court
- plus lisible
- plus robuste conceptuellement
- plus compatible avec une navigation TV
- plus simple a mapper sur une future machine d'etat

## Gate de sortie de la sous-phase 1.4

La sous-phase 1.4 peut etre consideree comme valide si:
- chaque ecran existant a une destination cible explicite
- les surfaces hybrides sont traitees
- les etats inline sont identifies
- les suppressions et fusions sont justifiees produitement

## Conclusion

La cible n'est pas de renommer l'existant, mais de redecouper le tunnel autour de vraies etapes utiles. Les decisions prises ici transforment un ensemble de routes historiques en un parcours UX plus compact et plus defendable.
