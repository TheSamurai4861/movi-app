# Sous-phase 1.3 - Contrat UX par ecran

## Objectif

Definir le contrat UX de chaque ecran cible du tunnel d'entree, afin que chaque surface ait:
- un objectif unique
- une condition d'apparition claire
- une action primaire dominante
- une sortie explicite vers la suite du parcours

Ce document ne decide pas encore le design visuel detaille. Il fixe le role de chaque ecran dans l'experience.

## Liste des ecrans cibles

Les ecrans cibles du tunnel sont:
- `Preparation systeme`
- `Auth`
- `Creation profil`
- `Choix profil`
- `Choix / ajout source`
- `Chargement medias`
- `Home vide` comme variante d'arrivee

Les routes techniques `launch` et `bootstrap` ne sont pas traitees comme ecrans produit autonomes.

## 1. Preparation systeme

Objectif unique:
- rassurer l'utilisateur pendant que le systeme determine la prochaine etape utile

Precondition d'entree:
- ouverture de l'app
- ou retour apres `retry`

Information critique a afficher:
- l'app se prepare
- si besoin, message bref de type `verification de votre acces` ou `preparation de votre experience`

Action primaire:
- aucune action explicite en mode nominal

Action secondaire:
- `Retry` uniquement si le systeme detecte un probleme recuperable

Action de retour ou d'annulation:
- aucune

Condition de sortie:
- soit une condition saine est atteinte et le flux avance automatiquement
- soit une action utilisateur devient necessaire et un ecran cible apparait

Comportement mobile:
- ecran tres compact, centre, charge mentale minimale

Comportement TV:
- lisibilite tres forte, message bref, aucun detail superflu

Variante nominale:
- splash premium bref avec transition automatique

Variante degradee:
- message explicatif + `Retry`
- ou bascule vers `Ecran reseau requis`

## 2. Auth

Objectif unique:
- authentifier l'utilisateur

Precondition d'entree:
- pas de session valide

Information critique a afficher:
- pourquoi on demande la connexion
- comment fonctionne le code a 8 chiffres

Action primaire:
- envoyer puis valider le code

Action secondaire:
- retour

Action de retour ou d'annulation:
- retour a la surface precedente si le contexte le permet

Condition de sortie:
- si premiere connexion -> `Creation profil`
- si compte existant -> `Choix profil`

Comportement mobile:
- formulaire lineaire simple

Comportement TV:
- a terme, flow dedie QR prefere
- en attendant, garder la surface la plus simple possible

Variante nominale:
- saisie email puis saisie code

Variante degradee:
- message d'erreur clair si code ou connexion invalide

## 3. Creation profil

Objectif unique:
- creer le premier profil necessaire pour entrer dans l'experience

Precondition d'entree:
- premiere connexion
- ou fallback local sans profil disponible

Information critique a afficher:
- pourquoi un profil est necessaire
- ce qui sera configure maintenant

Action primaire:
- creer le profil

Action secondaire:
- retour

Action de retour ou d'annulation:
- retour vers l'etape precedente si le contexte le permet

Condition de sortie:
- profil cree -> passage direct a `Choix / ajout source`

Comportement mobile:
- formulaire tres court

Comportement TV:
- limiter la saisie, favoriser des choix simples

Variante nominale:
- creation du premier profil

Variante degradee:
- message d'erreur de creation si sauvegarde echoue

## 4. Choix profil

Objectif unique:
- demander explicitement quel profil utiliser

Precondition d'entree:
- compte existant avec plusieurs profils possibles
- ou aucun profil courant selectionne

Information critique a afficher:
- il faut choisir un profil pour continuer

Action primaire:
- selectionner un profil

Action secondaire:
- retour

Action de retour ou d'annulation:
- retour seulement si cela ne casse pas la comprehension du parcours

Condition de sortie:
- profil selectionne -> retour automatique vers la suite du tunnel

Comportement mobile:
- selection claire, peu d'elements par ecran

Comportement TV:
- focus management tres stable
- selection telecommande optimisee

Variante nominale:
- liste ou grille de profils

Variante degradee:
- message si aucun profil n'est exploitable

## 5. Choix / ajout source

Objectif unique:
- obtenir une source active exploitable

Precondition d'entree:
- aucune source active
- source active invalide
- premiere connexion apres creation profil
- fallback local

Information critique a afficher:
- pourquoi on demande cette etape
- si besoin, pourquoi la source precedente ne peut plus etre utilisee

Action primaire:
- choisir une source existante ou en ajouter une nouvelle

Action secondaire:
- retour

Action de retour ou d'annulation:
- retour vers l'etape precedente si cela reste coherent

Condition de sortie:
- source valide -> verification catalogue puis suite du flux

Comportement mobile:
- hub simple, orienté tache

Comportement TV:
- navigation focalisee, actions peu nombreuses, lisibilite forte

Variante nominale:
- ajout de source lors de la premiere connexion
- ou choix d'une source lorsqu'une source active manque

Variante degradee:
- erreur rouge inline sous le bouton si la source est invalide
- message explicatif si la source active precedente n'est plus exploitable

## 6. Chargement medias

Objectif unique:
- preparer un `Home` suffisamment pret avant affichage

Precondition d'entree:
- profil valide
- source exploitable
- mise a jour media necessaire

Information critique a afficher:
- le contenu est en cours de preparation
- si le chargement dure, expliquer simplement pourquoi

Action primaire:
- attendre

Action secondaire:
- `Retry` si le chargement devient anormalement long

Action de retour ou d'annulation:
- aucune en nominal

Condition de sortie:
- chargement termine -> `Home`

Comportement mobile:
- surface courte, tres lisible, sans surcharge

Comportement TV:
- grand message, progression eventuelle, zero densite inutile

Variante nominale:
- transition breve ou ecran de chargement court

Variante degradee:
- ecran ou bloc `chargement plus long que prevu` avec `Retry`

## 7. Home vide

Objectif unique:
- afficher une arrivee valide mais vide, sans donner l'impression d'un bug

Precondition d'entree:
- source valide
- aucun contenu exploitable dans le catalogue

Information critique a afficher:
- la source est connectee, mais aucun contenu n'est disponible

Action primaire:
- comprendre / fermer le message

Action secondaire:
- retourner aux sources plus tard

Action de retour ou d'annulation:
- non prioritaire dans le tunnel immediat

Condition de sortie:
- l'utilisateur reste dans `Home`

Comportement mobile:
- message visible mais non envahissant

Comportement TV:
- message tres lisible, non ambigu

Variante nominale:
- non applicable

Variante degradee:
- etat vide explicatif

## Ecrans a ne plus considerer comme cibles autonomes

Ces surfaces existent dans l'etat actuel du code mais ne doivent plus etre consideres comme contrats UX finaux:
- `launch`
- `bootstrap` comme ecran separe du concept `Preparation systeme`
- `welcome/user` comme ecran hybride
- `welcome/sources/select` si la selection peut etre absorbee dans le hub source
- `welcome/sources/loading` si cette etape devient une surface de chargement unifiee

## Ecrans avec plus d'un objectif principal

Dans l'existant, les surfaces suivantes ont encore plus d'un objectif principal:
- `welcome/user`
- `welcome/sources`

Dans la cible, aucun ecran ne doit conserver cette ambiguite.

## Gate de sortie de la sous-phase 1.3

La sous-phase 1.3 peut etre consideree comme valide si:
- chaque ecran cible a un objectif unique
- chaque ecran cible a une condition d'entree et de sortie claire
- chaque ecran cible a une action primaire dominante
- les variantes degradees sont explicitement rattachees aux bons ecrans

## Conclusion

Le contrat UX cible remplace une logique d'ecrans historiques par une logique de surfaces specialisees. Chaque ecran existe pour une seule raison, et fait avancer l'utilisateur vers la prochaine etape utile sans ambiguite.
