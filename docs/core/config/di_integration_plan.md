# Plan d’intégration — `core/config` + DI

## 1. Objectifs
- Injecter `AppConfig`, `EnvironmentFlavor` et `SecretStore` dans GetIt.
- Offrir des providers Riverpod synchronisés avec DI.
- Préparer les modules consommateurs (network, iptv, features).

## 2. Étapes
1. **Bootstrap (`main.dart`)**
   ```dart
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     final loader = EnvironmentLoader();
     final flavor = loader.load();
     final config = await registerConfig(flavor: flavor);
     await initDependencies(appConfig: config);
     runApp(const MoviApp());
   }
   ```
2. **`initDependencies`**
   - Ajoute paramètres optionnels : `AppConfig? appConfig`.
   - Appelle des sous-modules :
     - `_registerLogging()`
     - `_registerConfig(config)`
     - `_registerNetwork()`
     - `_registerServices()`
3. **Module Config**
   - `registerConfig` place `AppConfig`, `EnvironmentFlavor`, `SecretStore`.
   - Exposer `AppConfig` via `appConfigProvider` (Riverpod) + overrides pour tests.
4. **Module Network**
   - Utilise `sl<AppConfig>().network` pour initialiser `HttpClientFactory`.
   - Enregistre `Dio`, `NetworkExecutor`.
5. **Tests**
   - `test_injector.dart` : helper pour `sl.reset()` + `registerConfig(flavor: FakeFlavor())`.
   - `config_overrides.dart` déjà existant → documenter comment l’utiliser dans les tests widget.
6. **Documentation**
   - Mettre à jour `docs/core/config_module_proposal.md` avec le flow bootstrap.
   - Ajouter une checklist “ajout d’un nouveau service” (penser à DI + provider + fake).

## 3. Résultat attendu
- `AppConfig` accessible partout (GetIt + Riverpod).
- Modules (network, iptv) lisent leur configuration sans reparser les `dart-define`.
- Tests/unitaires peuvent surcharger le config via overrides ou `test_injector`.
