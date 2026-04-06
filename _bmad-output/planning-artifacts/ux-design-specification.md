---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/planning-artifacts/implementation-readiness-report-2026-04-02.md
  - docs/archives/02-04-26/traceability/requirements_traceability.md
  - docs/archives/02-04-26/traceability/verification_matrix.md
  - docs/archives/02-04-26/risk/hazard_analysis.md
  - docs/archives/02-04-26/risk/failure_modes.md
  - docs/archives/02-04-26/security/threat_model.md
  - docs/archives/02-04-26/adr/ADR-PH4-001_media_resume_orchestrators.md
workflowType: 'ux-design'
project_name: 'movi'
user_name: 'Matteo'
date: '2026-04-02'
---

# UX Design Specification movi

**Author:** Matteo
**Date:** 2026-04-02

---

<!-- UX design content will be appended sequentially through collaborative workflow steps -->

## Executive Summary

### Project Vision

`movi` est une application media premium orientee movie/TV dont la promesse centrale repose sur la clarte, la fluidite et la confiance. L'experience ne doit pas seulement permettre d'acceder au contenu; elle doit donner une sensation immediate de qualite superieure, depuis le lancement de l'application jusqu'a la lecture, la reprise et la navigation entre appareils.

Le produit doit rendre les parcours critiques lisibles et robustes. Les etats sensibles comme l'authentification, le controle parental, l'abonnement, la synchronisation et les erreurs playback ne doivent jamais sembler opaques ou improvises. L'UX doit traduire des comportements systeme exigeants en experience simple, premium et comprehensible.

### Target Users

**Utilisateur principal media**
Utilisateur qui ouvre l'application pour trouver rapidement un contenu, le lancer sans friction, et retrouver facilement ce qu'il regardait deja. Il attend une app rapide, lisible et agreable sur mobile comme sur TV.

**Utilisateur multi-appareils**
Utilisateur qui passe d'un appareil a un autre et attend une continuite evidente de sa progression, de son contexte et de ses preferences sans effort mental supplementaire.

**Titulaire du compte / parent**
Utilisateur qui doit comprendre et controler des regles sensibles comme les profils, les restrictions parentales, les preferences runtime et le statut premium sans comportement ambigu ou dangereux.

**Support / operations**
Persona secondaire mais structurante: l'experience doit permettre de relier un symptome visible utilisateur a un etat comprehensible du produit, sans fuite de donnees sensibles.

### Key Design Challenges

- Concevoir une experience premium qui rende perceptible la fiabilite des flux critiques sans exposer la complexite technique sous-jacente
- Assurer une vraie coherence produit entre mobile et TV, avec une adaptation explicite au tactile, a la telecommande, au focus management et a la lisibilite 10-foot UI
- Rendre les etats sensibles lisibles et non ambigus: auth, entitlement, parental, pending-sync, offline, blocked, degraded, recovered
- Preserver la rapidite percue et la clarte de navigation dans un contexte brownfield ou certaines zones historiques restent structurellement contraintes

### Design Opportunities

- Faire de la clarte des etats critiques un marqueur premium distinctif plutot qu'un simple traitement d'erreur
- Transformer l'experience TV en avantage reel de produit, avec une navigation telecommande plus soignee que la moyenne
- Faire de la reprise media et du continue-watching cross-device un moment de valeur central et memorable
- Rendre le parcours abonnement et entitlement particulierement transparent, rassurant et conforme aux attentes store
- Utiliser les etats degrades et de recuperation comme des moments d'orientation utilisateur, pas comme des ruptures opaques

## Core User Experience

### Defining Experience

L'experience coeur de `movi` est la capacite a amener l'utilisateur d'un etat d'ouverture ou de reprise vers une lecture utile, rapide et confiante, sans friction mentale. La boucle principale n'est pas seulement "regarder une video"; c'est "ouvrir l'app, comprendre immediatement son contexte, retrouver le bon contenu, puis lancer ou reprendre la lecture avec certitude".

L'action la plus frequente et la plus critique a reussir est le passage du contexte courant de l'utilisateur vers le contenu pertinent. Cela inclut:
- retrouver ce qui etait en cours ou pertinent
- comprendre si l'acces est possible ou non
- lancer ou reprendre sans surprise
- revenir ensuite a un contexte de navigation coherent

Si `movi` reussit cette boucle mieux que les alternatives, le reste du produit gagne automatiquement en valeur percue.

### Platform Strategy

`movi` est une experience cross-platform concue d'abord pour `Android` et `Android TV`, avec deux modalites d'interaction de premier ordre:
- tactile sur mobile
- navigation directionnelle / telecommande sur TV

La strategie UX doit donc preserver un meme contrat produit sur les parcours critiques tout en adaptant explicitement:
- la densite visuelle
- la navigation
- le focus
- la hierarchie d'actions
- les feedbacks de systeme

Le produit ne doit pas traiter la TV comme un simple etirement de l'interface mobile. Les parcours critiques doivent etre repenses pour la lisibilite a distance, la navigation au focus et la predictibilite des transitions browse -> detail -> playback -> retour.

La strategie plateforme doit aussi assumer:
- un mode degrade comprehensible quand le reseau est lent ou indisponible
- une continuite locale minimale meme sans synchronisation immediate
- une evolution future possible vers `iOS` puis `Windows` sans changer l'experience coeur

### Effortless Interactions

Les interactions qui doivent devenir quasi invisibles pour l'utilisateur sont:

- atteindre un ecran utile tres rapidement apres ouverture
- comprendre en un coup d'oeil ce qui est disponible, en cours, repris possible ou bloque
- lancer un contenu depuis les surfaces principales sans parcours inutile
- reprendre exactement au bon endroit sans decision confuse ni boucle
- naviguer entre home, details, player et retour sans perdre le fil
- retrouver un etat coherent apres interruption, retour reseau ou changement d'appareil
- comprendre immediatement pourquoi un acces premium ou parental est autorise, refuse ou en attente

Les concurrents font souvent perdre du temps sur:
- des homes surchargees
- des statuts implicites
- des transitions lentes ou opaques
- des etats de reprise et de sync peu lisibles
- une UX TV mal pensee

`movi` doit eliminer ces frictions en reduisant le nombre de decisions inutiles et en rendant l'etat courant toujours explicite.

### Critical Success Moments

Les moments qui feront dire a l'utilisateur "c'est mieux" sont:

- l'ouverture de l'application qui aboutit presque immediatement a un ecran utile
- la presence d'un point d'entree clair vers ce qui compte maintenant: reprendre, continuer, lancer
- la reprise media exacte et stable apres interruption ou changement d'appareil
- la comprehension immediate d'un etat sensible: acces premium, restriction parentale, sync en attente, mode degrade
- la navigation TV qui reste fluide, lisible et previsible a la telecommande

Les moments qui ruineraient l'experience sont:
- un demarrage flou ou bloquant
- un statut d'acces ambigu
- une reprise incorrecte ou bouclee
- une navigation qui fait perdre le contexte
- un ecran TV difficile a lire ou a controler
- un etat degrade qui ressemble a un bug incomprehensible

La premiere vraie victoire utilisateur doit arriver tres tot: en quelques secondes, l'utilisateur doit sentir qu'il sait ou il est, quoi faire, et que l'app est fiable.

### Experience Principles

- **Utilite Immediate**: chaque ouverture doit conduire rapidement a un etat utile, jamais a une attente confuse
- **Contexte Toujours Visible**: l'utilisateur doit comprendre en permanence ce qu'il regarde, ce qu'il peut reprendre et ce qui est bloque
- **Lecture Sans Friction**: lancer ou reprendre un contenu doit demander un minimum d'effort et produire un resultat previsible
- **Etats Sensibles Explicites**: auth, parental, premium, sync et degrade doivent etre lisibles et non ambigus
- **Parite Produit, Interaction Adaptee**: mobile et TV partagent la meme logique produit mais pas les memes mecanismes d'interaction
- **Retour Sans Perte**: apres interruption, erreur ou changement d'appareil, l'utilisateur doit pouvoir reprendre sans reconstruire mentalement son parcours
- **Confiance Perceptible**: la robustesse technique doit se traduire en calme, clarte et previsibilite cote utilisateur

## Desired Emotional Response

### Primary Emotional Goals

L'emotion principale visee par `movi` est une **confiance calme**. L'utilisateur doit sentir que l'application est rapide, claire et sous controle, meme lorsque des etats sensibles ou des conditions degradees apparaissent.

La seconde emotion cle est une **satisfaction premium sans effort**. L'application doit donner l'impression d'etre plus propre, plus fluide et plus maitrisee que les alternatives, sans chercher a impressionner par du bruit visuel ou des interactions tape-a-l'oeil.

Les emotions les plus importantes a produire sont:
- confiance
- clarte
- maitrise
- fluidite
- reassurance
- plaisir discret

### Emotional Journey Mapping

**A la decouverte ou au premier lancement**
L'utilisateur doit ressentir une impression immediate de lisibilite et de qualite. Il ne doit pas se demander ou il est ni quoi faire ensuite.

**Pendant la boucle coeur**
Lorsqu'il parcourt, choisit, lance ou reprend un contenu, l'utilisateur doit se sentir guide sans etre assiste de facon lourde. Il doit ressentir de la fluidite, pas de la friction.

**Apres avoir atteint son objectif**
Une fois la lecture lancee ou la reprise reussie, l'utilisateur doit ressentir que tout s'est passe exactement comme il l'esperait. La bonne emotion ici est une satisfaction nette, presque silencieuse.

**Quand quelque chose se passe mal**
En cas d'erreur, d'acces bloque, de sync en attente ou de mode degrade, l'utilisateur ne doit pas ressentir panique ou mefiance. Il doit ressentir que l'application reste honnete, stable et recuperable.

**Au retour dans l'application**
Quand il revient apres interruption ou sur un autre appareil, l'utilisateur doit ressentir une continuite naturelle. L'app doit lui donner l'impression de se souvenir correctement de lui et de son contexte.

### Micro-Emotions

Les micro-emotions les plus critiques pour `movi` sont:

- **Confiance plutot que scepticisme**: l'utilisateur croit ce que l'interface lui dit sur l'etat de session, de reprise ou d'acces
- **Clarite plutot que confusion**: il comprend vite ce qui est possible, en attente, bloque ou deja en cours
- **Calme plutot qu'anxiete**: l'app ne dramatise pas les erreurs et ne laisse pas d'etat ambigu
- **Controle plutot qu'impuissance**: meme en cas d'echec, l'utilisateur voit quoi faire ensuite
- **Satisfaction plutot que simple tolerance**: quand tout marche bien, l'experience parait nettement plus propre que la moyenne
- **Continuite plutot que rupture**: les passages entre home, detail, player, reprise et changement d'appareil semblent naturels

### Design Implications

Si nous voulons que l'utilisateur ressente de la confiance calme, l'UX doit:
- rendre les etats systeme visibles sans jargon inutile
- eviter les transitions opaques et les attentes silencieuses
- afficher des actions suivantes claires en cas d'erreur ou de blocage

Si nous voulons produire une satisfaction premium, l'UX doit:
- privilegier une hierarchie visuelle nette
- accelerer l'acces au bon contenu ou a la reprise
- utiliser la motion et les transitions pour confirmer, pas pour distraire

Si nous voulons renforcer le sentiment de controle, l'UX doit:
- expliciter les statuts sensibles comme premium, parental, sync et offline
- conserver le contexte lors des retours et interruptions
- eviter les parcours qui obligent l'utilisateur a reconstruire sa situation mentale

Les emotions negatives a eviter sont:
- confusion
- suspicion
- frustration silencieuse
- sensation de perte de contexte
- impression d'instabilite
- anxiete face a un statut ambigu
- fatigue cognitive sur TV

### Emotional Design Principles

- **Clarte avant spectacle**: l'utilisateur doit comprendre avant d'etre impressionne
- **Confiance visible**: chaque etat critique doit inspirer de la fiabilite, pas du doute
- **Premium par la maitrise**: la sensation haut de gamme vient de la precision, de la fluidite et du calme
- **Erreur sans panique**: un probleme doit rester comprehensible, borne et recuperable
- **Continuite rassurante**: l'application doit sembler se souvenir correctement du contexte utilisateur
- **TV sans tension**: sur grand ecran, la navigation doit rester stable, lisible et apaisee
- **Etat explicite, charge mentale minimale**: l'interface doit faire porter au systeme le travail de clarte, pas a l'utilisateur

## UX Pattern Analysis & Inspiration

### Inspiring Products Analysis

**Netflix**
Netflix reste une reference forte pour la lisibilite immediate du catalogue, la priorisation du "continue watching" et la reduction de friction entre browse, detail et playback. Ce qui fonctionne particulierement bien comme source d'inspiration pour `movi`:
- entree rapide dans le contenu
- hierarchie claire entre hero, rails et actions principales
- capacite a remettre en avant ce qui compte maintenant
- navigation TV globalement previsible et orientee consommation

Le point le plus transferable n'est pas son apparence exacte, mais sa discipline sur la boucle "voir quelque chose de pertinent -> agir rapidement".

**Apple TV**
Apple TV inspire surtout par sa retenue visuelle, sa sensation premium et sa capacite a faire respirer le contenu. Comme reference pour `movi`, c'est utile pour:
- la sobriete de l'interface
- l'importance donnee au contenu comme objet principal
- la sensation de calme et de maitrise
- la coherence visuelle sur grand ecran

Ce produit montre qu'une UX premium ne vient pas seulement de la richesse fonctionnelle, mais d'une interface qui semble sure de ses priorites.

**Plex**
Plex est une reference pertinente pour la logique bibliotheque, la gestion de contextes media heterogenes et les parcours multi-surface plus orientes "media power user". Pour `movi`, l'interet est surtout:
- la structuration de bibliotheques et de details riches
- la gestion du retour au contenu deja entame
- la cohesion entre plusieurs contextes de consommation
- une logique plus proche des usages media hybrides et moins purement "catalogue editorial"

Plex est utile comme contrepoint: il montre a la fois de bonnes idees de structure media et les risques d'une interface qui devient trop dense si elle n'est pas disciplinee.

### Transferable UX Patterns

**Navigation Patterns**
- **Rail prioritaire "Reprendre / Continuer"**: pattern a reprendre pour faire emerger ce qui a de la valeur immediate a l'ouverture
- **Parcours browse -> detail -> playback tres court**: pattern essentiel pour soutenir la promesse de fluidite
- **Hero focal + rails secondaires**: utile pour donner une orientation claire sans noyer l'utilisateur dans des options equivalentes
- **Retour contextuel coherent**: indispensable pour que l'utilisateur ne perde pas sa situation apres detail ou player
- **Navigation TV a focus stable**: pattern non negociable pour `Android TV`

**Interaction Patterns**
- **Action principale toujours evidente**: "reprendre", "lancer", "continuer", "restaurer l'acces" ou "reessayer" doivent etre visuellement sans ambiguite
- **Resume explicite et confiant**: afficher clairement l'etat "reprendre ici" plutot qu'un mecanisme implicite peu visible
- **Etat degrade integre au flux**: quand quelque chose echoue, l'utilisateur doit rester dans un parcours actionnable
- **Statuts visibles dans le contexte**: premium, parental, sync en attente, offline ou bloque doivent etre lisibles a l'endroit ou la decision compte

**Visual Patterns**
- **Sobriete premium**: surfaces visuelles propres, peu de bruit, typographie lisible, contenu valorise
- **Contraste fort de priorite**: une action ou un contenu important doit dominer clairement le reste
- **Densite adaptee a la surface**: mobile plus compacte, TV plus aeree, plus lisible et plus stable
- **Motion de confirmation**: transitions utilisees pour expliquer et rassurer, pas pour distraire

### Anti-Patterns to Avoid

- **Homes surchargees de rails equivalents**: cela dilue la priorite et fatigue l'utilisateur
- **Autoplay envahissant ou punitif**: surtout sur TV, cela peut faire perdre le controle et augmenter la tension
- **Statuts implicites ou caches**: abonnement ambigu, sync invisible, reprise silencieuse, parental incomprehensible
- **Details trop denses sur TV**: trop de metadata, actions secondaires ou labels nuisent a la lisibilite 10-foot
- **Retours incoherents depuis le player**: si l'utilisateur revient a un ecran inattendu, le sentiment de perte de contexte est immediat
- **Etats d'erreur hors parcours**: un message de panne detache du flux principal casse la confiance
- **UI "power user" partout**: la richesse media doit etre controlee, sinon l'app parait compliquee plutot que premium

### Design Inspiration Strategy

**What to Adopt**
- La priorisation d'un point d'entree immediate vers le contenu pertinent, inspiree de Netflix
- Une presentation premium plus calme et plus retenue, inspiree d'Apple TV
- Une logique de bibliotheque et de reprise plus consciente du contexte, inspiree de Plex
- Une architecture de navigation TV au focus stable, orientee predictibilite
- Des etats utilisateur explicites directement dans le flux de navigation et de lecture

**What to Adapt**
- Le modele en rails doit etre conserve mais simplifie pour eviter la saturation
- Le hero editorial doit exister, mais sans ralentir l'acces aux actions principales
- La richesse metadata des ecrans detail doit etre forte sur mobile et disciplinee sur TV
- Les patterns de bibliotheque "media enthusiast" doivent etre adaptes a une experience plus simple et plus premium
- Les surfaces premium et entitlement doivent etre beaucoup plus explicites que chez plusieurs references du marche

**What to Avoid**
- Copier la densite ou la logique catalogue sans tenir compte des exigences de clarte de `movi`
- Cacher les etats sensibles derriere des icones, sous-menus ou changements d'etat implicites
- Confondre "premium" avec "cinematique lourde" si cela ralentit l'acces ou brouille les priorites
- Importer des comportements TV mediocres du marche, notamment focus fragile, hierarchie faible ou actions mal localisees

La strategie globale est donc la suivante:
- prendre a Netflix sa priorisation du moment utile
- prendre a Apple TV sa retenue premium
- prendre a Plex sa conscience des usages media reels
- retirer de ces references tout ce qui augmente la friction, la densite ou l'ambiguite d'etat
- construire une experience `movi` plus claire sur les etats critiques que la plupart des references existantes

## Design System Foundation

### 1.1 Design System Choice

Le choix retenu pour `movi` est un **design system custom proprietaire**, base sur des composants internes deja presents dans l'application et etendu par une librairie de composants Movi unifiee.

Le produit ne doit pas s'appuyer sur des composants visuels "tout faits" de Google comme langage d'interface final. L'objectif est que l'UI visible soit entierement portee par des primitives et composants propres a `movi`, avec une identite plus premium, plus media et mieux adaptee a la TV que le rendu Material standard.

Le framework Flutter reste le socle technique de l'application, mais pas la source du langage visuel produit.

### Rationale for Selection

Ce choix est le plus coherent avec `movi` pour quatre raisons.

**1. Une base custom existe deja**
L'application dispose deja de theming, de palette et de composants maison. Il est plus logique de consolider cette direction que de rebasculer vers un catalogue Google visible dans le produit.

**2. Le positionnement premium l'exige**
`movi` cherche une perception haut de gamme, calme, lisible et specifique au media. Une UI trop proche du Material par defaut affaiblirait la differenciation.

**3. La TV impose des composants specifiques**
Focus visible, navigation directionnelle, densite, tailles de cible et hierarchie d'information sur TV demandent des composants dedies. Les composants standards Google ne suffisent pas comme langage UX de premier ordre pour cet usage.

**4. Le brownfield demande de l'unification, pas une seconde grammaire**
Introduire davantage de composants visuels Google dans les nouveaux flux ferait coexister plusieurs grammaires UI. Il faut au contraire converger vers une seule couche de composants Movi.

### Implementation Approach

L'approche recommandee est la suivante.

**Couche 1: Design Tokens Movi**
Centraliser la fondation visuelle:
- couleurs
- typographie
- espacements
- rayons
- elevations
- opacites d'etat
- animations
- styles de focus
- tailles et densites mobile / TV

Cette couche reste branchee sur le systeme de theme Flutter, mais les tokens appartiennent a `movi`.

**Couche 2: Primitives UI Movi**
Construire ou consolider un socle de primitives proprietaires:
- `MoviButton`
- `MoviCard`
- `MoviInput`
- `MoviDialog`
- `MoviSheet`
- `MoviBadge`
- `MoviTag`
- `MoviRail`
- `MoviFocusFrame`
- `MoviStatePanel`

Ces primitives deviennent le point d'entree obligatoire pour toute nouvelle UI produit.

**Couche 3: Composants d'experience Movi**
Au-dessus des primitives, definir les composants specifiques au domaine:
- cartes media
- hero content
- rails de discovery
- continue watching
- surfaces detail movie / TV
- panneaux entitlement / premium
- panneaux parental / blocked
- bannieres pending-sync / degraded / recovered
- overlays et controles playback
- composants de navigation TV

**Couche 4: Wrappers techniques uniquement si necessaire**
Si certains widgets Flutter/Material restent necessaires pour des raisons techniques, ils doivent etre encapsules derriere des composants Movi. Ils ne doivent jamais devenir la grammaire visible de l'application.

### Customization Strategy

La strategie de personnalisation est stricte.

**Ce qui est autorise**
- utiliser Flutter comme infrastructure applicative
- utiliser le theme pour brancher tokens et comportements
- encapsuler des widgets bas niveau si cela reduit le cout technique
- etendre les composants deja existants dans l'app

**Ce qui devient la regle**
- tout nouveau composant visible doit etre un composant Movi
- tout nouvel ecran doit composer avec des primitives Movi avant d'utiliser des widgets standards
- les etats critiques doivent avoir des composants dedies et coherents
- mobile et TV doivent partager la meme famille visuelle avec des adaptations d'interaction explicites

**Ce qu'il faut eviter**
- ajouter directement de nouveaux `FilledButton`, `Card`, `Chip`, `Dialog` ou autres composants Google dans les surfaces produit
- habiller legerement un composant Google et l'appeler "custom"
- recreer un fourre-tout de composants sans gouvernance
- melanger plusieurs styles de composants selon les features

La strategie finale est donc:
- **Flutter pour le moteur**
- **tokens Movi pour la fondation**
- **composants Movi pour toute l'interface visible**
- **TV, media et etats critiques comme domaines de personnalisation de premier ordre**

## 2. Core User Experience

### 2.1 Defining Experience

L'experience definissante de `movi` est la suivante: **retrouver instantanement le bon contenu et reprendre ou lancer la lecture sans friction ni doute**.

C'est l'interaction que l'utilisateur doit pouvoir decrire simplement:
- "j'ouvre l'app"
- "je vois tout de suite ce qui compte maintenant"
- "je reprends ou je lance"
- "ca marche comme prevu"

Le coeur de valeur n'est donc pas seulement la consommation de contenu, mais la qualite de la transition entre:
- retour dans l'application
- comprehension immediate du contexte
- decision rapide
- lecture fiable

Si `movi` reussit parfaitement cette transition, toute l'experience parait superieure: plus premium, plus intelligente, plus calme.

### 2.2 User Mental Model

L'utilisateur n'entre pas dans `movi` avec un modele mental complexe. Il pense surtout en termes de:
- "qu'est-ce que je peux regarder maintenant ?"
- "est-ce que je peux reprendre ce que j'avais commence ?"
- "est-ce que c'est accessible ou bloque ?"
- "si je clique, est-ce que ca va vraiment marcher ?"

Son attente implicite est simple:
- l'application doit se souvenir de son contexte
- l'etat d'acces doit etre clair
- la lecture doit etre une consequence naturelle, pas une aventure technique

Par rapport aux solutions actuelles, les frustrations typiques sont:
- home trop chargee ou peu priorisee
- reprise peu fiable ou peu visible
- statut d'acces ambigu
- sync ou etats degrades implicites
- parcours TV qui perdent l'utilisateur dans le focus ou la hierarchie

Le modele mental attendu pour `movi` doit donc etre:
**"l'app sait ou j'en suis, me montre l'option la plus utile, et je peux agir tout de suite en confiance."**

### 2.3 Success Criteria

L'experience coeur est reussie si l'utilisateur ressent que "ca marche tout seul" sans perdre le sentiment de controle.

**Success indicators:**
- l'utilisateur atteint un ecran utile presque immediatement
- il identifie en moins de quelques secondes ce qu'il peut reprendre, lancer ou explorer
- l'action principale du moment est evidente visuellement
- la reprise se fait au bon endroit, sans boucle ni surprise
- le retour depuis detail ou player preserve le contexte de navigation
- un statut sensible comme premium, parental, offline ou sync en attente est compris sans interpretation
- sur TV, le focus reste stable et la prochaine action est toujours previsible

L'utilisateur doit se sentir:
- rapide
- competent
- oriente
- rassure

### 2.4 Novel UX Patterns

L'experience definissante de `movi` repose surtout sur des patterns etablis, mais recomposes avec plus de rigueur.

**Patterns etablis a assumer**
- home en rails / surfaces de priorite
- page detail avec action principale claire
- playback comme extension naturelle du detail
- continue watching / resume comme point d'entree fort
- retour contextuel coherent
- navigation TV a focus directionnel stable

**Ce que `movi` doit rendre plus fort que la moyenne**
- la visibilite des etats critiques directement dans le flux
- la clarte du "quoi faire maintenant"
- la qualite de reprise cross-device
- la continuite apres interruption, erreur ou retour reseau
- la lisibilite du statut premium / entitlement / parental

Il ne s'agit donc pas d'inventer un geste totalement nouveau. Il s'agit plutot de **combiner des patterns familiers de facon plus nette, plus fiable et plus explicite**.

### 2.5 Experience Mechanics

**1. Initiation**
L'utilisateur ouvre l'application ou revient apres interruption.
Le systeme doit le conduire tres vite vers:
- un ecran utile
- un etat comprehensible
- une priorite visible

Le point d'entree principal doit etre une surface qui repond au besoin du moment:
- reprendre
- continuer
- lancer
- corriger un blocage
- retrouver un contenu pertinent

**2. Interaction**
L'utilisateur parcourt peu, decide vite et agit.
Les mecanismes principaux sont:
- selection tactile ou focus TV
- action primaire toujours evidente
- parcours browse -> detail -> playback court
- chemin de reprise visible et confiant

L'utilisateur ne doit pas avoir a "deviner" si une lecture va marcher ou si un acces est disponible.

**3. Feedback**
Le systeme doit confirmer clairement:
- qu'un contenu est disponible
- qu'une reprise est possible
- qu'une action est en cours
- qu'un etat degrade ou bloque existe
- ce que l'utilisateur peut faire ensuite

Le feedback ne doit pas etre seulement technique. Il doit etre actionnable et situe dans le contexte.

**4. Completion**
L'utilisateur sait qu'il a reussi quand:
- la lecture demarre ou reprend correctement
- l'etat final correspond a son attente
- il peut revenir sans perdre sa situation
- l'app continue de paraitre stable apres l'action

Le succes n'est pas juste "video en cours". Le succes est:
**"j'ai atteint ce que je voulais, vite, clairement, et sans avoir eu a lutter contre l'interface."**

## Visual Design Foundation

### Color System

La fondation couleur de `movi` doit partir du theme deja present dans l'application. La palette actuelle est suffisamment distinctive et coherente avec les objectifs emotionnels du produit; il ne faut donc pas la remplacer, mais la formaliser.

**Couleur d'accent principale**
- `Movi Blue`: `#2160AB`

Cette couleur doit porter:
- les actions primaires
- les etats de focus importants
- les liens ou appels a l'action critiques
- certains indicateurs de progression ou d'activation

Elle ne doit pas etre surutilisee comme couleur decorative. Dans `movi`, le premium vient de la retenue, pas de la saturation.

**Palette sombre canonique**
- `bg/base`: `#141414`
- `bg/secondary`: `#282828`
- `surface/default`: `#1E1E1E`
- `surface/high`: `#1C1C1C`
- `text/primary`: `#FFFFFF`
- `text/secondary`: `#A6A6A6`

La palette sombre doit rester la presentation de reference pour l'experience media premium, en particulier sur TV et sur les parcours playback, detail et browse.

**Palette claire canonique**
- `bg/base`: `#FFFFFF`
- `surface/default`: `#F3F5F8`
- `surface/high`: `#E7EAF0`
- `text/primary`: `#141414`
- `text/secondary`: `#4F4F4F`

La palette claire doit rester sobre, structuree et moins "app generique" que la plupart des themes clairs standards.

**Semantic mapping**
- `primary`: `Movi Blue`
- `background`: fond principal du theme actif
- `surface`: cartes, panneaux, modales et zones de contenu
- `surface-emphasis`: surfaces prioritaires ou couches hautes
- `text-primary`: lecture principale
- `text-secondary`: metadata, descriptions, statuts non critiques
- `focus`: derive de `Movi Blue`, plus lumineux et plus visible sur TV
- `success`: a definir dans la meme logique de sobriete, jamais fluo
- `warning`: visible mais non anxiogene
- `error`: clair et actionnable, jamais dramatique
- `disabled`: derive des tons secondaires et jamais ambigu avec l'etat bloque

**Color principles**
- noir, gris et profondeur d'image doivent porter l'ambiance
- le bleu doit porter la decision, pas decorer toute l'interface
- les etats critiques doivent etre lisibles dans le contexte, sans noyer le contenu
- les surfaces premium doivent gagner en contraste de structure, pas en multiplication de couleurs
- le logo et les icones SVG `movi` doivent heriter de couleurs semantiques coherentes plutot que multiplier des variantes hardcodees

### Typography System

Le systeme typographique de `movi` doit rester sobre, lisible et stable. Il ne doit pas chercher une personnalite demonstrative; il doit soutenir la clarte, la vitesse de scan et la confiance.

La hierarchie existante dans le theme fournit deja une bonne base:
- `headline-small`: `24`, `600`, hauteur `1.2`
- `title-large`: `20`, `600`, hauteur `1.2`
- `title-medium`: `18`, `600`, hauteur `1.2`
- `body-large`: `16`, `500`, hauteur `1.4`
- `body-medium`: `14`, `500`, hauteur `1.4`
- `body-small`: `12`, `400`, hauteur `1.4`
- `label-large`: `16`, `600`
- `label-medium`: `14`, `500`
- `label-small`: `12`, `500`

**Typographic strategy**
- conserver une sans-serif propre, moderne et tres lisible
- privilegier la stabilite de lecture sur mobile et la lisibilite 10-foot sur TV
- reserver les poids forts aux titres, actions primaires et statuts critiques
- utiliser les styles secondaires pour metadata, descriptions et aides contextuelles
- eviter les contrastes typographiques "editoriaux" trop prononces qui nuiraient a la rapidite de comprehension

**Typographic principles**
- une action principale doit toujours ressortir sans crier
- les metadata doivent rester discretes mais lisibles
- les etats sensibles doivent etre comprenables en un coup d'oeil
- sur TV, la taille et le contraste priment sur la densite d'information

**Decision de fondation**
- on fige la hierarchie typographique actuelle comme reference UX
- la famille exacte peut rester celle du theme actuel tant qu'aucune police de marque explicite n'est imposee
- si une police proprietaire est choisie plus tard, elle devra respecter cette meme structure de taille, poids et lisibilite

### Spacing & Layout Foundation

La structure spatiale de `movi` doit communiquer le calme, la priorite et la maitrise. L'interface ne doit jamais paraitre tassee, ni molle.

La base deja visible dans le code est solide:
- echelle principale: `8 / 12 / 16 / 24 / 32`
- padding de page standard: `20 horizontal / 16 vertical`
- rayon courant: `16`
- composants capsule pour pills, tags et actions principales

**Spacing strategy**
- utiliser une micro-unite de `4` pour la precision
- conserver une echelle visible centree sur `8 / 12 / 16 / 24 / 32`
- utiliser `16` comme espace standard entre blocs lies
- utiliser `24` a `32` pour separer les sections ou respirations majeures
- conserver `20` horizontal comme largeur de confort mobile pour les pages standards

**Layout principles**
- priorite visuelle avant densite maximale
- une action principale par zone doit dominer clairement
- les surfaces media doivent respirer davantage que les surfaces utilitaires
- la TV doit augmenter l'air, la lisibilite et la stabilite du focus
- le retour de contexte doit rester spatialement coherent entre browse, detail et player

**Grid approach**
- mobile: structure simple a largeur contrainte avec marges laterales stables
- TV: layout plus aere, zones d'action plus larges, ecarts plus francs, focus plus visible
- les rails, grilles et hero doivent partager une logique d'alignement constante pour que l'utilisateur conserve ses reperes

**Component spacing relationships**
- interieur de composants: `8` a `16` selon densite
- ecart entre controles lies: `8` ou `12`
- ecart entre blocs d'information: `16`
- ecart entre sections majeures: `24` ou `32`
- les composants critiques TV doivent privilegier des cibles plus genereuses plutot qu'une densite forte

### Accessibility Considerations

La fondation visuelle de `movi` doit rester premium sans sacrifier la lisibilite ni la recuperabilite des parcours critiques.

**Accessibility rules**
- garantir un contraste suffisant entre texte et fonds dans les deux themes
- ne jamais exprimer un etat critique par la couleur seule
- reserver les couleurs d'accent aux points de decision et d'orientation
- rendre le focus TV tres visible, stable et constant
- conserver une hierarchie de texte lisible meme a distance
- maintenir des zones tactiles et focusables confortables
- faire en sorte que les etats `blocked`, `premium`, `offline`, `pending-sync` et `error` soient distinguables sans ambiguite

**Specific implications for Movi**
- le bleu principal ne doit pas devenir un texte de lecture longue sur fond sombre
- les gris secondaires doivent rester lisibles sur TV et ne pas tomber dans le faible contraste
- les panneaux d'erreur, de restriction ou de degradation doivent rester calmes, explicites et actionnables
- les composants custom Movi doivent embarquer des etats focus, disabled et pressed coherents par defaut
- les icones et le logo SVG doivent rester decorreles des couleurs fixes, pour pouvoir heriter proprement des roles semantiques et des etats d'interface
- l'iconographie custom ne doit jamais etre l'unique porteur d'un statut critique

## Design Direction Decision

### Design Directions Explored

Six directions ont ete explorees pour `movi`, toutes construites sur la meme fondation visuelle:
- palette sombre premium issue du theme existant
- accent `Movi Blue` `#2160AB`
- composants proprietaires Movi
- iconographie SVG custom
- priorite a la reprise
- lisibilite des etats critiques
- compatibilite mobile + Android TV

Les directions explorees sont:
- **Direction 1 - Spotlight Calm**: hero plus cinematographique, respiration maximale, signature premium forte
- **Direction 2 - Resume First**: home organisee autour de la reprise immediate et de l'action prioritaire
- **Direction 3 - Signal Layered**: etats critiques integres directement dans le flux produit
- **Direction 4 - Library Pulse**: variation plus dense, plus browse, plus bibliotheque
- **Direction 5 - Focus Frame**: direction TV-first avec focus visible et navigation directionnelle tres stable
- **Direction 6 - Editorial Balance**: compromis plus prudent et plus migrable entre premium, reprise et signaux systeme

### Chosen Direction

La direction recommandee pour `movi` est une **direction hybride** composee principalement de:
- la structure `Resume First` de la **Direction 2**
- le systeme de focus et de navigation TV de la **Direction 5**
- la respiration premium et le ton visuel de la **Direction 1**
- le traitement contextuel des etats critiques de la **Direction 3**

Concretement, cela signifie:
- une home centree d'abord sur "reprendre ou lancer maintenant"
- une action primaire du moment toujours dominante
- une presentation visuelle calme, sobre et premium
- une navigation TV avec focus net, constant et rassurant
- des statuts `premium`, `parental`, `offline`, `pending-sync` et `error` visibles dans le bon contexte, sans surcharge

La **Direction 4** n'est pas retenue comme base principale car elle deplace trop le produit vers une logique de catalogue dense.
La **Direction 6** reste une bonne base de migration si une adoption plus prudente est necessaire a court terme.

### Design Rationale

Cette direction hybride est la plus coherente avec la promesse coeur de `movi`: retrouver rapidement le bon contenu et reprendre ou lancer sans doute.

Elle est preferee parce qu'elle:
- met la reprise et la clarte d'action au centre de l'experience
- preserve une vraie sensation premium sans tomber dans le spectaculaire inutile
- traite Android TV comme une surface de premier ordre, pas comme une adaptation secondaire
- rend visibles les etats critiques qui conditionnent la confiance utilisateur
- reste compatible avec un brownfield Flutter deja en place et avec des composants Movi existants

Elle cree un meilleur equilibre entre:
- desirabilite premium
- efficacite immediate
- robustesse percue
- faisabilite de migration

### Implementation Approach

L'implementation devra suivre cet ordre:

**1. Fixer les patterns structurants**
- home avec priorite forte a `continue watching / resume`
- hero plus compact et plus utile qu'editorial
- detail avec action primaire dominante
- retour contextuel stable depuis player et details

**2. Deriver les composants prioritaires**
- `MoviResumeHero`
- `MoviContinueWatchingRail`
- `MoviFocusFrame`
- `MoviStatePanel`
- `MoviPremiumBadge`
- `MoviBlockedStateCard`
- `MoviPlaybackActionCluster`

**3. Appliquer la direction par surface**
- mobile: acces rapide, hierarchie nette, densite controlee
- TV: plus d'air, focus plus fort, cibles plus genereuses, transitions plus predictibles

**4. Gouverner strictement la densite**
- limiter le nombre de rails visibles
- eviter les homes surchargees
- reserver les signaux critiques aux endroits ou ils influencent une decision
- garder le bleu comme couleur d'action et de focus, pas comme decoration permanente

**5. Migrer de facon brownfield**
- adopter d'abord cette direction sur les surfaces coeur: home, detail, player overlays, continue watching, premium states, parental states
- utiliser la Direction 6 comme niveau minimal acceptable sur les zones legacy avant alignement complet

## Addendum 2026-04-03 - Canonical Entry Flow

Le recadrage approuve introduit un ordre UX cible explicite pour l'entree dans `movi`.

Ordre cible ecran par ecran:
- `Native Splash`
- `Entry Bootstrap Surface`
- `Auth Recovery / Sign-In Decision`
- `Profile Decision`
- `Source Hub`
- `Source Warmup / Catalog Recovery` uniquement si necessaire
- `Home Lite`
- `Home Hydrated`

Regles UX approuvees:
- l'utilisateur ne doit jamais percevoir `startup`, `launch`, `bootstrap` et `warmup` comme des couloirs techniques distincts
- tout etat critique d'entree doit expliciter ce qui se passe, ce qui est sur, et quelle action vient ensuite
- `WelcomeUserPage` ne doit plus etre defini comme une redirection auth implicite, mais comme une vraie surface de decision profil
- `WelcomeSourcePage` et `WelcomeSourceSelectPage` evoluent vers un `Source Hub` unifie avec etats `add`, `repair`, `restore`, `choose`, `continue degraded`
- `WelcomeSourceLoadingPage` devient un etat borne de warmup/recovery, pas un preload obligatoire avant toute entree utile
- `Home Lite` devient la premiere surface utile prioritaire des qu'un contexte sur existe

Contraintes TV additionnelles:
- auth, profil, source, erreur, timeout et offline doivent respecter les memes exigences de focus visible et de lisibilite `10-foot UI` que les surfaces discovery
