# Sous-phase 1.2 - User flows et variantes du tunnel d'entree

## Objectif

Formaliser les flux alternatifs du tunnel `ouverture app -> home` a partir du blueprint nominal retenu.

Ce document precise, pour chaque scenario important:
- l'etat detecte
- l'ecran ou la variante cible
- le message visible
- l'action primaire
- l'action secondaire
- l'issue attendue
- la nature du cas: branche legitime, etat inline, erreur bloquante ou recovery non bloquante

## Regle de lecture

Types de cas utilises:
- `Branche legitime`: variante normale du parcours, attendue produit
- `Etat inline`: variation absorbee dans un ecran existant
- `Erreur bloquante`: on ne peut pas continuer sans action ou resolution
- `Recovery non bloquante`: le systeme continue mais explique une degradation et propose une reprise

## Matrice des scenarios

| ID | Scenario | Type | Etat detecte | Ecran ou variante cible | Message visible | Action primaire | Action secondaire | Issue attendue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | Retour utilisateur sain | Branche legitime | Reseau OK, session valide, profil pret, source active exploitable | `Splashscreen / preparation` puis `Home` | Message de preparation bref | Attendre | Aucune | Arrivee directe sur `Home` |
| F2 | Premiere connexion saine | Branche legitime | Pas de session, aucun profil, aucune source | `Auth` -> `Creation profil` -> `Ajout source` -> `Chargement medias` | Messages de guidage lineaires | Continuer | Retour si necessaire | Arrivee sur `Home` apres chargement |
| F3 | Utilisateur existant non connecte | Branche legitime | Pas de session, compte deja existant | `Auth` puis `Choix profil` | Reconnexion + choix du bon profil | Se connecter | Retour | Reprise du tunnel nominal |
| F4 | Session valide mais aucun profil selectionne | Branche legitime | Session OK, profils disponibles, aucun profil courant | `Choix profil obligatoire` | Choisissez un profil pour continuer | Selectionner un profil | Retour | Profil fixe puis retour au flux nominal |
| F5 | Session valide, pas de source active exploitable | Branche legitime | Profil pret, source absente, supprimee ou invalide | `Choix / ajout source` avec message explicatif | Votre source active n'est plus disponible | Choisir ou ajouter une source | Retour | Source valide puis retour au flux nominal |
| F6 | Plusieurs sources et source active invalide | Branche legitime | Plusieurs sources disponibles, source active non exploitable | `Choix / ajout source` avec explication | La source active actuelle ne peut plus etre utilisee | Choisir une autre source | Ajouter une source | Une source valide devient active |
| F7 | Une seule source valide disponible | Branche legitime | Une seule source exploitable detectee | Pas d'ecran supplementaire | Aucun ou message de preparation bref | Attendre | Aucune | Auto-selection puis retour au flux nominal |
| F8 | Pas de maj medias necessaire | Etat inline | Source exploitable, frequence de maj non echue | Preparation absorbee | Aucun message detaille ou message bref | Attendre | Aucune | Passage direct a `Home` |
| F9 | Sync Supabase partiellement indisponible | Recovery non bloquante | Session OK, sync profils/sources/bibliotheque incomplete | Variante `Retry ou mode local` dans l'experience de preparation | Synchronisation indisponible pour le moment | Retry | Continuer en local | Soit sync reussie, soit bascule locale propre |
| F10 | Impossible de joindre le reseau | Erreur bloquante | Pas de reseau au lancement | `Ecran reseau requis` | Le wifi est necessaire pour continuer | Retry | Aucune | Retour au debut et nouvelle verification reseau |
| F11 | Chargement medias trop long | Recovery non bloquante | Temps de chargement superieur au seuil attendu | Variante `Chargement long` | Le chargement prend plus de temps que prevu | Retry | Attendre | Fin du chargement ou nouvelle tentative |
| F12 | Source saisie invalide | Erreur bloquante | Credentials ou endpoint non valides | `Choix / ajout source` avec erreur inline | Message rouge sous le bouton avec raison | Retry | Retour arriere | Correction ou changement de source |
| F13 | Source valide mais catalogue vide | Branche legitime | Connexion source OK, aucun contenu exploitable | `Home vide` avec message explicatif | Aucun contenu disponible pour cette source | Comprendre / fermer le message | Aller aux sources plus tard | `Home` s'affiche quand meme, avec etat vide explique |
| F14 | Fallback local apres echec cloud | Recovery non bloquante | Sync cloud impossible mais continuation locale autorisee | `Creation profil local` puis `Ajout source locale` | Connexion cloud indisponible, poursuite en local | Continuer en local | Retry cloud | Parcours local vers `Home` |
| F15 | Reprise apres interruption en plein tunnel | Branche legitime | App refermee puis rouverte pendant setup | Reprise au debut du tunnel | Reprenons la configuration | Recommencer | Aucune | Reprise propre du parcours depuis le debut |

## Focus sur les scenarios minimum attendus

Les scenarios minimum demandes par la roadmap sont couverts ainsi:
- premier lancement -> `F2`
- session valide -> `F1`
- session expiree -> `F3`
- session non verifiable mais retryable -> `F9`
- utilisateur offline au lancement -> `F10`
- aucun profil -> inclus dans `F2`
- aucun source -> `F5`
- une seule source disponible -> `F7`
- plusieurs sources disponibles -> `F6`
- echec de connexion source -> `F12`
- echec de preload recuperable -> `F11`

## Distinction explicite des types de reponse UX

## Branches legitimes

Ces cas font partie du produit, pas d'une anomalie:
- premiere connexion
- retour utilisateur sain
- choix profil obligatoire
- choix source si aucune source active exploitable
- `Home vide` si source valide mais catalogue vide

## Etats inline

Ces cas ne justifient pas un nouvel ecran:
- pas de maj medias necessaire
- erreur source sous le bouton d'ajout
- information contextuelle sur la source active invalide

## Erreurs bloquantes

Ces cas bloquent l'entree dans `Home`:
- absence de reseau
- source invalide tant qu'aucune source exploitable n'est fournie

## Recoveries non bloquantes

Ces cas degradent le tunnel mais gardent une issue claire:
- sync Supabase partiellement indisponible
- chargement medias trop long
- fallback local autorise

## Incoherences et duplications a supprimer

Les points suivants doivent etre elimines dans la suite de la phase:
- duplication implicite entre `welcome/user` et `auth/otp`
- duplication potentielle entre `welcome/sources` et `welcome/sources/select`
- exposition de plusieurs routes techniques la ou une seule experience de preparation suffit
- variation trop forte de ton entre erreurs, recovery et etats de preparation

## Principe de sortie vers le flux nominal

Chaque variante doit revenir vers le flux nominal des qu'une condition saine est retablie:
- reseau retabli -> retour a la preparation systeme
- session retablie -> retour a la verification profil
- profil choisi -> retour a la verification source
- source valide -> retour a la decision `maj medias necessaire ?`
- chargement termine -> `Home`

## Gate de sortie de la sous-phase 1.2

La sous-phase 1.2 peut etre consideree comme valide si:
- chaque scenario important a une cible UX explicite
- chaque scenario a une action primaire unique
- les cas bloquants et non bloquants sont distingues
- le tunnel sait toujours comment revenir vers le flux nominal

## Conclusion

Le tunnel cible n'est pas seulement un chemin ideal. C'est un systeme de reprises propre, ou chaque ecart au nominal est traite par une reponse UX simple, lisible et orientee vers un retour rapide au parcours principal.
