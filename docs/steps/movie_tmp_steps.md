toolName: search_codebase
            
status: success
          
query: Find AppSpacing utility or spacing constants; check existing spacing utilities or constants.
          

        
            
toolName: search_by_regex
            
status: success
          
query: SnackBar\(content:\s*Text\('
          
**Objectif**
- Zéro chaîne en dur dans la page film et micro‑optimisations de lisibilité/performance.

**Inventaire des chaînes à externaliser**
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:315` → `Aucune playlist disponible`
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:412` → `Ajouté à "${playlist.title}"`
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:440` → `Ajouté à "${playlist.title}"`
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:448` → `Erreur: $e`
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:580` → `Erreur: $e`
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:610` → `Erreur: $e`
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:640` → `Film non disponible dans la playlist`
- `lib/src/features/movie/presentation/pages/movie_detail_page.dart:655` → `Erreur: $e`

**Étapes ARB**
- Ajouter les clés et placeholders dans `l10n/app_*.arb`:
  - `movieNoPlaylistsAvailable`: “Aucune playlist disponible”
  - `addedToPlaylist`: “Ajouté à "{title}"” avec placeholder `title:String`
  - `errorWithMessage`: “Erreur: {message}” avec placeholder `message:String`
  - `movieNotAvailableInPlaylist`: “Film non disponible dans la playlist”
  - `errorLoadingPlaylists`: “Erreur lors du chargement des playlists: {message}`” avec `message:String`
  - `errorPlaybackFailed`: “Erreur lors de la lecture du film: {message}`” avec `message:String`
- Traductions minimales en `app_en.arb` et autres locales déjà présentes (`fr`, `de`, `it`, `pt`, `pl`, `nl`) pour éviter les trous.

**Remplacements dans la page**
- Remplacer les `Text('...')` par `AppLocalizations.of(context)!...`:
  - `movie_detail_page.dart:315` → `Text(AppLocalizations.of(context)!.movieNoPlaylistsAvailable)`
  - `movie_detail_page.dart:412, 440` → `Text(AppLocalizations.of(context)!.addedToPlaylist(playlist.title))`
  - `movie_detail_page.dart:448, 580, 610, 655` → `Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))`
  - `movie_detail_page.dart:640` → `Text(AppLocalizations.of(context)!.movieNotAvailableInPlaylist)`
  - `movie_detail_page.dart:469` (chargement playlists) → `Text(AppLocalizations.of(context)!.errorLoadingPlaylists(e.toString()))`
  - `movie_detail_page.dart:654` (lecture film) → `logger.error(AppLocalizations.of(context)!.errorPlaybackFailed(e.toString()), e, st)`
- Préférer les clés déjà existantes quand elles couvrent le besoin:
  - Actions “Annuler”, “Ajouter à une liste”, “Marquer vu/non vu”, etc. sont déjà en `app_localizations_fr.dart` et consommées dans le fichier.

**Micro‑optimisations const**
- Utiliser `const` pour:
  - `SizedBox(...)` statiques (espacement fixe).
  - `CupertinoActionSheetAction(...)` sans variables si possible; sinon garder non‑const.
  - Widgets purement statiques dans les sections (icônes, containers sans dépendances).
- Exemple:
  - `SizedBox(height: 16)` → `const SizedBox(height: 16)`
  - `CupertinoActionSheetAction(child: Text(...))` reste non‑const si dépend de `context`/localizations.

**Factorisation des espacements**
- Introduire un utilitaire `AppSpacing` si absent:
  - Fichier suggéré: `lib/src/core/utils/app_spacing.dart`
  - Constantes: `xs=8`, `s=12`, `m=16`, `l=24`, `xl=32`
  - Remplacer les `SizedBox(height: N)` récurrents par `SizedBox(height: AppSpacing.m)` pour cohérence visuelle.
- Astuce: commencer par les espacements de la page détail pour éviter un refactor global immédiat.

**Procédure technique**
- Ajouter/mettre à jour les clés dans `l10n/app_fr.arb` et au moins `app_en.arb`.
- Regénérer les localisations: `flutter gen-l10n`.
- Adapter `movie_detail_page.dart` pour utiliser les nouvelles clés.
- Lancer `flutter analyze` pour vérifier:
  - Absence de chaînes en dur dans la page.
  - Lints `prefer_const_constructors` mieux satisfaits (ajout des `const`).
- Optionnel: greps ciblés
  - Rechercher `SnackBar(content: Text('` pour détecter les chaînes restantes à migrer.
  - Rechercher `Text('` dans la page pour s’assurer qu’aucune chaîne UI statique n’a échappé.

**Critères de réussite**
- Plus aucune chaîne en dur dans `movie_detail_page.dart`.
- Clés ARB cohérentes et disponibles dans toutes les locales activées.
- `flutter analyze` sans avertissements sur imports inutilisés et avec davantage de `const`.
- UI inchangée fonctionnellement, plus lisible et localisable.