Parfait, on va transformer tout ça en **plan de modifs “pour l’équipe”**, sans code, juste ce qu’ils doivent faire et où.

---

## 1. À faire dans Codemagic (pipeline iOS)

**Fichier : `codemagic.yaml`**

1. **Vérifier que la variable `TMDB_API_KEY` n’est jamais vide**

   * Ajouter une étape juste avant le `flutter build ipa` qui :

     * affiche la *longueur* de `TMDB_API_KEY` dans les logs (pas la valeur complète),
     * stoppe le build (exit non-zero) si la variable est vide.
   * Objectif : si la clé n’est pas injectée, on le voit immédiatement dans Codemagic, pas sur l’iPhone avec un écran blanc.

2. **Aligner les `--dart-define` avec le code Flutter**

   * Garder l’argument actuel `--dart-define=TMDB_API_KEY=${TMDB_API_KEY}`.
   * Ajouter aussi les variantes que le code *pourrait* lire, par exemple :

     * `--dart-define=TMDB_API_KEY_DEV=${TMDB_API_KEY}`
     * `--dart-define=TMDB_API_KEY_PROD=${TMDB_API_KEY}`
   * But : peu importe quel nom la config lit aujourd’hui, la valeur sera bien présente dans le binaire iOS.

3. **(Optionnel mais utile) Ajouter une define d’environnement**

   * Par exemple `--dart-define=APP_ENV=prod` (ou dev/staging selon le workflow).
   * Cela permet à la config de savoir dans quel “flavor” elle tourne sans magie.

---

## 2. À faire dans la config applicative (AppConfig / config_module)

**Fichiers concernés** (noms à adapter à ton projet) :
`app_config.dart`, `config_module.dart`, `dev_environment.dart` / `prod_environment.dart`…

1. **Confirmer la source de la TMDB key**

   * Vérifier que la TMDB key est bien lue via `String.fromEnvironment(...)` avec un des noms suivants :

     * `TMDB_API_KEY` (prioritaire)
     * éventuellement `TMDB_API_KEY_DEV` / `TMDB_API_KEY_PROD` en fallback.
   * But : être sûr que ce que Codemagic passe en `--dart-define` correspond à ce que la config lit.

2. **Rendre la validation de config “mode-aware”**

   * Dans la fonction qui valide la config (typiquement `ensureValid` sur `AppConfig` ou équivalent) :

     * Introduire (ou utiliser s’il existe déjà) un paramètre du style `requireTmdbKey`.
     * En mode **prod / release**, ce paramètre doit être à `true` → si la clé est vide, on *continue* de considérer que c’est bloquant.
     * En mode **dev**, ce paramètre doit pouvoir être `false` → dans ce cas, pas d’exception, mais un warning logué.
   * But : en dev, l’appli ne doit pas crasher dès que la clé n’est pas là → on veut une UI d’erreur plutôt qu’un écran blanc.

3. **Documenter le comportement**

   * Ajouter dans un README interne :

     * “Si `TMDB_API_KEY` est vide en release, l’app ne démarre pas (erreur startup).”
     * “En dev, l’app démarre mais affiche un écran d’erreur explicite.”

---

## 3. À faire dans le bootstrap / démarrage Flutter

**Fichiers concernés :** `main.dart`, et un nouveau dossier/fichier `core/startup/…` ou équivalent.

### 3.1. Réorganiser ce qui se passe au démarrage

Aujourd’hui, tout (ou presque) se fait dans `main()` :

* chargement de l’environnement,
* chargement de la config,
* initialisation DI,
* initialisation du logger,
* puis `runApp`.

Ce qu’il faut faire :

1. **Créer un “Startup orchestrator” côté Riverpod**

   * Introduire un `FutureProvider` dédié (par exemple nommé `appStartupProvider`) qui :

     * charge le flavor (EnvironmentLoader),
     * appelle la fonction de config (`registerConfig`),
     * appelle la fonction d’init DI (`initDependencies`),
     * initialise le module de logging une fois la config prête.
   * Tout ce qui était async dans `main()` doit être déplacé dans ce provider.

2. **Créer un widget “porte de démarrage” (AppStartupGate)**

   * C’est un widget Riverpod qui :

     * observe `appStartupProvider`,
     * affiche :

       * un écran de splash/loader tant que le provider est en “loading”,
       * une page d’erreur si le provider est en “error”,
       * l’app réelle (`MoviApp` / `MyApp`) quand le provider est en “data”.
   * Sur l’écran d’erreur :

     * afficher un message utilisateur clair (en prod),
     * en dev, afficher aussi le détail de l’erreur (texte + éventuellement une partie de la stack),
     * proposer un bouton “Réessayer” qui invalide le provider pour relancer la séquence d’init.
   * **Important :** ce widget ne doit *pas* dépendre de la DI (pas de `sl<>`) → si l’init a planté, les services ne sont pas fiables.

3. **Simplifier `main.dart`**

   * Ne garder dans `main.dart` que :

     * l’initialisation Flutter (bindings),
     * les handlers globaux d’erreurs (FlutterError.onError, onError du dispatcher),
     * un `runApp` qui démarre :

       * un `ProviderScope` Riverpod,
       * avec comme enfant l’`AppStartupGate` qui enveloppe ton app principale.
   * Supprimer de `main.dart` :

     * les appels directs à `registerConfig`,
     * les appels directs à `initDependencies`,
     * les appels directs à `LoggingModule.register`,
     * toute la logique de “stages” si tu en avais.

Résultat attendu :

* Dès que l’app se lance, on affiche au minimum un **spinner / écran de chargement propre**, pas un écran blanc.
* Si un problème survient à l’init (TMDB key, DB, etc.), l’utilisateur voit une **page d’erreur contrôlée**, pas un crash silencieux.

---

## 4. À faire pour les logs (diagnostic + iOS)

1. **Pendant la phase de debug : instrumenter les étapes**

   * Dans la séquence d’init (dans le provider d’amorçage, pas dans le UI) :

     * ajouter des logs simples avant/après chaque grosse étape :

       * “avant registerConfig” / “après registerConfig OK”,
       * “avant initDependencies” / “après initDependencies OK”,
       * “avant LoggingModule.register” / “après LoggingModule.register OK”.
   * Ces logs doivent être visibles dans la console iOS (via Xcode) même si `app.log` n’est pas encore créé.
   * Une fois le problème résolu, ces logs “verbeux” peuvent être réduits ou protégés par `!kReleaseMode`.

2. **Clarifier où se trouve `app.log` sur iOS**

   * Documenter dans le README :

     * que le fichier `app.log` de l’app iOS est dans le **sandbox** de l’app (Documents),
     * comment le récupérer :

       * soit via Xcode → “Download Container”,
       * soit via l’app Fichiers si le partage de documents est activé.
   * Préciser que le `app.log` visible dans ton repo local correspond aux runs desktop/dev, **pas** aux logs iOS.

---

## 5. Ordre suggéré de mise en œuvre

Pour l’équipe, je proposerais cet ordre :

1. **Codemagic**

   * Ajouter le check de longueur `TMDB_API_KEY` et les `--dart-define` supplémentaires.
2. **Config**

   * Vérifier la source de la TMDB key dans la config.
   * Introduire la logique `requireTmdbKey` (strict en release, tolérant en dev).
3. **Bootstrap**

   * Créer le provider d’amorçage + le gate de démarrage.
   * Simplifier `main.dart` pour déléguer toute l’init à ce duo.
4. **Logs & Docs**

   * Instrumenter temporairement les différentes étapes d’init pour confirmer où ça bloquait.
   * Documenter :

     * comment builder avec la clé TMDB,
     * comment récupérer `app.log` sur iOS.

Si tu veux, tu peux maintenant me dire : “je vais donner ces instructions à l’équipe, vérifie-les comme si tu étais le lead dev”, et je te fais une version ultra-compacte prête à être collée dans une issue Jira / Notion.
