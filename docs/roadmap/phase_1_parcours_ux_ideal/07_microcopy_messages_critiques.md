# Sous-phase 1.5 - Microcopy et messages systeme critiques

## Objectif

Definir la microcopy critique du tunnel d'entree, avec un ton:
- premium
- clair
- court
- actionnable

Le but est que chaque message:
- explique ce qui se passe
- reduise l'incertitude
- oriente vers la prochaine action
- evite le jargon technique

## Principes de ton

- parler comme un produit maitrise, pas comme un systeme inquiet
- etre direct sans etre brusque
- rassurer sans noyer l'utilisateur dans les details
- privilegier les verbes simples et les phrases courtes
- toujours lier un probleme a une action ou une issue

## Ce qu'il faut eviter

- jargon technique visible: `timeout`, `session invalide`, `degraded retryable`, `bootstrap`
- formulations floues: `une erreur est survenue`, `probleme inconnu`, `echec de l'operation`
- messages passifs sans issue: `chargement...`
- ton anxiogene: `critical error`, `failure`, `fatal`
- accumulation de details systeme dans un ecran de tunnel

## Table de microcopy critique

| ID | Contexte | Type | Message recommande | Action primaire | Action secondaire | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | Ouverture app nominale | Progression | `Preparation de votre experience` | aucune | aucune | message principal du splash premium |
| M2 | Verification acces | Progression | `Verification de votre acces` | aucune | aucune | a utiliser si la phase se prolonge legerement |
| M3 | Sync compte et donnees | Progression | `Recuperation de vos donnees` | aucune | aucune | couvre profils, bibliotheque, sources |
| M4 | Preparation home | Progression | `Preparation de votre accueil` | aucune | aucune | preferable a un wording trop technique |
| M5 | Auth email | Guidage | `Connectez-vous pour continuer` | `Recevoir le code` | `Retour` | simple et explicite |
| M6 | Auth code envoye | Confirmation | `Votre code a ete envoye` | `Continuer` | `Changer d'adresse` | ton court et factuel |
| M7 | Verification code | Progression | `Verification du code` | aucune | aucune | etape transitoire |
| M8 | Premiere creation profil | Guidage | `Creez votre premier profil` | `Creer le profil` | `Retour` | onboarding assume |
| M9 | Choix profil requis | Blocage | `Choisissez un profil pour continuer` | `Choisir un profil` | `Retour` | action obligatoire |
| M10 | Source active manquante | Blocage | `Votre source n'est plus disponible` | `Choisir une source` | `Ajouter une source` | remplace un message technique |
| M11 | Aucune source configuree | Guidage | `Ajoutez votre premiere source` | `Ajouter une source` | `Retour` | premiere connexion ou fallback local |
| M12 | Source en cours de verification | Progression | `Verification de votre source` | aucune | aucune | juste apres validation |
| M13 | Source invalide | Erreur | `Impossible d'utiliser cette source` | `Reessayer` | `Modifier la source` | le detail technique peut etre en sous-texte |
| M14 | Source active invalide parmi plusieurs | Recovery | `Choisissez une autre source pour continuer` | `Choisir une source` | `Ajouter une source` | contexte multi-sources |
| M15 | Catalogue en cours de preparation | Progression | `Chargement de vos films et series` | aucune | aucune | wording principal du preload |
| M16 | Chargement long | Recovery | `Le chargement prend plus de temps que prevu` | `Reessayer` | `Attendre` | pas de jargon technique |
| M17 | Sync cloud partielle | Recovery | `Certaines donnees ne sont pas disponibles pour le moment` | `Reessayer` | `Continuer en local` | remplace tout message type `sync failed` |
| M18 | Absence de reseau | Blocage | `Le wifi est necessaire pour continuer` | `Reessayer` | aucune | conforme a ton arbitrage |
| M19 | Fallback local | Recovery | `Connexion indisponible. Vous pouvez continuer en local.` | `Continuer en local` | `Reessayer` | calme, sans dramatisation |
| M20 | Home vide | Information | `Votre source est connectee, mais aucun contenu n'est disponible pour le moment.` | `Compris` | `Voir mes sources plus tard` | important pour eviter l'effet bug |
| M21 | Reprise apres interruption | Recovery | `Reprenons la configuration` | `Continuer` | aucune | wording simple |
| M22 | Fin de preparation | Confirmation | `Tout est pret` | aucune | aucune | peut etre implicite selon animation |

## Messages secondaires ou sous-textes utiles

Ces formulations peuvent accompagner un message principal, sans surcharger l'ecran.

### Source invalide

Message principal:
- `Impossible d'utiliser cette source`

Sous-texte possible:
- `Verifiez l'adresse, l'identifiant ou le mot de passe.`

### Sync cloud partielle

Message principal:
- `Certaines donnees ne sont pas disponibles pour le moment`

Sous-texte possible:
- `Vous pouvez reessayer ou continuer avec les donnees locales.`

### Chargement long

Message principal:
- `Le chargement prend plus de temps que prevu`

Sous-texte possible:
- `Votre contenu est toujours en preparation.`

## Formulations a eviter

Remplacer:
- `Erreur inconnue`
par:
- `Impossible de terminer cette etape`

Remplacer:
- `Connection failed`
par:
- `Impossible de se connecter pour le moment`

Remplacer:
- `Session invalide`
par:
- `Reconnectez-vous pour continuer`

Remplacer:
- `Bootstrap failed`
par:
- `Impossible de preparer l'application`

Remplacer:
- `No active source found`
par:
- `Choisissez une source pour continuer`

## Ton recommande par type de message

### Progression

- tres court
- rassurant
- sans details techniques

### Erreur

- clair
- localise sur le probleme
- toujours accompagne d'une issue

### Blocage

- direct
- une action principale evidente
- aucune ambiguite sur ce qu'il faut faire

### Recovery

- calme
- honnête
- oriente vers la meilleure option disponible

### Confirmation

- breve
- sobre
- non theatrale

## Gate de sortie de la sous-phase 1.5

La sous-phase 1.5 peut etre consideree comme valide si:
- chaque etape critique du tunnel a au moins un message principal defini
- les messages bloquants ont une action primaire evidente
- les messages de recovery ont une issue claire
- le ton est coherent d'un bout a l'autre du tunnel

## Conclusion

La microcopy du tunnel doit donner une impression de maitrise. Elle n'a pas vocation a decrire la machine. Elle doit simplement rendre le chemin lisible, rassurant et actionnable au bon moment.
