## VAGUE 4 - COMPOSANTS PARTAGES ET SURFACES AMONT

### ÉTAPE D'ORIGINE
Migration des composants UI partagés et mise à jour des quatre surfaces amont (Préparation système, Auth, Création profil, Choix profil) vers le nouvel état canonique du tunnel cible.

### SOUS-ÉTAPES
1. **Implémenter `TunnelPageShell`** – wrapper de page commun avec navigation TV/mobile et bar d'actions cibles
2. **Implémenter `TunnelHeroBlock`** – bloc héro conforme spec UI phase 2 avec titre principal et sous-titre
3. **Implémenter `TunnelFormShell`** – container formulaire avec focus ring TV et feedback inline
4. **Implémenter les feedbacks inline cibles** – messages d'erreur/succès positionnés dans le flux du formulaire
5. **Migrer `splash_bootstrap_page` vers splash cible** – logo centré, indicateur de chargement, message bas conforme spec
6. **Implémenter `PreparationSysteme` (F1)** – surface avec `TunnelPageShell`, `TunnelHeroBlock`, `TunnelFormShell` et feedbacks inline
7. **Implémenter `Auth` (F2)** – surface avec `TunnelPageShell`, `TunnelHeroBlock`, `TunnelFormShell` et feedbacks inline
8. **Implémenter `CreationProfil` (F3)** – surface avec `TunnelPageShell`, `TunnelHeroBlock`, `TunnelFormShell` et feedbacks inline
9. **Implémenter `ChoixProfil` (F4)** – surface avec `TunnelPageShell`, `TunnelHeroBlock`, `TunnelFormShell` et feedbacks inline
10. **Ajouter flag `entry_journey_ui_v2`** – bascule les nouvelles surfaces au lieu des anciennes implémentations
11. **Écrire widget tests pour `TunnelPageShell`** – vérifie structure, navigation TV/mobile, actions
12. **Écrire widget tests pour `TunnelHeroBlock`** – vérifie contenu, layout, focus management TV
13. **Écrire widget tests pour `TunnelFormShell`** – vérifie focus rings TV, feedback inline display
14. **Écrire widget tests pour les feedbacks inline** – vérifie affichage et suppression des messages
15. **Écrire integration test parcours "première connexion"** – simule startup → splash → Préparation système → Auth → Création profil
16. **Écrire integration test parcours "session expirée"** – simule ressource manquante → retour Auth avec feedback inline
17. **Écrire integration test parcours "profil requis"** – simule absence de profil → Choix profil
18. **Écrire integration test "TV focus sur formulaires et galerie profils"** – vérifie focus TV correct sur champs et options
19. **Exécuter revue visuelle mobile** – inspection des surfaces amont sur device mobile
20. **Exécuter revue visuelle TV** – inspection des surfaces amont avec contrôleur TV, navigation directionnelle

### PÉRIMÈTRE EXCLU
- Tests e2e complets de bout en bout (appartiennent à la vague finale)
- Refactoring des composants legacy non impactés par les surfaces amont
- Ajout de nouvelles fonctionnalités au-delà des specs UI phase 2
- Modifications des parcours "après Choix profil" (appartiennent aux vagues suivantes)

### CRITÈRE DE FIN
Le flag `entry_journey_ui_v2` est activé dans tous les scénarios d'entrée connus, les widget tests des composants communs passent au vert, et les quatre tests integration de parcours couvrent correctement les transitions entre Préparation système, Auth, Création profil et Choix profil.