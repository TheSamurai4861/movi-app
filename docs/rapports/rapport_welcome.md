````markdown
# Rapport d’audit – Feature **WELCOME** (`lib/src/features/welcome`)

## 1. Résumé global (vue d’ensemble)

La feature **Welcome** joue un rôle d’**onboarding / démarrage** : connexion IPTV initiale, préparation du home, configuration utilisateur (nom + langue), et écrans d’accueil. L’architecture est globalement propre et cohérente : tout est regroupé dans `presentation/` (pages, providers, widgets, utils) et s’appuie sur les autres features (settings, iptv, home) pour la logique métier. L’usage de Riverpod (Notifier/NotifierProvider, FutureProvider) est maîtrisé, avec un bon découplage réseau via DI (`slProvider`) et `Dio`. :contentReference[oaicite:0]{index=0}  

Les principaux points faibles :  
- un **contrôleur de bootstrap** qui écoute l’event bus sans jamais détacher son listener (risque de fuite ou de comportements inattendus à long terme) ;  
- quelques **incohérences de state** (`WelcomeUiState.copyWith`) qui peuvent effacer des champs de manière implicite ;  
- du **code partiellement inutilisé** (test de connexion dans `WelcomeController`, `error_presenter`) ;  
- des **chaînes FR en dur** dans une feature censée être localisée, et des chemins de routes GoRouter écrits en dur. :contentReference[oaicite:1]{index=1}  

Avec quelques refactors ciblés (cleanup de l’event bus, copyWith, navigation centralisée, intégration ou suppression de la logique non utilisée), la feature peut clairement monter d’un cran vers du niveau “pro”.

---

## 2. Architecture & organisation

### 2.1. Rôle global du dossier

La feature `welcome` gère principalement :

- La **préparation de l’application** (preload du home, activation des sources IPTV, gestion d’un “splash bootstrap”). :contentReference[oaicite:2]{index=2}  
- Le **premier ajout de source IPTV** via un formulaire Xtream (url + username + password).  
- La **configuration utilisateur** minimaliste (nom + langue préférée).  
- Quelques widgets d’UI réutilisables (header, labeled field, FAQ row).

C’est donc une feature très orientée **flux utilisateur / orchestration**, la logique métier locale étant volontairement minimale (tout passe par les repositories/settings d’autres features).

### 2.2. Fichiers & responsabilités

- `welcome.dart`  
  Barrel qui exporte les widgets principaux (`WelcomeHeader`, `WelcomeForm`, `LabeledField`, `WelcomeFaqRow`). :contentReference[oaicite:3]{index=3}  

- `presentation/pages/`
  - `splash_bootstrap_page.dart` : page de splash qui attend la fin de `appPreloadProvider` puis navigue vers `home`. Gestion état : loading / erreur (avec retry) / navigation.  
  - `welcome_page.dart` : page principale d’accueil “source IPTV”, qui orchestre `WelcomeForm` et la connexion via `iptvConnectControllerProvider` (settings).  
  - `welcome_source_page.dart` : écran simple “choisir une source” avec bouton qui redirige vers `/settings/iptv/connect`.  
  - `welcome_user_page.dart` : page de configuration utilisateur (nom + langue), avec sélection de langue via `CupertinoActionSheet` + sauvegarde du profil via `userSettingsControllerProvider`. :contentReference[oaicite:4]{index=4}  

- `presentation/providers/`
  - `bootstrap_providers.dart` :  
    - `BootstrapState` + `BootstrapController` (Notifier) pour suivre les phases de démarrage (refresh IPTV, enrichissement, ready).  
    - `appPreloadProvider` (FutureProvider) qui effectue le bootstrap réel (startup app, activation de sources IPTV, pré-chargement du home).  
  - `welcome_providers.dart` :  
    - `WelcomeUiState` (UI-only : isTesting, isObscured, errorMessage, endpointPreview).  
    - `WelcomeController` (Notifier) pour la logique de formulaire (toggle mot de passe, prévisualisation d’URL, test de connexion IPTV via `NetworkExecutor`).  
    - `welcomeDioProvider` & `welcomeControllerProvider` pour injecter `Dio` depuis le conteneur DI. :contentReference[oaicite:5]{index=5}  

- `presentation/utils/`
  - `error_presenter.dart` : mapping `NetworkFailure` → message FR court pour l’UI. Actuellement non utilisé par `WelcomeForm`. :contentReference[oaicite:6]{index=6}  

- `presentation/widgets/`
  - `labeled_field.dart` : composant label + champ, simple et réutilisable.  
  - `welcome_faq_row.dart` : ligne “Des questions ?” + lien FAQ localisé.  
  - `welcome_form.dart` : formulaire Xtream IPTV complet, piloté soit en interne (connect + nav directe) soit par le parent via callback `onConnect`.  
  - `welcome_header.dart` : header graphique avec logo SVG et titres (avec accent color dynamique). :contentReference[oaicite:7]{index=7}  

### 2.3. Points forts d’architecture

- Architecture **orientée présentation** bien isolée : aucun domain/data propre à la feature, on fait appel aux services/repositories d’autres features via providers/DI.  
- Très bon usage de **Riverpod** : Notifier/NotifierProvider, FutureProvider, ConsumerWidget/ConsumerStatefulWidget.  
- Formulaire `WelcomeForm` **réutilisable** : logiquement indépendant, avec un contrat clair (`ConnectCallback` et `isLoading`) qui permet à l’appelant de gérer nav + feedback. :contentReference[oaicite:8]{index=8}  
- Préload du home (`appPreloadProvider`) robuste : timeout, fallback “partial data ok”, logs structurés via `LoggingService`.  

### 2.4. Points architecturaux à améliorer

- `BootstrapController` écoute l’event bus sans **gestion explicite de la subscription** (pas de `cancel()` sur le stream). À terme, risque de fuite ou de callbacks alors que le contrôleur est censé être détruit. :contentReference[oaicite:9]{index=9}  
- `WelcomeUiState.copyWith` écrase toujours `errorMessage` / `endpointPreview` par défaut, ce qui n’est pas cohérent avec le commentaire (“passer explicitement null pour effacer”).  
- Plusieurs **routes GoRouter sont codées en dur** dans la feature (`'/'`, `'/bootstrap'`, `'/settings/iptv/connect'`), ce qui couple fort l’onboarding au détail du router global (et casse facilement si les paths changent).  
- Quelques fonctions/utilitaires ne sont pas branchés à l’UI (`testConnection` du `WelcomeController`, `presentFailure` dans `error_presenter.dart`).  

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1. Problèmes **critiques**

---

#### C1 – Écoute de l’event bus sans désabonnement dans `BootstrapController`

- **Fichier / élément**  
  `presentation/providers/bootstrap_providers.dart` – `BootstrapController.start()`  

- **Problème**  
  Le contrôleur appelle :

  ```dart
  final bus = _ref.read(appEventBusProvider);
  bus.stream.listen((event) {
    if (event.type == AppEventType.iptvSynced &&
        state.phase == BootPhase.refreshing) {
      _kickoffEnrich();
    }
  });
````

mais ne conserve jamais la `StreamSubscription` ni ne l’annule dans `onDispose`. 

* **Pourquoi c’est un problème**

  * Risque de **memory leak** : le listener reste attaché même si le provider est disposé.
  * Possibilité de **callbacks fantômes** vers un contrôleur plus censé être actif (selon comment Riverpod gère sa durée de vie).
  * À mesure que l’on multiplie ce genre de patterns, la logique d’orchestration devient difficile à raisonner.

* **Suggestion de correction**

  * Stocker la subscription dans un champ et l’annuler dans `_registerDispose()` :

    ```dart
    class BootstrapController extends Notifier<BootstrapState> {
      StreamSubscription<AppEvent>? _busSub;

      @override
      BootstrapState build() {
        _registerDispose();
        return const BootstrapState();
      }

      void start() {
        if (_started) return;
        _started = true;

        final bus = _ref.read(appEventBusProvider);
        _busSub = bus.stream.listen((event) {
          if (event.type == AppEventType.iptvSynced &&
              state.phase == BootPhase.refreshing) {
            _kickoffEnrich();
          }
        });

        // ...
      }

      void _registerDispose() {
        ref.onDispose(() {
          _timeout?.cancel();
          _timeout = null;
          _busSub?.cancel();
          _busSub = null;
        });
      }
    }
    ```

---

### 3.2. Problèmes **importants**

---

#### I1 – `WelcomeUiState.copyWith` efface par défaut `errorMessage` et `endpointPreview`

* **Fichier / élément**
  `presentation/providers/welcome_providers.dart` – `WelcomeUiState.copyWith`

* **Problème**

  ```dart
  WelcomeUiState copyWith({
    bool? isTesting,
    bool? isObscured,
    String? errorMessage, // passer explicitement null pour effacer
    String? endpointPreview,
  }) {
    return WelcomeUiState(
      isTesting: isTesting ?? this.isTesting,
      isObscured: isObscured ?? this.isObscured,
      errorMessage: errorMessage,
      endpointPreview: endpointPreview,
    );
  }
  ```

  Si on appelle `copyWith(isTesting: true)`, alors `errorMessage` et `endpointPreview` deviennent `null` (car paramètres par défaut `null`) au lieu de conserver l’ancienne valeur. C’est **contraire au commentaire** et dangereux pour l’évolution du state. 

* **Impact**

  * Toutes les transitions d’état qui ne mentionnent pas explicitement `errorMessage`/`endpointPreview` les effacent silencieusement.
  * Exemple : `toggleObscure()` vide `errorMessage` et `endpointPreview` juste en changant la visibilité du mot de passe.

* **Suggestion de correction**
  Implémenter un pattern plus classique, tout en conservant la possibilité de “forcer null” avec un wrapper si besoin :

  ```dart
  WelcomeUiState copyWith({
    bool? isTesting,
    bool? isObscured,
    bool clearErrorMessage = false,
    String? errorMessage,
    bool clearEndpointPreview = false,
    String? endpointPreview,
  }) {
    return WelcomeUiState(
      isTesting: isTesting ?? this.isTesting,
      isObscured: isObscured ?? this.isObscured,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      endpointPreview: clearEndpointPreview
          ? null
          : (endpointPreview ?? this.endpointPreview),
    );
  }
  ```

  Et adapter les appels (par ex. `clearError()` → `copyWith(clearErrorMessage: true)`).

---

#### I2 – Code de test de connexion & error presenter non utilisés

* **Fichiers / éléments**

  * `WelcomeController.testConnection()` dans `welcome_providers.dart`
  * `presentFailure(NetworkFailure f)` dans `error_presenter.dart` 

* **Problème**

  * `WelcomeForm` ne fait jamais appel à `WelcomeController.testConnection()` ; toute la connexion passe par `iptvConnectControllerProvider.connect()`.
  * `presentFailure` n’est utilisé nulle part ; `WelcomeForm` reconstruit son propre message d’erreur à partir de `ui.errorMessage` + AppLocalizations.

* **Impact**

  * Code “mort” ou semi-mort qui **alourdit la surface mentale** de la feature.
  * Risque de divergence si un jour tu branches ce test mais que la logique d’erreur diverge du reste de l’app.

* **Suggestions**

  * Soit **brancher** le test de connexion sur un bouton “Tester la connexion” dans `WelcomeForm`, en utilisant `presentFailure` pour formater les erreurs de `NetworkFailure`.
  * Soit **supprimer** ce code pour alléger la feature, et laisser toute la logique réseau à `iptvConnectControllerProvider`.

---

#### I3 – Chaînes FR en dur (non localisées)

* **Fichiers / éléments**

  * `BootstrapState.message` (messages FR codés en dur dans l’état).
  * `WelcomeHeader` (titres par défaut “Bienvenue !”, “Ajouter votre première source”).
  * `WelcomeFaqRow` (“Des questions ?”). 

* **Problème**
  Ces chaînes contournent `AppLocalizations` alors que l’app est manifestement localisée. Sur `WelcomePage`, tu utilises `const WelcomeHeader()` sans surcharger le titre/subtitle, donc les valeurs FR en dur seront affichées même si la langue choisie est EN/ES/etc.

* **Impact**

  * Expérience d’onboarding partiellement localisée.
  * Risque de régression lors d’un ajout de langue (string “perdu” dans le code).

* **Suggestions**

  * Utiliser systématiquement `AppLocalizations` pour les textes affichés à l’utilisateur. Par exemple dans `WelcomePage` :

    ```dart
    WelcomeHeader(
      title: AppLocalizations.of(context)!.welcomeTitle,
      subtitle: AppLocalizations.of(context)!.welcomeSubtitle,
    );
    ```

  * Pour `BootstrapState`, soit exposer un `BootPhase` et laisser l’UI choisir le message localisé, soit passer la clé de localisation plutôt que le texte final.

---

#### I4 – Routes codées en dur dans la feature

* **Fichiers / éléments**

  * `WelcomePage` : `context.go('/bootstrap');`
  * `WelcomeForm` : `context.go('/');`
  * `WelcomeSourcePage` / `WelcomeUserPage` : `GoRouter.of(context).go('/settings/iptv/connect');` 

* **Problème**
  La feature Welcome dépend directement des chemins GoRouter sous forme de string literals, au lieu de passer par des route names / helpers centralisés (tu as déjà un `AppRouteNames.home` utilisé ailleurs).

* **Impact**

  * **Fragilité** : changement de path ⇒ erreurs runtime seulement (pas de compile-time error).
  * Couplage fort avec la config router globale.

* **Suggestion**

  * Exposer des helpers de navigation dans `core/router/router.dart` (ex. `AppRoutes.bootstrap`, `AppRoutes.home`, `AppRoutes.iptvConnect`) et les utiliser partout.
  * Ou utiliser `GoRouter.of(context).goNamed(AppRouteNames.bootstrap)` si tu as configuré des noms de routes.

---

### 3.3. Problèmes **nice to have**

---

#### N1 – Détails de style / const

* **Observation**
  Plusieurs widgets (`WelcomePage`, `WelcomeUserPage`, `WelcomeForm`) pourraient utiliser plus de `const` sur des `SizedBox`, `Padding`, `Text` statiques, etc. 

* **Impact**
  Pas dramatique, mais quelques rebuilds inutiles et une légèreté perdue côté optimisations compilateur.

* **Suggestion**
  Passer les widgets statiques en `const` dès que possible, surtout dans les colonnes / listes.

---

#### N2 – Factorisation possible des helpers langue dans `WelcomeUserPage`

* **Observation**
  `_getLanguageLabel` et `_isCurrentLanguage` contiennent une logique de normalisation de codes langue (fr-*, en-*, etc.) et un cas spécial `fr-MM`. 

* **Suggestion**

  * Extraire ces helpers dans un petit util (par ex. `language_utils.dart`) ou un value object dédié si tu envisages d’utiliser ce pattern ailleurs (settings, i18n).
  * Ça clarifie le rôle de la page (UI) et isole mieux la logique de mapping de codes.

---

#### N3 – `BootstrapController` non consommé par `SplashBootstrapPage`

* **Observation**
  La page `SplashBootstrapPage` ne lit que `appPreloadProvider`; le `BootstrapController` (phase `refreshing/enriching/ready`) n’est pas utilisé pour adapter l’UI. 

* **Suggestion**

  * Soit brancher `BootstrapController` pour afficher un message/état plus fin si tu veux un “vrai” bootstrap en plusieurs étapes.
  * Soit supprimer/mettre en pause ce contrôleur pour éviter la complexité inutile.

---

## 4. Plan de refactorisation par étapes

### Étape 1 – Sécuriser l’orchestration de bootstrap

1. Modifier `BootstrapController` pour **conserver la `StreamSubscription`** de l’event bus et l’annuler dans `ref.onDispose`.
2. Vérifier que `BootstrapController.start()` n’est appelé qu’une fois par cycle (c’est déjà le cas avec `_started`, garder ce pattern). 

### Étape 2 – Corriger `WelcomeUiState.copyWith` et aligner l’usage des erreurs

1. Revoir l’implémentation de `copyWith` pour qu’elle respecte vraiment “passer null pour effacer” et “ne rien passer pour conserver”.
2. Adapter les appels (`toggleObscure`, `testConnection`, `clearError`) pour utiliser les nouveaux paramètres.
3. Optionnel mais recommandé : brancher `error_presenter.presentFailure` si tu gardes la logique `NetworkFailure`. 

### Étape 3 – Nettoyer/impliquer le code non utilisé

1. Décider si tu veux une action “Tester la connexion” :

   * **si oui**, ajouter un bouton dans `WelcomeForm` qui appelle `WelcomeController.testConnection()`, affiche le résultat via `WelcomeUiState.errorMessage`.
   * **sinon**, supprimer la méthode `testConnection` et l’état `isTesting` pour simplifier le contrôleur.
2. Supprimer ou brancher `error_presenter.dart` en conséquence.

### Étape 4 – Localisation complète & navigation centralisée

1. Localiser tous les textes encore en dur dans la feature (messages `BootstrapState`, `WelcomeHeader` par défaut, “Des questions ?”).
2. Remplacer tous les `context.go('/…')` par des appels via des **noms de routes** ou des helpers centralisés pour réduire le couplage aux paths. 

### Étape 5 – Polishing / ergonomie & testabilité

1. Ajouter des `const` sur les widgets statiques des pages welcome.
2. Ajouter quelques **tests unitaires**/widget pour :

   * `WelcomeController` (toggleObscure, updateUrlPreview, `copyWith` correct, etc.).
   * `appPreloadProvider` (cas normal, partial data, timeout).
3. Envisager un petit test widget sur `SplashBootstrapPage` pour vérifier le comportement selon `AsyncValue` (loading/error/success + navigation).

---

## 5. Bonnes pratiques à adopter pour la suite

1. **Toujours gérer la durée de vie des listeners** (streams, event bus, timers) dans les Notifiers/StatefulWidgets via `ref.onDispose` / `dispose`.
2. **Centraliser les routes** (noms/paths) au niveau du router et ne jamais coder de chemins en dur dans les features.
3. Pour les `State` immuables (comme `WelcomeUiState`), adopter un `copyWith` clair :

   * ne rien passer ⇒ conserver,
   * passer explicitement une valeur (y compris null) ⇒ écraser.
4. **Localiser systématiquement** tous les textes UI via `AppLocalizations` pour éviter les “îlots FR” quand tu ajoutes des langues.
5. Limiter la logique d’orchestration aux **controllers/providers**, garder les pages/Widgets aussi “dumb” que possible (lecture d’état + déclenchement d’actions).
6. Éviter le code “mort” non branché : soit l’utiliser (avec un petit bouton, une option), soit le supprimer pour garder une base de code nette.
7. Ajouter des **tests ciblés** pour les parties qui coordonnent plusieurs layers (bootstrap, connexion IPTV) afin de sécuriser les refactors futurs.

Avec ces ajustements, ta feature `welcome` sera non seulement propre sur le plan architectural, mais aussi plus robuste et plus facile à faire évoluer (nouveaux flux d’onboarding, nouvelles sources, nouvelles langues, etc.).

```
::contentReference[oaicite:21]{index=21}
```
