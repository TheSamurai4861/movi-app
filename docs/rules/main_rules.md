# 1) Principes non négociables

1. **Dépendances vers l’intérieur uniquement**

   * `presentation → application → domain → data`
   * Le **domain ne dépend de rien** (pas de Flutter, pas de Dio, pas de JSON, pas de Firebase…).

2. **Domain = vérité métier**

   * Les règles métier, invariants, validations, et décisions vivent **dans domain**.
   * Aucun “if business” dans l’UI.

3. **Use cases = une intention, un job**

   * Un use case = une action métier (ex: `Login`, `GetUserProfile`, `SearchProducts`).
   * Pas de use case “fourre-tout”.

4. **Data = implémentation, jamais exposée**

   * DTO/Models, API, DB, cache = `data`.
   * Le reste ne voit que des **interfaces de repository** (définies côté domain).

5. **Testabilité avant tout**

   * Tout ce qui est logique doit être testable **sans Flutter** (domain + application).
   * Les couches basses doivent être substituables (mock/fake).



# 2) Structure de projet recommandée (feature-first)

Règle : **feature-first** + **clean layers par feature** (évite le “all repositories in one folder”).

Exemple :

* `lib/core/` (erreurs, utils, DI, network, base classes)
* `lib/features/auth/`

  * `domain/` (entities, value objects, repository interfaces)
  * `application/` (usecases, services, dto mappers “domain-safe” si besoin)
  * `data/` (datasources, api clients, models/dto, repository impl)
  * `presentation/` (pages, widgets, state management, ui models)
* `test/` miroir de `lib/`



# 3) Règles de code par couche

## Domain

1. **Types métier forts**

   * Utiliser des **Value Objects** quand ça apporte de la sécurité (Email, Password, Money…).
2. **Entities immuables**

   * Pas de mutation surprise.
3. **Repository interfaces ici**

   * `abstract class AuthRepository { Future<User> login(...); }`
4. **Erreurs métier explicites**

   * Les erreurs business ne sont pas des exceptions “random”.
   * Préférer un modèle clair : `Result/Failure` (ou `Either`) **dans domain**.

## Application

1. **Use cases orchestrent, ne bricolent pas**

   * Ils composent des repositories/services et renvoient un résultat clair.
2. **Pas de dépendances Flutter**

   * Pas de `BuildContext`, pas de widgets.
3. **Transactions et règles inter-domain**

   * Application gère l’orchestration (ex: “save then sync”).
4. **Pas de DTO réseau ici** (sauf si c’est un “application DTO” stable)

   * Application manipule **domain types**.

## Data

1. **Data sources séparées**

   * `RemoteDataSource` (API), `LocalDataSource` (DB/cache).
2. **Mapping strict DTO ↔ Domain**

   * Le mapping se fait dans data (ou via mapper dédié).
   * Jamais de `fromJson` dans une Entity domain.
3. **Gestion erreurs “techniques”**

   * Convertir les erreurs techniques en `Failure` compréhensible par le domain/application.
4. **Aucune logique métier**

   * Juste : fetch/store/map.

## Presentation

1. **UI = composition + état**

   * L’UI ne fait pas de calcul métier.
2. **State management prévisible**

   * BLoC/Cubit, Riverpod, ou autre — mais avec conventions strictes.
3. **Modèles UI séparés si nécessaire**

   * `ViewModel/UIModel` pour adapter l’affichage sans polluer le domain.
4. **Navigation & messages**

   * Pas de navigation depuis le domain/application (sauf via “events” traités côté UI).



# 4) Conventions de nommage (strictes)

1. **Entities** : `User`, `Invoice`
2. **Value objects** : `EmailAddress`, `Password`
3. **Use cases** : verbes d’action : `Login`, `GetCurrentUser`, `RefreshToken`
4. **Repositories** :

   * Interface domain : `AuthRepository`
   * Impl data : `AuthRepositoryImpl`
5. **Data sources** : `AuthRemoteDataSource`, `AuthLocalDataSource`
6. **DTO/Models** : suffixe clair : `UserDto`, `LoginRequestDto`
7. **Mappers** : `UserMapper` (ex: `toDomain`, `fromDomain`)



# 5) Gestion des erreurs (règles “senior”)

1. **Ne jamais laisser remonter des exceptions brutes à l’UI**
2. **Classifier**

   * Network (timeout, no connection)
   * Server (5xx)
   * Auth (401/403)
   * Validation (input)
   * Unknown
3. **Rendre l’erreur exploitable**

   * Un `Failure` doit porter : type, message affichable (ou clé i18n), cause technique optionnelle.
4. **Logs sans fuite**

   * Ne jamais logger token/mot de passe/PII.



# 6) Asynchronisme & annulation

1. **Toute opération I/O est async**
2. **Pas de side effects cachés**

   * Si un use case déclenche un refresh cache, c’est explicite.
3. **Streams maîtrisés**

   * Un `Stream` doit avoir un owner clair, et être fermé si nécessaire.



# 7) DI (Dependency Injection) et composition

1. **Injection partout**

   * Constructeurs avec dépendances.
2. **Enregistrement par couche**

   * `data` enregistre impl + datasources
   * `domain` n’enregistre rien (interfaces seulement)
3. **Aucun singleton global “magique”**

   * Pas de `ServiceLocator` caché dans tous les fichiers (sauf point unique maîtrisé).



# 8) Règles de performance et Flutter UI

1. **Widgets petits, const, et stables**

   * Maximiser `const`, éviter rebuilds inutiles.
2. **Build = pur**

   * Pas d’appel réseau dans `build`.
3. **Séparer layout et logique d’état**
4. **Listes performantes**

   * `ListView.builder`, pagination, memoization si besoin.



# 9) Qualité, style, et lisibilité

1. **Format + lints obligatoires**

   * `dart format` + règles lint strictes.
2. **Pas de duplication**

   * Extraire helpers/mappers/extensions quand utile, sans sur-abstraction.
3. **Commentaires**

   * On commente le “pourquoi”, pas le “quoi”.
4. **Fichiers courts**

   * Si un fichier dépasse ~300 lignes, on découpe.



# 10) Tests (règles minimales)

1. **Domain**

   * Unit tests sur entities/value objects/use cases critiques.
2. **Application**

   * Tests use cases : success + erreurs + edge cases.
3. **Data**

   * Tests mapping, tests repository avec fake datasources.
4. **Presentation**

   * Tests de state (bloc/cubit/notifier) et widgets clés.



# 11) Checklist “avant de commit”

1. Architecture respectée (dépendances ok)
2. Pas de logique métier dans l’UI
3. Mapping DTO ↔ Domain propre
4. Erreurs normalisées
5. Tests ajoutés/modifiés
6. Lints + format OK
7. Noms explicites, pas de “utils.dart” fourre-tout



# 12) Anti-patterns interdits (liste noire)

* Domain qui importe `flutter`, `dio`, `freezed` (si ça force du codegen dépendant), `json_annotation`, etc.
* Entity avec `fromJson/toJson`
* UI qui appelle directement un datasource
* Repository interface dans `data` seulement
* `try/catch` dans l’UI pour gérer des erreurs réseau
* “God class” `AppService` qui fait tout
* Mutations silencieuses d’état
