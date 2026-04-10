# Resume des changements non commites

Date du snapshot: 2026-04-10

Ce document resume l'etat des changements locaux non commités observes dans le depot au moment de l'analyse.

## Snapshot Git

- 28 fichiers suivis modifies
- 16 nouveaux fichiers non suivis
- Diff sur fichiers suivis: 1700 insertions, 526 suppressions
- Ce resume ne couvre que les changements locaux non commités visibles dans le working tree

## Resume fonctionnel

### 1. Ajout d'une couche de profils reseau pour Xtream

Le chantier principal introduit une gestion explicite des routes reseau utilisees pour les sources Xtream:

- ajout d'un modele `RouteProfile` avec profil par defaut et profils proxy
- ajout d'un modele `SourceConnectionPolicy` pour memoriser la route preferee, les routes de secours et le dernier profil fonctionnel
- ajout de repositories locaux pour persister ces profils et politiques
- ajout d'un store dedie aux identifiants proxy
- ajout d'une configuration de proxy explicite pour `Dio` via `DioProxyConfiguration`

Impact principal: l'application ne depend plus uniquement des variables d'environnement pour le proxy. Elle peut choisir un profil reseau par source Xtream.

### 2. Evolution de la base locale et de la couche storage

La base SQLite passe en version 24.

Nouveaux elements persistes:

- table `iptv_route_profiles`
- table `iptv_source_connection_policies`
- index associes pour la resolution par owner et compte
- nouvelles constantes de noms de tables dans la couche storage

Impact principal: les profils reseau et politiques de connexion deviennent persistants et scopes par owner local/utilisateur.

### 3. Ajout d'un service d'execution Xtream avec fallback de route

Un nouveau service `XtreamRouteExecutionService` centralise l'execution reseau Xtream:

- resolution des profils dans l'ordre: profil prefere, dernier profil fonctionnel, fallbacks
- construction d'un client HTTP a partir du profil choisi
- support des proxies avec ou sans credentials
- reessai automatique sur certains types d'erreurs reseau ou de blocage
- memorisation du dernier profil fonctionnel pour un compte
- logs dedies de succes et d'echec par profil

Impact principal: les appels Xtream deviennent plus resilients face aux blocages IP, timeouts, erreurs TLS ou proxies indisponibles.

### 4. Durcissement du data source Xtream

`XtreamRemoteDataSource` est fortement renforce:

- validation plus stricte des reponses d'authentification, categories, streams et series info
- detection des reponses HTML ou texte non JSON
- distinction entre reponse invalide et reponse probablement bloquee
- enrichissement du contexte d'erreur: host, action, status code, content type, type de payload, user agent effectif
- ajout d'un user agent explicite pour les appels Xtream

Nouvelles familles d'erreurs introduites:

- `XtreamInvalidResponseFailure`
- `XtreamBlockedResponseFailure`
- `XtreamRouteExecutionFailure`

Impact principal: les causes d'echec deviennent mieux classees et exploitables pour le diagnostic et le fallback.

### 5. Integration du routage reseau dans les flux metier IPTV

Les flux d'ajout, edition et rafraichissement d'une source Xtream prennent maintenant en compte les profils reseau:

- `AddXtreamSource` et `IptvRepository` acceptent `preferredRouteProfileId` et `fallbackRouteProfileIds`
- `IptvRepositoryImpl` authentifie une source via le service d'execution de route
- la politique de connexion est enregistree a la creation d'une source
- la politique est nettoyee si l'identifiant de compte change lors de l'edition
- le refresh du catalogue et l'authentification d'un compte passent par la nouvelle couche de routage

Impact principal: la selection de route n'est pas seulement un diagnostic UI, elle pilote effectivement l'acces Xtream.

### 6. Nouvelle UI de configuration reseau et de diagnostic Xtream

Deux nouvelles pages apparaissent dans les settings:

- `IptvNetworkProfilesPage`: CRUD des profils reseau/proxy
- `XtreamSourceTestPage`: diagnostic d'une source Xtream

Le test de source execute des etapes de probe:

- DNS
- TCP
- HTTP simple
- authentification
- validation finale

Le diagnostic affiche aussi:

- le profil utilise
- l'IP publique observee
- le detail des tentatives par profil
- la possibilite d'enregistrer le profil fonctionnel pour une source existante

Impact principal: l'utilisateur peut tester plusieurs routes avant validation et sauvegarder la meilleure.

### 7. Integration UI dans les formulaires d'ajout et d'edition IPTV

Les ecrans `iptv_source_add_page.dart` et `iptv_source_edit_page.dart` evoluent pour:

- choisir un profil prefere
- definir des profils de secours
- ouvrir la gestion des profils reseau
- lancer un test Xtream avant validation
- pre-remplir la politique de connexion existante en edition
- afficher le dernier profil fonctionnel connu en edition

Un widget dedie `XtreamRoutePolicyFormSection` mutualise cette partie du formulaire.

### 8. Routes applicatives et providers ajoutes

Ajouts dans le routing:

- `iptvNetworkProfiles`
- `xtreamSourceTest`

Ajouts cote state management:

- providers pour les profils reseau
- provider pour la politique de connexion d'une source
- controller d'edition des profils reseau
- controller de probe Xtream

### 9. Changement de comportement au demarrage et sur la synchro

`AppLaunchOrchestrator` et `XtreamSyncService` sont adaptes au nouveau modele d'erreurs:

- mapping des erreurs IPTV reseau vers des codes de lancement plus precis
- journalisation des succes et echecs avec redaction partielle des identifiants source/compte
- gestion des erreurs de refresh Xtream sans supposer qu'un echec leve toujours une exception brute

Impact principal: le demarrage et la synchro periodique remontent mieux les pannes reseau liees au routage Xtream.

## Nouveaux fichiers detectes

- `lib/src/core/network/proxy/proxy_configuration.dart`
- `lib/src/features/iptv/data/repositories/local_route_profile_repository.dart`
- `lib/src/features/iptv/data/repositories/local_source_connection_policy_repository.dart`
- `lib/src/features/iptv/data/services/public_ip_echo_service.dart`
- `lib/src/features/iptv/data/services/route_profile_credentials_store.dart`
- `lib/src/features/iptv/data/services/xtream_route_execution_service.dart`
- `lib/src/features/iptv/data/services/xtream_source_probe_service_impl.dart`
- `lib/src/features/iptv/domain/entities/source_connection_models.dart`
- `lib/src/features/iptv/domain/entities/source_probe_models.dart`
- `lib/src/features/iptv/domain/repositories/route_profile_repository.dart`
- `lib/src/features/iptv/domain/repositories/source_connection_policy_repository.dart`
- `lib/src/features/iptv/domain/repositories/source_probe_service.dart`
- `lib/src/features/settings/presentation/pages/iptv_network_profiles_page.dart`
- `lib/src/features/settings/presentation/pages/xtream_source_test_page.dart`
- `lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart`
- `lib/src/features/settings/presentation/widgets/xtream_route_policy_form_section.dart`

## Conclusion

Le lot en cours introduit une vraie strategie de routage reseau pour Xtream, avec persistance locale, UI de configuration, diagnostic detaille et fallback automatique. Le coeur du changement est moins cosmetique que structurel: l'application sait maintenant choisir, tester, memoriser et reutiliser une route reseau adaptee par source Xtream.
