## 2. Plan d’implémentation final (par étapes)

### Vue d’ensemble

1. **Créer un provider global de préchargement** (`appPreloadProvider`) dans le bootstrap.
2. **Déplacer `homeController.load()` dans le bootstrap**, via ce provider.
3. **Faire en sorte que `SplashBootstrapPage` attende `appPreloadProvider`** avant de naviguer vers Home.
4. **Supprimer l’appel à `homeController.load()` dans `HomePage.initState`**.
5. **Paralléliser `HomeController.load()`** pour réduire la durée.
6. **Gérer timeout + erreur propre** dans la splash.
7. (Optionnel) **Améliorer cache/skeletons** pour les redémarrages et refreshs.

Je te donne les tâches concrètes, fichier par fichier.

---

## 3. Tâches concrètes par fichier

> Je note les fichiers au format que tu aimes, d’après ce qu’on a déjà vu :
> `60` = router / launch gate, `65` = `AppStartupGate`, `66` = `app_startup_provider`,
> `289/293` = bootstrap (`SplashBootstrapPage` + providers),
> `125` = `home_page.dart`, `126` = providers/controlleur home, etc.
> Tu ajusteras avec tes numéros exacts.

### 3.1. Créer le provider de préchargement global

**Fichier(s) :** `bootstrap_providers.dart` (293) ou équivalent
**Objectif :** avoir un `FutureProvider<bool>` ou `FutureProvider<void>` qui :

* exécute la logique de bootstrap existante (enrich, comptes IPTV, etc.),
* appelle `homeController.load()`,
* se termine en **succès** quand tout ça est OK.

**Actions :**

1. Ajouter un `FutureProvider` du style :

   * nom (exemple) : `appPreloadProvider`.
   * Il doit :

     * lire les providers nécessaires à ton bootstrap (déjà existants : `bootstrapController`, etc.),
     * **n’entrer en ready** que quand :

       * la config DI est prête,
       * les comptes / sources IPTV minimales sont prêtes,
       * `homeController.load()` a **terminé sans erreur**.

2. **Important** : dans ce provider, tu **n’utilises plus de `Future.delayed(3s)` “gratuit”**.

   * À la place : tu attends réellement les promesses (futures) du bootstrap + `homeController.load()`.

3. Tu peux renvoyer `true` ou simplement `void` (l’important est qu’il soit en `data` / `error`).

---

### 3.2. Intégrer `homeController.load()` dans ce provider

**Fichier(s) :** `bootstrap_providers.dart` (293) + `home_providers.dart` (126)

Dans le corps de `appPreloadProvider` :

1. Lire `homeControllerProvider.notifier`.
2. Appeler `await homeController.load()` **une fois** :

   * avant, récupérer son state actuel,
   * si le state a déjà des données (cache) et pas d’erreur → tu peux décider de ne pas recharger, ou de recharger quand même (à toi de voir).
3. En cas d’erreur non critique (ex: TMDB down) :

   * logger,
   * décider si tu considères le preload comme échoué (`AsyncError`) ou “partiel mais acceptable” (retour en `data` avec moins de choses).

---

### 3.3. Faire attendre `SplashBootstrapPage` sur `appPreloadProvider`

**Fichier :** `SplashBootstrapPage` (289)

Aujourd’hui, elle :

* déclenche un enrichissement en LITE/FULL,
* attend un timer d’environ 3 s, puis marque `ready`,
* navigue ensuite vers `/`.

On change cette logique :

1. `SplashBootstrapPage` lit `appPreloadProvider` (nouveau provider).

2. En fonction de son `AsyncValue` :

   * `loading` :

     * afficher le fond sombre + loader + message type “Préparation de l’accueil…”.
   * `data` :

     * lancer la navigation vers `/` (Home) via `GoRouter.of(context).go('/')` **une seule fois**.
   * `error` :

     * afficher une UI d’erreur avec :

       * message simple (“Impossible de préparer la page d’accueil”),
       * un bouton “Réessayer” qui fait un `ref.refresh(appPreloadProvider)`.

3. **Supprimer / réduire le timeout** :

   * plus de passage automatique à `ready` après 3 s,
   * tu peux garder un **timeout global** dans `appPreloadProvider` (ex : 8–10 s) qui échoue explicitement avec une erreur type “timeout TMDB/IPTV” → ça déclenche la branche `error` de la splash.

---

### 3.4. Retirer `homeController.load()` de `HomePage.initState`

**Fichier :** `home_page.dart` (125)

Aujourd’hui :

* `_HomeContentState.initState()` a un `addPostFrameCallback` qui appelle systématiquement `homeController.load()`.

Action :

1. **Supprimer** cet appel de `initState` (ou le remplacer par un simple fallback + refresh, voir optionnel plus bas).
2. Garder uniquement :

   * le code lié au `precacheImageUrl`,
   * la logique de `RefreshIndicator` / pull-to-refresh (si tu en as une).

Pourquoi ?

* Le premier chargement est maintenant **orchestré par la splash**.
* Quand Home s’affiche :

  * soit les données sont déjà prêtes (cas normal),
  * soit la splash a échoué → tu affiches ce que tu as (ou un message/skeleton) et tu laisses à l’utilisateur le choix de **refresh**.

---

### 3.5. Paralléliser `HomeController.load()`

**Fichier :** `home_providers.dart` / `home_controller.dart` (126)

Objectif : réduire le temps réel de `load()`.

Actions :

1. Dans `load()` :

   * si ce n’est pas déjà le cas, lancer les futures **en parallèle** :

     * trending/hero,
     * sections IPTV,
     * continue watching films,
     * continue watching séries.
2. `await` ensuite les 4 futures et mettre à jour `state`.
3. Protéger contre les doublons :

   * si `state.isLoading` est déjà `true`, retourner immédiatement (éviter les double-load lors de refreshs multiples).

Résultat :

* Temps total ≈ **max**(durées des appels), au lieu de la somme.

---

### 3.6. Timeout + gestion d’erreur dans `appPreloadProvider`

**Fichier :** `bootstrap_providers.dart` (293)

Pour ne pas bloquer 30 s sur un backend down :

1. Autour des appels réseaux (Home load + bootstrap enrich), appliquer un `timeout` global (ex: 8–10 s).
2. En cas de timeout :

   * lever une exception contrôlée (ex. `AppPreloadTimeoutException`),
   * `appPreloadProvider` passe en `AsyncError`,
   * `SplashBootstrapPage` affiche la vue d’erreur + “Réessayer”.

Tu peux aussi décider de :

* utiliser le **cache** existant (si `homeController.state` a déjà des données stockées),
* et considérer que c’est “suffisant” pour passer en `data` malgré l’erreur réseau.

---

### 3.7. (Optionnel) Cache & Skeleton côté Home

Même si le but est que Home soit prête, deux choses restent utiles :

**A. Cache-first dans les repos**
*Fichiers :* `HomeFeedRepositoryImpl` (118), `TmdbCacheDataSource` (302)

* Vérifier que :

  * les appels de `HomeController.load()` consultent d’abord le cache local,
  * puis le réseau,
  * et gardent le cache comme fallback.

**B. Skeletons côté UI**
*Fichiers :* `home_hero_section.dart` / `home_hero_carousel.dart` (128–129), `home_page.dart` (125)

* Utiliser `_HeroSkeleton` quand :

  * `state.isLoading == true` ET `hero` vide.
* Utiliser des listes skeletons (cards grises) quand :

  * `state.isLoading == true` ET `iptvLists` vide.

C’est surtout utile pour :

* les **refresh** manuels (pull-to-refresh),
* les cas où tu décides de quand même laisser entrer dans Home après un timeout bootstrap.

---

## 4. Récap très synthétique

**Objectif** : quand Home apparaît, le hero + les listes sont déjà là.

**Implémentation finale :**

1. **293 – `bootstrap_providers.dart`**

   * Créer `appPreloadProvider` :

     * exécute le bootstrap + `homeController.load()` (parallélisé),
     * gère timeout + erreurs.

2. **289 – `SplashBootstrapPage`**

   * Observer `appPreloadProvider` :

     * `loading` → splash + loader,
     * `data` → navigation vers `/`,
     * `error` → erreur + bouton “Réessayer” (`ref.refresh(appPreloadProvider)`).

3. **125 – `home_page.dart`**

   * Supprimer le `homeController.load()` de `initState`.
   * Garder seulement refresh/pull-to-refresh + precache images.

4. **126 – `HomeController` et providers**

   * Rendre `load()` parallèle + idempotent.

5. **118,302,… (optionnel)**

   * Mettre en place un vrai `cache-first` pour accélérer les redémarrages.