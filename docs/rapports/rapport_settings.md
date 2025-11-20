# Rapport d’audit – Feature `settings`

*(à placer dans `docs/rapports/settings_feature_audit.md`)*

---

## 1. Résumé global (vue d’ensemble)

La feature **SETTINGS** est globalement de bon niveau : la séparation **domain / data / presentation** est en place, les value objects sont propres, et les providers Riverpod sont utilisés de manière cohérente. 
On voit une volonté claire de **Clean Architecture** (use cases, repositories, value objects) et un soin apporté à la gestion des erreurs côté stockage (wrapping en `StorageWriteFailure` / `StorageReadFailure`).
Cependant, la **page `SettingsPage`** concentre trop de responsabilités (UI + logique de formatage + orchestration IPTV + préférences), ce qui la rapproche d’un **“god widget”** difficile à tester et à faire évoluer. 
Autre point important : il existe un **domaine “Settings” théorique** (`SettingsRepository`, `UserPreferences`, `UserProfile`) qui n’est **pas réellement utilisé** par la page de settings actuelle, laquelle parle directement aux préférences du core (`LocalePreferences`, `PlayerPreferences`, `AccentColorPreferences`, `IptvSyncPreferences`). 
En résumé : base saine et assez pro, mais **architecture incomplètement appliquée** sur cette feature, avec quelques refactors structurants à prévoir pour aligner la UI sur le domaine, améliorer la testabilité et réduire la complexité de la page de settings.

---

## 2. Architecture & organisation

### 2.1 Rôle du dossier

La feature `settings` gère :

* Le **profil utilisateur léger** (prénom + code langue) et son stockage local.
* Les **préférences d’application** (thème, langue, IPTV sync, couleur d’accent, préférences de lecture).
* L’**écran de connexion IPTV** et sa logique de connexion + synchronisation.
* La **page principale des paramètres** (langue, IPTV, accent color, préférences player, etc.).

### 2.2 Structure du dossier

* `settings.dart`
  → Fichier “barrel” qui exporte les entités / repositories / use cases côté domaine. 

* `data/`

  * `user_settings_local_data_source.dart`
    → Lit/écrit un `UserProfile` dans un `ContentCacheRepository` (type `settings`, key `user_profile`). 
  * `user_settings_repository_impl.dart`
    → Implémentation de `UserSettingsRepository` enrobant les erreurs dans des `StorageReadFailure` / `StorageWriteFailure`. 
  * `settings_data_module.dart`
    → Module d’enregistrement DI (`sl`) pour `UserSettingsLocalDataSource` et `UserSettingsRepository`. 

* `domain/entities`

  * `user_preferences.dart`
    → Entité immuable avec enums `ThemePreference`, `LanguagePreference`, `NotificationFrequency` + `autoplayNext`. 
  * `user_profile.dart`
    → Entité légère `{ FirstName, LanguageCode }`. 

* `domain/repositories`

  * `settings_repository.dart`
    → Abstraction “complète” des réglages (`UserPreferences` + `UserProfile`). 
  * `user_settings_repository.dart`
    → Abstraction dédiée au stockage du `UserProfile` utilisateur (profil léger). 

* `domain/usecases`
  → Use cases ultra-fins, essentiellement des wrappers autour des repositories : `GetUserPreferences`, `UpdateUserPreferences`, `GetUserProfile`, `UpdateUserProfile`, `LoadUserProfile`, `SaveUserProfile`. 

* `domain/value_objects`

  * `first_name.dart`
    → VO avec `tryParse`, validation longueur / non-vide. 
  * `language_code.dart`
    → VO avec normalisation en lower-case, validation de longueur. 
  * `metadata_preference.dart`
    → VO avec liste d’options autorisées (`tmdb`, `none`). 

* `presentation/pages`

  * `iptv_connect_page.dart`
    → Formulaire de connexion IPTV (URL, username, password) + appel à `IptvConnectController`. 
  * `settings_page.dart`
    → Page de paramètres principale. Grosse classe, gère : sélection langue app, fréquence sync IPTV, couleur d’accent, langues audio/sous-titres du player, refresh IPTV, section comptes, etc. 

* `presentation/providers`

  * `iptv_connect_providers.dart`
    → Provider Riverpod `IptvConnectController` (Notifier), DI des use cases `AddXtreamSource`, `RefreshXtreamCatalog`, intégration `AppEventBus`. 
  * `user_settings_providers.dart`
    → `UserSettingsController` (Notifier + `UserSettingsState`) pour charger/sauvegarder le `UserProfile` via `UserSettingsRepository`. Fournit `currentUserIdProvider`. 

### 2.3 Respect de la séparation Domain / Data / Presentation

Points positifs :

* **Domain** bien isolé : pas de dépendance à Flutter, seulement des entités / VO / repos abstraits / use cases. ✔
* **Data** parle au core (`ContentCacheRepository`, `Storage*Failure`) et implémente les interfaces domain. ✔
* **Presentation** utilise Riverpod Notifier, injecte ses dépendances via providers + `slProvider`. ✔

Points à corriger :

* `SettingsPage` ne passe **jamais par `SettingsRepository` ou `UserPreferences`**. Elle parle directement à des services de préférences du core (`LocalePreferences`, `PlayerPreferences`, `AccentColorPreferences`, `IptvSyncPreferences`), ce qui contourne le domaine. 
* Le `UserSettingsController` est bien aligné avec `UserSettingsRepository`, mais n’est **pas branché à la UI de `SettingsPage`** (profil visuel avec “Matt / Manu / Ber” est purement maquetté, pas issu du domaine). 

### 2.4 Couplage & dépendances

* Couplage fort de `SettingsPage` au **core** :

  * `slProvider`, `AccentColorPreferences`, `LocalePreferences`, `IptvSyncPreferences`, `PlayerPreferences`, `XtreamSyncService`, `AppEventBus`, `homeControllerProvider`, etc. 
* `IptvConnectController` reste correct, mais lui aussi dépend du `slProvider` (via providers) et du `AppStateController`, `AppEventBus`. 
* La logique IPTV de refresh (`_refreshIptv`) dans `SettingsPage` orchestre directement repository IPTV, AppState, home refresh et événements, ce qui en fait un point de couplage important. 

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1 Problèmes **CRITIQUES**

#### 1) Domaine “Settings” défini mais contourné par la UI

* **Fichier / élément**

  * `settings_page.dart` (UI) vs. `domain/repositories/settings_repository.dart`, `user_preferences.dart`. 
* **Problème**
  La page de settings n’utilise pas `SettingsRepository` / `UserPreferences`. Elle lit/écrit directement dans des services de préférences du core (`LocalePreferences`, `PlayerPreferences`, etc.). Le domaine “Settings” existe mais n’est pas la source de vérité.
* **Pourquoi c’est un problème**

  * Rupture de la **Clean Architecture** : la présentation dépend de détails d’implémentation du core au lieu de passer par un domaine abstrait.
  * Risque de **duplication de logique** (si demain un autre écran doit gérer les prefs, il ne saura pas où se brancher).
  * Rend difficile l’évolution (changement de backend, synchronisation cloud, profils multiples, etc.).
* **Suggestion de correction**

  * Implémenter un **`SettingsRepositoryImpl`** qui s’appuie sur les préférences concrètes (`LocalePreferences`, `PlayerPreferences`, `AccentColorPreferences`, `IptvSyncPreferences`) mais expose un modèle **agrégé** `UserPreferences` côté domaine.
  * Adapter `SettingsPage` pour qu’elle ne parle qu’à des **use cases** (`GetUserPreferences`, `UpdateUserPreferences`, `GetUserProfile`, `UpdateUserProfile`) et plus directement aux services de préférences.

---

#### 2) `SettingsPage` = “God widget” (trop de responsabilités)

* **Fichier / élément**

  * `_SettingsPageState` et sa méthode `build`, + nombreuses méthodes privées dans `settings_page.dart`. 
* **Problème**

  * Le State contient :

    * La logique d’affichage pour 4 sections différentes (comptes, IPTV, app, playback).
    * La logique de **mapping** de codes de langue vers labels (`_getLanguageLabel`, `_isCurrentLanguage`).
    * La logique métier “métier app” autour de l’IPTV (`_refreshIptv`, orchestrations de refresh Home, émission d’événements).
    * Le mapping des options de sync (durée ↔ label), de couleurs d’accent, de langues audio/sous-titres, etc.
* **Pourquoi c’est un problème**

  * Complexité cognitive élevée : difficile de lire/raisonner rapidement sur l’écran.
  * Très difficile à **tester unitairement** (tout est dans un State de widget).
  * Évolutions futures risquent de casser des comportements sans qu’on s’en rende compte (zone d’effet énorme).
* **Suggestion de correction**

  * Extraire :

    * Les 4 grandes sections dans des **widgets dédiés** (ex : `SettingsAccountsSection`, `SettingsIptvSection`, `SettingsAppSection`, `SettingsPlaybackSection`).
    * La logique de mapping/langages, sync, couleurs dans des **services ou helpers purs** (ex : `SettingsFormatter`, `LanguageOptionMapper`).
  * Garder `_SettingsPageState` comme **orchestrateur léger** : lecture d’état via Riverpod, appels à des use cases/formatters, et construction de widgets de section.

---

### 3.2 Problèmes **IMPORTANTS**

#### 3) `SettingsRepository` / `UserSettingsRepository` et use cases partiellement “cosmétiques”

* **Fichiers / éléments**

  * `settings_repository.dart`, `user_settings_repository.dart`, use cases `GetUserPreferences`, `UpdateUserPreferences`, `GetUserProfile`, `UpdateUserProfile`, `LoadUserProfile`, `SaveUserProfile`. 
* **Problème**

  * Les use cases sont des **pass-through** (`call() => repo.method()`), sans logique métier ajoutée.
  * `SettingsRepository` n’est pas (ou très peu) utilisé dans la présentation, alors que `UserSettingsRepository` l’est via `UserSettingsController`.
* **Pourquoi c’est un problème**

  * Ça suggère une **architecture prévue mais non terminée** : on a une couche de plus (use cases) pour rien.
  * Multiplie les points d’entrée possibles pour modifier les settings, sans un flux clair.
* **Suggestion de correction**

  * Soit : enrichir réellement les use cases avec des règles métiers (validation, normalisation, side-effects).
  * Soit : simplifier et utiliser directement les repositories depuis les controllers (en assumant un style “Application Service = Controller”).
  * Clarifier l’intention : **qui est la “façade officielle”** pour gérer des réglages depuis la UI ?

---

#### 4) Logique métier IPTV embarquée dans `SettingsPage`

* **Fichier / élément**

  * Méthode `_refreshIptv` dans `settings_page.dart`. 
* **Problème**

  * La méthode :

    * Va chercher les comptes IPTV (`IptvLocalRepository`).
    * Met à jour l’`AppStateController` (active sources).
    * Appelle `RefreshXtreamCatalog` pour chaque source.
    * FORÇE un `refresh()` de la Home.
    * Émet un `AppEvent(AppEventType.iptvSynced)` via `AppEventBus`.
    * Gère le feedback UX (SnackBars, compteurs ok/ko).
* **Pourquoi c’est un problème**

  * Mélange complet de **logique métier** (orchestration des sources IPTV) et de **logique UI** (SnackBars, spinners) dans un widget.
  * Fort couplage avec plusieurs couches (core state, feature home, event bus, IPTV core), ce qui rend ce stateful widget très sensible à tout changement de ces couches.
* **Suggestion de correction**

  * Extraire un **use case applicatif** (ex. `RefreshAllIptvSources`) dans la feature IPTV ou une couche “application”.
  * Le State de `SettingsPage` n’appelle plus que ce use case, reçoit un résultat (counts ok/ko, message, éventuellement erreurs) et se contente d’afficher l’UI.
  * Tester ce use case indépendamment de la UI.

---

#### 5) Testabilité limitée des helpers de formatage (langue, synchro, player)

* **Fichier / élément**

  * `_getLanguageLabel`, `_isCurrentLanguage`, `_formatSyncInterval`, `_formatPlayerLanguage`, `_isCurrentPlayerLanguage`, `_getAccentColorName`, `_isCurrentAccentColor` dans `settings_page.dart`. 
* **Problème**
  Ces fonctions implémentent des règles précises (normalisation de codes langues, formattage d’intervalles, matching de couleurs) mais sont privées au State et “enfermées” dans la UI.
* **Pourquoi c’est un problème**

  * Difficile de les **tester unitairement** sans tester tout le widget.
  * Si demain la logique de mapping des langues ou de formatage des durées change, il n’y a aucune garantie par tests unitaires.
* **Suggestion de correction**

  * Déplacer ces fonctions dans un **helper pur** (ex. `SettingsFormatters`, `LanguageLabelMapper`) ou des **value objects** plus riches.
  * Écrire des tests unitaires ciblés sur ces helpers (ex : vérifier que `fr-BE` → `Français`, que `Duration(days: 365)` = “Désactivé”, etc.).

---

#### 6) Gestion des erreurs côté stockage peu expressive

* **Fichiers / éléments**

  * `UserSettingsRepositoryImpl.save` / `.load`. 
* **Problème**

  * Toute exception est mappée en `StorageWriteFailure` / `StorageReadFailure` sans logging ni conservation de la cause.
* **Pourquoi c’est un problème**

  * En prod, difficile de comprendre la cause réelle d’un échec (format cassé, corruption, I/O, clé manquante…).
  * Peut compliquer les analyses de bugs.
* **Suggestion de correction**

  * Logguer la cause (via `AppLogger` ou équivalent) avant de lancer la failure.
  * Selon la stratégie globale de l’app, envisager de retourner un **Result/Either** plutôt que de lancer des exceptions (alignement avec les autres features).

---

### 3.3 Problèmes **Nice to have**

#### 7) Maquettage “profils Matt / Manu / Ber” non relié au domaine

* **Fichier / élément**

  * `_buildProfileCircle` + usage dans `SettingsPage` (noms “Matt”, “Manu”, “Ber”, “Ajouter”). 
* **Problème**

  * UI de profils multi-utilisateurs purement statique, sans lien avec `UserProfile` / `UserSettingsController`.
* **Pourquoi c’est un problème**

  * Risque de confusion dans le code : ça ressemble à une vraie feature, mais ce n’est qu’un mock.
* **Suggestion de correction**

  * Soit : isoler clairement cette section comme **“mock UI”** (commentaires, TODO).
  * Soit : la brancher réellement sur le domaine (liste de profils, sélection active, etc.), via `UserSettingsController`.

---

#### 8) Magic values pour la désactivation de la sync IPTV

* **Fichier / élément**

  * `_syncIntervalOptions`, `_showSyncIntervalSelector`, `_isCurrentSyncInterval` dans `SettingsPage`. 
* **Problème**

  * La désactivation est modélisée par une `Duration(days: 365)` (“fake disabled”), alors que l’option UI “Désactivé” est un `null`.
* **Pourquoi c’est un problème**

  * “Magic number” difficile à comprendre et à maintenir.
  * Si la logique évolue, tu peux facilement casser la correspondance UI ↔ stockage.
* **Suggestion de correction**

  * Modéliser l’état “désactivé” soit par un **bool + Duration**, soit par `Duration?` (null = désactivé), et faire porter la conversion “technique” (vers ce que veut `IptvSyncPreferences`) dans un adapter dédié.

---

#### 9) Quelques petits points de style / const / i18n

* **Fichiers / éléments**

  * `IptvConnectPage`, `SettingsPage`. 
* **Problème**

  * Quelques `OutlineInputBorder()` / `SizedBox()` / `TextStyle` pourraient être `const`.
  * Certains textes sont hardcodés en français (“Désactivé”, “Toutes les 2 heures”, “Défaut du lecteur”) plutôt qu’issus de `AppLocalizations`.
* **Pourquoi c’est un problème**

  * Micro-perf et lisibilité (plus de `const` = moins de rebuilds inutiles).
  * i18n incomplète (difficile de supporter proprement d’autres langues UI).
* **Suggestion de correction**

  * Passer ce qui peut l’être en `const`.
  * Exposer les labels d’intervalle, de langues, etc. via `AppLocalizations` ou via une couche translation-friendly.

---

## 4. Plan de refactorisation par étapes

### Étape 1 – Brancher réellement la UI sur le domaine “Settings”

* Implémenter un **`SettingsRepositoryImpl`** qui :

  * Lit/écrit les préférences dans `LocalePreferences`, `PlayerPreferences`, `AccentColorPreferences`, `IptvSyncPreferences`.
  * Mappe ces données vers un `UserPreferences` cohérent (thème, langue, notifications, autoplay, etc.).
* Adapter `GetUserPreferences` / `UpdateUserPreferences` pour utiliser cette implémentation.
* Introduire un **`SettingsController` (Notifier)** dans `presentation/providers` qui :

  * Lit les prefs via `GetUserPreferences`.
  * Expose un state simple (current language, accent color, sync interval, audio/subtitle prefs…).
* Adapter `SettingsPage` pour qu’elle **ne parle plus directement aux services core**, mais seulement au `SettingsController` + use cases.

### Étape 2 – Découper `SettingsPage` en sous-widgets / sous-sections

* Extraire au moins :

  * `SettingsAccountsSection` (profils).
  * `SettingsIptvSection` (sources, sync, refresh).
  * `SettingsAppSection` (langue, accent color).
  * `SettingsPlaybackSection` (audio/subtitles).
* Garder `_SettingsPageState` comme orchestrateur :

  * Récupère les états via Riverpod (`SettingsController`, `AppStateProvider`, etc.).
  * Passe les callbacks et valeurs aux sous-widgets.

### Étape 3 – Extraire la logique IPTV de refresh dans un use case/app service

* Créer un use case (par ex. `RefreshActiveIptvSources`) dans la feature IPTV ou dans une couche “Application” :

  * Récupère les sources actives ou les init si vide.
  * Rafraîchit les catalogues (en parallèle éventuellement).
  * Actualise l’`AppState`, déclenche `homeController.refresh()`, émet `AppEvent.iptvSynced`.
  * Retourne un résultat `Result<RefreshSummary>` (avec `okCount`, `errorCount`, `firstErrorMessage`…).
* Adapter `_refreshIptv` pour appeler seulement ce use case et traduire le résultat en SnackBars.

### Étape 4 – Sortir les helpers de formatage dans des classes pures

* Créer par exemple :

  * `LanguageOptions` (constants + mapping code → label, comparaisons de codes).
  * `SyncIntervalFormatter` (conversion `Duration` ↔ label, gestion du “désactivé”).
  * `PlayerLanguageFormatter` (audio/subtitle).
  * `AccentColorOptions` (liste + naming, matching).
* Déplacer `_getLanguageLabel`, `_isCurrentLanguage`, `_formatSyncInterval`, `_formatPlayerLanguage`, `_isCurrentPlayerLanguage`, `_getAccentColorName`, `_isCurrentAccentColor` vers ces helpers.
* Ajouter quelques tests unitaires ciblés.

### Étape 5 – Clarifier et durcir la gestion des profils utilisateur

* Décider si la multi-profil est une vraie feature :

  * Si oui : modéliser des profils dans le domaine (liste de `UserProfile` + profil actif), et relier `SettingsAccountsSection` à `UserSettingsController`.
  * Si non : commenter clairement que c’est un **mock UI** à implémenter plus tard, pour éviter la confusion.

### Étape 6 – Améliorer la gestion des erreurs & le logging

* Dans `UserSettingsRepositoryImpl` :

  * Logguer les erreurs avec `AppLogger` avant de lancer `StorageReadFailure` / `StorageWriteFailure`.
* Dans `UserSettingsController` :

  * Harmoniser les messages d’erreur (`Impossible de charger le profil`, `Échec de la sauvegarde`) via les localisations (si besoin).
* Optionnel : aligner les patterns d’erreurs sur le reste du projet (`Result`, `Either`, etc.).

### Étape 7 – Polishing style, const, i18n

* Passer ce qui est simple en `const` dans les pages settings/iptv_connect.
* Extraire les labels “Désactivé”, “Toutes les 2 heures”, “Défaut du lecteur”, etc. dans les localisations.
* Ajouter quelques doc comments sur les classes principales (controllers, repositories, use cases).

---

## 5. Bonnes pratiques à adopter pour la suite

1. **Toute nouvelle option de réglage** doit passer par le **domaine Settings** (repos + use cases), pas par des services singleton dans la UI.
2. **Logique métier = hors des widgets** : garder les `StatefulWidget`/UI pour l’affichage + wiring, et mettre orchestration/formatage dans des services ou controllers testables.
3. Utiliser des **Notifiers/Controllers comme façade d’application** pour chaque feature (ici `SettingsController`, `UserSettingsController`, `IptvConnectController`).
4. Garder les **value objects riches** pour encapsuler les règles (validation, normalisation) plutôt que des `String` brutes.
5. Minimiser le **couplage au service locator** dans la présentation : préférer des providers Riverpod qui encapsulent l’accès à `sl`.
6. Éviter les **magic numbers** (ex. `Duration(days: 365)` pour désactiver) : modéliser clairement l’intention (bools, types dédiés).
7. Viser des **widgets de taille raisonnable** : dès qu’un écran dépasse ~300–400 lignes + beaucoup de responsabilités, prévoir une extraction en sous-widgets.
8. **Toujours prévoir la testabilité** : toute logique non pure (I/O, DI) devrait être derrière une abstraction, toute logique pure dans des helpers testés.
9. Harmoniser la **gestion des erreurs** (storage, network, domaine) avec un pattern unique (exceptions ou Result/Either), et toujours logguer la cause.
10. Continuer à utiliser des **barrels (`settings.dart`)** pour faciliter les imports, mais en veillant à ne pas importer toute la feature là où un simple use case spécifique suffit.

Si tu veux, on peut maintenant enchaîner sur un **plan concret de fichiers à créer/modifier** (avec exemples de signatures) pour l’étape 1 (brancher réellement la UI sur `SettingsRepository` + `UserPreferences`).
