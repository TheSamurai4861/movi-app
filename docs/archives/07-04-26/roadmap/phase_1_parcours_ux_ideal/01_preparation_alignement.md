# Sous-phase 1.0 - Preparation et alignement

## Objectif

Poser une base commune et factuelle avant de redesigner le tunnel `welcome -> auth -> source -> pre-home`.

Cette sous-phase ne redessine pas encore le parcours cible. Elle:
- fige le perimetre reel
- inventorie les ecrans et routes existants
- rassemble les contraintes fortes produit, plateforme et implementation
- liste les questions UX encore ouvertes avant le travail de flux nominal

## Perimetre confirme

Inclus:
- `/launch`
- `/bootstrap`
- `/welcome`
- `/welcome/user`
- `/auth/otp`
- `/welcome/sources`
- `/welcome/sources/select`
- `/welcome/sources/loading`
- la transition vers `/` quand `home` est pret

Exclus:
- la refonte fonctionnelle de `home`
- les surfaces browse et detail apres `home`
- le player hors impacts directs sur l'entree dans `home`
- le detail d'implementation de la future architecture cible

## Liste des ecrans et routes a traiter

### Routes du tunnel

- `AppRoutePaths.launch` -> `/launch`
- `AppRoutePaths.bootstrap` -> `/bootstrap`
- `AppRoutePaths.welcome` -> `/welcome`
- `AppRoutePaths.welcomeUser` -> `/welcome/user`
- `AppRoutePaths.authOtp` -> `/auth/otp`
- `AppRoutePaths.welcomeSources` -> `/welcome/sources`
- `AppRoutePaths.welcomeSourceSelect` -> `/welcome/sources/select`
- `AppRoutePaths.welcomeSourceLoading` -> `/welcome/sources/loading`
- `AppRoutePaths.home` -> `/`

### Ecrans reelement presents dans le tunnel

- [app_routes.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/app_routes.dart)
- [launch_redirect_guard.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/router/launch_redirect_guard.dart)
- [splash_bootstrap_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart)
- [welcome_user_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_user_page.dart)
- [auth_otp_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/auth/presentation/auth_otp_page.dart)
- [welcome_source_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_page.dart)
- [welcome_source_select_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart)
- [welcome_source_loading_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart)

### Logique de decision qui impacte fortement l'UX

- [app_launch_orchestrator.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/app_launch_orchestrator.dart)
- [enum.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/domain/enum.dart)

## Cartographie fonctionnelle de l'existant

### 1. `/launch`

Role actuel:
- point d'entree du guard de lancement
- route transitoire systeme
- non destination UX finale

Implication UX:
- etape purement technique
- probablement invisible ou tres breve dans le parcours cible

### 2. `/bootstrap`

Role actuel:
- ecran de chargement et de recovery du bootstrap
- montre `OverlaySplash` pendant l'orchestration
- montre `LaunchErrorPanel` si le bootstrap echoue

Implication UX:
- sert aujourd'hui de sas systeme unique avant routage reel
- concentre la perception de "preparation de l'app"

### 3. `/welcome/user`

Role actuel:
- ecran hybride entre accueil utilisateur, gestion profil et bascule implicite vers auth
- si Supabase est actif et l'utilisateur non authentifie, pousse automatiquement `/auth/otp`
- sinon charge les settings et profils
- si des profils existent, affiche un picker
- sinon permet la creation du premier profil
- peut afficher une `LaunchRecoveryBanner`

Implication UX:
- ecran a responsabilites multiples
- confusion potentielle entre "bienvenue", "auth" et "profil"

### 4. `/auth/otp`

Role actuel:
- ecran dedie a l'auth email + OTP
- deux etapes dans le meme ecran: email puis code
- au succes, relance le flux global

Implication UX:
- ecran relativement clair en soi
- mais son declenchement depuis `welcome/user` est aujourd'hui semi-implicite

### 5. `/welcome/sources`

Role actuel:
- hub mixte pour voir des sources distantes sauvegardees, pre-remplir des credentials, ajouter une source et activer une source
- supporte le mode local-first
- supporte un mode avec session cloud et persistance best-effort
- peut afficher une `LaunchRecoveryBanner`

Implication UX:
- ecran dense
- melange inventaire, edition implicite, ajout et activation

### 6. `/welcome/sources/select`

Role actuel:
- etape specialisee de selection d'une source active quand il y en a plusieurs
- persiste la source choisie
- declenche ensuite `/welcome/sources/loading`

Implication UX:
- ecran potentiellement redondant avec le hub source
- utile surtout si le produit assume une vraie etape de choix distincte

### 7. `/welcome/sources/loading`

Role actuel:
- charge les playlists et lance le preload avant `home`
- peut reessayer
- peut autoriser `Continuer quand meme`

Implication UX:
- etape critique de transition
- question ouverte forte: page dediee ou etat inline de fin de parcours

### 8. `/`

Role actuel:
- entree dans `home` via `AuthGate`
- ne fait pas partie de la refonte fonctionnelle demandee

Implication UX:
- le tunnel doit amener vers un `home` deja suffisamment pret pour sembler immediatement utile

## Contraintes produit et plateforme

## Session et auth

- l'auth peut exister comme precondition implicite du tunnel, pas seulement comme ecran explicite
- le guard de lancement et l'orchestrateur peuvent rerouter selon l'etat de session
- l'auth peut etre demandee en plein `welcome/user`
- les cas `session invalide`, `reauth required` et `degraded retryable` existent deja dans la logique de lancement
- le parcours doit rester comprehensible meme si la session n'est pas verifiable immediatement

## Profils

- l'absence de profil peut envoyer vers `welcome/user`
- `welcome/user` gere a la fois la creation du premier profil et la selection d'un profil existant
- le profil influence la suite du tunnel et possiblement des contraintes sensibles comme parental

## Sources IPTV

- le produit supporte plusieurs sources
- il existe un mode local-first sans dependance cloud stricte
- une source peut etre absente, unique, multiple ou partiellement pre-remplie
- les credentials et la selection de source active ont des effets directs sur la suite du parcours
- la source n'est pas un detail de settings dans ce tunnel, c'est une precondition d'utilite avant `home`

## Offline et recovery

- le tunnel doit supporter des cas degradés et des recoveries explicites
- `LaunchRecoveryBanner` apparait deja sur plusieurs ecrans
- le bootstrap peut continuer en mode local-first dans certains cas
- `welcome/sources/loading` supporte deja `retry` et `continue anyway`
- le parcours doit distinguer erreur bloquante, degradation acceptable et recovery actionnable

## Mobile et TV

- le projet vise explicitement mobile et TV
- certains ecrans utilisent deja des primitives TV-friendly comme `MoviFocusableAction`
- le tunnel ne peut pas etre pense seulement comme une suite de formulaires mobiles
- ordre d'actions, focus, densite d'information et lisibilite a distance sont des contraintes de premier ordre

## Navigation et architecture actuelle

- le tunnel depend d'un guard global de redirection
- la destination UX finale est decidee par l'orchestrateur de lancement
- certaines transitions sont explicites dans le routeur, d'autres sont declenchees depuis les ecrans eux-memes
- l'UX actuelle est fortement couplee a la logique de bootstrap et aux etats internes de lancement

## Performance percue

- le tunnel a un cout perceptible en plusieurs etapes: launch, bootstrap, auth, selection source, chargement source, preload home
- toute etape visible doit justifier son existence par une vraie valeur de comprehension ou de controle
- toute etape purement technique doit etre challengee

## Questions UX encore ouvertes

## Questions de structure du parcours

- le tunnel cible doit-il garder une distinction visible entre `launch` et `bootstrap`, ou les absorber dans une seule experience systeme
- le premier ecran utilisateur cible est-il `auth`, `profil`, `source`, ou un ecran unique qui orchestre ces besoins
- faut-il penser le tunnel comme une suite d'ecrans, ou comme peu d'ecrans avec des etats inline

## Questions sur auth et profil

- `welcome/user` et `auth/otp` doivent-ils rester separes
- l'auth doit-elle etre inline dans un ecran d'accueil utilisateur plus large
- la creation et la selection de profil doivent-elles coexister sur le meme ecran
- si l'utilisateur est deja authentifie et a deja un profil, faut-il totalement masquer cette etape

## Questions sur les sources

- `welcome/sources` doit-il devenir un vrai hub source unique
- `welcome/sources/select` apporte-t-il une clarte UX suffisante pour justifier un ecran dedie
- l'ajout d'une source et l'activation d'une source doivent-ils partager la meme surface
- dans le cas d'une seule source valide, faut-il auto-selectionner sans ecran intermediaire

## Questions sur le pre-home

- `welcome/sources/loading` doit-il rester une page pleine
- faut-il montrer le chargement reel, une progression simplifiee, ou seulement une transition breve
- quand `continue anyway` est-il utile produitement, et quand cree-t-il de la confusion
- quelle promesse minimale doit etre tenue avant d'entrer dans `home`

## Questions sur les etats degrades

- quels recoveries meritent un ecran plein
- quels recoveries doivent devenir une banniere
- quels recoveries doivent etre transformes en message inline dans un ecran deja ouvert
- comment exprimer un etat `degraded retryable` sans jargon technique

## Questions sur mobile et TV

- faut-il un meme sequencing UX avec deux presentations, ou des variantes de parcours selon device
- quelle etape est la plus fragile aujourd'hui en navigation TV
- quelle densite d'information est acceptable avant `home` sur TV

## Ambiguities restantes a lever avant la sous-phase 1.1

- definition exacte du premier ecran cible visible pour le flux nominal
- niveau de visibilite souhaite pour l'auth quand la session manque
- statut cible de `welcome/user`: ecran conserve, fusionne ou supprime
- statut cible de `welcome/sources/select`: ecran dedie ou etat absorbe
- statut cible de `welcome/sources/loading`: page dediee, overlay ou etat inline
- promesse minimale de `home ready` cote UX
- niveau de parite souhaite entre mobile et TV: meme flux strict ou adaptations structurelles autorisees

## Conclusion de la sous-phase 1.0

Le perimetre de travail est maintenant suffisamment borne pour lancer la sous-phase 1.1.

Les constats les plus structurants sont:
- le tunnel actuel existe deja comme une machine d'etat reelle, mais sa traduction UX est partiellement dispersee
- `welcome/user` et `welcome/sources` concentrent trop de responsabilites
- `auth`, `selection de source` et `pre-home` sont les trois zones les plus evidentes a challenger du point de vue UX
- le futur parcours devra arbitrer entre moins d'ecrans et plus de clarte, sans perdre la robustesse local-first ni la compatibilite TV
