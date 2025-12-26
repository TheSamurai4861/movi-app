# Plan d'optimisation : Preload et NetworkExecutor

## Problèmes identifiés

### 1. Preload avec appels réseau multiples (Moyen)

**Symptôme** : Le preload fait plusieurs appels réseau (Supabase, TMDB, IPTV) qui peuvent ralentir le lancement

**Analyse du code actuel** :

- `appPreloadProvider` dans `bootstrap_providers.dart` (ligne 144)
- Étapes séquentielles :

1. Startup technique
2. Auth + profiles Supabase
3. IPTV sources locales
4. Profile selection
5. IPTV accounts + playlists
6. IPTV sync (avec timeout 10s)
7. **Home preload** (avec timeout 30s) - ligne 384-386

- `home.load(awaitIptv: iptvCatalogReady)` peut bloquer jusqu'à 30s
- Timeout de 30s est long mais nécessaire pour les connexions lentes
- Les erreurs sont gérées mais les timeouts ralentissent le lancement

**Problèmes spécifiques** :

- **Home preload timeout 30s** : Trop long pour une bonne UX
- **Appels séquentiels** : Chaque étape attend la précédente
- **Pas de parallélisation** : IPTV sync et home preload pourraient être parallèles
- **Retries implicites** : NetworkExecutor fait des retries, ajoutant du temps
- **Pas de feedback utilisateur** : L'utilisateur ne sait pas ce qui charge

**Impact** :

- Lancement lent (jusqu'à 40s+ sur connexions lentes)
- Mauvaise UX : écran de chargement sans information
- Timeouts fréquents qui masquent les vrais problèmes
- Pas de différenciation entre "chargement" et "erreur réseau"

### 2. NetworkExecutor - Timeouts configurables (Faible)

**Symptôme** : Configuration des timeouts NetworkExecutor (10s par défaut)

**Analyse du code actuel** :

- `limiterAcquireTimeout` : 10s (ligne 31 dans network_executor.dart)
- `inflightJoinTimeout` : 15s (ligne 30)
- `_timeoutFromDio()` : 30s par défaut si non configuré (ligne 393)
- Timeout par requête configurable via paramètre `timeout`
- Retries avec backoff exponentiel (base 300ms, max 5s)

**Problèmes spécifiques** :

- **Timeout global 30s trop long** pour la plupart des requêtes TMDB/Supabase
- **limiterAcquireTimeout 10s** peut être long si beaucoup de requêtes en attente
- **inflightJoinTimeout 15s** peut bloquer si une requête précédente est lente
- **Pas de timeout différencié par type** : TMDB vs Supabase vs IPTV
- **Pas de circuit breaker visible** : Même si implémenté, pas de logs clairs

**Impact** :

- Attentes longues avant échec sur réseau lent
- Accumulation de requêtes en attente
- Pas d'adaptation au contexte (connexion mobile vs wifi)
- Difficile de diagnostiquer les problèmes de performance

## Solutions proposées

### 1. Optimiser le preload avec parallélisation et feedback

**Objectifs** :

- Réduire le temps de lancement de 40s à ~15s sur connexions normales
- Paralléliser les appels indépendants
- Donner un feedback clair à l'utilisateur
- Réduire les timeouts agressifs

**Modifications prévues** :

#### a) Paralléliser IPTV sync et home preload

**Fichier** : [`lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`](lib/src/features/welcome/presentation/providers/bootstrap_providers.dart)

**Problème actuel** :

````dart
// 7) IPTV sync (séquentiel)
await xtreamSync.syncAll(...)
  .timeout(const Duration(seconds: 10));

// 8) Home preload (séquentiel, après sync)
await home.load(awaitIptv: iptvCatalogReady)
  .timeout(const Duration(seconds: 30));
```

**Solution** :
```dart
// 7) Paralléliser IPTV sync et home preload
final syncFuture = xtreamSync.syncAll(...)
  .timeout(const Duration(seconds: 8), onTimeout: () {
    debugPrint('[Preload] IPTV sync timeout (continuing)');
    return null; // Continue sans bloquer
  });

final homeFuture = home.load(awaitIptv: false) // Ne pas attendre IPTV
  .timeout(const Duration(seconds: 15), onTimeout: () {
    debugPrint('[Preload] Home load timeout (continuing)');
    return null;
  });

// Attendre les deux en parallèle
await Future.wait([syncFuture, homeFuture], eagerError: false);
```

**Gain estimé** : -15 à -20 secondes sur connexions normales

#### b) Réduire le timeout home.load

**Actuellement** : 30s
**Nouveau** : 15s avec chargement progressif

**Justification** :
- TMDB répond généralement en 1-3s
- Supabase répond en 500ms-2s
- 15s laisse 3-5 tentatives avec retry
- Au-delà de 15s, l'utilisateur devrait voir une erreur explicite

#### c) Ajouter un feedback de progression

**Fichier** : [`lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`](lib/src/features/welcome/presentation/providers/bootstrap_providers.dart)

**Solution** :
```dart
// Créer un StateNotifier pour le feedback
final bootstrapProgressProvider = StateNotifierProvider<BootstrapProgressNotifier, BootstrapProgress>((ref) {
  return BootstrapProgressNotifier();
});

class BootstrapProgress {
  final String currentStep;
  final double progress; // 0.0 to 1.0
  final String? message;
  
  const BootstrapProgress({
    required this.currentStep,
    required this.progress,
    this.message,
  });
}

// Dans appPreloadProvider, mettre à jour la progression
void updateProgress(String step, double progress) {
  ref.read(bootstrapProgressProvider.notifier).update(
    BootstrapProgress(
      currentStep: step,
      progress: progress,
      message: _getStepMessage(step),
    ),
  );
}

// Usage dans le preload
updateProgress('auth', 0.1);
await auth...
updateProgress('profiles', 0.3);
await profiles...
updateProgress('home', 0.8);
await home...
```

#### d) Chargement progressif du home

**Fichier** : [`lib/src/features/home/presentation/providers/home_controller.dart`](lib/src/features/home/presentation/providers/home_controller.dart)

**Solution** :
- Charger le hero carousel immédiatement (requis)
- Charger les sections en arrière-plan (optionnel)
- Afficher l'écran dès que le hero est prêt

```dart
Future<void> load({bool awaitIptv = false}) async {
  // Phase 1 : Critique (blocking)
  await _loadHeroCarousel(); // 2-3s max
  
  // Phase 2 : Non-critique (background)
  unawaited(_loadSections(awaitIptv)); // Continue en arrière-plan
}
```

### 2. Optimiser NetworkExecutor timeouts

**Objectifs** :
- Réduire les timeouts par défaut
- Différencier par type de service
- Améliorer les logs de performance
- Ajouter des métriques visibles

**Modifications prévues** :

#### a) Réduire le timeout par défaut

**Fichier** : [`lib/src/core/network/network_executor.dart`](lib/src/core/network/network_executor.dart)

**Changements** :
```dart
// Actuellement
Duration _timeoutFromDio() {
  ...
  return const Duration(seconds: 30); // Trop long
}

// Nouveau
Duration _timeoutFromDio() {
  ...
  return const Duration(seconds: 15); // Plus réaliste
}
```

**Justification** :
- TMDB API répond en 1-3s normalement
- Supabase répond en <2s
- 15s permet 3-5 retries avec backoff
- Force les appelants à être explicites sur les timeouts longs

#### b) Timeout différencié par contexte

**Fichier** : [`lib/src/core/network/config/network_module.dart`](lib/src/core/network/config/network_module.dart)

**Solution** :
```dart
// Créer des constantes de timeout par service
class NetworkTimeouts {
  static const tmdb = Duration(seconds: 10);
  static const supabase = Duration(seconds: 8);
  static const iptv = Duration(seconds: 15); // Plus tolérant
  static const imageDownload = Duration(seconds: 20);
  
  static const limiterAcquire = Duration(seconds: 8);
  static const inflightJoin = Duration(seconds: 12);
}

// Appliquer lors de la configuration
NetworkModule.register() {
  final executor = NetworkExecutor(
    dio,
    limiterAcquireTimeout: NetworkTimeouts.limiterAcquire,
    inflightJoinTimeout: NetworkTimeouts.inflightJoin,
  );
}
```

#### c) Logs de performance améliorés

**Fichier** : [`lib/src/core/network/network_executor.dart`](lib/src/core/network/network_executor.dart)

**Solution** :
```dart
// Ajouter des logs de performance détaillés
void _logPerformance(String key, Duration elapsed, bool success) {
  logger?.debug(
    '[Network] key=$key elapsed=${elapsed.inMilliseconds}ms success=$success',
  );
  
  // Log warning si lent
  if (elapsed > const Duration(seconds: 5)) {
    logger?.warn(
      '[Network] SLOW REQUEST: key=$key elapsed=${elapsed.inMilliseconds}ms',
    );
  }
}

// Dans la méthode run(), après chaque requête
sw.stop();
_logPerformance(concurrencyKey ?? 'default', sw.elapsed, true);
```

#### d) Métriques de circuit breaker visibles

**Fichier** : [`lib/src/core/network/network_executor.dart`](lib/src/core/network/network_executor.dart)

**Solution** :
```dart
// Exposer les stats du limiteur via un provider
final networkStatsProvider = StreamProvider<Map<String, LimiterStats>>((ref) {
  final executor = sl<NetworkExecutor>();
  return Stream.periodic(const Duration(seconds: 5), (_) {
    return executor.getAllLimiterStats();
  });
});

// Ajouter méthode dans NetworkExecutor
Map<String, LimiterStats> getAllLimiterStats() {
  return _limiters.map((key, limiter) => MapEntry(key, limiter.stats));
}
```

### 3. Améliorer la gestion des erreurs réseau

**Fichier** : [`lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`](lib/src/features/welcome/presentation/providers/bootstrap_providers.dart)

**Solution** :
```dart
// Distinguer timeout vs erreur réseau vs erreur serveur
enum PreloadErrorType {
  networkTimeout,
  networkError,
  serverError,
  authError,
  unknown,
}

class PreloadError {
  final PreloadErrorType type;
  final String step;
  final String message;
  final bool isRetryable;
  
  const PreloadError({
    required this.type,
    required this.step,
    required this.message,
    required this.isRetryable,
  });
}

// Dans le catch
} on TimeoutException {
  return PreloadError(
    type: PreloadErrorType.networkTimeout,
    step: step,
    message: 'Connection timeout after ${timeout}s',
    isRetryable: true,
  );
} on SocketException {
  return PreloadError(
    type: PreloadErrorType.networkError,
    step: step,
    message: 'Network connection failed',
    isRetryable: true,
  );
}
```

## Ordre d'implémentation

1. **NetworkExecutor timeouts** : Réduire les timeouts par défaut (impact immédiat)
2. **Preload parallélisation** : IPTV sync + home load en parallèle
3. **Feedback progression** : Ajouter BootstrapProgressNotifier
4. **Home chargement progressif** : Séparer critique vs background
5. **Logs performance** : Améliorer les logs NetworkExecutor
6. **Métriques visibles** : Exposer les stats du circuit breaker

## Métriques de succès

### Avant optimisation
- Temps de lancement : 30-40s (connexion normale)
- Timeout home.load : 30s
- Pas de feedback utilisateur
- Logs peu informatifs

### Après optimisation
- Temps de lancement : 10-15s (connexion normale)
- Timeout home.load : 15s
- Feedback de progression visible
- Logs détaillés avec timings

### Gains attendus
- **-50% temps de lancement** sur connexions normales
- **-60% temps de lancement** si connexion rapide (parallélisation)
- **Meilleure UX** : feedback clair sur la progression
- **Meilleure observabilité** : logs détaillés pour diagnostiquer

## Vérifications

- [ ] Vérifier que la parallélisation ne casse pas les dépendances
- [ ] Tester avec connexion lente (throttling)
- [ ] Tester avec connexion rapide
- [ ] Vérifier que les timeouts ne sont pas trop agressifs
- [ ] Tester le feedback de progression
- [ ] Vérifier les logs de performance
- [ ] Tester le chargement progressif du home
- [ ] Vérifier que les erreurs sont bien catégorisées

## Risques et mitigations

### Risque 1 : Parallélisation casse des dépendances
**Mitigation** : Bien identifier les dépendances avant de paralléliser

### Risque 2 : Timeouts trop agressifs causent plus d'erreurs
**Mitigation** : Garder les retries avec backoff, surveiller les métriques

### Risque 3 : Chargement progressif rend l'UI instable
**Mitigation** : Utiliser des placeholders et animations de transition

### Risque 4 : Logs trop verbeux

````