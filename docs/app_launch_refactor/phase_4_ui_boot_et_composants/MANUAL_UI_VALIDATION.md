# Verification manuelle ciblee (Phase 4 etape 11)

## Contexte

L’environnement d’integration **ne remplace pas** un testeur humain sur
telephone, emulateur Android TV ou poste multi-ecrans. La definition de fini
accepte : **formats critiques verifies OU impossibilite documentee**.

Substituts retenus :

- **Tests widget** (tailles logiques, focus clavier, absence de debordement
  declare sur cas couverts).
- **`flutter analyze`** sur les surfaces boot / splash (absence d’erreurs
  statiques).
- **`flutter test test/core/startup/`** : derniere execution documentee ci-
  dessous.

## Preuve d’execution automatisee (CI / agent)

- `flutter test test/core/startup/` : **tous les tests passes** (158 tests au
  moment de la redaction ; le nombre exact peut evoluer avec le depot).
- `flutter analyze` sur `splash_bootstrap_page.dart` et
  `lib/src/core/startup/presentation/widgets/` : **aucun probleme signale**.

## Table surface | viewport | scenario | resultat | evidence | risque restant

```text
surface | viewport | scenario | resultat | evidence | risque restant
Chargement simple boot | 393x852 | message long, sans CTA | OK (substitut tests) | boot_simple_loading_screen_test | couleurs, animations, frame-rate : non goldens
Preparation catalogue | 393x852 | textes longs, sans CTA | OK (substitut) | boot_catalog_loading_screen_test | idem
Recovery (timeout, credentials, vide, auth, profil, source, choix, technique) | widget | mapper + panneau + pas de reasonCode brut | OK (substitut) | boot_critical_screens_widget_test + boot_screen_mapper_test | textes mapper en FR non passes par l10n sur ces ecrans (connu Phase 6)
Recovery focus Tab | tests | ordre primaire -> secondaire | OK | boot_recovery_panel_test | telecommande / D-pad Android TV non couvert
Home partiel banniere | EN l10n tests | actions + pas code brut | OK (substitut) | home_error_banner_test | locale FR a l’oeil sur device
Splash bootstrap parcours reel | device | idle -> chargements -> recovery -> Home | Non execute dans l’agent | pas de `flutter run` + pas d’APK interactif en CI | **A faire** sur emulateur ou device reel par l’equipe
Pages auth (OTP / mot de passe) | divers | navigation, champs | Partiel | test/features/auth/presentation/* | alignement Figma, zoom systeme : validation oculaire
Desktop largeur formulaires boot | large / etroit | maxWidth tokens | Partiel | BootFormTokens + pages action | fenetre ultra-etroite < 320 : rare, a glisser manuellement
Lisibilite TV / distance | TV ou grand ecran | titres recovery | Non valide en CI | impossible sans hardware | session manuelle TV ou emulateur + `README` equipe si besoin
```

## Validations impossibles dans cet environnement

- **Rendu pixel-perfect** vs Figma sans capture manuelle ou golden agree.
- **Gestes** (swipe refresh Home, retour systeme) hors scenarios de tests
  ecrits.
- **Peripheriques** : telecommande, clavier physique layout AZERTY/QWERTY,
  lecteur d’ecran complet (seulement Semantics partiels sur le logo boot).

## Checklist courte pour le developpeur (hors CI)

1. `flutter run` sur **telephone** ou emulateur **393x851** (proche 393x852) :
   observer splash, recovery si declenchee, absence de bouton sur chargement
   catalogue.
2. Meme build sur **tablette / fenetre desktop redimensionnee** : recovery
   centre, pas de formulaire boot qui deborde.
3. Si cible **TV** : parcourir recovery au **D-pad** ; confirmer que l’action
   secondaire est joignable (voir `RESPONSIVE_AND_FOCUS.md`).

## Definition de fini (etape 11)

- Les formats critiques sont **substitues par des tests** ou l’impossibilite
  est **documentee** (table ci-dessus + checklist humaine).
- Aucun probleme bloquant **nouveau** detecte par l’analyse statique sur les
  fichiers boot/splash cibles.
- La Phase 5 peut planifier le retrait du legacy en assumant une **validation
  device** complementaire par l’equipe produit / QA.

**Statut :** livre — ce document ; pas de regression bloquante detectee par les
moyens disponibles ; parcours `flutter run` **non** execute ici.
