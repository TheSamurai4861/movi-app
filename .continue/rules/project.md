# Project Context (Flutter)

- Code applicatif dans `lib/` (et parfois `lib/src/`).
- Tests dans `test/`.
- Ignorer `build/`, `.dart_tool/` par défaut.

## Directives à l’Agent
- **Utilise les outils de fichiers** (list/read/search) pour explorer le repo.
- **N’invente aucun fichier** : si un dossier n’existe pas, indique « (non trouvé) ».
- Commence par les **points d’entrée** (`lib/main.dart`, router, DI).
- **Toujours citer** les chemins réels dans diagnostics/plans/patches.
