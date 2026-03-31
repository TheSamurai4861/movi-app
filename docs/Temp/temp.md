1. **Analyse rapide**

La roadmap doit rester alignée avec l’architecture actuelle : Movi est déjà structuré par responsabilités métier, avec une auth non bloquante, une sync cloud amorcée tôt via `LibraryCloudSyncBootstrapper`, et une préférence de sync déjà persistée. Cela rend très naturel un premium centré sur les **entitlements cloud** plutôt que sur un blocage global de l’app.   

La bonne direction, conforme à `rules.md`, est donc de créer un **module métier d’abonnement** séparé, puis de brancher progressivement les fonctions cloud existantes dessus, sans injecter de logique premium directement dans l’UI ni dans `FeatureFlags`. `rules.md` insiste justement sur la séparation métier / technique, la responsabilité unique, l’inversion de dépendance et l’explicitation de la complexité.   

---

2. **Règles de `rules.md` appliquées**

* **Le métier au centre, détails techniques à l’extérieur** : le SDK d’achat ne doit pas fuiter dans Library, Settings ou Player. 
* **1 module = 1 rôle clair / 1 classe = 1 responsabilité** : éviter une grosse classe unique qui achète, restaure, cache, valide et pilote l’UI.  
* **Dépendre d’abstractions** : les features dépendent d’un contrat `SubscriptionRepository`, pas d’une implémentation store/vendor. 
* **Rendre la complexité explicite** : distinguer préférence utilisateur, entitlement premium, auth et état effectif. 
* **Testabilité** : chaque étape doit introduire une surface testable isolée avant de brancher l’UI. 

---

3. **Modifications proposées**

### Roadmap en 5 étapes

#### Étape 1 — Cadrer le modèle métier d’abonnement

Objectif : définir **ce qui est premium**, **pourquoi**, et **comment cela se traduit en droits d’accès**.

À produire :

* la liste finale gratuit vs premium
* un vocabulaire métier stable :

  * `PremiumFeature`
  * `SubscriptionStatus`
  * `SubscriptionEntitlement`
  * `BillingAvailability`
* la règle explicite d’accès, par exemple :

  * `canUseCloudSync`
  * `canRestoreCloudLibrary`
  * `canUseAdvancedCloudFeatures`

Décisions à figer :

* premium v1 = sync cloud et restauration multi-appareils
* gratuit = lecture, bibliothèque locale, playlists locales, watchlist locale, contrôle parental local
* pas de blocage global de l’app

Critère de sortie :

* on a un contrat métier simple, lisible, sans dépendance au SDK de paiement

#### Étape 2 — Introduire le module transverse `core/subscription`

Objectif : créer une base d’architecture propre avant tout branchement produit.

À prévoir :

* `domain/`

  * entités/statuts d’abonnement
  * interface `SubscriptionRepository`
* `application/`

  * `GetCurrentSubscription`
  * `PurchaseSubscription`
  * `RestoreSubscription`
  * `CanAccessPremiumFeature`
* `presentation/`

  * providers Riverpod
  * état d’UI d’achat/restauration
* `data/`

  * cache local d’état d’entitlement
  * implémentation provider/store plus tard

Règle clé :

* ne pas mettre l’abonnement dans `FeatureFlags`, car ce sont des toggles d’environnement, pas des droits utilisateur dynamiques. L’état d’abonnement doit rester un **état métier utilisateur** distinct. 

Critère de sortie :

* le projet compile avec un module d’abonnement vide mais bien structuré et injectable

#### Étape 3 — Brancher le provider d’achat multi-plateformes

Objectif : intégrer la couche technique d’achat sans contaminer le reste du code.

À faire :

* choisir l’adapter multi-plateformes retenu
* implémenter `SubscriptionRepository`
* gérer :

  * chargement des offres
  * achat
  * restauration
  * rafraîchissement de l’état premium
  * fallback “billing indisponible” selon plateforme
* prévoir les différences de plateformes dans l’infrastructure uniquement

Point d’attention :

* sur desktop non supporté pour achat natif, ne pas casser l’app ; exposer proprement un état “achat indisponible ici” mais conserver la lecture/restauration si possible

Critère de sortie :

* depuis une API métier unique, on peut :

  * lire le statut d’abonnement
  * acheter
  * restaurer
  * détecter les erreurs techniques vs utilisateur

#### Étape 4 — Connecter les entitlements aux fonctionnalités existantes

Objectif : faire respecter le premium là où il a de la valeur, sans multiplier les `if` dans toute l’UI.

Cibles prioritaires :

* `LibraryCloudSyncBootstrapper`
* `library_cloud_sync_providers`
* `CloudSyncPreferences`
* éventuels flux de sync plus larges si tu veux les inclure ensuite

Règle à rendre explicite :

* `effectiveCloudSyncEnabled = userWantsCloudSync && isAuthenticated && hasPremiumEntitlement`

Pourquoi c’est important :

* aujourd’hui, la sync cloud est bootstrappée tôt et la préférence `autoSyncEnabled` existe déjà ; il faut éviter que la perte d’abonnement corrompe la préférence utilisateur ou laisse tourner une sync non autorisée.  

Ce qu’il faut éviter :

* désactiver brutalement les données locales
* bloquer la bibliothèque locale
* éparpiller des contrôles premium dans chaque widget

Critère de sortie :

* les fonctions cloud premium sont bien protégées, mais l’expérience gratuite locale reste intacte

#### Étape 5 — Finaliser le parcours UX, la robustesse et les tests

Objectif : rendre le système compréhensible, fiable et maintenable.

À couvrir :

* entrée “Movi Premium” dans Settings
* écran d’offre
* achat
* restauration
* messages d’état clairs :

  * achat réussi
  * restauration réussie
  * aucun achat trouvé
  * billing indisponible
  * réseau indisponible
  * compte requis
* localisations associées
* logs utiles mais non bruyants
* tests unitaires, providers et scénarios de régression

Critère de sortie :

* l’utilisateur comprend ce qui est premium
* l’achat et la restauration fonctionnent
* une expiration ou une perte réseau ne casse pas le fonctionnement local

---

4. **Code ou diff**

Pas de code à ce stade.

La suite logique serait un **plan de dossiers/fichiers précis** pour l’étape 2, en restant strictement dans la structure existante.

---

5. **Vérifications / tests**

Tests à prévoir dès la roadmap :

* **Domaine**

  * premium actif / expiré / inconnu
  * accès autorisé ou refusé selon `PremiumFeature`
  * calcul correct de `effectiveCloudSyncEnabled`

* **Application**

  * achat réussi
  * restauration réussie
  * plateforme non supportée
  * utilisateur non authentifié
  * entitlement absent malgré préférence activée

* **Présentation / providers**

  * la sync cloud ne démarre pas sans entitlement
  * elle repart correctement après activation premium
  * l’UI affiche les bons messages d’erreur

* **Régression**

  * l’app continue à fonctionner entièrement en local sans abonnement
  * la lecture n’est jamais bloquée par erreur
  * les données locales ne sont pas perdues à l’expiration du premium

---

6. **Risques ou hypothèses**

* **Risque principal** : traiter l’abonnement comme un simple détail UI. Ce serait contraire à `rules.md` et fragile à long terme. 
* **Risque d’architecture** : créer une god class du type `SubscriptionManager`. `rules.md` demande explicitement de découper les responsabilités. 
* **Risque produit** : rendre payantes des fonctions cœur comme la lecture ou la bibliothèque locale nuirait à l’équilibre freemium.
* **Hypothèse retenue** : premium v1 = fonctionnalités cloud synchronisées, pas blocage de la consommation locale.
* **Hypothèse technique** : certaines plateformes auront peut-être une gestion d’achat plus limitée que mobile/web ; la roadmap suppose un design où cette contrainte reste confinée à la couche infrastructure.

Je peux maintenant te préparer l’**étape 2 détaillée dossier par dossier**, toujours sans code.
