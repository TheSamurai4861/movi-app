# Plan de correction : PerformanceModule et StorageModule

## Problèmes identifiés

### 1. PerformanceModule - Timeout et fallback incomplet (Moyen)

**Symptôme** : `await PerformanceModule.register(sl)` peut bloquer ou ne pas appliquer la configuration par défaut**Analyse du code actuel** :

- Timeout de 5s déjà implémenté sur `readCapabilities()`
- Bloc catch qui enregistre `PerformanceTuning` par défaut
- **Problème** : Le fallback n'applique PAS les configurations au `NetworkExecutor` (lignes 46-54 dans le bloc try)
- Si `readCapabilities()` timeout ou échoue, `NetworkExecutor` n'est jamais configuré avec les valeurs par défaut

**Impact** :

- Blocage au démarrage si la lecture des capacités échoue (5s de timeout)
- `NetworkExecutor` non configuré si timeout → utilise des valeurs non optimisées
- Logs incomplets en cas d'échec

**Solution** :

- Améliorer le bloc catch pour appliquer la configuration par défaut au `NetworkExecutor`
- Extraire la logique de configuration dans une fonction séparée pour réutilisation
- S'assurer que le module ne fait jamais échouer le startup

### 2. StorageModule - Pas de gestion d'erreurs (Faible mais critique)

**Symptôme** : Initialisation de la base de données SQLite sans gestion d'erreurs**Analyse du code actuel** :

- `await LocalDatabase.instance()` appelé directement sans try-catch (ligne 19)
- `LocalDatabase.instance()` peut échouer pour de multiples raisons :
- `getApplicationSupportDirectory()` échoue (permissions, système de fichiers)
- Migration de DB échoue (lignes 56-88 dans sqlite_database.dart)
- `openDatabase()` échoue (corruption DB, permissions, espace disque)
- Migrations `onUpgrade` échouent (erreurs SQL, données corrompues)

**Impact** :

- Blocage au démarrage si la DB ne peut pas être initialisée
- Crash de l'application
- Perte totale de fonctionnalités même si Supabase est disponible
- Pas de logs informatifs en cas d'échec

**Solution** :

- Ajouter try-catch autour de `LocalDatabase.instance()`
- Fallback vers une base en mémoire pour mode dégradé
- Logger les erreurs avec contexte
- Permettre à l'app de fonctionner sans storage local (mode cloud-only)

## Modifications prévues

### 1. Améliorer PerformanceModule avec fallback complet

**Fichier** : [`lib/src/core/performance/performance_module.dart`](lib/src/core/performance/performance_module.dart)**Modifications** :

#### a) Extraire la logique de configuration NetworkExecutor

Créer une fonction privée `_configureNetworkExecutor` qui prend un `PerformanceTuning` et applique la configuration :

````dart
static void _configureNetworkExecutor(GetIt sl, PerformanceTuning tuning) {
  if (!sl.isRegistered<NetworkExecutor>()) return;
  
  final executor = sl<NetworkExecutor>();
  executor.configureConcurrency('tmdb', tuning.tmdbMaxConcurrent);
  executor.configureLimiterAcquireTimeout(
    tuning.isLowResources ? const Duration(seconds: 30) : const Duration(seconds: 10),
  );
  executor.configureInflightJoinTimeout(
    tuning.isLowResources ? const Duration(seconds: 45) : const Duration(seconds: 15),
  );
  
  debugPrint('[DEBUG][Startup] PerformanceModule: NetworkExecutor configured (profile=${tuning.profile.name})');
}
```

#### b) Améliorer le bloc catch

Modifier le bloc catch (lignes 68-79) pour :
- Appliquer la configuration NetworkExecutor même en cas d'erreur
- Logger plus d'informations
- S'assurer que le module est toujours dans un état cohérent

```dart
} catch (e, st) {
  sw.stop();
  debugPrint('[DEBUG][Startup] PerformanceModule.register: ERROR after ${sw.elapsedMilliseconds}ms: $e');
  debugPrint('[DEBUG][Startup] PerformanceModule.register: Stack trace: $st');
  
  // Ne pas faire échouer le startup si PerformanceModule échoue
  // Utiliser des valeurs par défaut
  if (!sl.isRegistered<PerformanceTuning>()) {
    final defaultTuning = PerformanceTuning.fromProfile(PerformanceProfile.normal);
    sl.registerSingleton<PerformanceTuning>(defaultTuning);
    debugPrint('[DEBUG][Startup] PerformanceModule.register: Using default tuning as fallback');
    
    // Appliquer la configuration par défaut au NetworkExecutor
    _configureNetworkExecutor(sl, defaultTuning);
  }
}
```

#### c) Utiliser la fonction dans le bloc try

Remplacer les lignes 46-54 par un appel à `_configureNetworkExecutor(sl, tuning)` pour éviter la duplication.

### 2. Ajouter gestion d'erreurs à StorageModule

**Fichier** : [`lib/src/core/storage/services/storage_module.dart`](lib/src/core/storage/services/storage_module.dart)

**Modifications** :

#### a) Ajouter logs de debug et gestion d'erreurs

```dart
static Future<void> register() async {
  final sw = Stopwatch()..start();
  debugPrint('[DEBUG][Startup] StorageModule.register: START');
  
  try {
    if (!sl.isRegistered<Database>()) {
      debugPrint('[DEBUG][Startup] StorageModule.register: initializing LocalDatabase');
      final db = await LocalDatabase.instance().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[DEBUG][Startup] StorageModule.register: WARNING - LocalDatabase.instance timeout');
          throw TimeoutException('LocalDatabase.instance timeout', const Duration(seconds: 10));
        },
      );
      sl.registerSingleton<Database>(db);
      debugPrint('[DEBUG][Startup] StorageModule.register: LocalDatabase registered (${sw.elapsedMilliseconds}ms)');
    }
    
    // Enregistrer les repositories...
    _registerRepositories();
    
    sw.stop();
    debugPrint('[DEBUG][Startup] StorageModule.register: COMPLETE (total: ${sw.elapsedMilliseconds}ms)');
  } catch (e, st) {
    sw.stop();
    debugPrint('[DEBUG][Startup] StorageModule.register: ERROR after ${sw.elapsedMilliseconds}ms: $e');
    debugPrint('[DEBUG][Startup] StorageModule.register: Stack trace: $st');
    
    // Fallback : enregistrer une DB en mémoire pour mode dégradé
    debugPrint('[DEBUG][Startup] StorageModule.register: Using in-memory fallback');
    
    try {
      final inMemoryDb = await _createInMemoryDatabase();
      sl.registerSingleton<Database>(inMemoryDb);
      _registerRepositories();
      debugPrint('[DEBUG][Startup] StorageModule.register: In-memory fallback registered successfully');
    } catch (fallbackError) {
      debugPrint('[DEBUG][Startup] StorageModule.register: FATAL - Even fallback failed: $fallbackError');
      // Ne pas faire échouer le startup, mais logger clairement
      // L'app fonctionnera en mode cloud-only
    }
  }
}
```

#### b) Extraire l'enregistrement des repositories

Créer une fonction privée `_registerRepositories()` pour éviter la duplication entre le chemin normal et le fallback.

#### c) Créer une base en mémoire pour le fallback

```dart
static Future<Database> _createInMemoryDatabase() async {
  return await openDatabase(
    inMemoryDatabasePath,
    version: 17,
    onCreate: (db, version) async {
      // Créer uniquement les tables essentielles pour mode dégradé
      // (éviter les migrations complexes)
      await db.execute('''
        CREATE TABLE watchlist (
          content_id TEXT NOT NULL,
          content_type TEXT NOT NULL,
          title TEXT NOT NULL,
          poster TEXT,
          added_at INTEGER NOT NULL,
          user_id TEXT NOT NULL DEFAULT 'default',
          PRIMARY KEY (content_id, content_type, user_id)
        );
      ''');
      // ... autres tables essentielles
    },
  );
}
```

### 3. Ajouter logs de debug à LocalDatabase

**Fichier** : [`lib/src/core/storage/database/sqlite_database.dart`](lib/src/core/storage/database/sqlite_database.dart)

**Modifications** :

- Ajouter des logs de debug au début de `instance()` (ligne 27)
- Logger les étapes critiques (migration, openDatabase, etc.)
- Logger les erreurs avec contexte

```dart
static Future<Database> instance() async {
  final sw = Stopwatch()..start();
  debugPrint('[DEBUG][Startup] LocalDatabase.instance: START');
  
  if (_instance != null) {
    debugPrint('[DEBUG][Startup] LocalDatabase.instance: returning cached instance');
    return _instance!;
  }
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (_) {}
  
  // ... code existant avec logs ajoutés ...
  
  debugPrint('[DEBUG][Startup] LocalDatabase.instance: database path = $path');
  debugPrint('[DEBUG][Startup] LocalDatabase.instance: opening database');
  
  _instance = await openDatabase(
    path,
    version: 17,
    onConfigure: (db) async {
      debugPrint('[DEBUG][Startup] LocalDatabase.instance: onConfigure');
      await db.execute('PRAGMA foreign_keys = ON;');
      await _tryEnableWal(db);
    },
    onOpen: (db) async {
      debugPrint('[DEBUG][Startup] LocalDatabase.instance: onOpen (ensuring columns)');
      // ... code existant ...
    },
    onCreate: (db, version) async {
      debugPrint('[DEBUG][Startup] LocalDatabase.instance: onCreate (version $version)');
      // ... code existant ...
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      debugPrint('[DEBUG][Startup] LocalDatabase.instance: onUpgrade (from $oldVersion to $newVersion)');
      // ... code existant ...
    },
  );
  
  sw.stop();
  debugPrint('[DEBUG][Startup] LocalDatabase.instance: COMPLETE (total: ${sw.elapsedMilliseconds}ms)');
  
  return _instance!;
}
```

## Ordre d'implémentation

1. **PerformanceModule** : Extraire `_configureNetworkExecutor` et améliorer le fallback
2. **StorageModule** : Ajouter try-catch, timeout et fallback en mémoire
3. **LocalDatabase** : Ajouter logs de debug pour traçabilité
4. **Tests** : Vérifier que les fallbacks fonctionnent correctement

## Vérifications

- [ ] Vérifier que PerformanceModule ne fait jamais échouer le startup
- [ ] Vérifier que NetworkExecutor est toujours configuré (même avec fallback)
- [ ] Vérifier que StorageModule ne fait jamais échouer le startup
- [ ] Tester avec DB corrompue (fallback en mémoire)
- [ ] Tester avec timeout (timeout après 10s → fallback)
- [ ] Vérifier que les logs `[DEBUG][Startup]` sont cohérents
- [ ] Tester en mode cloud-only (sans DB locale)

## Bénéfices attendus

1. **Startup plus robuste** : Aucun module ne peut bloquer le démarrage
2. **Mode dégradé** : L'app peut fonctionner sans DB locale (cloud-only)
3. **Meilleure observabilité** : Logs détaillés pour diagnostiquer les problèmes
4. **Performance** : Timeouts pour éviter les attentes infinies


````