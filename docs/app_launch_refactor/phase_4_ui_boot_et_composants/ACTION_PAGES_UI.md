# Phase 4 - Etape 7 - Pages d'action raccordees

## Objectif

Aligner les surfaces **connexion**, **OTP**, **mot de passe oublie**,
**mise a jour mot de passe**, **welcome profil** (selection + creation premier
profil), **welcome source** (activation Xtream) et **welcome form** (ajout
source URL) sur les tokens boot (`BootFormTokens`) : champs ~300px, boutons
principaux ~250x50, radius 25 — **sans** modifier les controllers, validations
ni les appels `executeBootAction` / navigation existants.

## Table page | composant remplace | logique conservee | action boot | responsive | test

```text
auth_password_page | AppLabeledTextField decoration + largeur ; MoviPrimaryButton style | AuthPasswordController, signIn, focus TV | executeBootAction apres auth | ConstrainedBox existant + constrainTextField 300 | analyse + manuel
auth_forgot_password_page | idem email + bouton | AuthForgotPasswordController | navigation pop/go | maxWidth 480 colonne | idem
auth_otp_page | champs email/code + bouton principal | AuthOtpController | executeBootAction auth_completed | maxWidth 480 | idem
auth_update_password_page | deux champs + boutons | submitter Supabase | go authOtp | maxWidth 480 | idem
welcome_user_page | TextFormField nom + 2x MoviPrimaryButton | FirstName, createProfile, _runBootAction | BootActionIntent.retry | constrain 300 / 250 | idem
welcome_source_page | 4 TextField activation + Activer | Xtream connect, focus | — | constrain 300 / 250 | idem
welcome_form | 3 TextFormField + bouton Ajouter | welcomeController, iptv connect | navigation home / snack | constrain | idem
welcome_source_select_page | (liste uniquement) | — | executeBootAction | SettingsContentWidth deja | aucun changement UI champs
```

## Fichiers touches (resume)

| Fichier | Changement |
|---------|------------|
| `lib/src/features/auth/presentation/auth_password_page.dart` | `BootFormTokens` champs + bouton connexion |
| `lib/src/features/auth/presentation/auth_forgot_password_page.dart` | idem |
| `lib/src/features/auth/presentation/auth_otp_page.dart` | idem |
| `lib/src/features/auth/presentation/auth_update_password_page.dart` | idem |
| `lib/src/features/welcome/presentation/pages/welcome_user_page.dart` | Champ creation profil + boutons |
| `lib/src/features/welcome/presentation/pages/welcome_source_page.dart` | Formulaire activation |
| `lib/src/features/welcome/presentation/widgets/welcome_form.dart` | Formulaire URL/username/password |

## Inscription

Pas de page d'inscription separee dans `lib/src/features/auth` : le flux passe
par OTP / mot de passe selon les routes existantes.

## Definition de fini

- [x] Style champs / boutons principal aligne Figma boot sur les pages listees.
- [x] Logique metier et handlers inchanges.
- [x] Largeurs formulaires bornees sur desktop via helpers centrés.
