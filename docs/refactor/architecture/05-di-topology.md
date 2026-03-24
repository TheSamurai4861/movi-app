# Topologie DI / Riverpod / GetIt / AppState
## A2 — Cartographie de la dépendance réelle

## 1. Objet du document

Ce document cartographie la topologie réelle des dépendances dans Movi.

Le but n’est pas de produire une liste exhaustive de tous les `sl<T>()` du projet, mais de répondre aux questions structurantes :

- qui construit réellement quoi ;
- où Riverpod est la façade principale ;
- où GetIt reste la vraie source de vérité ;
- où les deux systèmes se mélangent ;
- pourquoi `AppStateController` est aujourd’hui un point de tension architectural.

Ce document doit permettre de préparer les décisions suivantes :
- cible DI officielle ;
- stratégie de migration ;
- réduction progressive des zones mixtes.

---

## 2. Résumé exécutif

La topologie actuelle du projet peut être résumée ainsi :

### 1. GetIt reste le registre principal des services métier
L’injecteur enregistre encore :
- `AppStateController`
- `AppLaunchStateRegistry`
- les modules data/features
- de nombreux services, repositories et use cases. :contentReference[oaicite:9]{index=9} :contentReference[oaicite:10]{index=10} :contentReference[oaicite:11]{index=11}

### 2. Riverpod pilote l’UI et une partie de la composition applicative
On observe des providers Riverpod qui :
- composent des repositories concrets ;
- gèrent des notifiers UI ;
- portent le routeur global ;
- lisent directement `appStateControllerProvider`. :contentReference[oaicite:12]{index=12} :contentReference[oaicite:13]{index=13} :contentReference[oaicite:14]{index=14}

### 3. `slProvider` sert de couche adaptatrice
Une partie importante des providers Riverpod ne construit pas réellement leurs dépendances :
ils vont les chercher dans GetIt via `ref.watch(slProvider)<T>()`. :contentReference[oaicite:15]{index=15} :contentReference[oaicite:16]{index=16} :contentReference[oaicite:17]{index=17}

### 4. `AppStateController` est la fracture principale
Il existe aujourd’hui plusieurs chemins d’accès à ce contrôleur :
- enregistrement GetIt côté injecteur ;
- accès Riverpod dans certains providers ;
- consommation via `sl<AppStateController>()` dans des modules et services legacy. :contentReference[oaicite:18]{index=18} :contentReference[oaicite:19]{index=19} :contentReference[oaicite:20]{index=20}

### Conclusion
Il n’existe pas encore de source de vérité DI unique.  
Le projet fonctionne avec une **cohabitation active**, pas avec une migration terminée.

---

## 3. Les trois couches observées

## 3.1 Couche A — GetIt comme registre de construction

Le fichier d’injection montre que GetIt reste responsable de l’enregistrement d’éléments structurants comme :
- `AppStateController`
- `AppLaunchStateRegistry`
- plusieurs modules feature/data appelés via `_registerFeatureModules()` ;
- des services et repositories utilisés ensuite ailleurs dans l’app. :contentReference[oaicite:21]{index=21}

Dans les modules feature, on voit aussi des enregistrements explicites de services métier dans GetIt, par exemple :
- `EnsureMovieEnrichment`
- `MovieStreamingService`
- `IptvAvailabilityService`
- `BuildMovieVideoSource`
- `GetMovieAvailabilityOnIptv` ;
avec plusieurs dépendances elles-mêmes résolues via `sl<T>()`. :contentReference[oaicite:22]{index=22}

Le même pattern existe côté home :
- `XtreamLookupService`
- `MoviePlaybackService`
- `HomeHeroMetadataService`
- `ContinueWatchingEnrichmentService`
- `LoadContinueWatchingMedia`
- `HomeFeedRepository`
sont enregistrés et assemblés via GetIt. :contentReference[oaicite:23]{index=23}

### Conclusion de cette couche
GetIt n’est pas un reliquat marginal.
Il reste aujourd’hui le **registre principal de construction** pour une large part du domaine et de la data.

---

## 3.2 Couche B — Riverpod comme façade applicative et UI

En parallèle, Riverpod porte clairement une partie de la composition applicative.

Exemple net côté routeur :
`appRouterProvider` est un provider global Riverpod qui lit :
- `appStateControllerProvider`
- `slProvider`
puis construit un `GoRouter` et son `LaunchRedirectGuard`. :contentReference[oaicite:24]{index=24}

Exemple côté movie :
`movieRepositoryProvider` est un `Provider<MovieRepository>` qui compose directement :
- remote data source
- image resolver
- repositories locaux
- `appStateControllerProvider`
- `userId`
puis instancie `MovieRepositoryImpl(...)`. :contentReference[oaicite:25]{index=25}

Exemple côté person :
`personRepositoryProvider` compose aussi directement :
- remote data source
- image resolver
- local data source
- locale
avant de construire `PersonRepositoryImpl(...)`. :contentReference[oaicite:26]{index=26}

On observe également plusieurs notifiers clairement Riverpod-first :
- `MovieToggleFavoriteNotifier`
- `TvToggleFavoriteNotifier`
- `SagaToggleFavoriteNotifier`
- `searchControllerProvider`
- `searchResultsControllerProvider`. :contentReference[oaicite:27]{index=27} :contentReference[oaicite:28]{index=28} :contentReference[oaicite:29]{index=29}

### Conclusion de cette couche
Riverpod n’est pas limité à l’état visuel.
Il sert déjà de **façade d’orchestration applicative**, surtout côté UI, routing et composition locale de certains repositories.

---

## 3.3 Couche C — `slProvider` comme zone mixte

Le signal le plus important de cette A2 est l’existence d’une couche adaptatrice :
des providers Riverpod exposent des dépendances qui restent en réalité construites par GetIt.

Exemples :
- `buildMovieVideoSourceUseCaseProvider = Provider<BuildMovieVideoSource>((ref) => ref.watch(slProvider)<BuildMovieVideoSource>())` :contentReference[oaicite:30]{index=30}
- `searchRepositoryProvider` retourne `locator<SearchRepository>()` depuis `slProvider` :contentReference[oaicite:31]{index=31}
- `contentRatingRepositoryProvider` et `agePolicyProvider` retournent aussi des dépendances issues de `slProvider`. :contentReference[oaicite:32]{index=32}

Autrement dit :
Riverpod expose une API moderne,
mais derrière cette API, la construction et la possession de l’objet restent souvent côté GetIt.

### Conclusion de cette couche
`slProvider` joue un rôle de compatibilité et d’unification d’accès,
mais il **cache l’origine réelle des dépendances** et prolonge la cohabitation ambiguë.

---

## 4. Cas central : `AppStateController`

## 4.1 Enregistré côté GetIt

L’injecteur montre explicitement :

- `sl.registerLazySingleton<AppStateController>(() => AppStateController())`
- `sl.registerLazySingleton<AppLaunchStateRegistry>(...)` :contentReference[oaicite:33]{index=33}

Cela signifie que le système DI legacy considère encore `AppStateController` comme un singleton de service locator.

---

## 4.2 Lu côté Riverpod

Le routeur global lit `appStateControllerProvider` via Riverpod. :contentReference[oaicite:34]{index=34}

`movieRepositoryProvider` injecte aussi directement `ref.watch(appStateControllerProvider)` dans `MovieRepositoryImpl`. :contentReference[oaicite:35]{index=35}

Ces exemples montrent qu’une partie du projet considère déjà Riverpod comme voie normale d’accès à l’état applicatif.

---

## 4.3 Encore consommé côté GetIt / zone legacy

Dans les modules home, plusieurs constructions utilisent encore directement `sl<AppStateController>()`, par exemple :
- `HomeHeroMetadataService(... appState: sl<AppStateController>())`
- `HomeFeedRepositoryImpl(... sl<AppStateController>(), ...)` :contentReference[oaicite:36]{index=36}

Dans les modules movie, `EnsureMovieEnrichment(...)` est enregistré avec `sl<AppStateController>()`. :contentReference[oaicite:37]{index=37}

Et côté tv, `tvRepositoryProvider` continue lui-même à lire `ref.watch(slProvider)<AppStateController>()` au lieu du provider Riverpod dédié. :contentReference[oaicite:38]{index=38}

### Conclusion sur `AppStateController`
`AppStateController` existe aujourd’hui dans une topologie à double accès :
- voie Riverpod ;
- voie GetIt ;
avec une zone mixte intermédiaire.

C’est le meilleur indicateur que la migration d’architecture n’est pas terminée.

---

## 5. Classification des zones

## 5.1 Zones plutôt Riverpod-first

Ce sont les zones où Riverpod semble être l’API de travail principale :

- notifiers UI (`MovieToggleFavoriteNotifier`, `TvToggleFavoriteNotifier`, `SagaToggleFavoriteNotifier`) :contentReference[oaicite:39]{index=39} :contentReference[oaicite:40]{index=40}
- contrôleurs de recherche (`searchControllerProvider`, `searchResultsControllerProvider`) :contentReference[oaicite:41]{index=41}
- routeur global (`appRouterProvider`) :contentReference[oaicite:42]{index=42}
- composition locale de certains repositories concrets (`movieRepositoryProvider`, `personRepositoryProvider`) :contentReference[oaicite:43]{index=43} :contentReference[oaicite:44]{index=44}

### Lecture
Riverpod est déjà fort là où :
- l’UI consomme directement l’état ;
- le cycle de vie doit être porté par le widget tree ;
- la composition locale d’un objet reste simple.

---

## 5.2 Zones plutôt GetIt-first

Ce sont les zones où GetIt semble encore être la vraie infrastructure de construction :

- enregistrement de `AppStateController` et `AppLaunchStateRegistry` :contentReference[oaicite:45]{index=45}
- modules data/features (`MovieDataModule`, `HomeFeedDataModule`, etc.) enregistrant services et use cases dans `sl` :contentReference[oaicite:46]{index=46} :contentReference[oaicite:47]{index=47}
- diagnostics de bootstrap basés sur `sl.isRegistered(...)` :contentReference[oaicite:48]{index=48}

### Lecture
GetIt reste le socle de beaucoup de services “profonds” :
data sources, services métier, use cases, modules transverses.

---

## 5.3 Zones mixtes / ambiguës

Ce sont les zones les plus coûteuses mentalement :

- providers Riverpod qui renvoient simplement `ref.watch(slProvider)<T>()` :contentReference[oaicite:49]{index=49} :contentReference[oaicite:50]{index=50} :contentReference[oaicite:51]{index=51}
- providers qui composent partiellement en Riverpod mais tirent encore des briques clés depuis `slProvider` :contentReference[oaicite:52]{index=52} :contentReference[oaicite:53]{index=53}
- `library_cloud_sync_providers.dart`, qui importe à la fois `flutter_riverpod`, `get_it`, `core/di`, `app_state_provider`, Supabase et profil courant. :contentReference[oaicite:54]{index=54}

### Lecture
Ces zones donnent une impression d’unification,
mais elles reportent en réalité la décision de “qui possède la dépendance”.

---

## 6. Constat principal de A2

Le constat le plus important n’est pas seulement que Riverpod et GetIt cohabitent.

Le vrai constat est :

### 1. Riverpod est souvent la façade de consommation
L’UI et certains providers consomment le système via Riverpod.

### 2. GetIt reste souvent la source de possession/construction
Les objets les plus structurants sont encore enregistrés et résolus dans `sl`.

### 3. `slProvider` rend la frontière moins visible
Il donne une API homogène côté Riverpod,
mais il empêche de voir immédiatement si la dépendance est réellement migrée ou non.

### 4. `AppStateController` cristallise cette ambiguïté
Il est à la fois :
- enregistré dans GetIt ;
- lu via Riverpod ;
- réinjecté dans d’autres services/modules ;
- et utilisé comme point de compatibilité entre anciens et nouveaux flux. :contentReference[oaicite:55]{index=55} :contentReference[oaicite:56]{index=56} :contentReference[oaicite:57]{index=57}

---

## 7. Ce que A2 permet de décider ensuite

Cette cartographie rend possible les décisions suivantes :

### Décision future 1
Choisir officiellement **où vit la source de vérité DI**.

### Décision future 2
Traiter `AppStateController` comme premier chantier de migration,
pas comme un détail secondaire.

### Décision future 3
Distinguer trois types de providers :
- vrais providers de composition ;
- wrappers de compatibilité ;
- providers à migrer hors de `slProvider`.

### Décision future 4
Ne pas refactorer les features sans tenir compte de leur mode réel d’injection.

---

## 8. Première proposition de classement migration

Ce classement n’est pas encore un plan d’implémentation, mais un tri utile.

### Catégorie A — déjà proches de la cible Riverpod
- router global
- notifiers UI
- repositories composés localement dans les providers

### Catégorie B — wrappers temporaires acceptables
- providers qui exposent proprement un use case GetIt à l’UI via Riverpod

### Catégorie C — zones prioritaires de migration
- tout ce qui dépend encore de `sl<AppStateController>()`
- services structurants home/movie/tv qui lisent encore l’état via GetIt
- providers mixtes où l’origine réelle de l’objet n’est plus lisible

---

## 9. Limites de cette étape

Cette A2 est une cartographie **structurelle et exploitable**, mais pas encore un inventaire exhaustif de toutes les lignes concernées.

Ce que l’on sait avec certitude :
- la coexistence Riverpod/GetIt est réelle ;
- elle est active dans plusieurs zones critiques ;
- `AppStateController` est le meilleur point de départ pour une migration propre.

Ce qui demandera encore une passe plus fine si nécessaire :
- compter précisément tous les usages de `sl<T>()` ;
- mesurer feature par feature le coût réel de migration.

---

## 10. Conclusion

A2 confirme que la DI de Movi n’est pas simplement “en transition”.
Elle est aujourd’hui **bifide** :

- Riverpod sert d’interface moderne et de couche d’orchestration ;
- GetIt reste un registre central de construction ;
- `slProvider` fait tenir ensemble les deux mondes ;
- `AppStateController` est le point où cette cohabitation devient la plus visible.

La conséquence directe pour la suite est claire :

**avant de refactorer massivement, il faut décider quelle couche doit posséder les dépendances à terme — et commencer par les zones qui lisent encore `AppStateController` via GetIt.**