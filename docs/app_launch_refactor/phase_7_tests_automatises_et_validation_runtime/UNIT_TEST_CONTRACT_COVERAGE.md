# Etape 7.1 - Couverture unitaire contrats de decision

## Cible

Valider les contrats unitaires critiques du tunnel boot (decision d'entree,
etat catalogue, mapping recovery, mapping ecran) avec assertions stables sur
`reasonCode`, actions et destination.

## Suites executees

- `test/core/startup/resolve_entry_decision_test.dart`
- `test/core/startup/resolve_catalog_readiness_test.dart`
- `test/core/startup/startup_recovery_mapper_test.dart`
- `test/core/startup/boot_screen_mapper_test.dart`

## Verification

- `ResolveEntryDecision`
  - auth requise, profil requis, selection profil/source requise, entree Home.
- `ResolveCatalogReadiness`
  - fresh/cached/stale/missing/unavailable/timeout/provider/credentials/empty.
- `StartupRecoveryMapper`
  - boot failure, source timeout/provider/credentials/empty, Home partiel.
- `BootScreenMapper`
  - reason code -> ecran attendu ;
  - ecran interactif -> action principale/focus ;
  - non fuite du `reasonCode` brut dans les textes visibles.

## Resultat

- Les 4 suites sont vertes.
- La couverture de decision critique 7.1 est validee.
