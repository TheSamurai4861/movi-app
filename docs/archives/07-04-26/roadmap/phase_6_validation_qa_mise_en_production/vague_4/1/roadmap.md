# ÉTAPE D'ORIGINE
**Implémenter `TunnelPageShell`** – wrapper de page commun avec navigation TV/mobile et bar d'actions cibles

## SOUS-ÉTAPES

1. **Créer le fichier `tunnel_page_shell.dart`** – définir la classe `TunnelPageShell` qui étend `ConsumerStatefulWidget` et encapsule l'état global (provider de sélection, focus coordinator si nécessaire)

2. **Implémenter la méthode `initState()` dans `TunnelPageShellState`** – initialiser le `FocusNode` pour la navigation clavier/TV si applicable

3. **Implémenter la méthode `dispose()` dans `TunnelPageShellState`** – nettoyer les ressources (disposer le `FocusNode`, détacher du focus coordinator)

4. **Implémenter une logique de détection de mode (`_isTvMode()`) similaire à `AppShellPage`** – utiliser `forceTvMode` en priorité, puis fallback sur heuristique platform + breakpoint large

5. **Créer la méthode privée `_buildActionsBuilders()`** – retourner une liste de `WidgetBuilder` pour les actions cibles (bar d'actions)

6. **Implémenter des builders d'action statiques** – créer `_builder1()`, `_builder2()`, etc. pour chaque action cible, retournant la page correspondante

7. **Implémenter la méthode `build()` principale** :
   - Lire l'état du provider de sélection (`selectedIndex`)
   - Déterminer si le mode est TV ou mobile selon heuristique
   - Construire la liste des builders d'actions
   - Obtenir les destinations depuis une factory (par exemple `buildCibaDestinations(context)`)
   - Appliquer la politique de rétention pour actions cibles

8. **Conditionner le rendu sur l'état de récupération au démarrage** – si non retryable, afficher seulement le corps ; sinon envelopper dans un `Stack` avec le `LaunchRecoveryBanner`

9. **Rendu du corps principal** :
   - Envelopper les shortcuts globaux (gestes TV/clavier vers actions cibles)
   - Conditionner sur le mode TV/mobile :
     - Mode TV → utiliser `TunnelTvLayout` (si à créer) ou layout TV existant adapté
     - Non-TV, breakpoint large → utiliser `TunnelLargeLayout` (si à créer) ou layout Large existant adapté
     - Mobile → utiliser `TunnelMobileLayout` (si à créer) ou layout Mobile existant adapté

10. **Créer les layouts adaptatifs (`TunnelTvLayout`, `TunnelLargeLayout`, `TunnelMobileLayout`)** – wrappers simples qui enveloppent `ShellContentHost` avec le layout correspondant (TV : sidebar autofocus ; Large : Row(sidebar + content) ; Mobile : bottom nav flottante)

## PÉRIMÈTRE EXCLU
- Implémentation des pages/actions cibles elles-mêmes (contenu de _buildActionsBuilders_)
- Migration des surfaces amont existantes vers `TunnelPageShell` (appartient à d'autres étapes)
- Tests unitaires/intégration (appartiennent aux étapes suivantes)

## CRITÈRE DE FIN
Le widget `TunnelPageShell` est implémenté, possède un `State<TunnelPageShell>` avec lifecycle complet, logique de détection TV/mobile, builders d'actions cibles, politiques de rétention, gestion du recovery banner, et au moins trois layouts adaptatifs (TV/Large/Mobile) prêts à recevoir le contenu des actions cibles.