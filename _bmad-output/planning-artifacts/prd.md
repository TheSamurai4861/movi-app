---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
inputDocuments:
  - docs/archives/02-04-26/rules_nasa.md
  - docs/archives/02-04-26/architecture/current_state.md
  - docs/archives/02-04-26/architecture/dependency_rules.md
  - docs/archives/02-04-26/roadmap/phase_4_refondation_noyau_critique.md
  - docs/archives/02-04-26/roadmap/phase_4_media_resume_robuste.md
  - docs/archives/02-04-26/traceability/requirements_traceability.md
  - docs/archives/02-04-26/traceability/verification_matrix.md
  - docs/archives/02-04-26/traceability/change_logbook.md
  - docs/archives/02-04-26/risk/hazard_analysis.md
  - docs/archives/02-04-26/risk/failure_modes.md
  - docs/archives/02-04-26/security/threat_model.md
documentCounts:
  briefCount: 0
  researchCount: 0
  brainstormingCount: 0
  projectDocsCount: 11
classification:
  projectType: mobile_app
  domain: general
  complexity: medium
  projectContext: brownfield
workflowType: 'prd'
---

# Product Requirements Document - movi

**Author:** Matteo
**Date:** 2026-04-02

## Executive Summary

`movi` est une application mobile brownfield de consommation movie/TV concue pour offrir une experience premium centree sur la rapidite, la fluidite et la qualite d'execution sur tout type d'appareil. Le produit ne vise pas seulement l'acces au contenu ; il vise une experience d'usage immediatement lisible, reactive et fiable, depuis le lancement de l'app jusqu'a la lecture et la reprise de contenu.

Le probleme traite n'est pas uniquement fonctionnel. Beaucoup d'applications negligent la qualite d'interface, la coherence UX et la performance percue, ce qui degrade la confiance, la clarte et le confort d'usage. `movi` doit donc combiner interface soignee, fonctionnalites utiles, temps de chargement courts et comportements robustes sur les parcours critiques. Dans ce contexte brownfield, le PRD doit formaliser les evolutions produit sans casser le socle existant deja engage sur des lots critiques.

### Ce Qui Rend `movi` Distinctif

La differenciation de `movi` repose sur un niveau d'exigence inhabituellement eleve sur le triptyque `UI / UX / performance`. L'objectif n'est pas d'accumuler des fonctionnalites, mais de livrer des fonctionnalites reellement utiles, rapides a comprendre, rapides a executer et coherentes sur tous les appareils. L'utilisateur doit sentir des les premieres secondes une qualite visuelle, interactive et technique nettement superieure a la moyenne.

L'insight central est que l'interface et la performance ne sont pas une finition cosmetique ; elles sont le produit. Cette vision est renforcee par une discipline d'ingenierie robuste sur les zones sensibles : demarrage fiable, comportements deterministes, reprise media sans boucle, etats surs, observabilite exploitable et maitrise des regressions. `movi` doit paraitre simple et premium cote utilisateur, tout en etant rigoureux et controlable cote systeme.

## Project Classification

Le projet est une application mobile classee dans le domaine `general` de la taxonomie BMAD, avec un positionnement reel de media grand public / entertainment. Sa complexite est `medium`, non par reglementation metier, mais par la criticite de plusieurs flux d'execution : bootstrap, auth, controle parental, playback, media resume, synchronisation et stockage. Le contexte est `brownfield`, avec une base existante a durcir et a faire evoluer.

## Success Criteria

### User Success

Les utilisateurs doivent percevoir `movi` comme une app immediatement rapide, fluide et premium. Le succes cote usage signifie qu'un utilisateur peut ouvrir l'app, atteindre un ecran utile sans attente visible, retrouver rapidement son contenu et reprendre sa lecture sans friction ni perte de contexte.

L'experience doit aussi donner une impression claire de qualite superieure a la moyenne : animations fluides, navigation lisible, absence d'etats confus, continuite entre appareils et confiance dans le fait que l'app garde correctement la progression, les preferences et l'etat utile.

Un utilisateur considere l'app comme "worth it" quand :
- il ouvre l'app et peut agir presque immediatement
- il retrouve sa progression ou ses changements sur un autre appareil quasi en temps reel
- l'interface reste fluide et agreable sur telephone, tablette et autres appareils supportes
- la lecture et la reprise fonctionnent sans surprise ni boucle
- il sent une qualite d'execution constante, pas seulement un bon catalogue

### Business Success

A `3 mois`, le produit est considere comme valide si `movi` atteint :
- `1 000` utilisateurs actifs mensuels
- une note store `>= 4,0`
- `>= 100` abonnements payants actifs
- une conversion abonnement `>= 10 %` des utilisateurs actifs mensuels

A `12 mois`, le produit est considere comme installe si `movi` atteint :
- `10 000` utilisateurs actifs mensuels
- une note store `>= 4,2`
- `>= 1 000` abonnements payants actifs
- une conversion abonnement `>= 10 %` maintenue a l'echelle
- une retention a `30 jours >= 35 %`

### Technical Success

Le produit est techniquement reussi si les parcours critiques sont a la fois rapides, deterministes et observables.

Seuils proposes :
- `cold start` vers ecran utilisable : `P50 <= 2,0 s` et `P95 <= 3,0 s` sur appareil de reference
- `warm start / reprise app` vers ecran utilisable : `P50 <= 1,0 s` et `P95 <= 1,8 s`
- navigation critique entre ecrans cles : `P95 <= 300 ms` avant interaction possible
- lancement playback apres action utilisateur : `P50 <= 2,5 s` et `P95 <= 5,0 s` sur reseau stable
- propagation de synchronisation multi-appareils : `90 % <= 5 s`, `99 % <= 30 s`
- fluidite des transitions critiques : au moins `95 %` des frames dans le budget de rendu sur appareils supportes de reference
- `crash-free sessions >= 99,7 %`

Contraintes de robustesse obligatoires :
- `0` crash loop connue au demarrage
- `0` fail-open connu sur auth ou parental control
- `0` boucle de media resume connue
- `0` secret ou PII dans logs, traces ou preuves
- tous les flux critiques instrumentes avec `operationId`, `reasonCode` et preuves exploitables avant release
- aucune release critique si les quality gates et preuves des flux `startup / auth / parental / playback / resume / sync` ne sont pas au vert

### Measurable Outcomes

Les resultats mesurables qui prouvent que `movi` tient sa promesse produit sont :
- ouverture percue comme rapide sur la majorite des sessions reelles
- synchronisation cross-device visible quasi immediatement dans l'usage courant
- qualite visuelle et interactive refletee par une note store `>= 4,0` puis `>= 4,2`
- monetisation validee par une conversion payante stable `>= 10 %`
- robustesse objectiviee par `>= 99,7 %` de sessions sans crash
- continuite d'experience validee par l'absence de regressions critiques sur les parcours mission-grade

## Product Scope

### MVP - Minimum Viable Product

Le MVP doit rendre toutes les fonctionnalites actuelles reellement `mission-grade`, pas simplement "presentes".

Le MVP inclut :
- demarrage rapide et fiable
- auth et restauration de session robustes
- navigation claire et fluide
- playback et media resume deterministes
- synchronisation multi-appareils fiable et observable
- settings, stockage et etats surs
- qualite UI/UX/perf homogene sur les appareils supportes
- monetisation stable si le flux d'abonnement fait partie de la version lancee

### Growth Features (Post-MVP)

Les fonctionnalites de croissance rendent `movi` plus competitif et plus premium :
- amelioration continue de la personnalisation non-IA
- decouverte de contenu plus efficace
- optimisation du parcours d'abonnement et de conversion
- continuite cross-device plus riche
- raffinement supplementaire des animations, du polish visuel et des micro-interactions
- adaptation plus poussee selon format d'ecran et type d'appareil

### Vision (Future)

La vision long terme est une `app intelligente` qui anticipe mieux les besoins utilisateur sans sacrifier clarte, controle et performance.

Cette vision inclut :
- recommandations IA utiles et credibles
- surface d'accueil plus contextuelle et personnalisee
- priorisation intelligente des contenus et des actions
- continuite d'usage encore plus forte entre appareils et moments de consommation
- experience premium ou intelligence, vitesse et qualite visuelle se renforcent mutuellement

## User Journeys

### 1. Utilisateur principal - Success Path

Yanis, 22 ans, aime regarder des films et series sur mobile, tablette et TV. Il veut une app qui donne une sensation "Netflix-grade" des l'ouverture, mais qui exploite correctement son abonnement IPTV avec plus de controle, plus de rapidite et plus de fonctionnalites utiles.

On le rencontre au moment ou il ouvre l'app pour se detendre rapidement. Son irritant actuel est simple : les alternatives sont lentes, visuellement brouillonnes, ou donnent une impression d'instabilite. Dans `movi`, il ouvre l'app, atteint un ecran utile presque immediatement, retrouve une interface claire, voit du contenu pertinent sans surcharge, et lance une lecture en quelques secondes.

Le moment de valeur arrive quand l'app lui donne a la fois vitesse, confort visuel et utilite reelle. Il n'a pas besoin de lutter contre l'interface. La lecture demarre vite, les animations restent fluides, et l'ensemble parait premium. Sa conclusion implicite est : "c'est enfin une app propre, rapide et agreable a utiliser".

Capacites revelees : demarrage rapide, home lisible, decouverte simple, navigation fluide, playback rapide, interface premium, stabilite percue.

### 2. Utilisateur principal - Edge Case Multi-Appareils

Le meme utilisateur commence un contenu sur un appareil, puis change de contexte quelques minutes plus tard. Il reprend sur une tablette ou un autre appareil et s'attend a retrouver presque immediatement sa progression, son etat utile et ses preferences.

On le rencontre au moment ou beaucoup d'apps echouent : progression absente, synchronisation lente, reprise imprecise, ou etat incoherent. Dans `movi`, l'utilisateur rouvre l'app sur un second appareil, voit sa progression arriver quasi immediatement, retrouve son episode ou film, puis reprend sans boucle, sans faux etat et sans devoir "reparer" manuellement son experience.

Le moment critique est la reprise. Si elle echoue, la promesse premium s'effondre. Si elle reussit de facon rapide et deterministe, l'utilisateur comprend que `movi` est serieuse sur la continuite d'usage. Sa nouvelle realite est simple : il peut changer d'appareil sans friction mentale.

Capacites revelees : synchronisation multi-appareils quasi directe, media resume deterministe, persistance robuste, etats coherents, recuperation propre apres interruption.

### 3. Titulaire du Compte / Parent

Claire utilise le service dans un contexte partage. Elle ne cherche pas seulement a consommer du contenu ; elle veut aussi gerer des profils, des restrictions et les parametres critiques sans ambiguite ni comportement dangereux.

On la rencontre quand elle doit configurer un profil, ajuster une restriction ou verifier que certains contenus restent inaccessibles. Son irritant principal est la peur d'un systeme flou : parametres qui ne s'appliquent pas vraiment, controle parental contournable, ou statut du compte mal compris. Dans `movi`, elle modifie un reglage, comprend immediatement l'effet de sa decision, et voit un comportement coherent, fail-safe et lisible.

Le moment de valeur arrive quand elle sent que le systeme protege correctement les decisions sensibles. L'app n'essaie pas d'etre "magique" ; elle est claire, sure et previsible. Elle gagne en confiance parce qu'elle comprend ce qui est applique et ce qui ne l'est pas.

Capacites revelees : gestion de profils, controle parental deny-by-default, settings robustes, statut d'abonnement lisible, feedback clair sur l'application des regles.

### 4. Support / Ops

Sam intervient quand un utilisateur signale un probleme de demarrage, de lecture, de reprise ou de synchronisation. Son but n'est pas de bricoler ; son but est d'identifier vite la cause, de confirmer le safe state atteint, et d'aider a resoudre sans exposer de donnees sensibles.

On le rencontre au moment d'un incident reel : reprise non restauree, lecture non lancee, sync retardee, ou comportement inattendu sur un appareil. Son irritant principal est l'opacite : logs insuffisants, correlation difficile, ou traces inutilisables. Dans `movi`, il dispose d'une observabilite exploitable avec reason codes, operation IDs et preuves suffisantes pour comprendre ce qui s'est passe sans PII.

Le moment de valeur arrive quand il peut diagnostiquer vite, qualifier le risque, et confirmer qu'aucun etat dangereux n'a ete expose a l'utilisateur. Son succes n'est pas seulement de "voir des logs", mais de pouvoir agir avec confiance et precision.

Capacites revelees : observabilite metier, reason codes, correlation d'evenements, diagnostics sans PII, safe states explicites, support des flux critiques par preuves exploitables.

### Synthese des Capacites Revelees

Ces journeys revelent les capacites produit suivantes :
- ouverture tres rapide vers un ecran utile
- interface premium, claire et fluide sur appareils supportes
- decouverte et lancement de contenu sans friction
- synchronisation multi-appareils quasi immediate
- reprise media deterministe et anti-boucle
- gestion fiable des profils, restrictions et parametres critiques
- comportements fail-safe / fail-closed sur les zones sensibles
- observabilite exploitable pour support et ops sans fuite de PII
- coherence d'etat percue par l'utilisateur a travers tout le cycle d'usage

## Domain-Specific Requirements

### Compliance & Platform Constraints

`movi` doit respecter les regles des plateformes de distribution et d'execution, en particulier sur la gestion des abonnements, les permissions demandees, la transparence des etats de compte et la protection des donnees utilisateur.

Les exigences minimales sont :
- aucun secret, token ou PII dans logs, traces, crash reports ou preuves
- statut d'abonnement toujours lisible, coherent et non ambigu
- restauration d'acces et d'entitlements coherente entre appareils autorises
- permissions limitees au strict necessaire
- comportements compatibles avec les attentes des stores et plateformes supportees

### Technical Constraints

#### TV Support

`movi` doit offrir une experience reellement exploitable sur les surfaces TV et assimilees, pas une simple adaptation visuelle mobile.

Exigences cles :
- navigation entierement utilisable a la telecommande ou aux controles directionnels
- focus management explicite, stable et previsible
- lisibilite a distance sur interface de type "10-foot UI"
- transitions claires entre navigation browse, detail, playback et reprise
- performances percues homogenes malgre les capacites variables des appareils TV
- coherence fonctionnelle entre mobile, tablette et TV sur les parcours critiques

#### Network Constraints

Le produit doit rester utile, comprehensible et sur dans des conditions reseau imparfaites.

Exigences cles :
- demarrage de l'app sans blocage infini en cas de reseau lent ou indisponible
- timeouts, retries et fallback bornes sur les flux critiques
- synchronisation multi-appareils rapide quand le reseau est bon, mais jamais au prix d'etats incoherents
- etats intermediaires lisibles pour l'utilisateur lors de sync, chargement ou reprise
- recuperation propre apres perte/retablissement du reseau
- playback, reprise et sync concus pour degradation maitrisee plutot que comportement erratique

#### Runtime Reliability

Les zones critiques doivent rester deterministes :
- bootstrap sans crash loop
- auth/session fail-closed
- parental control deny-by-default
- media resume sans boucle
- storage/sync observables et recuperables
- instrumentation systematique avec `operationId`, `reasonCode` et preuve exploitable

### Integration Requirements

`movi` depend d'integrations coherentes entre contenu, session, sync et abonnement.

Exigences d'integration :
- resolution fiable des contenus movie/TV et de leurs metadonnees
- propagation coherente de l'etat utilisateur entre appareils
- gestion correcte des entitlements lies a l'abonnement
- maintien d'un etat de lecture et de reprise coherent malgre changements d'appareil ou interruptions
- surface de diagnostic exploitable pour support/ops sans fuite de donnees sensibles

### Subscription Rules

Les regles d'abonnement doivent etre explicites, coherentes et sures.

Exigences cles :
- l'utilisateur doit toujours comprendre s'il a acces ou non a une fonctionnalite premium
- aucune fonctionnalite premium ne doit etre exposee par erreur en cas d'etat d'abonnement inconnu
- en cas d'incertitude sur l'entitlement, le systeme doit echouer en etat sur
- les changements d'abonnement doivent se refleter de facon coherente sur les appareils autorises
- restauration d'abonnement et revalidation d'acces robustes apres reconnexion, changement d'appareil ou reprise de session
- aucun ecran ou message ambigu sur l'etat payant / non payant

### Risk Mitigations

Les risques principaux a contenir sont :
- UX degradee ou inutilisable sur TV malgre support annonce
- etat d'abonnement incoherent entre appareils
- sync rapide mais incorrecte, menant a perte ou corruption de progression
- reprise bloquee ou erronee apres changement d'appareil ou interruption reseau
- erreurs de playback opaques pour l'utilisateur et non diagnostiquables pour le support
- degradation de performance percue sur appareils faibles ou reseaux instables

Les mitigations attendues sont :
- safe states explicites
- comportement fail-safe / fail-closed sur les decisions sensibles
- budgets de performance mesures par categorie d'appareil
- evidence-based validation avant release sur parcours `startup / auth / playback / resume / sync / subscription / TV`

## Exigences Specifiques Mobile

### Vue d'Ensemble du Type de Produit

`movi` est une application Flutter cross-platform concue en priorite pour `Android` et `Android TV` au lancement. Le produit doit livrer une experience premium et coherente sur mobile et TV, avec `iOS` envisage si la demande reelle le justifie, et `Windows` comme extension potentielle ulterieure.

Le type de projet impose une forte exigence sur la performance percue, la coherence multi-formats, la robustesse du playback, et la maitrise des contraintes propres aux stores et aux appareils a capacites variables.

### Considerations d'Architecture Produit

L'architecture mobile doit permettre :
- une base produit commune pour `Android` et `Android TV`
- des adaptations explicites selon surface d'usage : tactile, telecommande, grand ecran
- une gestion claire des differences de capacites entre appareils
- une persistance locale minimale pour continuite d'experience, cache utile et reprise d'etat
- une strategie de notifications decouplee des parcours critiques
- une extension future possible vers `iOS`, puis eventuellement `Windows`, sans refonte produit complete

Le systeme doit privilegier :
- rendu rapide vers ecran utile
- navigation fluide et focus management stable
- comportements deterministes sur playback, reprise et synchronisation
- instrumentation exploitable pour support, qualite et validation release

### Platform Requirements

Plateformes cibles :
- `Android` au lancement
- `Android TV` au lancement
- `iOS` en extension si demande marche confirmee
- `Windows` en extension potentielle ulterieure

Exigences plateforme :
- parite fonctionnelle sur les parcours critiques entre `Android` et `Android TV`
- adaptation explicite de l'UI aux usages TV, pas simple etirement d'interface mobile
- support de plusieurs classes d'appareils Android avec budgets de performance definis
- strategie d'extension future vers `iOS` et `Windows` sans dependances bloquantes a des comportements purement Android

### Device Permissions

Permissions autorisees :
- acces reseau / internet
- notifications
- stockage local limite aux besoins de base de donnees locale et cache image

Contraintes associees :
- aucune permission non essentielle au MVP
- communication explicite de la valeur apportee par les notifications
- usage du stockage local borne, controle et compatible avec la protection des donnees
- aucune dependance produit a des permissions fragiles ou intrusives

### Offline Mode

Le produit ne vise pas la lecture offline dans le MVP.

Le mode offline attendu est limite a :
- cache UI minimal
- conservation locale d'un etat utile minimal
- reprise d'etat locale quand cela est possible
- comportement comprehensible si reseau indisponible

Exigences associees :
- pas d'ecran bloque ni spinner infini en absence de reseau
- affichage clair des etats degrades
- fallback local pour preserver la perception de fluidite
- synchronisation differee et recuperation propre apres retour reseau

### Push Strategy

Les notifications push sont incluses pour informer l'utilisateur d'evenements utiles, notamment :
- nouvel episode d'une serie suivie
- autres evenements pertinents lies au contenu suivi ou a l'activite utilisateur

Exigences de strategie push :
- notifications utiles, peu nombreuses et non intrusives
- possibilite utilisateur de controle clair des preferences
- aucune dependance critique du produit aux notifications pour fonctionner
- coherence entre contenu suivi, preferences utilisateur et message recu
- mesure de l'impact sur retour utilisateur, engagement et reactivation

### Store Compliance

Distribution visee :
- `Google Play Store`
- `App Store`
- eventuellement distribution `Windows` plus tard selon strategie produit

Exigences store :
- conformite aux regles de distribution, d'abonnement et de transparence utilisateur
- comportement d'abonnement coherent avec les entitlements reellement actifs
- clarte sur l'acces premium, la restauration d'achat et l'etat de compte
- permissions limitees et justifiables
- experience suffisamment stable et qualitative pour soutenir la note store cible

### Implementation Considerations

Consequences d'implementation :
- traiter `Android` et `Android TV` comme cibles de lancement de premier ordre
- considerer `iOS` et `Windows` comme cibles conditionnelles tant que la demande n'est pas validee
- separer clairement les exigences de navigation tactile et telecommande
- encapsuler les services de notifications, stockage local et integration store derriere des contrats stables
- eviter tout choix technique qui compromettrait l'extension future multi-plateforme
- valider les parcours critiques sur classes d'appareils representatives avant release

## Cadrage Produit et Developpement Phase

### Strategie et Philosophie MVP

**MVP Approach:** equilibre entre preuve de qualite d'experience et preuve de conversion abonnement.

Le MVP de `movi` ne doit pas seulement montrer que l'app fonctionne ; il doit prouver simultanement que :
- l'experience est objectivement premium sur `Android` et `Android TV`
- les parcours critiques sont mission-grade et fiables
- les utilisateurs sont prets a payer pour cette qualite

Le MVP est donc un **experience-first MVP avec capacite de monetisation reelle**, pas un MVP minimaliste purement fonctionnel.

**Resource Requirements:** equipe reduite mais senior, capable de tenir un niveau de qualite eleve sur Flutter, UX/UI, playback, observabilite, QA et validation multi-appareils.

Equipe minimale recommandee :
- `1` lead Flutter / architecture
- `1` engineer Flutter focalise UX/performance/TV
- `1` engineer integration / backend-adjacent / sync / abonnement
- `1` QA ou validation engineer avec forte discipline preuve/gates
- design support fort, meme si non full-time

### Perimetre MVP (Phase 1)

**Core User Journeys Supported:**
- utilisateur principal qui ouvre l'app, trouve un contenu, lance une lecture rapidement
- utilisateur multi-appareils qui reprend sans friction ni incoherence
- titulaire du compte / parent qui comprend et controle les regles sensibles
- support / ops qui peut diagnostiquer les incidents critiques sans PII

**Must-Have Capabilities:**
- lancement sur `Android` et `Android TV`
- toutes les fonctionnalites deja implementees doivent etre portees a un niveau `mission-grade`
- home et navigation premium
- UX TV reellement exploitable a la telecommande
- playback robuste
- media resume deterministe
- synchronisation multi-appareils fiable
- auth/session robuste
- parental et settings sensibles en etat sur
- abonnement et entitlements clairement geres
- instrumentation et preuves sur les flux critiques
- performance percue elevee sur appareils cibles, y compris classes d'appareils faibles

### Capacites Post-MVP

**Phase 2 (Post-MVP):**
- `Windows`, considere comme extension rapide apres `Android` / `Android TV`
- raffinement supplementaire de la personnalisation non-IA
- optimisation avancee de conversion abonnement
- enrichissement des notifications et preferences associees
- polish supplementaire sur formats d'ecran et classes d'appareils

**Phase 3 (Expansion):**
- `iOS` si la demande est validee
- recommandations IA
- accueil contextuel plus intelligent
- priorisation dynamique des contenus et experiences personnalisees
- extensions produit au-dela du noyau premium actuel

### Strategie de Mitigation des Risques

**Technical Risks:**
- performance reelle degradee sur appareils faibles
- synchronisation multi-appareils trop lente ou incoherente
- UX TV insuffisante malgre support annonce
- regressions sur playback, resume ou startup en cherchant trop de largeur fonctionnelle

Mitigation :
- budgets de performance par classe d'appareil
- validation sur parc d'appareils representatif des le MVP
- quality gates bloquants sur `startup / auth / playback / resume / sync / TV`
- limitation volontaire du scope nouveau tant que l'existant n'est pas mission-grade

**Market / Platform Risks:**
- incompatibilite entre proposition IPTV / abonnement et certaines plateformes de distribution
- ambiguite entre valeur percue premium et valeur monetaire reelle
- risque de friction store autour des regles d'abonnement et de distribution

Mitigation :
- valider tres tot la compatibilite du modele de distribution avec les stores vises
- separer clairement promesse produit, source de contenu et mecanisme d'abonnement
- tester la volonte de payer sur un noyau premium deja solide
- ne pas supposer la compatibilite store comme acquise tant qu'elle n'est pas verifiee

**Resource Risks:**
- scope trop large pour maintenir le niveau de finition promis
- dispersion prematuree sur `iOS`, `Windows`, IA et raffinements non critiques
- sous-estimation du cout de validation multi-appareils et TV

Mitigation :
- faire de `Android + Android TV + mission-grade existant` la frontiere stricte du MVP
- traiter `Windows` comme extension immediate post-MVP, pas comme objectif de lancement
- repousser `iOS` et `IA` hors MVP
- privilegier la reduction de variabilite et la qualite de sortie sur l'ajout de nouveautes

## Functional Requirements

### Access & Session Management

- FR1: Les utilisateurs peuvent lancer l'application et atteindre un etat exploitable meme si certaines dependances de demarrage echouent.
- FR2: Les utilisateurs peuvent etablir, restaurer et terminer une session de maniere coherente sur les appareils supportes.
- FR3: Les utilisateurs peuvent comprendre s'ils ont acces ou non a une zone authentifiee lorsque l'etat de session change.
- FR4: Les utilisateurs peuvent reprendre l'usage de l'application apres interruption sans perdre leur contexte essentiel.

### Content Discovery & Navigation

- FR5: Les utilisateurs peuvent parcourir les contenus movie et TV disponibles dans une interface dediee a la decouverte.
- FR6: Les utilisateurs peuvent acceder aux details d'un contenu avant de decider de le lancer.
- FR7: Les utilisateurs peuvent retrouver un contenu pertinent a partir de l'etat actuel de l'application.
- FR8: Les utilisateurs peuvent identifier ce qu'ils regardent, ce qu'ils ont deja commence et ce qu'ils peuvent reprendre.
- FR9: Les utilisateurs peuvent naviguer entre les parcours cles sans perdre le sens de leur progression dans l'application.
- FR10: Les utilisateurs peuvent utiliser les parcours critiques sur mobile et sur TV avec des interactions adaptees au contexte d'usage.

### Playback & Viewing Continuity

- FR11: Les utilisateurs peuvent lancer la lecture d'un contenu eligible depuis les surfaces principales de l'application.
- FR12: Les utilisateurs peuvent interrompre puis reprendre un contenu sans devoir reconstruire manuellement leur progression.
- FR13: Les utilisateurs peuvent retrouver leur progression de lecture sur un autre appareil supporte.
- FR14: Les utilisateurs peuvent comprendre quand une lecture, une reprise ou une restauration de progression n'a pas pu aboutir.
- FR15: Les utilisateurs peuvent recuperer d'un echec de playback ou de reprise sans rester dans un etat bloquant ou ambigu.
- FR16: Les utilisateurs peuvent conserver une continuite d'usage meme quand la synchronisation n'est pas immediate.
- FR17: Les utilisateurs peuvent beneficier d'une experience de reprise coherente entre films, episodes et contenus deja entames.

### Profiles, Parental Controls & Preferences

- FR18: Les utilisateurs peuvent utiliser des profils distincts avec un contexte d'usage separe.
- FR19: Les titulaires de compte peuvent definir et modifier des restrictions parentales applicables aux profils concernes.
- FR20: Les titulaires de compte peuvent comprendre l'effet des restrictions et des parametres sensibles qu'ils appliquent.
- FR21: Les utilisateurs peuvent consulter et modifier leurs preferences d'application prises en charge.
- FR22: Les utilisateurs peuvent retrouver leurs preferences essentielles apres redemarrage ou changement d'appareil lorsque le produit les supporte.
- FR23: Les utilisateurs peuvent continuer a utiliser l'application dans un etat sur lorsque certaines preferences, regles ou politiques ne peuvent pas etre resolues.

### Subscription & Entitlement Management

- FR24: Les utilisateurs peuvent connaitre leur statut d'abonnement et leur niveau d'acces actuel.
- FR25: Les utilisateurs peuvent acceder aux fonctionnalites premium uniquement lorsqu'ils disposent des droits correspondants.
- FR26: Les utilisateurs peuvent retrouver leurs droits apres restauration de session, changement d'appareil ou revalidation du compte.
- FR27: Les utilisateurs peuvent comprendre pourquoi un acces premium est disponible, indisponible ou en attente de confirmation.
- FR28: Les titulaires de compte peuvent utiliser un parcours d'abonnement coherent avec les plateformes de distribution supportees.

### Notifications & Re-engagement

- FR29: Les utilisateurs peuvent choisir s'ils souhaitent recevoir des notifications liees au contenu suivi.
- FR30: Les utilisateurs peuvent etre informes lorsqu'un nouvel episode ou un evenement pertinent concerne leur contenu suivi.
- FR31: Les utilisateurs peuvent controler les preferences de notifications prises en charge par le produit.

### Cross-Device & Degraded Experience

- FR32: Les utilisateurs peuvent retrouver un etat utile minimal meme lorsque le reseau est indisponible ou degrade.
- FR33: Les utilisateurs peuvent comprendre que certaines donnees ou actions sont en attente de synchronisation.
- FR34: Les utilisateurs peuvent reprendre un usage normal apres retour du reseau sans devoir reparer manuellement leur etat.
- FR35: Les utilisateurs peuvent conserver une experience coherente entre appareils supportes meme lorsque certains evenements arrivent hors sequence.

### Supportability & Operational Visibility

- FR36: Le support et les operations peuvent diagnostiquer les incidents critiques de demarrage, session, lecture, reprise et synchronisation.
- FR37: Le support et les operations peuvent correler les evenements pertinents d'un parcours critique sans exposer de donnees sensibles.
- FR38: Le support et les operations peuvent distinguer un etat recuperable d'un etat necessitant une action corrective.
- FR39: Le produit peut exposer des informations de diagnostic suffisantes pour expliquer les echecs visibles par l'utilisateur.
- FR40: Le produit peut signaler les situations ou il fonctionne en etat degrade ou en etat sur.

## Non-Functional Requirements

### Performance

- L'application doit atteindre un ecran utilisable en `P50 <= 2,0 s` et `P95 <= 3,0 s` au cold start sur appareil de reference.
- L'application doit revenir a un ecran utilisable en `P50 <= 1,0 s` et `P95 <= 1,8 s` en warm start ou reprise.
- Les navigations critiques doivent devenir interactives en `P95 <= 300 ms` sur appareils supportes de reference.
- Le lancement de lecture doit aboutir en `P50 <= 2,5 s` et `P95 <= 5,0 s` sur reseau stable.
- Les transitions critiques doivent rester fluides, avec au moins `95 %` des frames dans le budget de rendu sur les appareils cibles de reference.
- Les budgets de performance doivent etre verifies sur au moins une classe d'appareil faible, une classe moyenne et une classe TV avant release.

### Security & Privacy

- Aucun secret, token, credential ou PII ne doit apparaitre dans les logs, traces, crash reports ou artefacts de preuve.
- Les donnees sensibles doivent etre protegees en transit et au repos selon les capacites des plateformes supportees.
- Les decisions d'acces sensibles doivent echouer en etat sur lorsque les informations necessaires sont absentes, incoherentes ou non verifiees.
- Les permissions appareil doivent etre limitees a `internet`, `notifications` et stockage local strictement necessaire au fonctionnement declare.
- Les parcours d'abonnement, de session et de diagnostic doivent respecter les regles de distribution et de transparence des stores cibles.

### Reliability & Resilience

- Le produit doit maintenir un taux de `crash-free sessions >= 99,7 %` sur les versions candidates a la release.
- Aucun crash loop connu au demarrage ne doit etre accepte en release.
- Aucun fail-open connu sur auth, parental control ou entitlement ne doit etre accepte en release.
- Aucun cas connu de boucle de media resume ne doit etre accepte en release.
- Les flux `startup`, `auth`, `playback`, `resume`, `sync` et `subscription` doivent disposer de timeouts, retries et fallback bornes.
- En condition de reseau degrade ou d'integration indisponible, l'application doit atteindre un etat degrade comprehensible plutot qu'un etat bloquant ou ambigu.

### Scalability

- Le produit doit supporter les objectifs cibles de `1 000` utilisateurs actifs mensuels a `3 mois` et `10 000` utilisateurs actifs mensuels a `12 mois` sans degradation majeure des parcours critiques.
- La croissance x10 entre les objectifs `3 mois` et `12 mois` ne doit pas introduire plus de `10 %` de degradation sur les budgets de performance critiques valides.
- Les mecanismes de synchronisation et de diagnostic doivent rester exploitables sous croissance du volume d'evenements utilisateur.
- Les limites connues de capacite doivent etre surveillees et rendues visibles avant qu'elles ne degradent silencieusement l'experience.

### Accessibility

- Les parcours critiques mobiles doivent respecter les attentes d'accessibilite de base des plateformes supportees pour lecture d'ecran, contraste, taille de texte supportee et navigation claire.
- Les parcours critiques TV doivent etre entierement utilisables via telecommande ou controle directionnel, avec focus visible, stable et previsible.
- Les ecrans cles doivent conserver une lisibilite adequate sur interface TV de type `10-foot UI`.
- Les etats d'erreur, de chargement, de blocage et d'etat degrade doivent etre communiques de facon perceptible et non ambigue.

### Integration & Compatibility

- Les integrations critiques de contenu, session, synchronisation et entitlement doivent exposer des contrats stables et des comportements de fallback definis.
- Le produit doit maintenir la parite fonctionnelle des parcours critiques entre `Android` et `Android TV` au lancement.
- Les differences de surface d'usage entre tactile et telecommande doivent etre traitees sans regression fonctionnelle sur les parcours critiques.
- Le produit doit pouvoir evoluer vers `iOS` puis `Windows` sans redefinition du contrat fonctionnel coeur.
- Toute dependance externe critique doit avoir une strategie de degradation maitrisee en cas d'indisponibilite ou de reponse incoherente.

### Observability & Supportability

- Tous les flux critiques doivent etre traces avec `operationId`, `reasonCode` et contexte suffisant pour diagnostic.
- Les artefacts de diagnostic doivent permettre de relier un echec visible utilisateur a un evenement systeme sans exposer de donnees sensibles.
- Les etats `safe`, `degrade`, `recovered` ou `failed` doivent etre explicitement discernables dans l'observabilite.
- Aucune release critique ne doit etre autorisee si les preuves attendues sur `startup / auth / parental / playback / resume / sync / subscription / TV` sont absentes ou au rouge.
- Les preuves de verification doivent rester indexables et tracables de `REQ -> FLOW -> INV -> TST -> EVD`.

## Addendum 2026-04-03 - Entry Flow Reframe

Le recadrage approuve sur `welcome / auth / sources / entry flow` clarifie que la promesse produit ne porte pas uniquement sur un "home completement hydrate", mais sur l'atteinte rapide d'un **premier etat utile** suivi d'une hydratation progressive.

Exigences additionnelles approuvees:
- distinguer explicitement `first useful state` et `fully hydrated home`
- autoriser une entree `home lite` quand un etat local sur et exploitable existe deja
- rendre explicites dans l'UX d'entree les etats `empty`, `loading`, `error`, `timeout`, `offline`, `expired`, `pending-sync`, `recovered`
- traiter les parcours d'entree `Android` et `Android TV` comme critiques au meme titre que discovery, detail et playback
- mesurer separement:
  - `launch -> first useful state visible`
  - `launch -> home hydrated`
  - `auth recovery visible`
  - `source warmup resolved`

Les quality gates MVP sont donc etendus:
- aucune release critique si la preuve `startup / auth / source selection / first useful home / TV entry flow` est absente ou au rouge
- aucune release critique si l'utilisateur doit attendre un preload complet alors qu'un etat utile, sur et borne pouvait etre affiche plus tot
