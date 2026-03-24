# Roadmap de transformation vers un projet plus clean

## Phase 0 — Geler le terrain

Objectif : éviter de refactorer dans le vide.

### À faire

* créer `docs/architecture/00-audit.md`
* lister :

  * les features réellement actives
  * les features secondaires
  * les expérimentations
  * les fichiers legacy
* définir les 5 parcours critiques :

  * lancement app
  * auth
  * ajout source IPTV
  * home
  * lecture vidéo
  * sync bibliothèque

### Livrable

Une carte simple :

* **indispensable maintenant**
* **utile plus tard**
* **à supprimer/archiver**

### Règle

Pendant toute la refonte : **pas de nouvelle feature**.

---

## Phase 1 — Choisir un seul centre de gravité pour l’injection

Objectif : supprimer la double architecture mentale.

Le plus gros levier ici est simple : **choisir Riverpod comme point d’entrée unique** pour l’app, et faire progressivement reculer GetIt.

Le snapshot montre :

* `flutter_riverpod`
* `get_it`
* `core/di`
* des providers qui lisent `slProvider`
* un bridge explicite Riverpod → GetIt au startup.   

### Décision recommandée

* **UI + orchestration + dépendances runtime = Riverpod**
* GetIt reste seulement temporaire derrière un adaptateur de transition

### Actions

1. interdire tout nouveau `sl<T>()` dans les nouvelles zones
2. créer une règle :

   * un provider construit un service
   * un service dépend d’interfaces claires
3. supprimer progressivement :

   * `replace<AppStateController>(...)`
   * les accès GetIt dans les providers presentation
4. à terme :

   * `core/di` devient minimal ou disparaît

### Gain

* moins de magie
* moins de bugs d’initialisation
* moins de difficulté à suivre le flux

---

## Phase 2 — Réduire drastiquement le startup

Objectif : rendre le lancement lisible.

Ton startup fait beaucoup trop de choses :

* binding
* environment
* config
* init dependencies
* bridge d’état
* sanity check Supabase
* logging
* sync IPTV background
* écoute de préférences, etc. 

### Problème

Le démarrage devient une gare de triage. Or le startup doit juste :

* préparer le minimum vital
* déléguer le reste

### Cible

Créer 3 niveaux :

* **Bootstrap critique**

  * env
  * config
  * auth/session minimale
* **Bootstrap applicatif**

  * profil courant
  * source IPTV sélectionnée
* **Bootstrap différé**

  * préchargements
  * sync background
  * warmups
  * logs non critiques

### Actions

* découper `app_startup_provider` en :

  * `bootstrap_core_provider`
  * `bootstrap_session_provider`
  * `post_boot_tasks_provider`
* retirer du startup tout ce qui peut être lancé après affichage du shell
* remplacer les gros blocs commentés par des use cases nommés

### Gain

* startup testable
* écran de chargement plus simple
* moins de dépendances croisées

---

## Phase 3 — Reclasser l’architecture en 4 zones nettes

Objectif : arrêter le flou entre `core`, `shared` et `features`.

Aujourd’hui, ton projet contient :

* `core/*`
* `shared/*`
* `features/*`
* des services métier qui semblent parfois vivre dans `shared`, parfois dans `core`, parfois dans une feature. 

### Cible recommandée

#### 1. `app/`

Tout ce qui compose l’app :

* `app.dart`
* router
* theme global
* startup
* shell

#### 2. `foundation/`

Infra transversale pure :

* config
* logging
* network
* storage
* security
* env
* erreurs techniques

#### 3. `domain/`

Objets métier transverses réels :

* media reference
* playback progress
* content rating
* éventuellement interfaces communes

#### 4. `features/`

Chaque feature autonome :

* auth
* profile
* iptv
* home
* search
* library
* movie
* tv
* person
* saga
* player
* settings
* parental

### Règle

* `core/widgets` doit être revu :

  * soit `app/widgets`
  * soit dans la feature concernée
* `shared/` doit devenir **minuscule**

  * seulement ce qui est réellement partagé et stable
  * sinon on remonte dans une feature ou dans `domain`

### Gain

Tu sauras enfin où ranger quoi.

---

## Phase 4 — Simplifier la synchro bibliothèque

Objectif : faire tomber un gros nœud de complexité.

La zone library/sync semble être l’une des plus lourdes :

* `comprehensive_cloud_sync_service`
* `history_sync_applier`
* `playlists_sync_applier`
* `watchlist_sync_applier`
* provider de sync
* invalidations UI
* event bus global.  

### Problème

Tu as probablement mélangé :

* orchestration métier
* accès données
* gestion d’état UI
* refresh des écrans
* événements globaux

### Cible

Un pipeline explicite :

`SyncLibraryUseCase`
→ `pushLocalChanges()`
→ `pullRemoteChanges()`
→ `resolveConflicts()`
→ `persistMergedState()`

### Actions

1. créer un seul point d’entrée :

   * `SyncLibraryUseCase`
2. cacher les appliers derrière ce point d’entrée
3. séparer :

   * logique de sync
   * état UI de sync
4. limiter l’event bus :

   * seulement si vraiment nécessaire
   * sinon invalidation ciblée Riverpod
5. documenter les règles de conflit

   * local wins ?
   * server wins ?
   * timestamp wins ?

### Gain

* flux compréhensible
* sync testable
* moins de side effects

---

## Phase 5 — Réduire les couches là où elles n’apportent rien

Objectif : éviter la clean architecture “cosmétique”.

Vu l’arborescence, certaines features ont probablement trop de couches pour leur poids réel. Exemple typique :

* entity
* repository interface
* repository impl
* datasource
* mapper
* service
* usecase
* provider
  pour une action très simple. 

### Règle pragmatique

Tu gardes la clean architecture **seulement là où elle rapporte** :

* auth
* iptv
* library sync
* player
* parental
* profile

Pour les zones simples :

* page + controller/provider + repository concret peuvent suffire

### À compresser en priorité

* pages settings secondaires
* petits wrappers métiers
* micro use cases trop fins
* services qui ne font qu’un appel repository

### Heuristique

Supprimer une couche quand :

* elle ne porte aucune règle métier
* elle ne sert qu’à “passer le ballon”
* elle ne facilite ni test ni réutilisation

---

## Phase 6 — Recentrer chaque feature autour d’un “feature API”

Objectif : arrêter les imports en toile d’araignée.

Chaque feature devrait exposer un point d’entrée clair, par exemple :

* `features/library/library.dart`
* `features/iptv/iptv.dart`
* etc.

Tu as déjà commencé à le faire sur certaines zones. 

### Cible

Chaque feature expose :

* ses routes/pages publiques
* ses providers publics
* ses modèles publics indispensables

Et garde privé :

* dto
* datasource
* impl
* helpers internes

### Gain

* moins d’imports anarchiques
* frontières plus nettes
* meilleure encapsulation

---

## Phase 7 — Rationaliser `core/widgets` et la UI partagée

Objectif : éviter le “cimetière de composants”.

Le dossier `core/widgets` est souvent un endroit qui grossit trop vite. Dans ton snapshot, il y a beaucoup de composants Movi globaux. 

### Tri recommandé

* **design system vrai**

  * boutons
  * cards
  * pills
  * placeholders
* **widgets d’app**

  * splash
  * nav
  * shell
* **widgets feature**

  * restent dans leur feature

### Règle

Un widget ne va en partagé que s’il est :

* réutilisé à au moins 3 endroits
* stable
* agnostique métier

---

## Phase 8 — Nettoyage dette / legacy

Objectif : enlever le bruit.

J’ai déjà un suspect i18n :

* `fr_MM`
* `app_localizations_bu.dart`
* logique de locale “folklore” qui semble partiellement branchée.  

### À auditer puis nettoyer

* fichiers de locale expérimentaux
* modules “README” morts
* providers plus appelés
* services legacy dépendant encore de GetIt
* duplicated local vs supabase repositories quand un seul flux suffit
* commentaires qui expliquent des contournements historiques

### Règle

Tout fichier doit être dans l’un de ces états :

* actif
* deprecated avec date de retrait
* supprimé

---

# Ordre de refactor recommandé

## Sprint 1

* audit + cartographie
* gel des features
* inventaire des dépendances
* liste des flux critiques

## Sprint 2

* simplification startup
* réduction bridge Riverpod/GetIt
* décision d’architecture officielle

## Sprint 3

* refonte library sync
* suppression des invalidations dispersées
* centralisation du flux sync

## Sprint 4

* reclassement `core/shared/features`
* déplacer fichiers vers la nouvelle structure
* feature APIs propres

## Sprint 5

* compression des couches inutiles
* nettoyage widgets
* suppression legacy i18n et helpers morts

## Sprint 6

* documentation finale :

  * architecture
  * conventions
  * arbre cible
  * règles pour les nouveaux fichiers

---

# Arborescence cible simplifiée

```text
lib/
  main.dart
  src/
    app/
      app.dart
      router/
      startup/
      shell/
      theme/

    foundation/
      config/
      env/
      logging/
      network/
      storage/
      security/
      error/

    domain/
      media/
      playback/
      profile/
      sync/

    features/
      auth/
      profile/
      iptv/
      home/
      search/
      library/
      movie/
      tv/
      person/
      saga/
      player/
      settings/
      parental/

    design_system/
      widgets/
      tokens/
      assets/
```

---

# Règles d’architecture à figer

1. **Une seule stratégie d’injection**

   * Riverpod first

2. **Le startup ne fait pas de métier**

   * il compose, il ne décide pas

3. **Une feature possède son flux**

   * UI
   * state
   * use cases
   * data

4. **Shared est exceptionnel**

   * pas une poubelle

5. **Pas de couche vide**

   * chaque couche doit justifier son existence

6. **Pas de provider qui orchestre 8 systèmes**

   * créer un use case/service dédié

7. **Tout legacy est marqué**

   * sinon supprimé

---

# Ce que je ferais en premier à ta place

Dans cet ordre précis :

1. **Écrire la convention d’architecture cible**
2. **Choisir Riverpod comme source de vérité**
3. **Refactor le startup**
4. **Refactor la sync library**
5. **Nettoyer l’i18n/legacy**
6. **Reclasser les dossiers**
7. **Compresser les couches trop fines**