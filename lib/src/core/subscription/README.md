## Core Subscription

Cadrage de l’étape 1 pour introduire les abonnements dans Movi sans casser les usages gratuits essentiels.

### Objectif métier

Introduire un modèle freemium lisible, cohérent et testable où l’abonnement contrôle un ensemble clair de capacités premium, tout en conservant une base gratuite suffisamment utile pour découvrir et utiliser l’application.

Ce module doit rester **métier d’abord** :
- le droit d’accès premium est un **entitlement utilisateur**
- ce n’est **pas** un `FeatureFlag`
- ce n’est **pas** une décision laissée aux widgets
- ce n’est **pas** un détail du SDK d’achat

### Pourquoi ce cadrage

Le périmètre gratuit doit préserver le cœur de l’expérience :
- consulter le catalogue
- lire une vidéo
- rechercher du contenu
- gérer une bibliothèque locale simple
- connecter et gérer localement ses sources IPTV

Le premium v1 peut ensuite monétiser :
- la continuité multi-appareils via le cloud
- des fonctionnalités locales avancées jugées à forte valeur perçue
- des fiches et espaces de découverte plus riches

### Décision produit v1

#### Gratuit
- lecture vidéo locale et navigation dans l’app
- recherche
- fiches film / série
- playlists locales
- watchlist locale
- historique local
- gestion locale des sources IPTV

#### Premium
- synchronisation cloud de la bibliothèque
- restauration cloud de la bibliothèque sur un autre appareil
- synchronisation cloud des playlists
- synchronisation cloud de l’historique et de la progression
- synchronisation cloud des favoris / watchlist
- continue watching local
- profils locaux
- contrôle parental local
- fiches saga / acteur

### Fonctionnalités premium cadrées

#### `cloudLibrarySync`
**Valeur perçue**
Retrouver automatiquement sa bibliothèque sur plusieurs appareils.

**Risque si laissé gratuit**
La principale valeur de continuité multi-appareils devient difficile à monétiser.

**Décision**
Premium v1.

#### `cloudLibraryRestore`
**Valeur perçue**
Récupérer rapidement sa bibliothèque après connexion sur un nouvel appareil.

**Risque si laissé gratuit**
La restauration devient gratuite alors qu’elle dépend de l’infrastructure cloud premium.

**Décision**
Premium v1.

#### `cloudPlaylistSync`
**Valeur perçue**
Conserver ses playlists entre mobile, desktop et TV.

**Risque si laissé gratuit**
Réduit fortement la différenciation du premium.

**Décision**
Premium v1.

#### `cloudPlaybackSync`
**Valeur perçue**
Retrouver sa progression et son historique sur plusieurs appareils.

**Risque si laissé gratuit**
Une grande partie de la valeur premium cloud est offerte gratuitement.

**Décision**
Premium v1.

#### `cloudFavoritesSync`
**Valeur perçue**
Retrouver facilement favoris et watchlist sur tous les appareils.

**Risque si laissé gratuit**
Affaiblit la proposition de valeur du compte premium lié au cloud.

**Décision**
Premium v1.

#### `localContinueWatching`
**Valeur perçue**
Retrouver rapidement ce qui a été commencé dans l’application.

**Risque si laissé gratuit**
Réduit la valeur d’organisation et de reprise de lecture du premium.

**Décision**
Premium v1.

#### `localProfiles`
**Valeur perçue**
Séparer plusieurs usages et plusieurs personnes dans la même installation.

**Risque si laissé gratuit**
Une partie importante de la personnalisation locale devient non monétisée.

**Décision**
Premium v1.

#### `localParentalControls`
**Valeur perçue**
Sécuriser l’accès aux contenus et adapter l’usage familial.

**Risque si laissé gratuit**
Une fonctionnalité à forte valeur perçue pour les foyers reste entièrement offerte.

**Décision**
Premium v1.

#### `extendedDiscoveryDetails`
**Valeur perçue**
Accéder à des fiches saga / acteur enrichissant l’exploration du catalogue.

**Risque si laissé gratuit**
Diminue la capacité du premium à proposer une expérience de découverte plus riche.

**Décision**
Premium v1.

### Hors périmètre v1
- blocage de la lecture vidéo locale
- blocage de la recherche
- blocage des fiches film / série
- blocage de la bibliothèque locale simple
- promotions complexes
- offres multiples avancées
- pricing expérimental
- logique marketing détaillée

### Offre recommandée

#### Produit
Un seul produit logique : `Movi Premium`.

#### Variantes commerciales
- mensuel
- annuel

#### Positionnement
“Débloque la continuité, la personnalisation et les fiches enrichies de Movi.”

### Vocabulaire métier à conserver

Le vocabulaire doit rester stable avant l’implémentation.

#### `PremiumFeature`
Capacité premium adressable explicitement par le métier.

Valeurs cadrées pour v1 :
- `cloudLibrarySync`
- `cloudLibraryRestore`
- `cloudPlaylistSync`
- `cloudPlaybackSync`
- `cloudFavoritesSync`
- `localContinueWatching`
- `localProfiles`
- `localParentalControls`
- `extendedDiscoveryDetails`

#### `SubscriptionStatus`
État métier d’abonnement du compte courant.

Valeurs cadrées pour v1 :
- `unknown`
- `inactive`
- `active`
- `gracePeriod`
- `expired`

#### `BillingAvailability`
Disponibilité technique de l’achat ou de la restauration sur la plateforme courante.

Valeurs cadrées pour v1 :
- `available`
- `restoreOnly`
- `unavailable`

#### `SubscriptionEntitlement`
Projection métier des droits réellement accordés à l’utilisateur.

Un entitlement doit répondre à une question simple :
“L’utilisateur peut-il accéder à telle capacité premium maintenant ?”

### Familles de fonctionnalités premium

Pour éviter de mélanger des règles différentes, les fonctionnalités premium sont réparties en deux familles.

#### Capacités premium cloud
Elles nécessitent :
- un entitlement premium actif
- un utilisateur authentifié
- et, si applicable, une préférence utilisateur activant la synchronisation

Fonctionnalités concernées :
- `cloudLibrarySync`
- `cloudLibraryRestore`
- `cloudPlaylistSync`
- `cloudPlaybackSync`
- `cloudFavoritesSync`

#### Capacités premium locales
Elles nécessitent :
- un entitlement premium actif

Fonctionnalités concernées :
- `localContinueWatching`
- `localProfiles`
- `localParentalControls`
- `extendedDiscoveryDetails`

### Règles métier explicites

#### Règle 1 — l’abonnement ne remplace pas les préférences utilisateur
Une préférence exprime ce que l’utilisateur souhaite.
Un entitlement exprime ce que le compte a le droit de faire.
Ces deux notions ne doivent pas être fusionnées.

#### Règle 2 — les fonctionnalités cloud premium ont une règle d’accès explicite
Une capacité cloud premium est active uniquement si :
- l’utilisateur souhaite le comportement concerné quand une préférence existe
- l’utilisateur est authentifié
- l’utilisateur possède l’entitlement premium requis

Formule métier de référence pour la sync cloud :

`effectiveCloudSyncEnabled = userWantsCloudSync && isAuthenticated && hasCloudSyncEntitlement`

#### Règle 3 — les fonctionnalités locales premium ne dépendent pas de l’auth cloud
Une capacité premium locale est active si :
- l’utilisateur possède l’entitlement premium requis

Formule métier de référence :

`effectiveLocalPremiumEnabled = hasRequiredEntitlement`

#### Règle 4 — perdre le premium ne détruit pas les données gratuites existantes
L’expiration ou l’absence d’abonnement :
- désactive l’accès aux capacités premium
- ne supprime pas la bibliothèque locale gratuite
- ne bloque pas la lecture locale gratuite
- ne casse pas la navigation gratuite

#### Règle 5 — l’UI ne décide pas seule du premium
Les écrans affichent l’offre, les erreurs et les appels à l’action.
La décision d’accès appartient au métier.

### Décisions d’architecture déjà figées

- Ne pas stocker l’abonnement dans `FeatureFlags`.
- Ne pas disperser des `if premium` dans les widgets métier.
- Ne pas créer une classe fourre-tout de type `SubscriptionManager`.
- Prévoir un futur module `core/subscription/` séparé par responsabilités :
  - `domain`
  - `application`
  - `data`
  - `presentation`

### Critères d’acceptation de l’étape 1

L’étape 1 est terminée si :
- le périmètre gratuit vs premium est décidé
- le vocabulaire métier est stabilisé
- les règles d’accès cloud et local sont explicitées
- le premium v1 ne casse pas les usages gratuits essentiels
- l’implémentation future peut être branchée sans mélanger abonnement, auth, préférences et UI

### Questions volontairement laissées pour l’étape suivante

- quel provider d’achat concret sera retenu
- quelles plateformes supporteront l’achat natif en v1
- à quels écrans exacts le paywall apparaîtra
- quel wording final sera utilisé dans les localisations
