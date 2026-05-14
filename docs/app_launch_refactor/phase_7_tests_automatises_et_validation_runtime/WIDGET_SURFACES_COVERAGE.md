# Etape 7.2 - Couverture widget des surfaces critiques

## Cible

Valider les surfaces UI boot critiques en widget tests:

- chargements simples;
- preparation catalogue;
- recovery actionnable;
- banniere Home partielle.

## Suites executees

- `test/core/startup/boot_critical_screens_widget_test.dart`
- `test/core/startup/boot_simple_loading_screen_test.dart`
- `test/core/startup/boot_catalog_loading_screen_test.dart`
- `test/core/startup/boot_recovery_panel_test.dart`
- `test/features/home/presentation/widgets/home_error_banner_test.dart`

## Verifications couvertes

- Chargements simples:
  - logo centre;
  - message affiche;
  - aucune action focusable.
- Preparation catalogue:
  - message principal;
  - sous-message secondaire;
  - robustesse viewport etroit (393x852).
- Recovery:
  - action principale visible et focusable;
  - action secondaire visible seulement quand attendue;
  - ordre de focus primaire -> secondaire.
- Home partial banner:
  - message l10n contextualise;
  - action principale exposee;
  - compatibilite comportement compact.
- Garde-fous anti-fuite:
  - pas de `reasonCode` brut en UI;
  - pas d'URL brute ni identifiant interne affiche.

## Resultat

- Toutes les suites widget 7.2 passent.
- La couverture des surfaces critiques est validee.
