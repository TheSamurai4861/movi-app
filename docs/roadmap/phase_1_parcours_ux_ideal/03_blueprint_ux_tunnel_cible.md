# Sous-phase 1.1 - Blueprint UX du tunnel cible

## Objectif

Formaliser le flux nominal ideal du tunnel `ouverture app -> home`, a partir du workflow retenu, en separant:
- le parcours principal de retour utilisateur
- le parcours guide de premiere connexion
- les etapes visibles et invisibles
- les auto-skips autorises
- les points de decision qui doivent rester explicites

Ce document ne traite pas encore la matrice complete des variantes. Il fixe la trajectoire cible par defaut.

## Hypotheses retenues

- `home` n'apparait jamais avant la fin du chargement juge necessaire
- le tunnel privilegie une `home prete` plutot qu'une `home rapide mais incomplete`
- le premier parcours est plus guide et plus visible que le retour utilisateur
- un utilisateur deja connu, avec session, profil et source valides, doit voir le moins d'etapes possibles
- les etapes purement systeme restent invisibles ou regroupees dans une seule surface de preparation

## Definition du flux nominal cible

## Flux nominal principal

Le flux nominal principal est le parcours par defaut a optimiser en premier.

Persona cible:
- utilisateur deja connu
- session valide
- profil selectionne ou selectionnable sans friction
- source active exploitable
- reseau disponible

Sequence cible:
1. ouverture app
2. splashscreen / preparation systeme
3. verification reseau, session et sync Supabase
4. verification du profil
5. verification de la source active
6. chargement des medias requis si necessaire
7. affichage de `home`

Interpretation UX:
- l'utilisateur ne doit pas traverser plusieurs ecrans intermediaires si tout est deja en ordre
- toute la logique `session -> sync -> profil -> source -> preload` doit etre absorbee dans une seule experience de preparation tant qu'aucune action utilisateur n'est requise

## Flux nominal guide de premiere connexion

Ce flux n'est pas un cas d'erreur. C'est le parcours guide de premiere mise en service.

Persona cible:
- utilisateur non connecte
- premiere connexion
- aucun profil encore cree
- aucune source encore configuree

Sequence cible:
1. ouverture app
2. splashscreen / preparation systeme breve
3. auth code 8 chiffres
4. creation du premier profil
5. ajout de la premiere source
6. chargement des medias
7. affichage de `home`

Interpretation UX:
- ce parcours peut etre plus visible car il structure l'onboarding
- il doit rester lineaire, sans bifurcations inutiles ni retour en arriere implicite

## Etapes visibles vs invisibles

## Etapes visibles

Ces etapes sont visibles car elles apportent soit une action utilisateur, soit une reassurance necessaire.

- `Splashscreen / preparation systeme`
- `Auth code 8 chiffres`
- `Creation profil`
- `Choix profil` quand aucun profil n'est deja selectionne
- `Choix / ajout source` quand la source active manque ou n'est plus exploitable
- `Chargement medias` si ce chargement dure suffisamment pour devoir etre explique
- `Home`

## Etapes invisibles ou absorbees

Ces etapes existent dans le systeme, mais ne doivent pas forcement exister comme ecrans distincts.

- `launch`
- `bootstrap` en tant que route technique
- verification reseau quand elle reussit rapidement
- verification session quand elle reussit rapidement
- sync Supabase quand elle reussit dans des delais normaux
- verification du profil si un profil valide est deja connu
- verification de la source active si elle est deja exploitable
- decision `mise a jour necessaire ?` tant qu'aucune action utilisateur n'est requise

## Auto-skips autorises

Pour reduire la friction, ces transitions doivent etre automatiques.

### Utilisateur deja connecte

- sauter l'ecran d'auth si la session est valide
- sauter l'etape profil si un profil est deja selectionne et encore valide
- sauter l'etape source si la source active est toujours exploitable
- sauter l'ecran de chargement detaille si le preload est tres court

### Premiere connexion

- apres succes de l'auth, aller directement a la creation profil
- apres creation profil, aller directement a l'ajout source
- apres source valide, aller directement au chargement medias

### Cas de maj non necessaire

- si aucune mise a jour media n'est requise selon la frequence definie, aller directement a `home`

## Sequence minimale avant Home

La sequence minimale acceptable avant `home` est:
1. verification reseau
2. verification session ou auth
3. validation d'un profil
4. validation d'une source exploitable
5. chargement media requis
6. `home`

Ce qui ne doit plus arriver dans la cible:
- afficher `home` avant d'avoir decide si le profil et la source sont utilisables
- afficher plusieurs ecrans successifs purement techniques
- obliger un utilisateur sain a repasser par des choix deja resolus

## Ecran le plus probable apres l'ouverture

Pour la majorite des utilisateurs de retour, l'ecran le plus probable apres l'ouverture doit etre:
- un `splashscreen de preparation premium`

Cet ecran doit:
- rassurer
- porter la marque
- absorber les verifications techniques
- ne pas donner l'impression d'un empilement de routes

Il ne doit pas:
- ressembler a un ecran d'erreur par defaut
- exposer du jargon technique
- multiplier les sous-etapes visibles si tout se passe bien

## Principe de routage UX cible

Le principe de routage cible est:
- `one clear next step`

Regle:
- tant que le systeme peut decider seul, il ne montre pas un nouvel ecran
- des qu'une action utilisateur devient necessaire, il ouvre une etape claire avec une action primaire unique
- des qu'une condition redevient saine, il repart automatiquement vers la suite nominale

## Flux nominal cible - Forme compacte

### Retour utilisateur sain

`Ouverture app -> Splashscreen premium -> Verifications systeme absorbees -> Chargement medias si necessaire -> Home`

### Premiere connexion saine

`Ouverture app -> Splashscreen bref -> Auth -> Creation profil -> Ajout source -> Chargement medias -> Home`

## Decisions UX deja implicites dans ce flux

- `launch` ne doit pas exister comme ecran produit
- `bootstrap` doit etre percu comme une experience de preparation, pas comme une route technique autonome
- `welcome/user` n'est pas conserve tel quel comme ecran hybride de reference
- le retour utilisateur doit tendre vers un tunnel quasi invisible tant que tout est sain
- le premier parcours garde des etapes visibles et assumees

## Impacts mobile

- privilegier un parcours vertical simple et lineaire
- minimiser les ecrans de transition
- accelerer l'entree dans `home` quand aucun choix n'est requis
- garder des formulaires courts avec une action primaire dominante

## Impacts TV

- limiter encore plus le nombre d'ecrans visibles sur le parcours de retour
- privilegier des decisions rares mais tres claires
- rendre chaque etape visible facilement navigable a la telecommande
- eviter les surfaces trop denses avant `home`

## Points encore deferes a la sous-phase 1.2

La sous-phase 1.1 fixe le flux nominal, mais ces cas seront formellement traites ensuite:
- fallback local apres echec partiel Supabase
- absence de reseau
- source invalide
- source valide mais catalogue vide
- chargement trop long
- cas multi-profils sans selection courante
- cas multi-sources avec source active invalide

## Gate de sortie de la sous-phase 1.1

La sous-phase 1.1 peut etre consideree comme valide si:
- le parcours principal de retour utilisateur est defini
- le parcours guide de premiere connexion est defini
- les etapes visibles et invisibles sont distinguees
- les auto-skips sont explicites
- aucune etape nominale ne semble redondante ou purement technique

## Conclusion

Le tunnel cible n'est pas une succession d'ecrans historiques. C'est une experience compacte qui cache la complexite quand tout va bien, et qui n'expose une etape visible que lorsqu'une action ou une clarification utilisateur est vraiment necessaire.
