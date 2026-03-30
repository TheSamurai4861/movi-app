# Startup réel — Movi
## A1 — Cartographie vérifiée du démarrage

## 1. Objet du document

Ce document décrit le démarrage réel de Movi à partir du snapshot du projet.

L’objectif est de :
- reconstituer la chaîne de démarrage ;
- distinguer les responsabilités réellement différentes ;
- identifier les nœuds où le lancement devient complexe ;
- préparer un futur refactor du startup sans hypothèses fragiles.

Ce document ne cherche pas encore à proposer la nouvelle architecture cible.
Il documente d’abord l’existant.

---

## 2. Résumé vérifié

Le démarrage de Movi est actuellement composé de **quatre couches distinctes** :

### 1. Boot technique
Il démarre dans `main.dart`, où l’application prépare l’environnement d’exécution Flutter et installe le point d’entrée de startup. :contentReference[oaicite:7]{index=7}

### 2. Gate de startup
`AppStartupGate` suspend le rendu de l’application principale tant que `appStartupProvider` n’a pas terminé. Elle gère aussi l’écran d’erreur et le retry. :contentReference[oaicite:8]{index=8}

### 3. Boot applicatif transverse
Le startup provider ne fait pas qu’une initialisation minimale : il semble aussi porter une partie de la DI, du logging, de la compatibilité legacy et de services de fond. La présence de `app_startup_provider.dart` et le reste du système de startup le confirment. :contentReference[oaicite:9]{index=9}

### 4. Lancement métier / navigation d’entrée
Une fois l’application rendue, la logique d’entrée continue via :
- `AppLaunchOrchestrator`
- `LaunchRedirectGuard`
- les routes `launch`, `welcome/*`, `bootstrap`, puis certaines routes IPTV dans `settings`. :contentReference[oaicite:10]{index=10} :contentReference[oaicite:11]{index=11}

Conclusion :
le “startup” actuel ne correspond pas à une seule chose, mais à un **ensemble de mécanismes superposés**.

---

## 3. Fichiers centraux du démarrage

### Point d’entrée et app principale
- `lib/main.dart`
- `lib/src/app.dart` :contentReference[oaicite:12]{index=12}

### Startup transverse
- `lib/src/core/startup/app_startup_provider.dart`
- `lib/src/core/startup/app_startup_gate.dart`
- `lib/src/core/startup/app_launch_criteria.dart`
- `lib/src/core/startup/app_launch_orchestrator.dart` :contentReference[oaicite:13]{index=13}

### Routing de lancement
- `lib/src/core/router/launch_redirect_guard.dart`
- `lib/src/core/router/app_route_paths.dart`
- `lib/src/core/router/app_route_names.dart`
- `lib/src/core/router/app_routes.dart` :contentReference[oaicite:14]{index=14}

### Welcome / bootstrap UI
- `splash_bootstrap_page.dart`
- `welcome_user_page.dart`
- `welcome_source_page.dart`
- `welcome_source_select_page.dart`
- `welcome_source_loading_page.dart`
- `bootstrap_providers.dart` :contentReference[oaicite:15]{index=15}

---

## 4. Séquence fonctionnelle du démarrage

## Étape 1 — Entrée dans `main()`

Le projet montre que `main.dart` fait partie du point d’entrée réel, avant toute logique de startup UI. Le snapshot confirme l’existence de `lib/main.dart` et le fait que l’application monte ensuite `AppStartupGate(child: const MyApp())`. :contentReference[oaicite:16]{index=16} :contentReference[oaicite:17]{index=17}

### Ce qu’on peut affirmer
- le boot commence hors du dossier `core/startup` ;
- le runtime Flutter est préparé avant l’évaluation du provider de startup ;
- `AppStartupGate` est déjà au cœur du point d’entrée.

### Ce qu’il ne faut pas sur-affirmer sans refactor plus fin
Le snapshot suggère plusieurs initialisations techniques avant le rendu, mais pour un plan d’architecture il vaut mieux retenir surtout leur rôle global plutôt que figer dès maintenant une liste définitive “à déplacer”.

---

## Étape 2 — Blocage global via `AppStartupGate`

Le code de `AppStartupGate` montre explicitement :
- un état loading ;
- un état erreur ;
- un état succès ;
- un retry par invalidation de `appStartupProvider` ;
- et seulement ensuite le rendu du vrai `child`. :contentReference[oaicite:18]{index=18}

### Interprétation solide
Le startup provider est donc un **pré-requis global de rendu**.

### Conséquence
Tant que ce provider n’a pas réussi, l’application principale n’existe pas encore du point de vue UI.

---

## Étape 3 — Startup provider comme nœud transverse

Le projet contient bien `app_startup_provider.dart`, mais la vérification du snapshot montre surtout que cette brique existe au sein d’un système plus large de startup. :contentReference[oaicite:19]{index=19}

À partir des autres indices relevés dans le snapshot et du rôle qu’on lui voit jouer dans le flux, on peut considérer avec un bon niveau de confiance qu’il sert de point central pour :
- l’initialisation transverse ;
- la mise en cohérence avec l’état global ;
- une partie de la compatibilité DI ;
- et des services de fond liés au runtime applicatif. :contentReference[oaicite:20]{index=20} :contentReference[oaicite:21]{index=21}

### Point de vigilance
C’est ici qu’il faut rester précis :
on peut affirmer que le startup provider est central,
mais il faudra une lecture dédiée de son corps complet pour figer ligne par ligne ce qui est strictement critique, applicatif ou différable.

---

## Étape 4 — Rendu de `MyApp` puis branchement de comportements globaux

Le snapshot montre qu’après le startup, `app.dart` branche `LibraryCloudSyncBootstrapper` haut dans l’arbre. :contentReference[oaicite:22]{index=22}

### Interprétation solide
Le lancement ne s’arrête donc pas à “startup réussi = app prête”.
Une partie du comportement applicatif global est encore ajoutée au moment du rendu de l’application principale.

### Conséquence
Le périmètre réel du démarrage doit inclure :
- le startup gate ;
- le provider de startup ;
- les bootstrapper globaux injectés dans `app.dart`.

---

## Étape 5 — Navigation d’entrée et redirections de lancement

Le snapshot des routes montre explicitement :
- les imports liés à `LaunchRedirectGuard` ;
- les pages `welcome/*` ;
- la route `launch` ;
- la route `bootstrap` ;
- et les routes `settings/iptv/*`. :contentReference[oaicite:23]{index=23}

### Interprétation solide
Le démarrage réel de l’utilisateur passe par une **state machine de navigation d’entrée**,
pas seulement par un chargement technique.

### Ce que cela implique
Le startup est en réalité réparti entre :
- un préchargement applicatif ;
- un contrôle du rendu ;
- un mécanisme de redirection/routage ;
- et des écrans de bootstrap/welcome.

---

## Étape 6 — Orchestration métier de lancement

Le simple fait que le projet contienne séparément :
- `app_launch_criteria.dart`
- `app_launch_orchestrator.dart`
- `launch_redirect_guard.dart` :contentReference[oaicite:24]{index=24}

montre que la logique d’entrée a déjà été modélisée comme un sous-système dédié.

### Interprétation solide
Le projet ne possède pas seulement un startup technique :
il possède aussi un **lancement métier orchestré**.

### Ce qu’on peut affirmer sans surinterpréter
- l’entrée produit est structurée ;
- elle dépend de critères de lancement ;
- elle n’est pas entièrement absorbée par le routeur ;
- elle n’est pas non plus entièrement contenue dans le provider de startup.

---

## 5. Ce que le démarrage englobe réellement aujourd’hui

La lecture la plus juste du snapshot est la suivante :

### A. Boot technique
Ce qui prépare Flutter et le runtime initial.

### B. Gate de startup
Ce qui bloque ou autorise le rendu global.

### C. Boot applicatif transverse
Ce qui prépare certains services et la cohérence globale de l’application.

### D. Lancement métier / navigation
Ce qui décide vers quel parcours l’utilisateur doit aller :
- auth
- bootstrap
- welcome
- puis shell/home/settings IPTV selon les cas. :contentReference[oaicite:25]{index=25}

---

## 6. Problèmes structurels confirmés

## 6.1 Le mot “startup” recouvre plusieurs systèmes
Ce n’est pas un seul mécanisme, mais au moins :
- une gate UI ;
- un provider global ;
- une logique de lancement ;
- un ensemble de routes d’entrée.

---

## 6.2 La frontière entre boot technique et boot applicatif est floue
Le projet commence dans `main.dart`, passe par un startup gate, puis continue à injecter des comportements transverses dans `app.dart`. :contentReference[oaicite:26]{index=26}

### Effet
Il est difficile de savoir exactement où “finit” le démarrage.

---

## 6.3 Le lancement métier est réparti
Le snapshot confirme la présence conjointe de :
- `AppStartupGate`
- `app_startup_provider`
- `AppLaunchOrchestrator`
- `LaunchRedirectGuard`
- routes `launch`, `bootstrap`, `welcome/*` :contentReference[oaicite:27]{index=27} :contentReference[oaicite:28]{index=28}

### Effet
Pour expliquer pourquoi l’utilisateur arrive à un endroit donné, il faut suivre plusieurs mécanismes.

---

## 6.4 La migration DI traverse déjà le démarrage
Le snapshot montre que GetIt reste structurant dans plusieurs modules, avec `sl<AppStateController>()` encore injecté dans des services métier. :contentReference[oaicite:29]{index=29} :contentReference[oaicite:30]{index=30}

### Effet
Le démarrage est déjà influencé par un enjeu d’architecture transverse, pas seulement par du boot.

---

## 6.5 Des services globaux sont accrochés au niveau applicatif
`LibraryCloudSyncBootstrapper` est injecté très haut, dans `app.dart`. :contentReference[oaicite:31]{index=31}

### Effet
Le “startup réel” déborde du seul sous-système `core/startup`.

---

## 7. Ce qu’il faut retenir pour le refactor

Après vérification, la conclusion la plus robuste est :

### Le futur refactor devra séparer explicitement 4 choses
1. ce qui est nécessaire pour démarrer Flutter proprement ;
2. ce qui est nécessaire pour autoriser le rendu de l’application ;
3. ce qui relève du lancement métier utilisateur ;
4. ce qui est un comportement global branché trop tôt ou trop haut.

### Ce qu’il ne faut pas faire trop tôt
- déplacer des fichiers au hasard ;
- fusionner `startup`, `launch guard` et `orchestrator` sans cartographie DI ;
- décider trop tôt que tel service est “différable” sans revue plus fine du code concerné.

---

## 8. Conclusion

La vérification confirme bien le diagnostic de départ :

Movi ne possède pas un “startup trop gros”.
Movi possède **plusieurs sous-systèmes de démarrage superposés**, dont les frontières sont encore trop peu explicites.

Le résultat le plus important de cette étape A1 est donc :

**le démarrage doit désormais être traité comme une architecture à part entière, pas comme un simple détail d’initialisation.**