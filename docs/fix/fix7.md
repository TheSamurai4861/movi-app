Voici le nouveau fix à déposer dans ton dossier `fix` (par ex. `fix8_ios_tmdb_key_cod emagic.md`).

---

# Fix 8 — iOS “Erreur au démarrage (config ou réseau)” après build Codemagic (clé TMDB absente)

*Date : 2025-11-15*

## 1. Contexte

* Tu es sur **Windows**, donc :

  * Debug local uniquement sur **Windows** (`flutter run -d windows`).
  * Builds iOS faites via **Codemagic** → génération d’un **IPA** → installation sur ton iPhone.
* Sur l’iPhone, au lancement de l’app, tu vois :

  > **“Erreur au démarrage (config ou réseau)”**
  > (écran d’erreur de `AppStartupGate`)
* Tu n’as **pas accès au debug iOS** (pas de Xcode, pas de console iOS).
* Tu soupçonnes que la **clé TMDB n’est plus définie dans Codemagic**, donc pas injectée en `--dart-define`.

L’objectif de ce fix :
👉 **Rétablir un démarrage normal sur iOS** en réinjectant correctement la clé TMDB dans les workflows Codemagic **+** te donner un protocole de validation faisable depuis Windows uniquement.

---

## 2. Diagnostic (probable cause)

### 2.1 Comportement côté code (logique d’amorçage)

Dans ton architecture actuelle :

1. `app_startup_provider` :

   * Charge l’environnement (`APP_ENV=dev|staging|prod`).
   * Calcule un booléen du type `requireTmdbKey` (souvent basé sur `kReleaseMode` et/ou le flavor).
   * Appelle `registerConfig(requireTmdbKey: ...)`.

2. `registerConfig` / `AppConfig.ensureValid()` :

   * Si `requireTmdbKey == true` **et** que `tmdbApiKey` est vide ou absente :

     * Lève une exception (`StateError` ou similaire).
   * Cette exception remonte dans le `FutureProvider` d’amorçage → `AppStartupGate` passe en état `error`.

3. `AppStartupGate` :

   * En **dev** ou en mode diagnostic, tu peux afficher le détail de l’erreur.
   * En **release classique**, tu afficher juste :

     > “Erreur au démarrage (config ou réseau)”
   * C’est exactement ce que tu vois sur ton iPhone.

Donc :
➡️ L’écran d’erreur signifie que **le provider a levé une exception** au démarrage (très probablement `AppConfig` qui refuse une config invalide → TMDB key vide).

### 2.2 Comportement côté Codemagic

* Avant, tu avais une variable sécurisée `TMDB_API_KEY` dans Codemagic, passée dans le `flutter build ipa` via `--dart-define=TMDB_API_KEY=${TMDB_API_KEY}`.
* Tu indiques que **la clé TMDB n’est plus présente dans Codemagic** :

  * Soit la variable d’environnement a été supprimée,
  * Soit elle n’est plus utilisée dans les arguments `--dart-define` du workflow iOS.

Conséquence directe :

* L’IPA générée ne contient **aucune** valeur pour `TMDB_API_KEY`.
* Sur iOS (build release), si `requireTmdbKey == true`, ton `AppConfig` échoue → l’app ne sort jamais de l’écran d’amorçage et affiche ton message d’erreur générique.

📌 **Conclusion**
La cause la plus probable est bien :

> **TMDB key absente dans les `--dart-define` du workflow Codemagic iOS** → config invalide → `AppStartupGate` en erreur sur iPhone.

---

## 3. Plan d’action global

1. **Confirmer le bug sur Windows** (reproduire la même config “sans TMDB”).
2. **Réintroduire correctement la clé TMDB dans Codemagic**.
3. **Forcer les workflows Codemagic iOS à passer la clé en `--dart-define`**.
4. (Optionnel mais conseillé) **Ajouter un mode diagnostic “sans Xcode”** pour les futurs soucis de démarrage.

---

## 4. Étape 1 — Reproduire et confirmer sur Windows

> Objectif : vérifier que **sans TMDB key**, ta build release **prod** plante de la même façon.

1. **Lance l’app en release prod sans clé sur Windows :**

   ```bash
   flutter run -d windows --release --dart-define=APP_ENV=prod
   ```

   * Comportement attendu :

     * L’app affiche **la même UI d’erreur** (“Erreur au démarrage…”),
     * La console Flutter montre une exception du type :

       * `StateError: AppConfig.network.tmdbApiKey is empty...`
       * ou similaire.

2. **Lance l’app en release prod avec une clé inline (juste pour tester) :**

   ```bash
   flutter run -d windows --release \
     --dart-define=APP_ENV=prod \
     --dart-define=TMDB_API_KEY=TA_CLE_TMBD
   ```

   * Comportement attendu :

     * L’app **démarre normalement** (Home, requêtes TMDB OK),
     * Donc tu confirmes que **la seule différence → présence/absence de la clé**.

3. (Optionnel) Teste un release **dev** pour vérifier que dev est plus permissif :

   ```bash
   flutter run -d windows --release --dart-define=APP_ENV=dev
   ```

   * Si `requireTmdbKey` est bien limité à prod, cette commande devrait démarrer même sans clé.
   * Sinon, note que ta logique rend la clé obligatoire aussi en dev release, et adapte le plan Codemagic en conséquence.

---

## 5. Étape 2 — Remettre la clé TMDB dans Codemagic

> But : que **tous les IPA iOS utiles** embarquent systématiquement une clé TMDB valide.

### 5.1 Recréer les variables d’environnement

Dans Codemagic, pour ton workflow iOS (ou globalement) :

1. Ajoute une variable sécurisée :

   * **Name** : `TMDB_API_KEY`
   * **Value** : ta vraie clé TMDB (ex. Bearer v4 ou clé v3, selon ton implémentation).
   * Coche “Secure / Encrypted”.

2. Si ton code supporte plusieurs noms (`TMDB_API_KEY_DEV`, `TMDB_API_KEY_PROD`, etc.), ajoute-les également et donne-leur la **même valeur**:

   * `TMDB_API_KEY_DEV`
   * `TMDB_API_KEY_PROD`

   → Ça évite les “undefined” sur certaines branches de code.

### 5.2 S’assurer que le build iOS DEV passe la clé

Dans le workflow Codemagic qui build ton **IPA pour tester sur ton iPhone** (souvent un `ios-dev-ipa` ou similaire), vérifie / adapte la commande de build Flutter :

* Qu’elle ressemble à ceci (en concept) :

  ```bash
  flutter build ipa --release --no-codesign \
    --target=lib/main.dart \
    --dart-define=APP_ENV=dev \
    --dart-define=TMDB_API_KEY=${TMDB_API_KEY} \
    --dart-define=TMDB_API_KEY_DEV=${TMDB_API_KEY}
  ```

Points importants :

* `--release` → IPA installable / réaliste.
* `APP_ENV=dev` → flavor dev (plus permissif éventuellement).
* `TMDB_API_KEY=${TMDB_API_KEY}` → la clé est injectée dans le binaire.
* Si ton code lit aussi `TMDB_API_KEY_DEV`, penser à le définir aussi.

### 5.3 S’assurer que le build iOS PROD passe la clé

Pour ton workflow “prod” (celui qui servira un jour à soumettre à l’App Store), commande typique :

```bash
flutter build ipa --release --no-codesign \
  --target=lib/main.dart \
  --dart-define=APP_ENV=prod \
  --dart-define=TMDB_API_KEY=${TMDB_API_KEY} \
  --dart-define=TMDB_API_KEY_PROD=${TMDB_API_KEY}
```

Avant la commande de build, il est sain d’ajouter un petit script de vérification :

```bash
if [ -z "$TMDB_API_KEY" ]; then
  echo "❌ TMDB_API_KEY is empty. Aborting build."
  exit 1
fi
echo "✅ TMDB_API_KEY length: ${#TMDB_API_KEY}"
```

👉 Résultat : **plus jamais** de build prod sans clé.

---

## 6. Étape 3 — Rebuilder l’IPA et valider sur iPhone

1. **Lance le workflow DEV iOS** dans Codemagic (celui qui produit l’IPA pour ton iPhone) :

   * Vérifie dans les logs que :

     * `TMDB_API_KEY` est bien détectée et non vide.
     * La commande `flutter build ipa` est appelée avec les bons `--dart-define`.

2. **Télécharge l’IPA** généré (artifact Codemagic) et installe-le sur ton iPhone comme d’habitude.

3. **Ouvre l’app sur l’iPhone** :

   * Comportement attendu :

     * L’écran d’amorçage s’affiche (loader).
     * Puis l’app passe à la Home (plus de “Erreur au démarrage (config ou réseau)”).
     * Les contenus TMDB se chargent normalement.

Si tu as toujours l’erreur après avoir confirmé que la clé est bien injectée :

* Retourne à **l’Étape 1 sur Windows** :

  * Lance un `flutter run -d windows --release --dart-define=APP_ENV=prod --dart-define=TMDB_API_KEY=...`
  * Vérifie si ça plante encore ou non.
* Si Windows passe et iOS ne passe pas : la cause peut être plus réseau/TLS (mais d’abord, il faut éliminer **100%** des problèmes de clé).

---

## 7. (Optionnel) Étape 4 — Mode diagnostic “sans Xcode”

Pour les prochains bugs de démarrage sur iOS :

1. Introduire une constante `FORCE_STARTUP_DETAILS` :

   * Dans `AppStartupGate`, calcule `showDetails` comme par ex. :

     * `showDetails = !kReleaseMode || forceStartupDetails`
       où `forceStartupDetails` est un `bool.fromEnvironment('FORCE_STARTUP_DETAILS', defaultValue: false)`.

2. Lors d’un build “de debug terrain” :

   * Ajoute à ta commande Codemagic :

     ```bash
     --dart-define=FORCE_STARTUP_DETAILS=true
     ```
   * Ainsi, sur l’iPhone, l’écran d’erreur affichera **le message d’exception complet** au lieu d’un texte générique.

3. Tu pourras alors, même sans Xcode :

   * Lire sur l’écran la cause exacte (`AppConfig.network.tmdbApiKey is empty`, par ex.),
   * Faire une capture d’écran et me la partager si besoin.

---

## 8. Résultat attendu

Après ce fix :

* ✅ Les workflows Codemagic iOS **embarqu ent systématiquement une clé TMDB valide** via `--dart-define`.
* ✅ Les builds iOS **dev** que tu installes sur ton téléphone démarrent sans rester bloqués sur l’erreur de config.
* ✅ Les builds prod refuseront de se construire si la TMDB key est absente (fail rapide du pipeline).
* ✅ Tu disposes d’une **procédure claire** pour reproduire/valider sur Windows avant d’envoyer sur Codemagic.
* ✅ Optionnel : tu peux activer un mode diagnostic spécial pour afficher les détails d’erreur directement sur l’iPhone.

---

## 9. Checklist rapide à garder dans le dossier `fix`

* [ ] Sur Windows :

  * [ ] `flutter run -d windows --release --dart-define=APP_ENV=prod` **échoue** sans clé (confirmé).
  * [ ] `flutter run -d windows --release --dart-define=APP_ENV=prod --dart-define=TMDB_API_KEY=...` **passe**.
* [ ] Dans Codemagic :

  * [ ] Variable `TMDB_API_KEY` recréée et remplie.
  * [ ] Commande `flutter build ipa` (dev iOS) passe bien `--dart-define=TMDB_API_KEY=${TMDB_API_KEY}`.
  * [ ] Commande `flutter build ipa` (prod iOS) passe la clé **et** refuse le build si elle est vide.
* [ ] Sur iPhone :

  * [ ] L’IPA dev actuelle démarre jusqu’à la Home.
  * [ ] Plus de “Erreur au démarrage (config ou réseau)” juste après lancement.

---

Si tu veux, au prochain message tu peux coller la partie **Codemagic YAML** de ton workflow iOS (juste la section build), et je te marquerai **en commentaire dans le YAML** où ajouter les `--dart-define` pour TMDB et, éventuellement, `FORCE_STARTUP_DETAILS`.
