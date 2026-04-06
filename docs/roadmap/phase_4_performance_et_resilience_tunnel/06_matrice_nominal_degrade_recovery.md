# Sous-phase 4.5 - Matrice nominal / degrade / recovery et safe states

## Objectif

Definir les safe states critiques du tunnel et la matrice de comportement associee, afin que chaque erreur importante debouche sur:
- une surface visible coherente
- une action primaire claire
- une issue attendue defendable

Cette sous-phase ne redefinit ni les surfaces UX de phase 1 et 2, ni le modele canonique de phase 3. Elle fixe comment le tunnel se comporte quand tout va bien, quand il degrade, et quand il entre en recovery.

## Principe directeur

Le tunnel ne doit jamais laisser l'utilisateur dans un entre-deux opaque.

Chaque situation critique doit produire:
- soit une progression nominale
- soit un `safe state` degrade explicite
- soit une action de recovery claire

Le critere de qualite n'est pas seulement "arriver a `home`", mais:
- savoir pourquoi on n'y est pas encore
- offrir une prochaine action utile
- borner le temps avant un etat comprehensible

## Rappel de coherence avec le modele canonique

La matrice ci-dessous s'aligne sur:
- `stage`: `preparing_system`, `auth_required`, `profile_required`, `source_required`, `preloading_home`, `ready_for_home`
- `execution_mode`: `nominal`, `degraded`, `blocked`
- `continuity_mode`: `cloud`, `local_fallback`

Rappel important:
- `Home vide` n'est pas un etat tunnel distinct
- `Home vide` est une issue fonctionnelle de `ready_for_home` avec `content_state = empty`

## Catalogue des safe states critiques

Les safe states recommandes du tunnel sont:

1. `network_required_blocked`
2. `auth_required_explicit`
3. `profile_selection_required`
4. `source_selection_required`
5. `source_recovery_required`
6. `local_fallback_entry`
7. `prehome_partial_recovery`
8. `ready_for_home_empty`

## Definition rapide des safe states

### `network_required_blocked`

Usage:
- pas de reseau utilisable
- aucune continuation sure autorisee

Surface:
- `Preparation systeme`

Promesse UX:
- dire clairement que le wifi ou internet est requis
- proposer un retry manuel

### `auth_required_explicit`

Usage:
- session absente
- session expiree
- re-verification obligatoire

Surface:
- `Auth`

Promesse UX:
- faire sortir le tunnel de l'ambiguite
- demander l'action de connexion explicitement

### `profile_selection_required`

Usage:
- profils resolves mais aucun profil selectionne ou selection invalide

Surface:
- `Choix profil`

Promesse UX:
- faire du choix profil la seule action principale

### `source_selection_required`

Usage:
- aucune source exploitable selectionnee
- source courante absente ou non resolue

Surface:
- `Choix / ajout source`

Promesse UX:
- permettre de choisir ou ajouter une source
- ne pas cacher la raison du blocage

### `source_recovery_required`

Usage:
- source selectionnee mais invalide
- validation source timeout ou erreur non fatale

Surface:
- `Choix / ajout source` avec message inline ou banner de recovery

Promesse UX:
- permettre `Retry`
- permettre retour a la liste des sources

### `local_fallback_entry`

Usage:
- cloud partiellement indisponible
- continuation locale consideree sure

Surface:
- `Preparation systeme`, puis eventuellement `Creation profil` ou `Choix / ajout source`

Promesse UX:
- expliquer que l'app continue en mode local
- ne pas melanger cette bascule avec un succes cloud nominal

### `prehome_partial_recovery`

Usage:
- pre-home minimal incomplet dans les limites autorisees
- certains enrichissements restent differrables apres `home`

Surface:
- `Chargement medias`

Promesse UX:
- tenir la promesse pre-home minimale
- ne pas attendre le catalogue complet `10-15 s`

### `ready_for_home_empty`

Usage:
- source valide
- catalogue minimal resolu
- aucun contenu exploitable

Surface:
- `Home` avec empty state explicatif

Promesse UX:
- sortie fonctionnelle claire
- pas de faux echec tunnel

## Matrice nominal / degrade / recovery

| Mode | Etat detecte | Stage cible | Comportement systeme | Surface visible | Action primaire | Action secondaire | Issue attendue |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `nominal` | startup OK, session OK, profil OK, source OK, preload minimal OK | `ready_for_home` | enchaine les resolutions sans interruption visible inutile | `Preparation systeme` puis `Chargement medias` tres court si necessaire | attendre la fin du chargement | aucune ou retour contextuel | entree sur `Home` prete |
| `nominal` | session absente attendue | `auth_required` | route vers auth sans passer par un etat d'erreur | `Auth` | se connecter / confirmer le code | recommencer le parcours | session resolue puis suite nominale |
| `nominal` | utilisateur connu sans profil selectionne | `profile_required` | demande un choix explicite | `Choix profil` | selectionner un profil | recommencer le parcours | progression vers resolution source |
| `nominal` | utilisateur connu sans source active | `source_required` | ouvre le hub source avec contexte explicatif | `Choix / ajout source` | choisir ou ajouter une source | retour en arriere / restart | progression vers validation source |
| `nominal` | source valide mais catalogue vide | `ready_for_home` | termine le tunnel sans erreur | `Home` avec empty state | ajouter / changer de source | retry sync si utile | `Home vide` explicite |
| `degraded` | connectivite absente ou internet non joignable | `preparing_system` avec `execution_mode = blocked` | stoppe les resolutions distantes et atteint vite un etat comprehensible | `Preparation systeme` avec message reseau requis | `Retry` | recommencer le parcours | retour au nominal si reseau retabli |
| `degraded` | session resolve timeout mais fallback local autorise | `preparing_system` puis branche locale | entre en `local_fallback` borne | `Preparation systeme` avec explication, puis suite locale | continuer en local | retry cloud | progression vers profil/source local |
| `degraded` | inventaire profils indisponible mais donnees locales exploitables | `profile_required` avec `continuity_mode = local_fallback` | lit le snapshot local au lieu du cloud | `Choix profil` | choisir un profil local | retry sync cloud | retour vers tunnel nominal local |
| `degraded` | inventaire sources indisponible mais source locale exploitable | `source_required` ou continuation directe | conserve la source locale si sure | `Choix / ajout source` seulement si necessaire | conserver ou choisir une source | retry sync cloud | suite locale sans blocage opaque |
| `degraded` | source validation lente au-dela de `slow` mais avant `blocked` | `source_required` | garde la surface source avec message de lenteur | `Choix / ajout source` | patienter ou `Retry` | changer de source | succes source ou bascule recovery |
| `degraded` | `preloading_home` lent mais minimal encore atteignable | `preloading_home` avec `loading_state = slow` | montre que le chargement est plus long que prevu | `Chargement medias` | patienter | `Retry` si timeout franchi | entree sur `Home` quand le minimum est pret |
| `degraded` | cloud partiel apres auth OK | stage courant avec `execution_mode = degraded` | separe ce qui doit bloquer de ce qui peut etre differe | surface courante avec banner de recovery si utile | continuer sur le chemin autorise | retry cloud | progression sans faux succes cloud |
| `recovery` | session expiree ou reconfirmation obligatoire | `auth_required` avec `execution_mode = blocked` | invalide la continuation precedente et relance auth | `Auth` | se reconnecter | recommencer le parcours | nouvelle session puis reprise nominale |
| `recovery` | profil selectionne devenu invalide | `profile_required` | efface la selection invalide et exige un nouveau choix | `Choix profil` | choisir un autre profil | recommencer le parcours | reprise vers source |
| `recovery` | source selectionnee invalide ou supprimee | `source_required` | retire la source active invalide et force un choix manuel | `Choix / ajout source` avec message explicatif | choisir une autre source | `Retry` validation | reprise vers preload minimal |
| `recovery` | source validation timeout au-dela de la borne | `source_required` avec recovery explicite | stoppe l'attente infinie et ouvre le mode de correction | `Choix / ajout source` avec message d'erreur | `Retry` validation | changer de source | succes source ou maintien safe state |
| `recovery` | `preloading_home` partiel a l'expiration de la borne globale | `preloading_home` puis `ready_for_home` si minimum atteint | coupe le travail differrable, conserve le minimum et poursuit apres `home` | `Chargement medias` puis `Home` | continuer vers `Home` | retry enrichissements secondaires plus tard | `Home` utile avec chargements post-home |
| `recovery` | retry epuise sans continuation sure | stage courant avec `execution_mode = blocked` | atteint un state bloque clair au lieu d'une boucle | surface courante avec message fort | recommencer le parcours | retour / fermer | sortie explicite et non opaque |

## Mapping simplifie etat -> surface -> action -> issue

| Etat detecte | Surface cible | Action primaire | Issue attendue |
| --- | --- | --- | --- |
| `network_unavailable` | `Preparation systeme` | `Retry` | reprise des resolutions si reseau OK |
| `auth_missing` / `auth_expired` | `Auth` | confirmer la connexion | retour au nominal apres session valide |
| `profile_missing` / `profile_selection_required` | `Choix profil` | selectionner un profil | retour vers resolution source |
| `source_missing` | `Choix / ajout source` | choisir ou ajouter une source | retour vers validation source |
| `source_invalid` | `Choix / ajout source` | changer ou revalider la source | retour vers preload minimal |
| `catalog_minimal_timeout` avec minimum non atteint | `Chargement medias` ou surface precedente selon contrat fautif | `Retry` | reprise du preload borne |
| `catalog_minimal_ready` + `source_catalog_empty` | `Home` vide | ajouter / changer de source | sortie fonctionnelle claire |
| `local_fallback_active` | surface nominale suivante avec contexte local | continuer | progression locale bornee |

## Regles de coherence avec les surfaces UI

Les safe states de phase 4 doivent reutiliser exclusivement les surfaces cibles de phase 1 et 2:
- `Preparation systeme`
- `Auth`
- `Creation profil`
- `Choix profil`
- `Choix / ajout source`
- `Chargement medias`
- `Home` avec empty state

Ils ne doivent pas recreer:
- un ecran d'erreur reseau autonome
- une page de timeout dediee
- une page de validation source dediee
- une page `home vide` hors `Home`

Regle:
- si le systeme peut encore demander une action contextuelle claire, rester sur la surface metier courante
- ne changer de surface que si le stage canonique change vraiment

## Regles d'entree en safe state

1. entrer en safe state avant la borne `blocked` si l'utilisateur ne comprend plus ce qui se passe
2. ne jamais laisser un retry automatique repousser indefiniment l'acces a une surface comprehensible
3. ne pas cacher un `local_fallback` derriere un faux succes cloud
4. privilegier `source_required` plutot que multiplier des sous-etats techniques
5. privilegier `ready_for_home` si le minimum utile est atteint, meme si le catalogue complet continue apres

## Zones de fragilite restantes

Les points suivants restent sensibles pour l'implementation:
- seuil exact ou un timeout de `catalog_minimal_ready` doit renvoyer a `source_required` plutot que rester sur `Chargement medias`
- frontiere precise entre `degraded` et `blocked` quand le cloud est partiellement disponible mais incoherent
- politique de reprise une fois le cloud revenu apres un `local_fallback`
- granularite du message de recovery source pour distinguer:
  - identifiants invalides
  - timeout
  - source vide
- reprise post-home des enrichissements sans detruire la perception de stabilite

## Decisions recommandees

- traiter `offline` comme un vrai `blocked safe state`, pas comme un spinner long
- traiter `session invalide` comme un retour direct a `Auth`, pas comme une erreur generique
- traiter `source invalide` comme un retour au hub source, pas comme un ecran technique
- traiter `catalogue vide` comme une issue fonctionnelle, pas comme une panne
- traiter `catalogue complet 10-15 s` comme un travail post-home, pas comme un pre-home allonge

## Verdict

La sous-phase `4.5` est suffisamment stable si l'on retient ces points:
- chaque erreur critique a maintenant un safe state cible
- chaque safe state reutilise une surface deja validee
- la matrice couvre les cas nominaux, degrades et de recovery sans reintroduire d'ecrans techniques

La suite logique est la sous-phase `4.6`, pour transformer ces decisions en liste d'optimisations obligatoires avant release.
