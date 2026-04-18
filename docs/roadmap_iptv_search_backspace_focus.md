# Roadmap - Bug recherche IPTV (conflit clavier vs focus)

## Contexte
Sur `IptvSourcesPage`, le comportement mobile/clavier montre des fermetures inattendues de la recherche.
Le point central n'est pas un focus global desactive sur mobile, mais une collision entre:
- la logique de retour route (`goBack` / `escape` / `backspace`),
- l'etat du champ de recherche (`TextField` + `FocusNode`),
- la logique d'ouverture/fermeture (`_toggleSearch`, `_openSearch`, `_closeSearch`).

## Diagnostic de depart
Faits verifies dans le code:
- Le focus de navigation des boutons custom est desactive en mobile/tablette dans `MoviFocusableAction`.
- Le champ de recherche garde un `FocusNode` actif.
- `backspace` est traite comme un retour global au meme niveau que `goBack` et `escape`.
- Quand la recherche est visible et le champ focus, la logique de retour peut vider/fermer la recherche.

Fichiers de reference:
- `lib/src/features/settings/presentation/pages/iptv_sources_page.dart`
- `lib/src/core/widgets/movi_focusable_action.dart`

## Objectif
Rendre le comportement clavier coherent et previsible:
- ne pas fermer la recherche de maniere inattendue pendant l'edition du champ,
- conserver la navigation retour attendue hors saisie,
- rester compatible mobile, desktop, TV et claviers physiques.

## Perimetre
Inclus:
- logique clavier/back de `IptvSourcesPage`,
- tests cibles de la page si existants/proches,
- verification runtime ciblee du flux ouverture/fermeture recherche.

Exclus:
- refactor global du systeme focus,
- modification transverse des autres pages Search/Library/Settings,
- redesign UI.

## Plan par phases

### Phase 0 - Reproduction et contrat de comportement
1. Reproduire le bug avec les commandes de `docs/run_logs_commands.md`.
2. Poser un contrat comportemental explicite par touche:
- `backspace` dans un `TextField` focus: edition texte uniquement.
- `escape` ou `goBack` dans le champ vide: fermeture recherche (si UX validee).
- `escape` ou `goBack` hors recherche: retour page.
3. Lister les variantes:
- recherche ouverte + champ focus + texte non vide,
- recherche ouverte + champ focus + texte vide,
- recherche ouverte + focus bouton recherche,
- recherche fermee.

Livrable:
- matrice attendue `etat x touche -> action`.

### Phase 1 - Correction minimale locale
1. Isoler la gestion des touches de retour dans une methode dediee lisible.
2. Ne plus traiter `backspace` comme retour global quand un champ editable est focus.
3. Conserver `goBack`/`escape` pour les cas retour UI explicites.
4. Preserver la logique existante de `_openSearch`, `_closeSearch`, `_toggleSearch` autant que possible.

Livrable:
- patch cible dans `iptv_sources_page.dart`, sans refactor large.

### Phase 2 - Tests cibles
1. Ajouter/adapter des tests widget sur `IptvSourcesPage` (ou helper teste).
2. Cas minimaux:
- `backspace` en saisie ne ferme pas la recherche,
- `escape` ou `goBack` ferme selon contrat quand champ vide,
- navigation retour page intacte hors mode saisie.

Livrable:
- tests cibles passants sur les cas de regression.

### Phase 3 - Verification contractuelle
Ordre:
1. tests cibles au plus proche,
2. `flutter analyze`,
3. `flutter test` complet seulement si impact transverse,
4. run runtime de validation du parcours corrige (si necessaire).

Commandes runtime de reference:
- `flutter run -d windows --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true *>&1 | Tee-Object -FilePath output/flutter-run-windows.log`

Livrable:
- resultats de commandes et constats attendu/observe.

### Phase 4 - Cloture
1. Documenter les fichiers modifies.
2. Documenter les commandes executees et leur resultat.
3. Lister les risques restants et points non verifies.

Livrable:
- compte-rendu final conforme a `docs/codex_execution_contract.md`.

## Criteres d'acceptation
- Le champ recherche ne se ferme plus sur `backspace` pendant la saisie.
- Le comportement `escape` / `goBack` est coherent avec la matrice de comportement validee.
- Pas de regression de navigation sur la page `IptvSourcesPage`.
- Changement local, lisible, sans refactor hors sujet.

## Risques et points d'attention
- Divergence de comportement selon OS/clavier physique (Windows, Android, TV remote).
- Ambiguite UX entre "vider le champ" vs "fermer la recherche" sur touche retour.
- Interactions possibles avec `FocusRegionScope` et handlers directionnels existants.

## Fichiers pressentis pour implementation
- `lib/src/features/settings/presentation/pages/iptv_sources_page.dart`
- `test/` (fichier de test widget cible a creer ou completer selon structure existante)
- `docs/run_logs_commands.md` (utilisation seulement, pas de modification requise)

## Execution phase 1 (2026-04-17)

### Patch applique
- Correction locale dans `iptv_sources_page.dart` uniquement.
- Extraction de la logique de filtrage des touches retour dans `_shouldHandleRouteBackKey(...)`.
- Ajout d'un garde `_isTextInputFocused()` pour ne pas traiter `backspace` comme retour global quand un champ texte est focus.
- `goBack` et `escape` conservent le comportement de retour existant.

### Resultat attendu du patch
- En edition du champ recherche, `backspace` supprime du texte au lieu de vider/fermer la recherche via le handler route.
- Hors saisie texte, `backspace` conserve son role de touche retour.

## Execution phase 2 (2026-04-17)

### Strategie retenue
- Option "helper teste" appliquee (conforme a la phase 2: widget test ou helper teste).
- Extraction d'une fonction pure testable: `shouldHandleIptvSourcesBackKey(...)`.
- Le code page continue d'utiliser la meme logique via `_shouldHandleRouteBackKey(...)`.

### Tests ajoutes
- `test/features/settings/presentation/pages/iptv_sources_page_back_key_test.dart`

Cas verifies:
- `backspace` + champ texte focus -> non gere comme retour global.
- `backspace` + pas de champ texte focus -> gere comme retour global.
- `escape` -> gere comme retour global.
- `goBack` -> gere comme retour global.
- touche non retour -> ignoree.

### Resultats
- Test cible: OK (`All tests passed`).
- Analyse statique: OK (`No issues found`).

## Execution phase 3 (2026-04-17)

### Verifications executees (ordre contractuel)
1. Test cible proche:
   - `flutter test test/features/settings/presentation/pages/iptv_sources_page_back_key_test.dart --dart-define-from-file=.env`
   - Resultat: OK (`All tests passed`).
2. Analyse statique:
   - `flutter analyze`
   - Resultat: OK (`No issues found`).
3. Validation runtime (Windows + logs):
   - `flutter run -d windows --dart-define-from-file=.env --dart-define=FORCE_STARTUP_DETAILS=true *>&1 | Tee-Object -FilePath output/flutter-run-windows.log`
   - Resultat: application lancee, bootstrap `startup_ready`, puis arret propre.

### Logs de reference
- `output/flutter-test-iptv-sources-back-key.log`
- `output/flutter-analyze.log`
- `output/flutter-run-windows.log`

### Couverture et limites
- Couvert:
  - decision clavier `backspace/escape/goBack` via test cible,
  - sante build/analyze,
  - demarrage runtime instrumente avec logs.
- Non couvert dans cette phase:
  - verification manuelle interactive complete du scenario UI "ouvrir recherche -> taper -> backspace" sur device.
