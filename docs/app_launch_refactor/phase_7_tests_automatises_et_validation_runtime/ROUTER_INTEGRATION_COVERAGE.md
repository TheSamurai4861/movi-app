# Etape 7.3 - Couverture router/integration des parcours launch

## Cible

Valider les parcours critiques de routage `launch` et la coherence des
redirections selon l'etat boot/tunnel.

## Suites executees

- `test/core/router/new_user_auth_launch_flow_test.dart`
- `test/core/router/launch_redirect_guard_boot_alignment_test.dart`
- `test/core/router/launch_redirect_guard_tunnel_surface_test.dart`
- `test/core/router/launch_redirect_guard_reconnect_test.dart`

## Parcours verifies

- `launch -> auth`
- `launch -> create profile`
- `launch -> choose profile`
- `launch -> add source`
- `launch -> choose source`
- `launch -> catalog preparing -> home`
- `launch -> source recovery`
- `launch -> home partial`

## Resultat

- Les 4 suites router/integration sont vertes.
- Les redirections critiques restent alignees avec le tunnel boot.
- Les routes sensibles (`auth`, `welcome`, `home`) respectent les contraintes
  de readiness et de recovery.
