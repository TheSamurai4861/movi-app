# Roadmap - Refonte complete du parcours d'entree (welcome -> auth -> sources -> pre-home)

## Objectif

Preparer une refonte complete du tunnel qui mene l'utilisateur depuis l'ouverture de l'application jusqu'a l'arrivee sur `home`, sans traiter la refonte fonctionnelle de `home` elle-meme.

Le perimetre couvre:
- `launch` / bootstrap
- `welcome`
- `auth`
- ajout et selection de source
- chargement de source
- preload avant entree `home`

Le perimetre ne couvre pas:
- la refonte UX et fonctionnelle de `home`
- les ecrans de decouverte apres l'arrivee sur `home`
- la lecture media hors impacts directs sur le tunnel d'entree

## Contexte actuel

Le code expose deja un tunnel explicite autour de:
- `/launch`
- `/welcome/user`
- `/auth/otp`
- `/welcome/sources`
- `/welcome/sources/select`
- `/welcome/sources/loading`
- preload bootstrap vers `/`

Ce tunnel melange aujourd'hui plusieurs responsabilites:
- orchestration de demarrage
- restauration de session
- decisions UX de routage
- gestion des profils
- connexion et selection de sources IPTV
- preload des donnees necessaires avant `home`

La refonte doit viser quatre gains simultanes:
- un chemin UX plus lisible et plus court
- une UI/UX premium et coherente mobile + TV
- une baisse nette de la complexite technique et des couplages
- de meilleures performances percues et reelles sur tout le tunnel

## Principes directeurs

- `One journey, one state model`: un seul modele d'etat canonique pour tout le tunnel.
- `Contracts first`: backend, session, source et preload doivent etre definis par contrats avant la refonte des ecrans.
- `Local-first, cloud-safe`: l'experience doit rester comprehensible et sure en mode degrade.
- `UI follows state`: la navigation et les variantes d'ecrans derivent d'etats metier explicites, pas de conditions dispersees.
- `Fast by design`: chaque etape doit etre budgetee en temps, en nombre d'appels et en cout de rendu.
- `TV-grade clarity`: focus, densite, lisibilite et ordre d'actions doivent etre penses pour mobile et TV.

## Cible produit

Le parcours cible doit repondre a cette logique:
1. ouvrir l'app et comprendre immediatement l'etat courant
2. restaurer la session si possible, sinon ouvrir un auth clair et direct
3. verifier si un profil et une source exploitables existent
4. guider l'utilisateur vers la prochaine action obligatoire, sans branchements ambigus
5. terminer par un preload minimal et borne avant entree dans `home`

Les etats critiques qui doivent devenir explicites:
- `checking_app_state`
- `auth_required`
- `auth_degraded_retryable`
- `profile_required`
- `source_required`
- `source_selection_required`
- `source_sync_in_progress`
- `ready_for_home`
- `blocked_with_recovery`

## Roadmap generale

### Phase 0 - Cadrage et audit du tunnel existant

But: figer l'existant avant de le remplacer.

Travaux:
- cartographier le tunnel actuel frontend, backend et navigation
- inventorier tous les branchements reels, y compris les cas de recuperation
- mesurer les temps actuels du tunnel: cold start, warm start, auth, source sync, preload
- lister les ecrans, providers, services, repositories, routes et side effects concernes
- identifier les dettes majeures: doubles responsabilites, duplication de logique, etats non types, chargements inutiles, couplages UI -> infra

Livrables:
- schema du flux actuel
- inventaire des points de decision
- baseline de performance et de fiabilite
- liste priorisee des irritants UX/UI/archi

Gate de sortie:
- le tunnel actuel est documente de bout en bout
- les cas nominaux, degrades et de recovery sont connus

### Phase 1 - Definition du parcours UX ideal

But: decider le chemin utilisateur cible avant de toucher a l'implementation.

Travaux:
- redessiner le tunnel ideal `launch -> auth/profile -> source -> pre-home`
- reduire le nombre d'etapes visibles quand l'utilisateur est deja en etat valide
- definir les variantes par contexte: premier lancement, session expiree, utilisateur offline, aucune source, plusieurs sources, erreur recuperable
- definir pour chaque ecran:
  - objectif unique
  - information critique a afficher
  - action primaire
  - action secondaire
  - comportement mobile
  - comportement TV
- definir les microcopies et messages systeme critiques

Livrables:
- blueprint UX du tunnel cible
- user flow principal et flows alternatifs
- wireframes basse fidelite de chaque etape
- decision de ce qui doit etre fusionne, supprime ou converti en etat inline

Gate de sortie:
- un chemin principal ideal est valide
- chaque branche alternative a une raison explicite et une issue claire

### Phase 2 - Cible UI/UX et systeme visuel

But: transformer le blueprint UX en specification d'interface exploitable.

Roadmap detaillee:
- [00_roadmap_definition_cible_ui_ux_systeme_visuel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/00_roadmap_definition_cible_ui_ux_systeme_visuel.md)

Travaux:
- definir la direction visuelle du tunnel d'entree
- harmoniser hero, titres, formulaires, etats de chargement, erreurs et confirmations
- revoir la hierarchie visuelle des ecrans welcome, auth, source et pre-home
- definir composants reutilisables pour:
  - layout de page tunnel
  - header
  - formulaire
  - choix de source
  - loading progressif
  - recovery banner
  - empty state / error state
- definir focus management et navigation telecommande pour TV

Livrables:
- spec UI du tunnel
- inventaire des composants a creer ou refactorer
- regles de responsive et d'accessibilite
- checklist d'implementation UX pour mobile et TV

Gate de sortie:
- chaque ecran du tunnel a une structure cible claire
- les composants communs sont identifies avant implementation

### Phase 3 - Architecture cible frontend et backend

But: separer nettement orchestration, etat metier, UI et integrations.

Roadmap detaillee:
- [00_roadmap_definition_architecture_cible_frontend_backend.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/00_roadmap_definition_architecture_cible_frontend_backend.md)

Travaux:
- definir un `entry journey orchestrator` unique pour tout le tunnel
- formaliser la machine d'etat du parcours d'entree
- separer:
  - presentation
  - application/orchestration
  - domain policies
  - data/adapters
- redefinir les contrats backend et infra utiles au tunnel:
  - restauration de session
  - verification auth
  - chargement de profils
  - inventaire des sources
  - selection de source active
  - preload minimal pre-home
- clarifier le role de `Riverpod`, `GetIt`, routeur et composition root
- definir la strategie de feature flags et rollout si la refonte est livree par paliers

Livrables:
- schema d'architecture cible
- contrats et interfaces du tunnel
- machine d'etat du parcours
- liste des modules a extraire, fusionner ou simplifier

Gate de sortie:
- les contrats et responsabilites sont figes
- aucune ecriture UI ne commence sans frontieres claires

### Phase 4 - Strategie performance et resilience

But: rendre le tunnel plus rapide, plus previsible et plus robuste.

Roadmap detaillee:
- [00_roadmap_definition_performance_et_resilience_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/00_roadmap_definition_performance_et_resilience_tunnel.md)

Travaux:
- definir des budgets de performance par etape
- borner les timeouts, retries, preload et fallback
- eliminer les chargements inutiles avant `home`
- separer `must-have before home` et `can-load-after-home`
- ajouter instrumentation sur toutes les transitions du tunnel
- definir les reason codes et evenements de mesure
- concevoir les safe states pour offline, timeout, session invalide, source invalide et preload partiel

Livrables:
- budget de performance du tunnel
- plan d'instrumentation
- matrice nominal / degrade / recovery
- liste des optimisations obligatoires avant release

Gate de sortie:
- chaque etape a un budget de temps
- chaque erreur critique a un etat de repli defini

### Phase 5 - Decoupage d'implementation

But: transformer la cible en lots executables sans casser le produit.

Roadmap detaillee:
- [00_roadmap_definition_decoupage_implementation.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_5_decoupage_implementation/00_roadmap_definition_decoupage_implementation.md)

Travaux:
- decouper la refonte en epics techniques et UX
- ordonner les lots selon les dependances
- definir ce qui peut etre livre derriere feature flag
- identifier les migrations de composants et routes
- prevoir la coexistence temporaire ancien tunnel / nouveau tunnel si necessaire

Ordre recommande:
1. instrumentation et mesures
2. machine d'etat + orchestrateur d'entree
3. contrats auth/profile/source/preload
4. composants UI communs du tunnel
5. ecrans `welcome` et `auth`
6. ecrans `sources` et `source selection`
7. ecran `source loading` et preload pre-home
8. nettoyage final des anciens branchements

Livrables:
- backlog de lots
- dependances entre lots
- plan de migration
- definition des criteres de done par lot

Gate de sortie:
- chaque lot est assez petit pour etre revu, teste et rollbacke

### Phase 6 - Validation, QA et mise en production

But: verifier que la refonte est vraiment meilleure avant generalisation.

Roadmap detaillee:
- [00_mega_roadmap_implementation_et_verification.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/00_mega_roadmap_implementation_et_verification.md)

Travaux:
- definir tests unitaires, widget, integration et e2e du tunnel
- couvrir les scenarios critiques:
  - premier lancement
  - session valide
  - session expiree
  - utilisateur offline
  - aucune source
  - une seule source
  - plusieurs sources
  - echec de preload
- comparer les metriques avant/apres
- prevoir rollout progressif, observabilite, rollback et kill switch

Livrables:
- matrice de validation
- plan de test du tunnel
- checklist de release
- plan de rollback

Gate de sortie:
- le tunnel cible est plus simple, plus rapide et mieux observe que l'existant
- aucun cas critique connu n'est degrade

## Workstreams transverses

### UX / Product
- parcours ideal
- simplification des branches
- microcopy et messages de recovery
- coherences mobile / TV

### Frontend
- composants tunnel
- navigation declarative
- focus management
- ecrans et etats visuels

### Backend / Data / Infra
- contrats de session
- contrats source et selection active
- preload minimal
- erreurs typees et resilience

### Performance / Observabilite
- budgets
- traces et metrics
- instrumentation des transitions
- comparaison avant/apres

### QA / Release
- scenarios de bout en bout
- feature flags
- rollout
- rollback

## Criteres de succes

La roadmap est consideree comme reussie si la refonte permet:
- moins d'etapes visibles et moins de decisions ambigues avant `home`
- un parcours coherent entre mobile et TV
- une architecture plus simple a raisonner et a tester
- un gain mesurable sur cold start, warm start et temps d'acces a un etat utile
- une meilleure lisibilite des etats degrades et des actions de recuperation
- une reduction nette des couplages entre UI, routing, orchestration et details infra

## Prochaine etape recommandee

Avant toute implementation, produire trois artefacts cibles:
1. un schema du flux actuel et du flux cible
2. une specification UX page par page du tunnel
3. une specification d'architecture du `entry journey orchestrator` et de sa machine d'etat

Une fois ces trois artefacts valides, la refonte peut etre decoupee en stories d'implementation realistes.
