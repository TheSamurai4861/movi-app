# Refactor du lancement de l'app

## But du chantier

Ce chantier vise a rendre le lancement de l'application plus lisible, plus
rapide et plus actionnable pour l'utilisateur.

Aujourd'hui, le lancement melange plusieurs sujets dans un meme tunnel :

- initialisation technique de l'app ;
- validation de la session ;
- selection du profil ;
- selection ou restauration de la source IPTV ;
- verification du catalogue local ;
- refresh eventuel du catalogue ;
- preparation de Home ;
- affichage des erreurs ou etats de recuperation.

Le resultat est fonctionnel, mais certains etats sont difficiles a comprendre
cote utilisateur et difficiles a diagnostiquer cote developpement. Un catalogue
absent ou une source a resynchroniser peut bloquer l'ouverture de Home pendant
plusieurs secondes sans surface claire. A l'inverse, certaines erreurs non
critiques de Home ne doivent pas etre traitees comme des echecs complets du
lancement.

## Objectif produit

Le lancement doit expliquer clairement ce que l'app est en train de faire et ce
que l'utilisateur peut faire quand une etape ne peut pas continuer.

Les ecrans de boot doivent couvrir au minimum :

- demarrage technique ;
- verification de session ;
- resolution du profil ;
- resolution de la source IPTV ;
- preparation ou resynchronisation du catalogue ;
- recuperation source en cas d'erreur ;
- ouverture de Home en mode normal ;
- ouverture de Home avec contenu partiel quand une section non critique echoue.

## Objectif technique

Le code de lancement doit separer clairement quatre decisions :

1. L'app peut-elle demarrer techniquement ?
2. L'utilisateur peut-il entrer dans l'app ?
3. La source et le catalogue permettent-ils d'ouvrir Home ?
4. Home est-elle complete ou partiellement degradee ?

Ces decisions ne doivent pas etre masquees derriere une erreur generique. Chaque
etat doit produire un reason code stable, une destination claire et, si
necessaire, une action de recuperation.

## Ce que Figma doit aider a definir

Les maquettes Figma doivent servir a designer les surfaces utilisateur pour les
etats du lancement, pas seulement un splash screen.

Elles doivent aider a repondre a ces questions :

- quel message afficher pendant une preparation source longue ?
- comment distinguer une attente normale d'une erreur recuperable ?
- quelles actions proposer pour une source indisponible ?
- comment afficher un Home partiel sans faire croire que toute l'app est cassee ?
- comment garder l'experience compatible mobile, desktop et TV ?

## Perimetre du premier chantier

Ce premier chantier ne doit pas ajouter de nouvelles fonctionnalites metier. Il
doit stabiliser et clarifier le lancement existant.

Inclus :

- cartographier les etats actuels du boot ;
- definir les etats UX a designer ;
- definir les transitions entre boot, source recovery et Home ;
- identifier les reason codes attendus ;
- preparer les contrats necessaires entre l'orchestrateur et l'UI.

Exclus pour l'instant :

- refonte complete de Home ;
- refonte complete de la recherche ;
- changement du modele de donnees IPTV ;
- redesign global de l'app ;
- ajout de nouvelles sources ou providers.

## Definition de fini

Le chantier sera considere pret a implementer quand :

- tous les etats de lancement attendus sont listes ;
- chaque etat a une destination ou une action claire ;
- les ecrans Figma couvrent les etats utilisateur importants ;
- les transitions critiques sont documentees ;
- le comportement cible est testable avec des logs ou tests automatises.

## Point de depart observe

L'analyse du run Windows du 10 mai 2026 montre que l'app atteint Home
correctement, mais que le demarrage peut durer environ 10,8 secondes quand le
snapshot catalogue local est absent et qu'un refresh IPTV bloquant est
necessaire.

Le prochain objectif est donc de transformer ce temps d'attente en experience
comprehensible et controlable, tout en preservant l'ouverture rapide de Home
quand un snapshot exploitable est deja disponible.
