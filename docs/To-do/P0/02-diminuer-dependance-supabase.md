# Réduire la dépendance de l'app à Supabase

## Problème actuel

L'app ne peut se lancer correctement que si le serveur Supabase est disponible. En cas de panne ou d'indisponibilité du service, les utilisateurs risquent de perdre l'accès à l'application.

## Objectif

- Identifier les dépendances critiques à Supabase
- Définir un mode de fonctionnement dégradé lorsque Supabase est indisponible
- Permettre à l'app de rester utilisable pour les usages non bloquants
- Implémenter une solution propre, maintenable et cohérente avec l'architecture existante

## Portée

### Inclus

- Audit du lancement de l'app et des points de dépendance à Supabase
- Analyse des données qui doivent rester accessibles hors ligne
- Définition d'un comportement de repli si le backend est indisponible
- Mise en place d'une stratégie pour conserver les fonctionnalités essentielles

### Exclu pour l'instant

- Migration complète hors de Supabase
- Refonte totale de la synchronisation cloud
- Réécriture complète de l'architecture de données

## Cartographie actuelle des dépendances à Supabase

### Lecture rapide

- Blocage P0 au démarrage :
  - `lib/src/core/supabase/supabase_module.dart`
  - `lib/src/core/di/injector.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
- Couplage fort au backend :
  - authentification
  - profils
  - sources IPTV distantes
  - onboarding utilisateur / source
- Couplage moyen, dégradable si on prévoit un fallback :
  - code PIN et récupération PIN
  - signalement de contenu
  - édition / synchronisation des sources IPTV
- Couplage optionnel, déjà partiellement tolérant à l'absence de backend :
  - synchronisation cloud de la bibliothèque
  - synchronisation des préférences utilisateur
  - synchronisation des favoris / historique / playlists
- Zones déjà locales ou local-first :
  - stockage SQLite / secure storage
  - dépôt local IPTV
  - bibliothèque locale
  - réglages utilisateur locaux

### Domaine 1 - Infrastructure et composition racine

- Fichiers principaux :
  - `lib/src/core/supabase/supabase_module.dart`
  - `lib/src/core/di/injector.dart`
  - `lib/src/core/supabase/supabase_providers.dart`
  - `lib/src/core/startup/app_startup_provider.dart`
- Dépendance observée :
  - `SupabaseModule.register()` initialise le SDK et enregistre `SupabaseClient` dans `GetIt`
  - `initDependencies()` appelle systématiquement `SupabaseModule.register()` puis `_registerSupabaseRepositories()`
  - plusieurs services sont ensuite enregistrés uniquement si `SupabaseClient` existe
- Niveau de criticité :
  - critique
- Constats :
  - l'infra DI sait déjà sauter certains enregistrements si Supabase n'est pas configuré
  - mais une partie de l'app continue ensuite à résoudre des dépendances Supabase de manière obligatoire

### Domaine 2 - Authentification et session

- Fichiers principaux :
  - `lib/src/core/auth/auth_module.dart`
  - `lib/src/core/auth/data/repositories/supabase_auth_repository.dart`
  - `lib/src/core/auth/data/repositories/stub_auth_repository.dart`
  - `lib/src/core/auth/presentation/widgets/auth_gate.dart`
  - `lib/src/core/profile/presentation/providers/profile_auth_providers.dart`
- Dépendance observée :
  - l'auth applicative repose sur `SupabaseAuthRepository`
  - `AuthModule` sait déjà basculer sur `StubAuthRepository` si Supabase n'est pas configuré ou si `SupabaseClient` manque
  - plusieurs écrans pilotent leur état avec les changements de session Supabase
- Niveau de criticité :
  - fort, mais partiellement découplé
- Constats :
  - l'auth a déjà un vrai pattern de fallback exploitable
  - la couche UI reste néanmoins pensée autour d'un état de session Supabase

### Domaine 3 - Profils

- Fichiers principaux :
  - `lib/src/core/profile/data/datasources/supabase_profile_datasource.dart`
  - `lib/src/core/profile/data/repositories/supabase_profile_repository.dart`
  - `lib/src/core/profile/presentation/providers/profile_di_providers.dart`
  - `lib/src/core/profile/presentation/controllers/profiles_controller.dart`
- Dépendance observée :
  - le contrat `ProfileRepository` existe, mais l'implémentation branchée est uniquement `SupabaseProfileRepository`
  - `profileRepositoryProvider` lève une erreur si `SupabaseClient` est nul
  - le chargement, le CRUD et la sélection des profils dépendent donc du backend
- Niveau de criticité :
  - critique
- Constats :
  - il n'existe pas encore d'implémentation locale de `ProfileRepository`
  - le domaine profil est aujourd'hui une dépendance structurelle à Supabase

### Domaine 4 - Lancement de l'app et bootstrap

- Fichiers principaux :
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/di/injector.dart`
- Dépendance observée :
  - `AppLaunchOrchestrator.build()` résout directement `SupabaseProfileRepository` et `SupabaseIptvSourcesRepository`
  - le flow de lancement lit les profils distants puis les sources IPTV distantes avant de décider `welcomeUser`, `welcomeSources`, `chooseSource` ou `home`
  - si aucun compte local IPTV n'existe, le bootstrap tente d'hydrater le local depuis Supabase
- Niveau de criticité :
  - critique et bloquant
- Blocages identifiés :
  - pas de chemin alternatif si les repositories Supabase ne sont pas enregistrés
  - la vérité métier du bootstrap pour les profils et les sources est distante
  - la disponibilité locale n'est utilisée qu'après lecture remote, pas comme source primaire de repli

### Domaine 5 - Sources IPTV et credentials

- Fichiers principaux :
  - `lib/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart`
  - `lib/src/features/iptv/data/services/iptv_credentials_edge_service.dart`
  - `lib/src/features/settings/presentation/providers/iptv_connect_providers.dart`
  - `lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart`
  - `lib/src/features/welcome/presentation/pages/welcome_source_page.dart`
  - `lib/src/features/library/application/services/comprehensive_cloud_sync_service.dart`
- Dépendance observée :
  - les métadonnées de sources sont stockées côté Supabase
  - les credentials peuvent être chiffrés / déchiffrés via une Edge Function
  - `IptvConnectController` est explicitement paramétré pour exiger Supabase par défaut afin d'éviter une boucle avec le bootstrap
  - `WelcomeSourcePage` recharge les sources depuis Supabase et peut pré-remplir le mot de passe via l'Edge Function
- Niveau de criticité :
  - critique pour l'onboarding et le bootstrap, forte pour l'édition
- Constats :
  - le dépôt local IPTV existe déjà, mais il n'est pas encore la source de vérité du parcours de lancement
  - il y a déjà de la logique de sync best-effort et du chiffrement edge réutilisable dans une future stratégie hybride

### Domaine 6 - Contrôle parental et PIN

- Fichiers principaux :
  - `lib/src/core/parental/data/services/profile_pin_edge_service.dart`
  - `lib/src/core/parental/data/repositories/pin_recovery_repository_impl.dart`
  - `lib/src/core/parental/data/datasources/pin_recovery_remote_data_source.dart`
- Dépendance observée :
  - la vérification / mise à jour du PIN passe par l'Edge Function `profile-pin`
  - la récupération du PIN utilise l'auth OTP Supabase puis la fonction de mise à jour du PIN
  - `PinRecoveryRemoteDataSource` dépend aussi d'une Edge Function `pin-recovery`
- Niveau de criticité :
  - moyenne
- Constats :
  - ces fonctions ne bloquent pas le lancement de l'app
  - elles nécessitent en revanche un vrai comportement dégradé explicite si le backend est indisponible
  - `PinRecoveryRemoteDataSource` est enregistré dans la DI mais n'est pas au coeur du flux actuellement utilisé

### Domaine 7 - Signalement de contenu

- Fichiers principaux :
  - `lib/src/core/reporting/data/repositories/supabase_content_reports_repository.dart`
  - `lib/src/core/reporting/presentation/widgets/report_problem_sheet.dart`
- Dépendance observée :
  - les signalements sont insérés dans la table Supabase `content_reports`
  - le widget de signalement lit directement `SupabaseClient` pour résoudre l'`accountId`
- Niveau de criticité :
  - moyenne
- Constats :
  - fonctionnalité non bloquante pour l'app
  - le couplage est plus fort que nécessaire car il remonte jusque dans le widget UI

### Domaine 8 - Bibliothèque et synchronisation cloud

- Fichiers principaux :
  - `lib/src/features/library/presentation/providers/library_remote_providers.dart`
  - `lib/src/features/library/application/services/library_cloud_sync_service.dart`
  - `lib/src/features/library/application/services/comprehensive_cloud_sync_service.dart`
  - `lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart`
  - `lib/src/features/library/data/library_data_module.dart`
- Dépendance observée :
  - les repositories distants Supabase existent pour favoris, historique, playlists et playback history
  - `LibraryCloudSyncController` arrête proprement la sync si `supabaseClientProvider` vaut `null`
  - `hybridPlaybackHistoryRepository` reste local-first et ne sync remote que si disponible
  - `ComprehensiveCloudSyncService` pousse aussi les sources IPTV et les préférences utilisateur vers Supabase
- Niveau de criticité :
  - faible à moyenne
- Constats :
  - la bibliothèque locale est déjà exploitable sans Supabase
  - cette zone constitue un bon exemple du niveau de découplage visé pour le reste de l'app

### Domaine 9 - Zones déjà découplées ou déjà prêtes pour un mode dégradé

- Fichiers principaux :
  - `lib/src/features/library/data/library_data_module.dart`
  - `lib/src/features/settings/data/settings_data_module.dart`
  - `lib/src/core/supabase/supabase_providers.dart`
  - `lib/src/core/auth/data/repositories/stub_auth_repository.dart`
- Constats :
  - la bibliothèque principale, les réglages utilisateur et le stockage local ne dépendent pas structurellement de Supabase
  - `supabaseClientProvider` retourne déjà `null` au lieu de casser l'app quand Supabase est absent
  - plusieurs providers cloud savent donc déjà s'éteindre proprement
- Conséquence :
  - la réduction de dépendance ne part pas de zéro
  - la bonne direction est d'étendre les patterns de fallback existants aux domaines profils, bootstrap et sources IPTV

## Dépendances bloquantes au démarrage

### Statut

- Étape terminée
- Dépendances bloquantes identifiées et triées par ordre d'impact sur le boot

### Chaîne de blocage actuelle

- `appStartupProvider`
  - initialise l'environnement et appelle `initDependencies()`
- `initDependencies()`
  - appelle `SupabaseModule.register()`
  - tente d'enregistrer les repositories Supabase requis par le bootstrap
- `AppLaunchOrchestrator.run()`
  - vérifie la session
  - charge les profils depuis Supabase
  - charge les sources IPTV depuis Supabase
  - seulement ensuite consulte / hydrate le local

### Blocage 1 - Initialisation Supabase fail-fast

- Fichiers concernés :
  - `lib/src/core/startup/app_startup_provider.dart`
  - `lib/src/core/di/injector.dart`
  - `lib/src/core/supabase/supabase_module.dart`
- Mécanisme bloquant :
  - `appStartupProvider` appelle `initDependencies()`
  - `initDependencies()` appelle `SupabaseModule.register()`
  - `SupabaseModule.register()` rethrow si la validation de config ou `Supabase.initialize(...)` échoue
- Conséquence :
  - si Supabase est configuré mais inaccessible / invalide, le startup casse avant même d'entrer dans le bootstrap métier
- Niveau :
  - P0 critique

### Blocage 2 - Repositories Supabase requis par le bootstrap

- Fichiers concernés :
  - `lib/src/core/di/injector.dart`
  - `lib/src/core/startup/app_launch_orchestrator.dart`
- Mécanisme bloquant :
  - `_registerSupabaseRepositories()` n'enregistre `SupabaseProfileRepository` et `SupabaseIptvSourcesRepository` que si `SupabaseClient` existe
  - `AppLaunchOrchestrator.build()` résout pourtant ces deux classes de manière obligatoire
- Conséquence :
  - si Supabase n'est pas configuré ou si le client n'est pas disponible, le bootstrap ne sait pas se construire proprement
- Niveau :
  - P0 critique

### Blocage 3 - Profils distants obligatoires avant toute navigation utile

- Fichiers concernés :
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/profile/data/repositories/supabase_profile_repository.dart`
  - `lib/src/core/profile/presentation/providers/profile_di_providers.dart`
- Mécanisme bloquant :
  - après la session, le bootstrap exécute `profiles_fetch`
  - il appelle directement `_profileRepository.getProfiles(accountId: ...)`
  - il n'existe pas d'implémentation locale de `ProfileRepository` pour prendre le relais
- Conséquence :
  - aucune suite de démarrage n'est possible si la lecture des profils Supabase échoue
  - le flow `welcomeUser` n'est atteint que si l'appel remote réussit et retourne une liste vide
- Niveau :
  - P0 critique

### Blocage 4 - Sources IPTV distantes obligatoires avant lecture du local

- Fichiers concernés :
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart`
- Mécanisme bloquant :
  - le bootstrap exécute `sources_fetch` avant `local_accounts_fetch`
  - l'appel remote vers `SupabaseIptvSourcesRepository.getSources(...)` est donc un prérequis au reste du parcours
- Conséquence :
  - même si des données IPTV locales existent ou pourraient suffire, elles ne sont pas consultées tant que la lecture remote n'a pas réussi
  - `welcomeSources` n'est atteint que si la lecture remote réussit et retourne 0 source
- Niveau :
  - P0 critique

### Blocage 5 - Le local IPTV n'est utilisé qu'après validation du remote

- Fichiers concernés :
  - `lib/src/core/startup/app_launch_orchestrator.dart`
  - `lib/src/core/storage/repositories/iptv_local_repository.dart`
- Mécanisme bloquant :
  - `local_accounts_fetch` arrive après `profiles_fetch` et `sources_fetch`
  - si aucun compte local n'existe, l'app tente ensuite `_hydrateLocalAccountsFromSupabase(...)`
- Conséquence :
  - le local n'est pas la source de repli du démarrage
  - le local est aujourd'hui seulement un cache ou une projection dérivée du remote
- Niveau :
  - P0 structurel

### Dépendances Supabase présentes mais non bloquantes pour le boot

- Non bloquantes au démarrage :
  - récupération du PIN
  - Edge Function `profile-pin`
  - signalement de contenu
  - sync cloud bibliothèque
  - sync des préférences utilisateur
- Pourquoi :
  - ces domaines dépendent bien de Supabase, mais ils n'interviennent pas dans la chaîne minimale qui permet d'atteindre `home`, `welcomeUser`, `welcomeSources` ou `chooseSource`

### Synthèse exploitable

- Les dépendances réellement bloquantes au démarrage sont :
  - initialisation Supabase quand la config est active
  - résolution obligatoire des repositories Supabase dans le bootstrap
  - lecture des profils distants
  - lecture des sources IPTV distantes
  - ordre de séquencement qui relègue le local après le remote
- Conclusion :
  - la prochaine étape utile n'est pas de supprimer Supabase partout
  - la prochaine étape utile est de redéfinir le boot pour qu'il puisse partir d'abstractions métier avec fallback local

## Scénarios à couvrir

### Démarrage de l'app sans Supabase

- Comportement actuel :
  - la DI tolère partiellement l'absence de Supabase, mais le bootstrap continue à résoudre des repositories Supabase obligatoires
- Comportement cible :
  - l'app doit démarrer sur ses données locales et signaler simplement que les fonctions cloud sont indisponibles
  - si des profils locaux existent, ils suffisent à entrer dans l'app
  - si au moins une source IPTV locale existe, elle suffit à éviter un blocage sur `welcomeSources`
  - l'absence de session Supabase ne doit pas bloquer l'accès au mode local
- Blocages identifiés :
  - `AppLaunchOrchestrator`
  - `SupabaseProfileRepository` comme unique implémentation profil
  - `SupabaseIptvSourcesRepository` comme vérité métier du parcours source
- Solution envisagée :
  - stratégie `local-first` pour les profils et les sources au boot
  - fallback cloud différé après entrée dans l'app
- Notes :
  - ce scénario est le point de rupture principal actuel
  - Supabase redevient une capacité de synchronisation, pas une condition d'accès au lancement

### Utilisation hors connexion

- Fonctionnalités devant rester accessibles :
  - navigation générale
  - lecture des données déjà en cache / locales
  - sélection et utilisation des profils locaux
  - bibliothèque locale
  - réglages locaux
  - sources IPTV déjà enregistrées localement
  - vérification PIN locale
- Fonctionnalités pouvant être désactivées :
  - authentification distante
  - récupération et reset du PIN
  - signalement
  - sync cloud
  - push des préférences utilisateur
- Source de données locale envisagée :
  - SQLite
  - secure storage / vault
  - préférences locales
  - stockage local dédié pour les profils
- Notes :
  - une grande partie de la base technique locale existe déjà
  - le mode dégradé cible autorise explicitement un accès local sans session cloud active

### Synchronisation différée

- Données concernées :
  - profils
  - sources IPTV
  - favoris
  - historique
  - playlists
  - préférences utilisateur
- Déclenchement de la synchro :
  - au redémarrage
  - au retour réseau
  - via action manuelle dans les settings
- Gestion des conflits :
  - stratégie locale d'abord par défaut
  - push / pull différé par domaine
  - pas de file d'attente généralisée pour cette étape
- Notes :
  - la bibliothèque dispose déjà de premiers patterns de sync non bloquants
  - les actions cloud indisponibles sont désactivées proprement au lieu d'être mises en attente par défaut

### Gestion des erreurs backend

- Types d'erreurs à gérer :
  - Supabase non configuré
  - client non initialisé
  - session absente
  - panne réseau
  - erreur RLS / schéma
  - indisponibilité Edge Function
- UX attendue côté utilisateur :
  - pas de blocage global
  - seules les fonctions cloud indisponibles sont neutralisées
- Messages / fallback à prévoir :
  - "Synchronisation cloud indisponible"
  - "Connexion cloud requise pour cette action"
  - "Fonction momentanément indisponible"
  - "Mode local actif"
- Notes :
  - éviter de propager des erreurs techniques Supabase jusqu'aux widgets
  - privilégier une désactivation ciblée avec message non bloquant

## Options d'architecture à comparer

### Option 1

- Description :
  - stratégie `local-first` avec synchronisation cloud différée
  - les profils et sources locaux permettent le boot
  - les fonctions cloud deviennent optionnelles et se réactivent quand Supabase revient
- Avantages :
  - élimine le blocage principal au démarrage
  - cohérente avec la bibliothèque déjà local-first
  - UX plus robuste en offline ou en cas de panne backend
- Inconvénients :
  - nécessite d'introduire un vrai stockage local pour les profils
  - impose de clarifier les règles de réconciliation local / remote
- Impact technique :
  - moyen à fort, concentré sur bootstrap, profils et sources IPTV
- Décision :
  - retenue

### Option 2

- Description :
  - stratégie `remote-first` avec cache local de secours
  - Supabase reste la source principale de vérité au boot
- Avantages :
  - moins de changements conceptuels sur les domaines existants
  - limite le risque de divergence local / remote
- Inconvénients :
  - ne supprime pas complètement la dépendance psychologique et technique au backend
  - plus fragile au démarrage si le fallback est incomplet
- Impact technique :
  - moyen, mais moins robuste à long terme
- Décision :
  - non retenue

## Tâches et réflexions

- Analyser l'implémentation actuelle de Supabase et du lancement de l'app
- Identifier les dépendances strictement nécessaires au fonctionnement
- Définir ce qui doit continuer à fonctionner sans backend
- Proposer une stratégie de repli réaliste
- Implémenter l'alternative retenue
- Vérifier le comportement via des tests et des runs ciblés

## Checklist d'exécution

- [x] Cartographier tous les points de dépendance à Supabase
- [x] Identifier les dépendances bloquantes au démarrage
- [x] Définir le comportement offline / dégradé cible
- [x] Choisir la stratégie de stockage local ou de fallback
- [x] Implémenter les adaptations nécessaires
- [x] Vérifier que l'app reste lançable sans backend
- [x] Tester la reprise de synchronisation

## Critères de validation

- L'app peut se lancer même si Supabase est indisponible
- Les fonctionnalités essentielles restent accessibles
- Les erreurs backend n'entraînent pas de blocage global
- La stratégie de synchronisation est compréhensible et robuste

## Plan d'implémentation

### Étape 1 - Audit technique

- Statut : terminée

#### Dépendances critiques et bloquantes

- Initialisation fail-fast :
  - `SupabaseModule.register()` casse le startup si Supabase est configuré mais ne s'initialise pas
- Bootstrap et lancement :
  - `AppLaunchOrchestrator` dépend directement de `SupabaseProfileRepository` et `SupabaseIptvSourcesRepository`
- Profils :
  - aucune implémentation locale de `ProfileRepository`
- Sources IPTV :
  - le bootstrap décide encore l'onboarding à partir des sources distantes
  - les comptes locaux sont lus trop tard pour servir de fallback primaire

#### Dépendances fortes mais dégradables

- Authentification :
  - fallback existant via `StubAuthRepository`
- Contrôle parental / PIN :
  - dépend d'OTP Supabase et d'Edge Functions
- Signalement :
  - dépendance directe Supabase dans le repository et dans le widget

#### Dépendances optionnelles déjà presque découplées

- Sync cloud bibliothèque
- Repositories distants favoris / historique / playlists
- Sync des préférences utilisateur
- Playback history hybride local-first

#### Conclusion d'audit

- Le vrai coeur du problème n'est pas "Supabase partout"
- Le vrai blocage est concentré sur 3 zones :
  - composition racine
  - bootstrap
  - domaine profils / sources IPTV
- Plus précisément, le point de rupture suit cette séquence :
  - init Supabase
  - résolution des repositories bootstrap
  - lecture remote des profils
  - lecture remote des sources
  - utilisation du local seulement en aval
- La suite doit donc prioriser un fallback propre pour ces 3 zones avant toute refonte plus large

### Étape 2 - Choix de la stratégie de fallback

- Statut : validée

#### Décisions produit validées

- Profils au démarrage :
  - `local-first`
  - des profils locaux suffisent à entrer dans l'app sans Supabase
- Sources IPTV au démarrage :
  - `local-first`
  - une source locale suffit à éviter un blocage sur `welcomeSources`
- Session cloud en mode dégradé :
  - l'absence de session Supabase ne bloque pas l'accès local
- Contrôle parental offline :
  - vérification PIN locale conservée
  - récupération et reset PIN désactivés sans backend
- Actions cloud indisponibles :
  - désactivation ciblée avec message non bloquant
  - pas de file d'attente généralisée dans cette étape

#### Stratégie de stockage local retenue

- Profils :
  - introduire un stockage local dédié pour permettre le boot sans backend
- Sources IPTV :
  - s'appuyer sur le dépôt local existant comme base de repli au démarrage
- Credentials IPTV :
  - conserver `CredentialsVault` / secure storage comme stockage local sensible
- Réglages utilisateur :
  - conserver le stockage local actuel comme source disponible en permanence
- Bibliothèque :
  - conserver l'approche actuelle local-first déjà en place

#### Règle de fonctionnement cible

- Au boot :
  - on essaie d'abord le local pour accéder à l'app
- Après entrée dans l'app :
  - on tente la synchronisation Supabase si disponible
- Si Supabase est indisponible :
  - l'app reste utilisable en mode local
  - seules les fonctions cloud sont neutralisées proprement

### Étape 3 - Implémentation

- Statut : implémentée

#### Adaptations réalisées

- Stockage local des profils :
  - ajout d'une table SQLite `local_profiles`
  - ajout de la migration de schéma associée
  - alignement du fallback mémoire sur le même schéma
- Domaine profils :
  - ajout de `LocalProfileRepository`
  - ajout de `FallbackProfileRepository`
  - stratégie `local-first` avec lecture locale prioritaire et synchronisation Supabase en best-effort quand disponible
- Injection de dépendances :
  - enregistrement d'un `ProfileRepository` générique au lieu d'imposer directement `SupabaseProfileRepository`
  - maintien des repositories Supabase en option, non comme prérequis structurel du boot
- Bootstrap :
  - `AppLaunchOrchestrator` repose désormais sur `ProfileRepository`
  - absence de session Supabase traitée comme `local mode`, sans redirection forcée vers l'auth
  - lecture des comptes IPTV locaux avant toute tentative remote
  - récupération des sources Supabase uniquement si aucun compte local n'est disponible
  - échec remote IPTV transformé en fallback local, sans casser le lancement
- Flux UI / navigation impactés :
  - `AuthGate` n'empêche plus l'accès aux écrans locaux quand l'utilisateur n'est pas authentifié
  - `LaunchRedirectGuard` laisse le bootstrap décider du parcours en mode local-first
  - `WelcomeUserPage` et `SettingsPage` ne bloquent plus la gestion des profils sur la session cloud
  - `WelcomeSourcePage`, création et édition de source IPTV passent en stratégie Supabase best-effort

#### Résultat attendu après cette étape

- L'app peut s'appuyer sur les profils locaux et les sources IPTV locales pour démarrer
- L'absence de session cloud ne bloque plus l'entrée dans l'app
- Les écritures cloud deviennent secondaires et ne cassent plus le flux local
- Le couplage dur entre bootstrap et repositories Supabase est supprimé pour les profils

### Étape 4 - Tests et validation

- Analyse statique :
  - `flutter analyze` OK après implémentation
- Vérification offline automatisée :
  - ajout d'une suite `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
  - validation du parcours `welcomeUser` sans session ni backend
  - validation du parcours `welcomeSources` avec profil local mais sans source cloud
  - validation du parcours `home` avec profil local et source IPTV locale
- Commande validée :
  - `flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- Vérification automatisée de la reprise de synchronisation :
  - ajout d'une suite `test/features/library/presentation/providers/library_cloud_sync_controller_test.dart`
  - validation qu'aucune auto-sync ne part tant que `supabaseClientProvider` est indisponible
  - validation qu'une auto-sync repart automatiquement quand le client cloud redevient disponible avec un profil déjà sélectionné
  - correction associée dans `LibraryCloudSyncController` :
    la temporisation de 30 secondes n'est plus consommée par un déclenchement auto sans prérequis valides
- Commandes validées :
  - `flutter test test/features/library/presentation/providers/library_cloud_sync_controller_test.dart`
- Reste à valider manuellement :
  - panne réelle backend / réseau sur build applicatif complet
  - reprise de synchronisation sur retour réseau réel sans recréation du client Supabase

## Risques / points d'attention

- Ne pas casser la cohérence entre identifiants locaux et identifiants distants des profils
- Éviter une divergence silencieuse entre sources IPTV locales et sources distantes
- Clarifier la source de vérité par domaine avant d'implémenter un fallback
- Ne pas multiplier les accès directs à `SupabaseClient` dans l'UI
- Garder la sync cloud non bloquante même après découplage

## Questions ouvertes

- Quelle règle de réconciliation appliquer si les profils locaux et distants divergent au retour réseau ?
- Faut-il prévoir dès la première implémentation une détection explicite "mode local actif" dans l'UI globale ?

## Notes complémentaires

- Des patterns de dégradation existent déjà et sont réutilisables :
  - `StubAuthRepository`
  - `supabaseClientProvider`
  - providers remote nullables dans la bibliothèque
  - repository hybride local-first pour l'historique de lecture
- `PinRecoveryRemoteDataSource` est déjà branché en DI, mais le flux actuel repose surtout sur `PinRecoveryRepositoryImpl` + `ProfilePinEdgeService`
- Cette cartographie indique clairement que la prochaine étape utile est de définir le comportement cible sans backend pour les profils, le bootstrap et les sources IPTV
