## 1. Analyse rapide

Le snapshot montre une base qui **vise** une structure propre : plusieurs modules sont déjà séparés en `domain / application / data / presentation`, et certaines briques sont plutôt saines, par exemple `AuthSession/AuthSnapshot`, `AgePolicy`, `CachePolicy` ou `PerformanceTuning`, qui restent lisibles et assez proches des règles métier.   

En revanche, il y a des écarts importants avec `rules.md` sur 4 axes :

1. **architecture inversée** dans plusieurs points de `core`,
2. **erreurs importantes masquées** par des fallbacks silencieux,
3. **duplication et multi-sources de vérité** sur l’auth,
4. **fichiers/classes trop gros** côté bootstrap, stockage, réseau et UI. Ces écarts vont directement contre les règles de séparation des couches, de responsabilité unique, de dépendance aux abstractions, de non-masquage des erreurs et d’évitement des god classes.  

Mon classement P0 → P2 ci-dessous est donc orienté **cause racine**, pas cosmétique. Le snapshot analysé est celui de `lib/src/core` fourni dans `directory_snapshot.md`. 

## 2. Règles de `rules.md` appliquées

J’ai priorisé les corrections en appliquant surtout ces règles :

* **Clean Architecture** : les couches internes ne doivent pas dépendre des détails externes, ni du framework, ni de l’UI, ni de la DB. 
* **SRP / anti-god class** : une classe ou un module ne doit avoir qu’une seule raison de changer ; les gros fichiers et gros modules sont un signal d’alerte. 
* **Dépendances propres** : dépendre d’abstractions, injecter explicitement, éviter le couplage fort et les effets de bord cachés. 
* **Gestion des erreurs** : ne pas masquer les erreurs importantes, différencier erreur métier / technique / utilisateur, logguer utilement sans bruit. 
* **Duplication / complexité / lisibilité / testabilité** : éviter les doubles sources de vérité, découper les traitements longs, garder un code testable et compréhensible vite.  

## 3. Modifications proposées

### P0 — À corriger d’abord

**P0.1 — Casser les dépendances `core -> features` dans la logique applicative du parental**
`core/parental/application/services/child_profile_rating_preload_service.dart` dépend directement de `features/iptv/domain/entities/xtream_playlist_item.dart`, `features/movie/data/datasources/tmdb_movie_remote_data_source.dart` et `features/tv/data/datasources/tmdb_tv_remote_data_source.dart`. C’est un vrai écart d’architecture : un service applicatif de `core` ne devrait pas connaître des datasources concrètes de features. Cela viole directement la règle “les couches internes ne doivent pas dépendre des couches externes”.  

**Correction racine** :
extraire des **ports** côté `core/parental/domain` ou `application`, par exemple :

* `ContentCandidateRepository`
* `MovieMetadataResolver`
* `SeriesMetadataResolver`
* `ContentRatingWarmupGateway`

Puis déplacer les implémentations concrètes vers les features / infra, et injecter ces abstractions dans `ChildProfileRatingPreloadService`. Aujourd’hui, ce service mélange orchestration métier, résolution technique d’IDs, accès TMDB concret et connaissance IPTV concrète. C’est du P0 parce que ça rend `core` instable, difficile à tester et fragile aux changements de features.  

**P0.2 — Arrêter les fallbacks silencieux qui masquent des erreurs d’initialisation**
Dans `AuthModule`, si Supabase est configuré mais que `SupabaseClient` n’est pas enregistré, le code retombe silencieusement sur `StubAuthRepository`. Dans `StorageModule.register()`, si la DB réelle échoue, le module bascule sur une base SQLite en mémoire. Ces deux comportements masquent des erreurs techniques critiques et peuvent produire soit un mode auth faux, soit une perte silencieuse de persistance.   

Ça contredit directement `rules.md` sur la gestion des erreurs importantes. 

**Correction racine** :

* en **prod**, échouer explicitement avec une erreur claire si l’initialisation requise n’est pas disponible ;
* réserver les modes dégradés à un **flag explicite** de dev/test ;
* si un fallback existe, le rendre visible via un état applicatif explicite, jamais silencieux.

Exemple de stratégie :

* `AuthModule` → `throw StateError('Supabase configured but SupabaseClient is missing')`
* `StorageModule` → fallback in-memory uniquement si `allowInMemoryFallback == true`

**P0.3 — Réparer l’incohérence du flux “pin recovery”**
Le contrat métier parle de `resetToken`. La datasource `PinRecoveryRemoteDataSource` expose bien un flux `request / verify / reset` autour d’un `resetToken`. Mais `PinRecoveryRepositoryImpl.resetPin()` convertit `resetToken.trim()` en `profileId`, puis appelle `ProfilePinEdgeService.setPin(profileId: ..., pin: ...)`. On a donc un contrat nommé “token” qui est utilisé comme un identifiant métier, tandis qu’une datasource dédiée au recovery existe en parallèle sans être la source principale du flux.   

C’est un problème de **nommage**, de **contrat** et potentiellement de **sécurité fonctionnelle**. `rules.md` demande qu’une fonction et une classe soient alignées avec leur comportement réel. 

**Correction racine** :
choisir **un seul** flux cohérent :

* soit `PinRecoveryRepositoryImpl` passe **entièrement** par `PinRecoveryRemoteDataSource`,
* soit on renomme le contrat pour ne plus parler de `resetToken` mais de `profileId`, si c’est vraiment le comportement voulu.

En l’état, c’est du P0 parce que le contrat public ment sur la donnée transportée.  

---

### P1 — Important, juste après

**P1.1 — Supprimer la duplication de la source de vérité d’authentification**
Il y a déjà `core/auth/presentation/providers/auth_providers.dart` avec `AuthController` basé sur `AuthRepository`, mais aussi `core/profile/presentation/providers/profile_auth_providers.dart` avec `SupabaseAuthStatusNotifier` qui réécoute directement Supabase. Cela crée deux pipelines d’auth, deux états, deux timings possibles, et un couplage direct du profil à Supabase.  

**Correction racine** :

* garder **une seule** source de vérité : `AuthRepository -> AuthController -> providers dérivés`,
* faire consommer `profile/*` cette source unifiée,
* supprimer le notifier auth spécifique au profil.

C’est un P1 clair au titre de la duplication et de la cohérence. 

**P1.2 — Découper les gros fichiers et gros modules qui deviennent des points de friction**
Plusieurs tailles sont déjà un signal structurel :

* `injector.dart` : ~25 KB,
* `network_executor.dart` : ~32 KB,
* `manage_profile_dialog.dart` : ~32 KB,
* `create_profile_dialog.dart` : ~19 KB,
* `child_profile_rating_preload_service.dart` : ~18 KB,
* `storage_module.dart` : ~11.8 KB.     

Selon `rules.md`, ce sont des signaux typiques de god class / god object ou au minimum de responsabilités trop concentrées. 

**Correction racine** :

* `injector.dart` → un registrar par module (`AuthRegistrar`, `StorageRegistrar`, `ReportingRegistrar`, etc.)
* `network_executor.dart` → séparer cache mémoire, inflight dedup, retry policy, limiter
* dialogs profile → extraire validation, state form, widgets sections, actions métier
* `storage_module.dart` → séparer init DB, fallback policy, repository registration

**P1.3 — Réduire le couplage au service locator dans les services métier et l’UI**
`LocalDataCleanupService` reçoit `GetIt` et résout dynamiquement ses dépendances, ce qui cache les vraies dépendances du service. `ReportProblemSheet` lit directement `SupabaseClient` depuis `slProvider` dans le widget UI.  

**Correction racine** :

* injecter explicitement les abstractions nécessaires au constructeur,
* côté UI, appeler un use case / controller / notifier, pas `SupabaseClient` directement,
* réserver `GetIt` au composition root.

C’est un P1 parce que ça dégrade testabilité, lisibilité et isolation des responsabilités. 

**P1.4 — Unifier la propriété de la configuration réseau/performance**
`NetworkModule` crée un `NetworkExecutor` avec `defaultMaxConcurrent: 12`, alors que `PerformanceTuning.fromProfile()` porte déjà des décisions de tuning (`tmdbMaxConcurrent: 8` ou `3`) et `PerformanceModule` reconfigure ensuite l’exécuteur. Il y a donc plusieurs endroits où la stratégie de concurrence vit.  

**Correction racine** :

* une seule source de vérité : `PerformanceTuning`
* `NetworkModule` doit créer avec des valeurs neutres, puis recevoir une config typed unique
* supprimer les commentaires ad hoc du type “augmenté à 12 pour éviter les blocages”

**P1.5 — Recentrer la logique métier hors des widgets**
`ReportProblemSheet` gère sélection de profil, lecture auth Supabase, erreurs, soumission ; `RestrictedContentSheet` gère validation PIN et messages d’erreur ; les dialogs profile portent beaucoup de logique de validation et d’orchestration.   

**Correction racine** :
déplacer ces comportements dans des `Notifier`/controllers/use cases dédiés, et laisser les widgets ne gérer que l’affichage + binding.

---

### P2 — Important mais non bloquant immédiat

**P2.1 — Corriger les noms qui ne reflètent pas le comportement réel**
`AuthGate` ne “gate” pas vraiment : même en `unauthenticated`, il rend `child`; il sert surtout à attendre la résolution initiale de session. Le nom est trompeur. 

**Correction** : renommer en `AuthBootstrapGate`, `SessionResolutionGate` ou faire un vrai gate.

**P2.2 — Sortir les chaînes UI codées en dur vers la localisation**
Plusieurs widgets portent encore des messages en dur : `RestrictedContentSheet` (`PIN invalide`, `Aucun PIN défini...`), `ReportProblemSheet` (`Aucun profil sélectionné`, `Connexion requise`), `RestartRequiredDialog` avec tout son contenu textuel.   

**Correction** : tout passer dans `AppLocalizations`.

**P2.3 — Corriger la corruption d’encodage dans commentaires et docs**
Le snapshot montre plusieurs commentaires avec mojibake (`sÃ...`, `DÃ...`, `mÃ...`). Ce n’est pas fonctionnellement critique, mais ça dégrade fortement la lisibilité et la crédibilité du code.   

**P2.4 — Remplacer le bruit `debugPrint` par le logger projet**
`StorageModule`, `PerformanceModule` et `appStartupProvider` produisent beaucoup de `debugPrint`, alors qu’un `AppLogger` structuré existe déjà avec niveaux, sampling, rate limiting et sanitation.    

**Correction** :

* logger applicatif partout,
* catégories (`startup`, `storage`, `performance`),
* moins de logs “pas-à-pas”, plus de logs utiles.