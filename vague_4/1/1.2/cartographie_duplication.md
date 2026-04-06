# 📊 Rapport de Cartographie de Duplication - Étape 1.2

**Généré le :** 4/5/2026  
**Phase :** Phase 6 Validation/QA/Mise en production  
**Vague :** Vague 4

---

## 🔍 Méthodologie d'analyse

Pour chaque composant identifié, identification des similarités et duplications :

- **WidgetState** - Type de widget (ConsumerWidget, StatelessWidget, StatefulWidget)
- **Taille du texte H1** - Taille et style des titres principaux
- **Couleur logo** - Couleur principale du logo/application
- **Positionnement** - Alignement et layout global

---

## 📁 F1 - Préparation système

### Surface 1.1 : Splash Bootstrap (`splash_bootstrap_page.dart`)

| Éléments                | Détails                                                                  |
| ----------------------- | ------------------------------------------------------------------------ |
| **Nom du fichier**      | `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart` |
| **WidgetState**         | ConsumerWidget (via Consumer)                                            |
| **Taille H1**           | N/A (message de progression variable via providers)                      |
| **Couleur logo**        | #XXXXXX (via OverlaySplash → currentAccentColorProvider)                 |
| **Positionnement logo** | Center(Align.topCenter) - Logo centré verticalement, spinner dessous     |

**Composants enfants identifiés :**

1. `OverlaySplash` - Affiche messages "initialisation", "scan cloud...", "configuré..." avec spinner
2. `LaunchErrorPanel` - Gère les états d'erreur avec bouton "Reessayer"
3. `AppAssets.iconAppLogoSvg` (via OverlaySplash)

**Imports utilisés :**

- **Natives :** flutter/material.dart, flutter_riverpod/flutter_riverpod.dart
- **Tierces :** go_router/go_router.dart

---

### Surface 1.2 : Overlay Splash (`overlay_splash.dart`)

| Éléments                | Détails                                                |
| ----------------------- | ------------------------------------------------------ |
| **Nom du fichier**      | `lib/src/core/widgets/overlay_splash.dart`             |
| **WidgetState**         | ConsumerWidget + \_ElapsedLoadingText (StatefulWidget) |
| **Taille H1**           | N/A (texte de progression via \_ElapsedLoadingText)    |
| **Couleur logo**        | #XXXXXX (via currentAccentColorProvider - dynamique)   |
| **Positionnement logo** | Center(Logo à 120px de haut, spinner en dessous)       |

**Composants enfants identifiés :**

1. `Stack/Center` - Logo app centré (120px)
2. `Positioned/CircularProgressIndicator` - Spinner de chargement
3. `_ElapsedLoadingText` - Texte de progression avec temps écoulé

**Imports utilisés :**

- **Natives :** flutter/cupertino.dart, flutter/material.dart
- **Tierces :** flutter_svg/flutter_svg.dart

**🔄 Duplication identifiée :** `OverlaySplash` est **réutilisé** par la Surface 1.1 comme composant enfant, avec même contenu mais implémentation centralisée dans un widget séparé (`core/widgets/` vs `features/welcome/`).

---

### Surface 1.3 : Launch Error Panel (gestion erreurs)

| Éléments           | Détails                                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| **Nom du fichier** | `lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart` + `lib/src/core/widgets/launch_error_panel.dart` |
| **WidgetState**    | StatelessWidget                                                                                                          |
| **Taille H1**      | N/A (message d'erreur variable)                                                                                          |
| **Couleur logo**   | N/A (pas de logo sur cet écran)                                                                                          |
| **Positionnement** | Center(Align.bottom - bouton "Reessayer")                                                                                |

**Composants enfants identifiés :**

1. `Text/Row` - Message d'erreur + bouton "Reessayer"
2. `Padding/Container` - Bordures et espacement

**Imports utilisés :**

- **Natives :** flutter/material.dart
- **Tierces :** go_router/go_router.dart

**🔄 Duplication identifiée :** `LaunchErrorPanel` est **réutilisé** par la Surface 1.1 et par `WelcomeUserPage`, avec même contenu mais implémentation centralisée dans `core/widgets/`.

---

## 📁 F2 - Authentification

### Surface 2.1 : Auth Gate (`auth_gate.dart`)

| Éléments           | Détails                                                 |
| ------------------ | ------------------------------------------------------- |
| **Nom du fichier** | `lib/src/core/auth/presentation/widgets/auth_gate.dart` |
| **WidgetState**    | ConsumerWidget                                          |
| **Taille H1**      | N/A (titre "Authentification 2FA" via Header)           |
| **Couleur logo**   | N/A                                                     |
| **Positionnement** | Logo app centré (si affiché), champs auth en dessous    |

**Composants enfants identifiés :**

1. `OverlaySplash` - Affichage pendant l'état "unknown"
2. Child conditionnel - Rend le child quand Supabase non configuré
3. Formulaires d'authentification (si implémenté)

**Imports utilisés :**

- **Natives :** flutter/material.dart, flutter_riverpod/flutter_riverpod.dart
- **Tierces :** go_router/go_router.dart

---

### Surface 2.2 : Auth OTP (`auth_otp_page.dart`)

| Éléments           | Détails                                                            |
| ------------------ | ------------------------------------------------------------------ |
| **Nom du fichier** | `lib/src/features/auth/presentation/auth_otp_page.dart`            |
| **WidgetState**    | ConsumerStatefulWidget + \_AuthOtpPageState (ConsumerState)        |
| **Taille H1**      | ~28px ("Authentification 2FA" via WelcomeHeader)                   |
| **Couleur logo**   | Non présent sur cette page                                         |
| **Positionnement** | Header centré en haut, formulaire email + OTP centré verticalement |

**Composants enfants identifiés :**

1. `WelcomeHeader` - Titre et sous-titre "Authentification 2FA"
2. `LabeledField (TextFormField)` - Champ email avec validation
3. `LabeledField (TextFormField)` - Champ OTP code (8 chiffres max)
4. `MoviPrimaryButton` - Bouton principal "Envoyer le code" / "Vérifier le code"
5. `LayoutBuilder/Row/Column` - Boutons secondaires

**Imports utilisés :**

- **Natives :** flutter/material.dart, flutter/services.dart, flutter_riverpod/flutter_riverpod.dart
- **Tierces :** go_router/go_router.dart

---

## 📁 F3 - Création profil

### Surface 3.1 : Welcome User (`welcome_user_page.dart`)

| Éléments           | Détails                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| **Nom du fichier** | `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`        |
| **WidgetState**    | ConsumerStatefulWidget + \_WelcomeUserPageState                             |
| **Taille H1**      | ~28px ("Bienvenue", "Créer votre profil" via WelcomeHeader)                 |
| **Couleur logo**   | #XXXXXX (via OverlaySplash → currentAccentColorProvider)                    |
| **Positionnement** | Header centré en haut, galerie profils centrée avec OverlaySplash optionnel |

**Composants enfants identifiés :**

1. `WelcomeHeader` - Titre "Créer votre profil" / "Bienvenue"
2. `OverlaySplash` - Affichage en attendant l'authentification Supabase
3. `LaunchRecoveryBanner` - Bande pour erreurs de relance
4. `CircularProgressIndicator` - Loading state des profils
5. `Text + TextSpan (Debug)` - Message d'erreur et stack trace
6. `Wrap/ProfileAvatarChip` - Galerie de boutons profils existants
7. `MoviPrimaryButton` - Bouton "Continuer"
8. `LabeledField (TextFormField)` - Champ nom utilisateur

**Imports utilisés :**

- **Natives :** flutter/material.dart, flutter/cupertino.dart, flutter_riverpod/flutter_riverpod.dart
- **Tierces :** go_router/go_router.dart

---

## 📁 F4 - Choix profil

### Surface 4.1 : Welcome User (choix du profil) - Même fichier que F3

| Éléments           | Détails                                                                             |
| ------------------ | ----------------------------------------------------------------------------------- |
| **Nom du fichier** | `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` (même fichier) |
| **WidgetState**    | ConsumerStatefulWidget + \_WelcomeUserPageState                                     |
| **Taille H1**      | ~28px ("Bienvenue", "Créer votre profil" via WelcomeHeader)                         |
| **Couleur logo**   | #XXXXXX (via OverlaySplash → currentAccentColorProvider)                            |
| **Positionnement** | Header centré en haut, galerie profils centrée comme état principal                 |

**Composants enfants identifiés :**

1. `Wrap/ProfileAvatarChip` - Galerie de boutons profils avec label et couleur
2. `GestureDetector` - Gestion du tap pour sélection de profil
3. `FocusNode (debugLabel: 'WelcomeUserSubmit')` - Focus management TV
4. `MoviPrimaryButton` - Bouton "Continuer" après sélection

**Imports utilisés :** (Identiques à F3)

- **Natives :** flutter/material.dart, flutter/cupertino.dart, flutter_riverpod/flutter_riverpod.dart
- **Tierces :** go_router/go_router.dart

---

## 📊 Différences de styles entre chaque surface

### Tableau comparatif des dimensions et positionnements

| Surface                  | WidgetState            | Taille H1 (px) | Couleur Logo        | Positionnement Logo                     | Dépendances        |
| ------------------------ | ---------------------- | -------------- | ------------------- | --------------------------------------- | ------------------ |
| **Splash Bootstrap**     | ConsumerWidget         | N/A (variable) | Dynamique (#XXXXXX) | Center(Align.topCenter)                 | Natives + GoRouter |
| **Overlay Splash**       | Consumer + State       | N/A (variable) | Dynamique (#XXXXXX) | Center (120px haut)                     | CUPRINTIVE + SVG   |
| **Launch Error Panel**   | StatelessWidget        | N/A            | N/A                 | Center(Align.bottom)                    | MoviPrimaryButton  |
| **Auth Gate**            | ConsumerWidget         | N/A            | N/A                 | Logo app centré si affiché              | Natives + GoRouter |
| **Auth OTP**             | ConsumerStatefulWidget | ~28px          | Non présent         | Header centré haut, formulaire vertical | Natives + GoRouter |
| **Welcome User (F3/F4)** | ConsumerStatefulWidget | ~28px          | Dynamique (#XXXXXX) | Header haut, galerie centrée            | Natives + GoRouter |

---

## 🔄 Duplication : Widgets identiques en contenu mais différents en implémentation

### **Catégorie 1 : Splash/Initialisation** (4 instances conceptuelles, 3 fichiers réels)

| Instance                             | Contenu                                        | Implémentation                                   | Différences de style                               |
| ------------------------------------ | ---------------------------------------------- | ------------------------------------------------ | -------------------------------------------------- |
| A - Splash Bootstrap (F1.1)          | Message de progression bootstrap home          | Via `OverlaySplash` (fichier centralisé)         | Même implémentation, contenu variable via provider |
| B - Overlay Splash (F1 - réutilisée) | Spinner + Logo + message temps écoulé          | Fichier dédié `core/widgets/overlay_splash.dart` | Identique à A, code partagé                        |
| C - Auth Gate unknown state (F2.1)   | OverlaySplash pendant "unknown" auth           | Via `OverlaySplash` (même composant)             | Identique à A/B, contenu = "inconnu"               |
| D - Welcome loading state (F3.1)     | OverlaySplash pendant chargement auth Supabase | Via `OverlaySplash` (même composant)             | Identique à A/B/C, contenu = "chargement profils"  |

**Différences de styles :**

- **Logo :** Tous utilisent le même logo via `AppAssets.iconAppLogoSvg` avec couleur dynamique
- **Spinner :** `CircularProgressIndicator` standard Flutter, positionnement centré
- **Texte :** Variable selon la phase (preload → loading home → opening home → prepared)

### **Catégorie 2 : Erreur de relance** (3 instances conceptuelles, 2 fichiers réels)

| Instance                   | Contenu                                    | Implémentation                                   | Différences de style                               |
| -------------------------- | ------------------------------------------ | ------------------------------------------------ | -------------------------------------------------- |
| A - Splash Bootstrap error | Bouton "Reessayer" + message erreur        | Via `LaunchErrorPanel` ou `LaunchRecoveryBanner` | Layout centré (top vs bottom selon usage)          |
| B - Welcome User error     | Relancer bootstrap + stack trace debug     | Via `LaunchRecoveryBanner`                       | Layout centré, contenu plus détaillé (stack trace) |
| C - Auth Gate fallback     | Rend du child quand Supabase non configuré | Conditionnel direct (pas de widget séparé)       | Pas de logo ni spinner, juste le child rendu       |

**Différences de styles :**

- **Bouton :** `MoviPrimaryButton` standard Flutter Riverpod
- **Texte :** Couleur variable (blanc par défaut, gris pour messages secondaires)
- **Positionnement :** TopCenter (splash) vs BottomCenter (error recovery)

---

## 📦 Dépendances natives vs dépendances tierces utilisées

### **Dépendances Natives (Flutter)**

| Package                                  | Utilisation principale         | Surfaces concernées                       |
| ---------------------------------------- | ------------------------------ | ----------------------------------------- |
| `flutter/material.dart`                  | Widgets Scaffold, AppBar, etc. | Toutes les surfaces                       |
| `flutter/cupertino.dart`                 | CupertinoActionSheet, etc.     | WelcomeUserPage                           |
| `flutter_riverpod/flutter_riverpod.dart` | Riverpod Provider/Consumer     | Toutes les surfaces avec state management |
| `flutter/services.dart`                  | Authentification, plateforme   | AuthOTPPage, AuthGate                     |

### **Dépendances Tierces**

| Package                          | Utilisation principale | Surfaces concernées                 |
| -------------------------------- | ---------------------- | ----------------------------------- |
| `go_router/go_router.dart`       | Navigation et routing  | Toutes les surfaces avec navigation |
| `flutter_svg/flutter_svg.dart`   | Affichage logos SVG    | OverlaySplash, SplashBootstrapPage  |
| `url_launcher/url_launcher.dart` | Ouvrir liens externes  | SettingsPage (via reusage)          |

### **Analyse du couplage dépendances :**

| Surface             | Dépendances Natives           | Dépendances Tierces | Niveau de couplage                   |
| ------------------- | ----------------------------- | ------------------- | ------------------------------------ |
| SplashBootstrapPage | Flutter + Riverpod            | GoRouter, SVG       | Élevé (routing nécessaire)           |
| OverlaySplash       | Flutter (Cupertino, Material) | SVG                 | Moyen (pas de routing direct)        |
| LaunchErrorPanel    | Flutter (Material)            | GoRouter            | Élevé (navigation error handling)    |
| AuthGate            | Flutter + Riverpod            | GoRouter            | Élevé (routing conditionnel)         |
| AuthOTPPage         | Flutter + Riverpod            | GoRouter            | Élevé (flow complet avec navigation) |
| WelcomeUserPage     | Flutter + Riverpod            | GoRouter            | Moyen (pas de routing direct)        |

**🚨 Observation :** `go_router` est présent dans toutes les surfaces, créant un couplage fort au routing. Pour les écrans purement "splash/init", le routing n'est pas toujours nécessaire (OverlaySplash peut être utilisé sans routing).

---

## 📋 Recommandations de refactoring identifiées

### **1. Réutilisation d'OverlaySplash** ✅

- **État :** Déjà bien implémenté - code partagé entre toutes les surfaces splash
