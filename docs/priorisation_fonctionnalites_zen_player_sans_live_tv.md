# Priorisation des fonctionnalités – App Lecteur IPTV Flutter (hors Live TV)

## 1. Résumé exécutif

Analyse réalisée sur l’export des discussions utilisateurs, **en excluant volontairement toutes les demandes liées au Live TV** : zapping, liste des chaînes, EPG, preview de chaînes, contrôle du direct, replay live, multi-view de flux live et assimilés.

- **Nombre total d’idées détectées après filtrage Live TV :** 29
- **Nombre d’idées retenues :** 16
- **Top 5 des fonctionnalités les plus importantes :**
  1. Recherche, filtres et découverte VOD/Séries
  2. Contrôle parental + profils sécurisés
  3. Téléchargements en arrière-plan + centre de téléchargements
  4. Suivi de visionnage + progression + contrôle de l’autoplay
  5. Gestion des sources, profils et démarrage
- **Principaux problèmes utilisateurs détectés :**
  - Difficulté à trouver rapidement le bon film / la bonne série
  - Trop de doublons liés aux langues, qualités ou versions
  - Contrôle parental insuffisant pour un usage familial serein
  - Téléchargements jugés peu pratiques ou trop cachés
  - Manque de continuité d’usage entre profils, appareils et sessions
  - Paramètres de lecture pas assez persistants ni intelligents
- **Opportunités produit majeures :**
  - Positionner l’app comme un lecteur VOD / séries premium, orienté confort
  - Réduire la friction dans la découverte et la lecture
  - Renforcer la rétention via historique, progression, sync et personnalisation
  - Mieux couvrir les usages famille, offline et multi-profils

## 2. Méthode d’analyse

Les idées ont été extraites à partir des discussions utilisateurs, puis regroupées par **problème produit** plutôt que par message individuel.

### Principes appliqués
- Fusion des doublons quand plusieurs messages exprimaient le même besoin sous des formes différentes
- Reformulation en fonctionnalités actionnables pour une équipe produit / dev
- Exclusion des demandes :
  - liées au **Live TV**
  - liées au **contenu fourni** plutôt qu’au lecteur
  - trop floues, trop niche, trop coûteuses ou hors cadre légal / produit

### Logique de priorisation
- **P0** : fort impact, fréquence élevée, manque important dans l’expérience actuelle
- **P1** : très utile, fort gain UX ou rétention, mais derrière les irritants majeurs
- **P2** : amélioration utile mais non bloquante
- **P3** : nice-to-have, différenciation ou expérimentation

## 3. Tableau synthétique des fonctionnalités

| Fonctionnalité | Priorité | Impact | Effort | Fréquence | Catégorie | Résumé |
|---|---|---:|---:|---:|---|---|
| Recherche, filtres et découverte enrichie | P0 | 5 | 4 | 5 | Découverte | Filtrer par langue, genre, note, date, qualité, acteur, tags cliquables |
| Contrôle parental + profils sécurisés | P0 | 5 | 3 | 4 | Sécurité / famille | PIN, verrouillage catégories sensibles, profil admin, réglages protégés |
| Téléchargements en arrière-plan + centre dédié | P0 | 5 | 4 | 4 | Offline | Téléchargement persistant, historique visible, dossier configurable |
| Suivi de visionnage + progression + autoplay maîtrisé | P0 | 5 | 3 | 4 | Rétention | Désactiver autoplay, badge vu, reprise, progression par épisode |
| Gestion des sources, profils et démarrage | P0 | 4 | 4 | 4 | Architecture / UX | Source par profil, catégorie de démarrage, chargement sélectif |
| Préférences de lecture persistantes | P1 | 4 | 2 | 4 | Player UX | Langue, ratio, zoom, ajustement, qualité préférée mémorisés |
| Sélection du lecteur par type de contenu | P1 | 4 | 3 | 3 | Compatibilité | Choisir le player selon VOD, série, bande-annonce |
| Sync Trakt / historique externe | P1 | 4 | 3 | 3 | Rétention / écosystème | Synchroniser l’avancement films et séries |
| Favoris avancés et listes personnalisées | P1 | 4 | 3 | 3 | Organisation | Favoris plus visibles, listes perso, masquage d’éléments |
| Métadonnées visibles sur les cartes | P1 | 4 | 2 | 3 | Découverte | Notes, âge, qualité, titre sous l’affiche |
| UX catalogue / home plus personnalisable | P2 | 3 | 3 | 3 | UI / personnalisation | Home plus clair, sections ajustables, meilleurs layouts |
| Sous-titres avancés | P2 | 3 | 3 | 2 | Accessibilité | Taille, couleur, position, délai |
| Casting / AirPlay pour VOD et séries | P2 | 3 | 5 | 2 | Écosystème | Diffusion vers TV / appareils compatibles |
| Authentification locale simplifiée | P2 | 3 | 3 | 2 | Sécurité / confort | Biométrie, PIN système, reconnexion plus simple |
| Compatibilité Fire TV / devices non-Google | P3 | 3 | 4 | 2 | Plateforme | Réduire la dépendance aux services Google |
| Recommandations, trailers et découverte premium | P3 | 2 | 4 | 2 | Différenciation | Suggestions “pour vous”, trailers auto, découverte enrichie |

## 4. Détail des fonctionnalités par priorité

### P0

#### Recherche, filtres et découverte enrichie
- **Pourquoi c’est prioritaire :** c’est l’irritant le plus transversal côté films et séries.
- **Problème utilisateur résolu :** trop de résultats doublonnés, difficulté à distinguer les bonnes versions, exploration lente.
- **Description fonctionnelle :**
  - filtres par langue audio
  - genres cliquables depuis les fiches
  - tri par note, date, popularité
  - affichage de la qualité et de la langue directement dans les résultats
  - possibilité d’étendre la recherche aux acteurs, genres et tags
- **Bénéfice produit :** accès plus rapide au bon contenu, meilleure qualité perçue.
- **Complexité estimée :** Moyenne à élevée
- **Dépendances :** qualité des métadonnées, index local, cache.
- **Packages / ressources Flutter utiles :** `drift`, `flutter_riverpod`, `go_router`
- **Notes d’implémentation :** commencer par langue + genre + qualité visible, puis enrichir la recherche avancée.
- **Origine :** synthèse de demandes sur filtres langue, genres cliquables et meilleure recherche films/séries.

#### Contrôle parental + profils sécurisés
- **Pourquoi c’est prioritaire :** besoin concret, récurrent, important pour l’usage familial.
- **Problème utilisateur résolu :** accès trop facile à des catégories sensibles ou aux réglages critiques.
- **Description fonctionnelle :**
  - PIN par profil
  - profil administrateur
  - verrouillage de catégories sensibles
  - protection des réglages sources et options critiques
- **Bénéfice produit :** app plus rassurante pour les familles, moins de support, meilleure confiance.
- **Complexité estimée :** Moyenne
- **Dépendances :** stockage sécurisé, modèle de rôles profils.
- **Packages / ressources Flutter utiles :** `local_auth`, `flutter_secure_storage`
- **Notes d’implémentation :** séparer verrou contenu, verrou réglages et verrou changement de source.
- **Origine :** synthèse de demandes sur PIN, catégories adultes, profils enfants et profil admin.

#### Téléchargements en arrière-plan + centre dédié
- **Pourquoi c’est prioritaire :** fonctionnalité directement utile et fortement attendue.
- **Problème utilisateur résolu :** téléchargement fragile, peu visible, dépendant de l’app ouverte.
- **Description fonctionnelle :**
  - téléchargements en tâche de fond avec notifications de progression
  - écran “Téléchargements” dédié
  - accès aux contenus téléchargés avec visuel, titre et épisode
  - choix du répertoire de téléchargement
  - confirmation avant suppression
- **Bénéfice produit :** meilleure expérience offline, confort d’usage nettement supérieur.
- **Complexité estimée :** Élevée
- **Dépendances :** permissions stockage, reprise de tâche, gestion du disque selon plateforme.
- **Packages / ressources Flutter utiles :** `background_downloader`, `path_provider`
- **Notes d’implémentation :** prévoir reprise après redémarrage et gestion propre des erreurs d’espace disque.
- **Origine :** demandes explicites sur téléchargements films/séries en arrière-plan, rubrique dédiée et choix du dossier cible.

#### Suivi de visionnage + progression + autoplay maîtrisé
- **Pourquoi c’est prioritaire :** fort effet rétention, frustration très visible sur les séries.
- **Problème utilisateur résolu :** perte de repères, épisodes qui s’enchaînent sans contrôle, reprise peu claire.
- **Description fonctionnelle :**
  - option pour désactiver l’autoplay de l’épisode suivant
  - badge “vu” et pourcentage de progression
  - ligne “reprendre la lecture”
  - logique d’épisode précédent / navigation plus pratique dans les saisons
- **Bénéfice produit :** meilleure continuité d’usage, moins d’irritation, plus de fidélité.
- **Complexité estimée :** Moyenne
- **Dépendances :** stockage local de progression, structure série / saison / épisode.
- **Packages / ressources Flutter utiles :** `drift`, `shared_preferences`
- **Notes d’implémentation :** définir un seuil de complétion clair, par exemple “vu” à 95%.
- **Origine :** synthèse de demandes sur autoplay, reprise, badge vu et navigation dans les épisodes.

#### Gestion des sources, profils et démarrage
- **Pourquoi c’est prioritaire :** améliore l’entrée dans l’app et réduit beaucoup de friction.
- **Problème utilisateur résolu :** mauvaise catégorie au lancement, changement de source manuel, expérience non adaptée au profil.
- **Description fonctionnelle :**
  - source par profil
  - catégorie par défaut configurable
  - mémorisation de la dernière section consultée
  - chargement sélectif des contenus souhaités au démarrage
  - retour visuel plus clair pendant les chargements
- **Bénéfice produit :** démarrage plus rapide, expérience plus personnelle, meilleure clarté.
- **Complexité estimée :** Moyenne à élevée
- **Dépendances :** modèle profil/source, cache, persistance.
- **Packages / ressources Flutter utiles :** `flutter_riverpod`, `shared_preferences`, `drift`
- **Notes d’implémentation :** tracer les temps de chargement et les abandons pour valider les gains.
- **Origine :** synthèse de demandes sur source par profil, catégorie par défaut, dernière catégorie mémorisée et chargement sélectif.

### P1

#### Préférences de lecture persistantes
- **Pourquoi c’est prioritaire :** quick win à fort impact quotidien.
- **Problème utilisateur résolu :** devoir reconfigurer souvent langue, ratio, zoom ou ajustement.
- **Description fonctionnelle :** mémoriser les préférences de lecture globales et, si utile, les surcharger par contenu ou profil.
- **Bénéfice produit :** expérience plus stable, plus personnelle, moins répétitive.
- **Complexité estimée :** Faible à moyenne
- **Dépendances :** persistance locale.
- **Packages / ressources Flutter utiles :** `shared_preferences`, `drift`
- **Notes d’implémentation :** distinguer préférences globales et overrides ponctuels.
- **Origine :** demandes sur sauvegarde du mode d’ajustement, ratio et préférences similaires.

#### Sélection du lecteur par type de contenu
- **Pourquoi c’est prioritaire :** besoin concret pour certains codecs, trailers ou types de médias.
- **Problème utilisateur résolu :** le lecteur natif n’est pas toujours le plus adapté.
- **Description fonctionnelle :** choisir le lecteur par type de contenu : VOD, séries, bande-annonces, voire player externe si nécessaire.
- **Bénéfice produit :** meilleure compatibilité et moins de frustration.
- **Complexité estimée :** Moyenne
- **Dépendances :** abstraction player, intégration native selon plateforme.
- **Packages / ressources Flutter utiles :** `media_kit`, `video_player_media_kit`
- **Notes d’implémentation :** prévoir un fallback automatique si le lecteur préféré échoue.
- **Origine :** demandes sur lecteur externe et choix du lecteur selon le contenu.

#### Sync Trakt / historique externe
- **Pourquoi c’est prioritaire :** forte valeur pour les utilisateurs avancés et multi-appareils.
- **Problème utilisateur résolu :** historique et progression enfermés dans l’app locale.
- **Description fonctionnelle :** connexion Trakt pour synchroniser progression, films vus, séries suivies et éventuellement watchlists.
- **Bénéfice produit :** meilleur écosystème, rétention renforcée, réduction du coût de changement.
- **Complexité estimée :** Moyenne
- **Dépendances :** OAuth, mapping contenu, fiabilité métadonnées.
- **Packages / ressources Flutter utiles :** OAuth Flutter standard + persistance sécurisée
- **Notes d’implémentation :** commencer par sync progression et “watched”, puis watchlist ensuite.
- **Origine :** demande récurrente et ancienne sur l’intégration Trakt.

#### Favoris avancés et listes personnalisées
- **Pourquoi c’est prioritaire :** améliore l’organisation sur gros catalogues.
- **Problème utilisateur résolu :** favoris trop limités ou peu visibles.
- **Description fonctionnelle :**
  - rendre l’ajout aux favoris plus visible
  - créer des listes personnalisées
  - masquer certains contenus ou variantes non désirées
- **Bénéfice produit :** meilleure appropriation, moins de bruit dans les catalogues.
- **Complexité estimée :** Moyenne
- **Dépendances :** modèle de listes, persistance locale.
- **Packages / ressources Flutter utiles :** `drift`, `flutter_riverpod`
- **Notes d’implémentation :** différencier favoris simples et listes intelligentes.
- **Origine :** synthèse autour des besoins d’organisation, de favoris et de masquage.

#### Métadonnées visibles sur les cartes
- **Pourquoi c’est prioritaire :** effet premium immédiat pour un coût raisonnable.
- **Problème utilisateur résolu :** besoin d’ouvrir trop de fiches pour choisir quoi regarder.
- **Description fonctionnelle :** afficher directement sur les cartes : note, âge recommandé, qualité, langue et éventuellement titre sous l’affiche.
- **Bénéfice produit :** choix plus rapide, meilleure lisibilité catalogue.
- **Complexité estimée :** Faible
- **Dépendances :** métadonnées disponibles.
- **Packages / ressources Flutter utiles :** UI interne, pas de dépendance critique.
- **Notes d’implémentation :** rendre ces badges activables/désactivables dans les réglages.
- **Origine :** demandes sur notes, âge, qualité et titres sous les affiches.

### P2

#### UX catalogue / home plus personnalisable
- **Pourquoi c’est prioritaire :** utile pour améliorer la perception premium, sans être bloquant.
- **Problème utilisateur résolu :** home parfois mal hiérarchisé, sections peu adaptées aux préférences.
- **Description fonctionnelle :** permettre un meilleur réglage des sections affichées, de la taille des cartes et de certains layouts selon le device.
- **Bénéfice produit :** app plus agréable et plus adaptable.
- **Complexité estimée :** Moyenne
- **Dépendances :** design system, responsive layout.
- **Packages / ressources Flutter utiles :** `go_router`, `flutter_riverpod`
- **Notes d’implémentation :** partir sur des presets plutôt qu’une personnalisation totalement libre.
- **Origine :** synthèse de suggestions sur home, hiérarchie des contenus et adaptation iPad / portrait.

#### Sous-titres avancés
- **Pourquoi c’est prioritaire :** amélioration utile pour le confort et l’accessibilité.
- **Problème utilisateur résolu :** sous-titres peu lisibles ou mal placés.
- **Description fonctionnelle :** réglages de taille, style, couleur, position et délai.
- **Bénéfice produit :** meilleur confort de visionnage.
- **Complexité estimée :** Moyenne
- **Dépendances :** moteur de sous-titres, player choisi.
- **Packages / ressources Flutter utiles :** `chewie`, `subtitle`
- **Notes d’implémentation :** proposer d’abord quelques presets accessibles.
- **Origine :** déduction raisonnable issue des besoins de personnalisation du player.

#### Casting / AirPlay pour VOD et séries
- **Pourquoi c’est prioritaire :** attendu dans une app média premium mais non vital à court terme.
- **Problème utilisateur résolu :** difficulté à basculer une lecture VOD/série vers un écran secondaire.
- **Description fonctionnelle :** diffusion vers appareils compatibles, avec état de session et contrôles de base.
- **Bénéfice produit :** meilleure intégration salon / foyer.
- **Complexité estimée :** Élevée
- **Dépendances :** SDK natifs, compatibilité formats, permissions réseau local.
- **Packages / ressources Flutter utiles :** intégrations natives à évaluer au cas par cas.
- **Notes d’implémentation :** MVP recommandé sur un seul protocole d’abord.
- **Origine :** demandes sur cast et AirPlay, requalifiées hors Live TV.

#### Authentification locale simplifiée
- **Pourquoi c’est prioritaire :** gain de confort, cohérent avec profils et sécurité.
- **Problème utilisateur résolu :** reconnexion peu fluide, manque de sécurité locale simple.
- **Description fonctionnelle :** activer la connexion locale via biométrie, PIN système ou équivalent selon plateforme.
- **Bénéfice produit :** login plus rapide, perception plus premium.
- **Complexité estimée :** Moyenne
- **Dépendances :** biométrie / PIN OS, stockage sécurisé.
- **Packages / ressources Flutter utiles :** `local_auth`, `flutter_secure_storage`
- **Notes d’implémentation :** à lier au profil principal ou à des profils protégés.
- **Origine :** demande sur authentification par clé / mot de passe appareil / PIN système.

### P3

#### Compatibilité Fire TV / devices non-Google
- **Pourquoi c’est prioritaire :** sujet réel mais plateforme-spécifique.
- **Problème utilisateur résolu :** incompatibilités liées aux Google services sur certains appareils.
- **Description fonctionnelle :** audit et adaptation pour limiter les dépendances GMS quand elles ne sont pas nécessaires.
- **Bénéfice produit :** meilleure couverture matériel.
- **Complexité estimée :** Moyenne à élevée
- **Dépendances :** plugins compatibles, tests réels sur devices.
- **Packages / ressources Flutter utiles :** audit plugin par plugin.
- **Notes d’implémentation :** traiter cela comme un chantier compatibilité, pas comme une simple feature.
- **Origine :** demande explicite sur Fire TV.

#### Recommandations, trailers et découverte premium
- **Pourquoi c’est prioritaire :** intéressant pour différencier, mais après stabilisation du socle.
- **Problème utilisateur résolu :** découverte encore trop passive.
- **Description fonctionnelle :** suggestions “pour vous”, trailers automatiques optionnels, meilleure mise en avant des contenus proches des goûts utilisateur.
- **Bénéfice produit :** meilleure rétention et sensation de produit moderne.
- **Complexité estimée :** Moyenne à élevée
- **Dépendances :** analytics, historique, métadonnées.
- **Packages / ressources Flutter utiles :** analytics + persistance + player.
- **Notes d’implémentation :** commencer par recommandations simples basées sur l’historique local.
- **Origine :** synthèse de demandes sur trailers auto, sections enrichies et découverte plus intelligente.

## 5. Idées écartées ou non retenues

- **Toutes les demandes Live TV** : hors périmètre demandé
  - zapping
  - contrôle du direct / timeshift
  - EPG live
  - liste / overlay chaînes
  - multi-view de flux live
  - replay live
- **Demandes de contenu spécifique** : hors sujet, le lecteur ne contrôle pas le catalogue fournisseur
- **Fonctions trop floues ou isolées** : non priorisées faute de valeur démontrée
- **Fonctions potentiellement risquées côté produit / légal** : écartées
- **Portages plateforme trop coûteux à court terme** : WebOS / LG TV / Linux gardés hors scope immédiat

## 6. Recommandation roadmap

### Vague 1 : quick wins
- Désactiver l’autoplay épisode suivant
- Mémoriser langue, ratio, zoom, ajustement
- Afficher note, qualité, langue et titre plus clairement
- Ajouter filtres langue + genre + qualité visible
- Ajouter catégorie de démarrage configurable
- Ajouter confirmation avant suppression d’un téléchargement

### Vague 2 : fonctionnalités structurantes
- Refonte de la recherche / découverte VOD-Séries
- Téléchargements en arrière-plan + centre dédié
- Contrôle parental + profil admin + PIN par profil
- Gestion source par profil
- Historique, progression et reprise avancée
- Choix du lecteur selon le type de contenu

### Vague 3 : optimisations et différenciation
- Sync Trakt
- Listes personnalisées et favoris avancés
- Casting / AirPlay
- Recommandations personnalisées
- Auth locale simplifiée
- Compatibilité Fire TV renforcée

## 7. Ressources techniques Flutter

### Vidéo / player
- Flutter `video_player` (officiel)  
  https://docs.flutter.dev/cookbook/plugins/play-video
- `media_kit`  
  https://pub.dev/packages/media_kit
- `media_kit_video`  
  https://pub.dev/packages/media_kit_video
- `video_player_media_kit`  
  https://pub.dev/packages/video_player_media_kit
- `chewie`  
  https://pub.dev/packages/chewie

### Téléchargements / fichiers / persistance
- `background_downloader`  
  https://pub.dev/packages/background_downloader
- `path_provider`  
  https://pub.dev/packages/path_provider
- `shared_preferences`  
  https://pub.dev/packages/shared_preferences
- `drift`  
  https://pub.dev/packages/drift
- `drift_flutter`  
  https://pub.dev/packages/drift_flutter

### Sécurité / profils
- `flutter_secure_storage`  
  https://pub.dev/packages/flutter_secure_storage
- `local_auth`  
  https://pub.dev/packages/local_auth

### État / navigation
- `flutter_riverpod`  
  https://pub.dev/packages/flutter_riverpod
- `go_router`  
  https://pub.dev/packages/go_router

### Accessibilité / qualité UI
- Flutter accessibility  
  https://docs.flutter.dev/ui/accessibility
- Accessibility widgets / Semantics  
  https://docs.flutter.dev/ui/widgets/accessibility
- Accessibility testing  
  https://docs.flutter.dev/ui/accessibility/accessibility-testing

### Analytics / instrumentation
- Firebase Analytics for Flutter  
  https://firebase.google.com/docs/analytics/flutter/get-started
- Firebase for Flutter  
  https://firebase.google.com/docs/flutter

### Sous-titres
- `subtitle`  
  https://pub.dev/packages/subtitle

## Recommandation finale

Si l’objectif est de **maximiser la valeur produit hors Live TV**, l’ordre conseillé est :

1. **Recherche / filtres / découverte**
2. **Contrôle parental + profils sécurisés**
3. **Téléchargements solides**
4. **Progression / reprise / autoplay**
5. **Gestion des profils et des sources**
6. **Sync et différenciation premium**

Ce séquencement améliore à la fois la **perception premium**, la **rétention**, la **qualité d’usage quotidienne** et la **capacité de monétisation** sans disperser l’équipe sur des sujets live hors scope.
