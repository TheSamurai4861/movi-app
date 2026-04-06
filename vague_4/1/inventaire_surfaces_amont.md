# Inventaire des surfaces amont - Fiches de surface (Étape 1.1)

## Table des matières
- [F1 - Préparation système](#f1-préparation-système)
- [F2 - Authentification](#f2-authentification)
- [F3 - Création profil](#f3-création-profil)
- [F4 - Choix profil](#f4-choix-profil)

---

## F1 - Préparation système

### Surface 1.1 : Splash Bootstrap (`splash_bootstrap_page`)

| Éléments | Détails |
|----------|---------|
| **Nom du fichier** | `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart` |
| **Classe widget principale** | `SplashBootstrapPage` (ConsumerWidget) |
| **Imports clés** | ```dart\n- flutter/material.dart, flutter_riverpod/flutter_riverpod.dart\n- movi/l10n/app_localizations.dart\n- movi/src/core/widgets/widgets.dart (OverlaySplash, LaunchErrorPanel)\n- movi/src/core/startup/app_launch_orchestrator.dart\n``` |

**Composants enfants identifiés :**
1. **OverlaySplash** - Affiche "initialisation", "scan cloud...", "configuré..." avec spinner et texte de progression
2. **LaunchErrorPanel** - Gère les états d'erreur avec bouton "Reessayer"
3. **AppAssets.iconAppLogoSvg** (via OverlaySplash)

**Dépendances :**
- `home_bootstrap_progress_stage_provider` - Suivi des phases de bootstrap home
- `app_launch_state_provider` - État global du lancement
- `app_launch_orchestrator_provider` - Orchestratrice de lancement

---

### Surface 1.2 : Overlay Splash (`overlay_splash`)

| Éléments | Détails |
|----------|---------|
| **Nom du fichier** | `lib/src/core/widgets/overlay_splash.dart` |
| **Classe widget principale** | `OverlaySplash` (ConsumerWidget) + `_ElapsedLoadingText` (StatefulWidget) |
| **Imports clés** | ```dart\n- flutter/cupertino.dart, flutter/material.dart\n- flutter_svg/flutter_svg.dart\n- movi/src/core/utils/app_assets.dart\n- movi/src/core/state/app_state_provider.dart\n``` |

**Composants enfants identifiés :**
1. **Stack/Center** - Logo app centré (120px)
2. **Positioned/CircularProgressIndicator** - Spinner de chargement
3. **_ElapsedLoadingText** - Texte de progression avec temps écoulé

**Dépendances :**
- `currentAccentColorProvider` - Pour obtenir la couleur d'accentuation
- `app_assets.dart` - Gestion des assets SVG

---

### Surface 1.3 : Launch Error Panel (`launch_error_panel`)

| Éléments | Détails |
|----------|---------|
| **Nom du fichier** | `lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart` + `lib/src/core/widgets/launch_error_panel.dart` |
| **Classe widget principale** | `LaunchRecoveryBanner` (StatelessWidget), `LaunchErrorPanel` (StatelessWidget) |
| **Imports clés** | ```dart\n- flutter/material.dart\n- movi/src/core/widgets/movi_primary_button.dart\n``` |

**Composants enfants identifiés :**
1. **Text/Row** - Message d'erreur + bouton "Reessayer"
2. **Padding/Container** - Bordures et espacement

**Dépendances :**
- `movi_primary_button.dart` - Bouton MoviPrimaryButton

---

## F2 - Authentification

### Surface 2.1 : Auth Gate (`auth_gate`)

| Éléments | Détails |
|----------|---------|
| **Nom du fichier** | `lib/src/core/auth/presentation/widgets/auth_gate.dart` |
| **Classe widget principale** | `AuthGate` (ConsumerWidget) |
| **Imports clés** | ```dart\n- flutter/material.dart, flutter_riverpod/flutter_riverpod.dart\n- movi/src/core/auth/domain/entities/auth_models.dart\n- movi/src/core/auth/presentation/providers/auth_providers.dart\n- movi/src/core/config/config.dart\n- movi/src/core/widgets/overlay_splash.dart\n``` |

**Composants enfants identifiés :**
1. **OverlaySplash** - Affichage pendant l'état "unknown" (AuthStatus.unknown)
2. **Conditionale : `if (!_isAuthEnabled()) { return child; }`** - Rend le child quand Supabase n'est pas configuré
3. **ref.watch(authStatusProvider)** - Écoute de l'état d'authentification

**Dépendances :**
- `auth_status_provider` - Provider pour l'état d'authentification
- `supabase_config.from_environment` - Configuration Supabase (defines)

---

### Surface 2.2 : Auth OTP (`auth_otp_page`)

| Éléments | Détails |
|----------|---------|
| **Nom du fichier** | `lib/src/features/auth/presentation/auth_otp_page.dart` |
| **Classe widget principale** | `AuthOtpPage` (ConsumerStatefulWidget) + `_AuthOtpPageState` (ConsumerState<AuthOtpPage>) |
| **Imports clés** | ```dart\n- flutter/material.dart, flutter/services.dart\n- flutter_riverpod/flutter_riverpod.dart, go_router/go_router.dart\n- movi/l10n/app_localizations.dart\n- movi/src/core/auth/domain/entities/auth_models.dart\n- movi/src/core/router/router.dart\n- movi/src/core/utils/app_spacing.dart\n- movi/src/core/widgets/movi_primary_button.dart\n- movi/src/features/auth/presentation/providers/auth_providers.dart\n- movi/src/features/auth/presentation/auth_otp_controller.dart\n- movi/src/features/welcome/presentation/widgets/labeled_field.dart\n- movi/src/features/welcome/presentation/widgets/welcome_header.dart\n``` |

**Composants enfants identifiés :**
1. **WelcomeHeader** - Titre et sous-titre "Authentification 2FA"
2. **LabeledField (TextFormField)** - Champ email avec validation, focus node
3. **LabeledField (TextFormField)** - Champ OTP code (8 chiffres max)
4. **MoviPrimaryButton** - Bouton principal "Envoyer le code" / "Vérifier le code"
5. **LayoutBuilder/Row/Column** - Boutons secondaires "Réenvoyer le code", "Changer l'email"

**Dépendances :**
- `auth_otp_controller_provider` - Controller pour gérer OTP state (sending, verifying, cooldown)
- `auth_status_provider` - État global d'authentification
- `app_localizations` - Traductions localisées

---

### Surface 2.3 : Auth Gate (alternative) - Pas de fichier séparé identifié

Aucun fichier nommé `authscreen*`, `loginscreen*` n'a été trouvé dans le projet. L'authentification passe uniquement par `AuthGate` → `OverlaySplash` → `AuthOtpPage`.

---

## F3 - Création profil

### Surface 3.1 : Welcome User (`welcome_user_page`)

| Éléments | Détails |
|----------|---------|
| **Nom du fichier** | `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` |
| **Classe widget principale** | `WelcomeUserPage` (ConsumerStatefulWidget) + `_WelcomeUserPageState` |
| **Imports clés** | ```dart\n- flutter/foundation.dart, flutter/material.dart, flutter/cupertino.dart\n- flutter_riverpod/flutter_riverpod.dart, go_router/go_router.dart\n- movi/src/core/router/app_route_names.dart\n- movi/src/core/state/app_state_provider.dart\n- movi/l10n/app_localizations.dart\n- movi/src/core/utils/app_spacing.dart\n- movi/src/core/widgets/overlay_splash.dart\n- movi/src/core/widgets/movi_primary_button.dart\n- movi/src/features/welcome/presentation/widgets/labeled_field.dart\n``` |

**Composants enfants identifiés :**
1. **WelcomeHeader** - Titre "Créer votre profil" / "Bienvenue"
2. **OverlaySplash** - Affichage en attendant l'authentification Supabase
3. **LaunchRecoveryBanner** - Bande pour les erreurs de relance ("Relancer le bootstrap")
4. **CircularProgressIndicator** - Loading state des profils
5. **Text + TextSpan (Debug)** - Message d'erreur et stack trace
6. **Wrap/ProfileAvatarChip** - Galerie de boutons profils existants
7. **MoviPrimaryButton** - Bouton "Continuer" pour sélectionner ou créer profil
8. **LabeledField (TextFormField)** - Champ nom utilisateur (création du 1er profil)
9. **ScaffoldMessenger** - SnackBar d'erreur de validation

**Dépendances :**
- `supabase_client_provider`, `supabase_auth_status_provider` - Auth Supabase
- `user_settings_controller_provider` - Provider pour settings
- `profiles_controller_provider` - Gestion des profils
- `selected_profile_controller_provider` - Profil sélectionné

---

### Surface 3.2 : Welcome User (suite) - Pas de fichier séparé identifié

Aucun fichier nommé `createscreenshell*`, `createsettings*` trouvé en dehors de ce code consolidé dans `welcome_user_page.dart`. Le flux est géré dans un seul widget avec conditionnelles.

---

## F4 - Choix profil

### Surface 4.1 : Welcome User (choix du profil)

| Éléments | Détails |
|----------|---------|
| **Nom du fichier** | `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` (même fichier) |
| **Classe widget principale** | `WelcomeUserPage` (ConsumerStatefulWidget) + `_WelcomeUserPageState` |
| **Imports clés** | Identiques à F3 (section 3.1) |

**Composants enfants identifiés :**
1. **Wrap/ProfileAvatarChip** - Galerie de boutons profils avec label et couleur
2. **GestureDetector** - Gestion du tap pour sélection de profil
3. **FocusNode (debugLabel: 'WelcomeUserSubmit')** - Focus management TV
4. **MoviPrimaryButton** - Bouton "Continuer" après sélection

**Dépendances :**
- `profiles_controller_provider` - CRUD des profils
- `selected_profile_controller_provider` - State du profil actif

---

### Surface 4.2 : Splash Bootstrap (suite) - Pas de fichier séparé identifié

Aucun fichier nommé `choosescreen*` trouvé. Le choix de profil se fait dans le même widget `WelcomeUserPage`.

---

## Résumé global des surfaces amont

| Fichier | Widget principal | État de la surface |
|---------|------------------|-------------------|
| `splash_bootstrap_page.dart` | SplashBootstrapPage | **F1** - Préparation système |
| `overlay_splash.dart` | OverlaySplash | **F1** (réutilisé) - Initialisation |
| `launch_error_panel.dart` + `launch_recovery_banner.dart` | LaunchErrorPanel / LaunchRecoveryBanner | **F1** - Gestion erreurs |
| `auth_gate.dart` | AuthGate | **F2** - Authentification |
| `auth_otp_page.dart` | AuthOtpPage | **F2** - OTP flow |
| `welcome_user_page.dart` | WelcomeUserPage | **F3 + F4** - Création & Choix profil |

---

## Observations techniques

### Duplication de contenu :
- `SplashBootstrapPage` utilise `OverlaySplash` et `LaunchErrorPanel` pour un design cohérent
- `WelcomeUserPage` réutilise les mêmes widgets d'overlay et d'erreur
- Les composants enfants (`OverlaySplash`, `LaunchRecoveryBanner`) sont partagés entre surfaces

### Implémentation vs Contenu :
- L'implémentation est centralisée dans des widgets réutilisables (`OverlaySplash`, `LaunchErrorPanel`)
- Le contenu varie via les messages de progression et d'erreur injectés depuis les providers

---

*Généré le 4/4/2026 - Phase 6 Validation/QA/Mise en production - Vague 4, Étape 1.1*