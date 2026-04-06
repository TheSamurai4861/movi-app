# Sous-phase 2.7 - Validation finale de la phase 2

## Objectif

Clore la phase 2 `Cible UI/UX et systeme visuel` avec:
- une synthese de la cible UI finale
- un recap des decisions UI prises
- les sujets deferes a la phase architecture ou a l'implementation
- les risques restants
- la liste des artefacts produits
- un verdict explicite sur la stabilite de la phase

## Cible UI finale du tunnel

La cible UI retenue repose sur un principe simple:
- le tunnel garde une seule grammaire visuelle de bout en bout
- chaque surface rend evidente l'action principale
- les etats systeme sont traites comme partie integrante du design
- mobile et TV partagent la meme logique, avec des ecarts de densite et de focus plutot que des parcours paralleles

La cible UI se decompose ainsi:

### Surfaces de progression

- `Preparation systeme` comme splash immersif, tres bref en nominal
- `Chargement medias` comme surface de progression explicite mais sobre

### Surfaces `hero + form`

- `Auth`
- `Creation profil`

### Surfaces de selection premium

- `Choix profil`
- `Choix / ajout source`

### Etat de destination

- `Home vide` comme empty state integre a `Home`, jamais traite comme erreur

## Decisions UI principales actees

### Direction visuelle

- direction `premium sobre`
- tunnel sombre par defaut
- coherence visuelle forte avec `home`
- palette Movi conservee
- typo existante conservee
- iconographie cible via `Lucide Icons`

### Structures d'ecran

- `Preparation systeme` reste ultra compacte
- `Auth` et `Creation profil` suivent un pattern `hero + form`
- `Choix profil` fait de la galerie l'action primaire
- `Choix / ajout source` reste un hub unique, sans ecran d'erreur dedie
- `Chargement medias` est plus explicite que le splash, sans devenir technique

### Systeme de composants

- un socle commun du tunnel est explicitement defini
- les primitives a creer et a refactorer sont identifiees
- les composants critiques de feedback, loading, gallery et form sont cadres
- la duplication connue entre widgets welcome est maintenant nommee et ciblee

### Etats et feedback

- les etats sont regroupes en familles claires: progression, confirmation, information, recovery, erreur bloquante
- les regles `inline vs bloc vs surface` sont explicites
- les messages critiques restent proches de l'action concernee
- la motion reste courte, discrete et utilitaire

### Mobile et TV

- pas de tunnel TV autonome
- meme ordre logique des blocs
- TV plus aeree, plus lisible et plus focalisee
- focus comme element visuel de premier ordre sur TV

## Sujets deferes a la phase architecture

Ces sujets ne remettent pas en cause la cible UI, mais doivent etre traites techniquement:

- mapping exact entre routes actuelles et nouvelles surfaces UI
- orchestration technique de `Preparation systeme`
- machine d'etat du tunnel d'entree
- definition exacte de `home ready`
- regles d'auto-skip robustes
- conditions techniques du `chargement long`
- integration des banners et etats inline dans les flux reels
- reprise apres interruption du tunnel
- futur flow TV par QR code

## Sujets deferes a l'implementation UI

Ces sujets sont cadres, mais doivent encore etre concretises en code:

- creation de `TunnelPageShell`
- creation de `TunnelHeroBlock`
- creation de `TunnelFormShell`
- creation des galleries et cartes profil/source
- fusion et refactor des `LabeledField`
- refactor de `WelcomeHeader`, `WelcomeForm`, `IptvSourceSelectionList`, `OverlaySplash`
- encadrement final du style de focus tunnel au-dessus des primitives existantes

## Risques restants

Les principaux risques encore ouverts sont:

- reintroduire des variantes locales d'ecrans au lieu de passer par les composants communs
- laisser des ecrans welcome existants deriver visuellement pendant la migration
- traiter les erreurs differemment selon les surfaces malgre la spec commune
- sous-estimer l'impact du focus order reel sur TV
- laisser des details techniques remonter dans les messages finaux
- faire diverger la future implementation de `Choix / ajout source` entre onboarding et settings

## Artefacts produits dans cette phase

- [01_preparation_alignement_ui.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/01_preparation_alignement_ui.md)
- [02_direction_visuelle_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/02_direction_visuelle_tunnel.md)
- [03_hierarchie_visuelle_ecrans.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/03_hierarchie_visuelle_ecrans.md)
- [04_systeme_composants_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/04_systeme_composants_tunnel.md)
- [05_etats_feedback_et_motion.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/05_etats_feedback_et_motion.md)
- [06_responsive_accessibilite_et_tv.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/06_responsive_accessibilite_et_tv.md)
- [07_spec_ui_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/07_spec_ui_tunnel.md)
- [08_checklist_implementation_ui_ux.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/08_checklist_implementation_ui_ux.md)

## Verdict de stabilite

Verdict:
- la phase 2 est suffisamment stable pour passer a la phase architecture puis a l'implementation UI

Pourquoi:
- la direction visuelle est fixee
- la structure de chaque surface est definie
- le systeme de composants est identifie
- les etats et feedbacks sont cadres
- les regles mobile, accessibilite et TV sont explicites
- une spec UI consolidee et une checklist d'implementation existent

Ce qui n'est pas encore final:

- la decomposition technique finale en stories et lots de code
- le mapping architecturel exact des composants et routes
- les details d'implementation concrets des composants communs

## Recommandation de suite

La suite recommandee est:
1. phase architecture: definir orchestrateur, machine d'etat, contracts et mapping des surfaces
2. phase implementation: construire d'abord les composants tunnel communs avant de migrer les ecrans

## Conclusion

La phase 2 a converti les decisions UX du tunnel en une cible UI defendable, coherente et exploitable. Le projet peut maintenant avancer vers l'architecture et l'implementation sans re-ouvrir les arbitrages visuels majeurs, sauf changement produit volontaire.
