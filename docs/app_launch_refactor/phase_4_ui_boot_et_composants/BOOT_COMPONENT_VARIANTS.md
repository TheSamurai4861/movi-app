# Phase 4 - Etape 6 - Variantes composants boot

## Objectif

Aligner les composants existants sur les contraintes Figma boot (393×852)
**sans** modifier le comportement par defaut des ecrans qui ne passent pas par
les helpers dedies.

## Table composant | ecart Figma | solution | API / livrable | impact hors boot | test

```text
MoviPrimaryButton | 250x50, radius 25, gras 16 | Style injecte via [buttonStyle] + [height] depuis tokens boot | BootFormTokens.bootPrimaryButtonStyle ; usage dans BootRecoveryPanel | inchangé si appels existants sans ces props | boot_recovery_panel_test
TextButton secondaire recovery | meme hauteur / rayon que primaire | TextButton.styleFrom aligne sur BootFormTokens | BootRecoveryPanel | idem | idem
AppLabeledTextField | 300x50, radius 25, padding 20, fond gris | Decoration partagee optionnelle | BootFormTokens.bootTextFieldDecoration(theme) a passer en [decoration] | aucun si non utilise | profile/auth (etape 7)
ProfileAvatarChip | initiale 32 bold dans disque 75, icone generique | [avatarInitial] affiche premier graphème, sinon [icon] | nouveau param optionnel + doc UTF-8 | defaut = icone comme avant | profile_avatar_chip_test
```

## Fichiers

| Fichier | Role |
|---------|------|
| `lib/src/core/startup/presentation/widgets/boot_form_tokens.dart` | Constantes + `bootPrimaryButtonStyle` + `bootTextFieldDecoration` |
| `lib/src/core/startup/presentation/widgets/boot_recovery_panel.dart` | Applique les tokens aux actions |
| `lib/src/core/profile/presentation/ui/widgets/profile_avatar_chip.dart` | Initiale optionnelle |

## Focus TV / clavier

- `MoviPrimaryButton` conserve bordure / scale au focus (non regresse).
- `welcome_user_page` : le focus visuel reste porté par `MoviFocusableAction` /
  `MoviFocusFrame` autour du chip (pas de second focus interne au chip).

## Definition de fini

- [x] Tokens boot centralises et documentes.
- [x] Recovery boot consomme les tokens boutons.
- [x] `ProfileAvatarChip` permet l’initiale sans casser l’icone par defaut.
- [x] `AppLabeledTextField` : decoration boot disponible sans modification du widget partage.
