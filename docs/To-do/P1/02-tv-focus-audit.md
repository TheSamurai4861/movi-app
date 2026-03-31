## Audit focus TV (Android TV / D‑pad) — Movi

Objectif : cartographier les entrées/sorties de focus et identifier où le focus peut être perdu.

### Shell (sidebar + contenu)
- **Fichier**: `lib/src/features/shell/presentation/pages/app_shell_page.dart`
- **Entrée de focus**: Sidebar (FocusNode partagé `_sidebarFocusNode`) via `AppShellTvLayout(autofocus: true)` dans `SidebarNav`.
- **Règles déjà en place**:
  - Flèche **→** depuis sidebar : `focusTabEntry(selectedTab)`
  - Flèche **←** depuis contenu : `focusInDirection(left)` puis fallback sidebar + `rememberContentFocus`
- **Risque**:
  - Certaines pages ne “registerPreferredNode” pas → `focusTabEntry` peut échouer et le focus reste sidebar.

### Home
- **Fichier**: `lib/src/features/home/presentation/widgets/home_desktop_layout.dart` (utilisé en Desktop/TV)
- **Entrée de focus**: `_heroPrimaryActionFocusNode` (registerPreferredNode `ShellTab.home`)
- **Risque**:
  - Carrousels horizontaux : vérifier `MoviEnsureVisibleOnFocus` sur les items extrêmes.
  - Modals/dialogs : restore focus après fermeture.

### Search
- **Fichier**: `lib/src/features/search/presentation/pages/search_page.dart`
- **Focus nodes existants**:
  - `_focusNode` (TextField)
  - `_firstHistoryItemFocusNode`
  - `_firstProviderFocusNode`
  - `_firstGenreFocusNode`
- **Manque probable**:
  - Pas de `registerPreferredNode(ShellTab.search, ...)` → entrée de focus non garantie depuis sidebar.
- **Risque**:
  - D‑pad sur TextField (clavier virtuel / focus bloqué) : besoin d’une “sortie” claire vers résultats.

### Library
- **Fichier**: `lib/src/features/library/presentation/pages/library_page.dart`
- **Entrée de focus**: un FocusNode “first” (registerPreferredNode `ShellTab.library`).
- **Risque**:
  - Grilles/listes : voisins et bords (← vers sidebar) cohérents.

### Settings
- **Fichier**: `lib/src/features/settings/presentation/pages/settings_page.dart`
- **Entrée de focus**: `_firstProfileFocusNode` (registerPreferredNode `ShellTab.settings`)
- **Risque**:
  - ListView : ensureVisible sur focus
  - Navigation horizontale dans section profils (bords).

### Movie details
- **Fichier**: `lib/src/features/movie/presentation/pages/movie_detail_page.dart`
- **Points focusables**: CTA “Regarder”, bouton “Versions”, cast, saga.
- **Risque**:
  - Bottom sheet variantes (MoviePlaybackVariantSheet) : autofocus/restore focus.

### TV details (série)
- **Fichier**: `lib/src/features/tv/presentation/pages/tv_detail_page.dart`
- **Points focusables**: CTA principal, saisons/épisodes, menu actions.
- **Risque**:
  - Carrousels/épisodes : ensureVisible + bords
  - Bottom sheet variantes épisodes : autofocus/restore focus.

### Player
- **Fichier**: `lib/src/features/player/presentation/pages/video_player_page.dart`
- **Risque**:
  - Priorité des touches télécommande (select/back/←→↑↓) vs gestures.
  - Menus audio/sous-titres : navigation complète au D‑pad.

