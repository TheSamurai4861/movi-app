# Criticité composants (C/L) — phase 0 (étapes 6.1–6.3)

**Lot** : `PH0-LOT-008` (sous-étapes **6.1–6.3** ; lot clôturé à l’issue de 6.3).  
**Date** : `2026-04-02`  
**Référentiel** : [`docs/rules_nasa.md`](../rules_nasa.md) §3.1–§3.2, et cohérence avec le plan phase 0.

---

## 1) Définitions NASA (à appliquer sans dilution)

### 1.1 Criticité de changement (C1–C4)

- **C1 — Critique**  
  Impact possible sur : sécurité, confidentialité, auth, paiement, intégrité des données, corruption, crash au démarrage, indisponibilité majeure, exécution de commande non autorisée.
- **C2 — Élevé**  
  Régression majeure, blocage utilisateur, perte partielle de fonctionnalité critique, dégradation importante de performance ou de fiabilité.
- **C3 — Modéré**  
  Défaut non bloquant avec impact sur UX, maintenabilité, observabilité, performance secondaire ou robustesse locale.
- **C4 — Mineur**  
  Cosmétique, wording, nettoyage local, amélioration sans impact fonctionnel significatif.

### 1.2 Classe logicielle interne (L1–L4)

Chaque composant doit être classé selon son impact métier et opérationnel :

- **L1 — Safety / Security / Data Critical**
- **L2 — Business Critical**
- **L3 — Supporting**
- **L4 — Non critical / internal convenience**

Rappel de règle : le niveau de preuve, de revue et de test augmente avec la classe.

---

## 2) Grille initiale par domaine (présumée) — étape 6.1.2

Méthode : classification **conservatrice** basée sur le rôle fonctionnel du domaine dans la chaîne “auth / données / contrôle d’accès / lecture IPTV / sélection de contenu / lecture et synchronisation”.

Notation :
- `L` = classe logicielle interne présumée (impact métier/opérationnel)
- `C` = criticité typique du changement pour ce domaine (pour cadrer les gates futurs)
- `Incertitudes` = zones à affiner en 6.2 (composant granulaire) et/ou en 6.3 (cohérence priorités P0/P1)

| Domaine | L (présumé) | C (présumé) | Justification courte | Incertitudes / limites (pour 6.2) |
|---|---|---|---|---|
| Startup / orchestration / navigation guards | L1 | C1 | Peut affecter l’accès (gate auth/premium) et le démarrage (risques crash/indisponibilité) | Dépend de l’étendue exacte de la logique security au-delà des garde-fous |
| Auth (OTP, session, gates) | L1 | C1 | Sécurité, auth, intégrité des flux de contrôle d’accès | Distinguer “auth contrôle” vs “auth simple API” au niveau composant |
| Subscription / premium gating (accès fonctions) | L1 | C1 | Contrôle d’accès (risque “exécution de fonctionnalité non autorisée”) | Préciser si des erreurs mènent à de l’exposition de données ou uniquement gating UX |
| Storage / persistence (base locale, secure storage, chiffrement) | L1 | C1 | Confidentialité et intégrité des données persistées | Granulariser : DB vs secure storage vs migrations |
| Parental / profils enfant / contrôle parental | L1 | C1 | Safety et restriction de contenu | Valider si l’impact “safety” est strict (exposition de contenu bloqué) ou “préférence UX” |
| Network / clients data (Supabase, HTTP, résolveurs distants) | L2 | C2 | Fiabilité critique (risque blocage), et exposition de secrets/tokens côté client | Séparer “réseau pour lecture” vs “réseau pour auth/tokens” au niveau composant |
| IPTV integration (Xtream, endpoints, playlist ingestion/fallback) | L2 | C2 | Disponibilité contenu : peut bloquer lecture / sélection | Déterminer quel sous-module influence directement l’intégrité des données |
| Player / playback pipeline (sélection, progress, sync, tracks/subtitles) | L2 | C2 | Fonctionnalité centrale : peut dégrader fortement UX/fiabilité | Certaines variations peuvent être plus C3 (UX) si non bloquantes |
| Movies / TV metadata & selection (variants, matching) | L2 | C3 | Influence lecture (contenu correct) mais généralement sans effet sécurité directe | Clarifier impacts “aucune variante sélectionnée” (bloquant ou fallback) |
| Library management (playback history, playlists, sync) | L2 | C2 | Données métier (historique, playlists) : risque perte/sync dégradé | Préciser le degré “perte de données” vs “simple UX” |
| Settings & preferences (sous-titres, sync offset, préférences) | L3 | C3 | Perturbe UX et robustesse locale, sans sécurité directe | Déterminer si certaines préférences influencent la sécurité ou la lecture critique |
| UI screens & layouts (home, welcome, shell, widgets de présentation) | L4 | C4 | Cosmétique / UX locale ; risque C3 seulement si couplé à des gates | Assurer découplage UI ↔ logique métier (règles d’architecture) |
| Search / discovery / category browsing | L3 | C3 | Recherche = UX, peut dégrader découverte mais pas contrôle d’accès | Si la recherche influence des “actions” (par ex. import/sync), revoir C |

---

## 3) Tableau granulaire “composant / zone / L” — étape 6.2

Règles de rédaction :
- “Composant” est un groupe fonctionnel correspondant à un dossier et/ou une unité métier (service, contrôleur, guard, repository).
- “Zone” renvoie au dossier réel attendu pour faciliter la localisation dans le dépôt.
- “L” est assigné de façon conservatrice pour éviter d’omettre un composant L1 safety/security/data critical.
- “Incertitudes” décrit les points qui seront affinés en **6.3** (priorités P0/P1) et/ou via la granularisation 8 (violations d’architecture).

| Composant (unité fonctionnelle) | Zone code (référence) | L (présumé) | Justification courte | Incertitudes / limites (à clarifier) |
|---|---|---|---|---|
| Guards d’accès (routing/redirect, reconnect guards) | `lib/src/core/router/` | L1 | Empêche l’accès non autorisé et guide l’état “post-auth”. Un défaut peut bloquer ou exposer des flux | Déterminer si l’implémentation gère aussi des conditions “premium” vs seulement “auth” |
| Orchestrateur de startup / bootstrap | `lib/src/core/startup/` | L1 | Affecte la séquence de bootstrap, peut causer crash au démarrage ou état invalide | Préciser quel sous-système “sécurité” est garanti avant lancement des features |
| Gating premium (capacité, accès, UI sections) | `lib/src/core/subscription/` + `lib/src/features/subscription/` | L1 | Décide si une fonctionnalité est autorisée (risque d’exécution non autorisée) | Clarifier si des erreurs côté gating mènent à exposition de données vs uniquement UX |
| Auth/session + disponibilité backend | `lib/src/core/` (dépend de Supabase client availability) | L1 | Une erreur auth peut rendre l’application incohérente ou permettre des flux invalides | Localiser les classes exactes qui “assurent” l’état auth vs “subissent” la disponibilité réseau |
| Stockage local & chiffrement (prefs sécurisées / secure storage) | `lib/src/core/preferences/` + `lib/src/core/storage/security/` (si présent) | L1 | Intégrité et confidentialité des données persistées (settings, offsets, sous-titres) | Confirmer quels champs sont chiffrés et quels sont simplement persistés en clair |
| Sanitization des messages (éviter fuite via logs) | `lib/src/core/logging/sanitizer/` | L1 | Mesure safety/security : réduction du risque de fuite d’infos sensibles | Vérifier couverture : types de messages réellement filtrés (erreurs Supabase, tokens, endpoints) |
| Parental gating (profils & résolution metadata) | `lib/src/core/parental/` + `lib/src/features/iptv/` (résolveurs metadata) | L1 | Contrôle de restriction : risque sécurité/safety (contenu restreint) | Clarifier si le “block” est strict (ne rend pas) vs dégrade (fallback partiel) |
| Client réseau & accès Supabase (répos & sync) | `lib/src/shared/data/services/` + `lib/src/features/*/data/` | L2 | Fiabilité critique : peut bloquer sync / lecture ; risque “token/endpoint” si bug | Séparer : lecture/sync (L2) vs auth/token management (plutôt L1) |
| Ingestion IPTV (catalog/fixtures/mappers, endpoints) | `lib/src/features/iptv/` (data/domain) | L2 | Ouvre la chaîne vers endpoints et sélection de contenu ; défaut = indisponibilité ou contenu incorrect | Définir impact exact : erreurs d’ingestion -> fallback “safe” ou “unsafe” |
| Résolution playback (movies) | `lib/src/features/movie/domain/usecases/` + `presentation/providers/` | L2 | Choisit la variante de lecture ; défaut = mauvaise lecture, dégradation UX/fiabilité | Clarifier l’effet sur robustesse : “aucune variante” -> erreur ou fallback |
| Résolution playback (episodes TV) | `lib/src/features/tv/domain/usecases/` + `data/services/` | L2 | Même rôle côté TV : sélection correcte et fiabilité | Déterminer si certaines ambiguïtés déclenchent exceptions bloquantes |
| Pipeline player (media repo, tracks, subtitles) | `lib/src/features/player/` + `lib/src/core/widgets/` | L2 | Lecture et synchronisation : risque de “break playback” et robustesse UI | Distinguer pipeline subtitle (L2) vs UI overlay (potentiellement L3) |
| Synchronisation playback offset (par profil) | `lib/src/core/state/` + `lib/src/core/preferences/` | L2 | Erreurs -> reprise incorrecte/instabilité ; perte de fonctionnalité UX | Clarifier si des erreurs entraînent corruption durable des prefs |
| Résolution et sync des sous-titres (settings) | `lib/src/features/settings/` (services + pages) | L2 (services) / L3 (pages) | Le réglage influence la lecture ; la page est UX, le service est critique | Split strict demandé : classifier “service de sync” vs “UI réglages” séparément en 6.2+ |
| Service de sélection de tracks / subtitle appearance | `lib/src/features/player/` + `lib/src/core/preferences/` | L2 | Mauvais tracks/sous-titres = dégradation lecture, pas sécurité directe | Vérifier robustesse si la piste sélectionnée n’existe pas |
| Bibliothèque / historique playback (résolution & repos) | `lib/src/features/library/` | L2 | Données métier : sync, historique, reprises ; risque perte partielle si bug | Clarifier “loss” : perte définitive vs simple désynch |
| Tri / présentation playlists (non critique) | `lib/src/features/library/domain/services/` + `presentation/widgets/` | L3 | Impact principal UX (tri/affichage) | Si le tri déclenche des accès réseau/side-effects (rare) -> réévaluer |
| Recherche / découverte (discovery UX) | `lib/src/features/search/` | L3 | UX sans impact direct sécurité | Revoir si des actions “import/sync” sont initiées depuis les écrans |
| UI pages / widgets (là où aucun service critique n’est impliqué) | `lib/src/features/*/presentation/pages/` | L4 | Cosmétique/affichage : risque fonctionnel limité si découplage correct | Démontrer absence d’effets de bord métier dans les widgets si nécessaire |

## 3.1 Validation des cas “non classé faute d’information”

À ce stade, tous les composants listés ci-dessus ont une valeur `L` assignée de façon conservatrice.

Risque de programme (critère NASA §6.2.2) : aucun composant **L1** n’est resté volontairement **non classé** faute d’information dans cette cartographie initiale.

Règle : si en 6.2/6.3 un composant **L1** (safety/security/data critical) ne peut pas être classé faute d’information, il doit être ajouté dans une liste “risque de programme” (au sens `docs/rules_nasa.md` et plan phase 0) et le programme doit s’arrêter sur le lot concerné.

---

## 4) Ce que cette grille valide (et ce qu’elle ne valide pas)

- Valide : définitions NASA + une granularisation initiale au niveau “composants fonctionnels” (6.2).
- Valide (6.3) : cohérence de principe avec l’ordre concret recommandé P0/P1 du plan v3 (§23) via un mapping “zone/composant -> priorité”.
- Ne valide pas encore : la granularisation “composant fin” à 100% (fine-scope) et les arbitrages fins qui nécessiteront la décomposition en phase 2/8.

---

## 4.1) Alignement avec l’ordre concret recommandé (plan v3 §23) — étape 6.3

Mapping conservateur (priorité au niveau “feature / core area”, comme dans le plan) :

| Composant (unité fonctionnelle) | Zone code (référence) | Priorité plan (v3 §23) | Arbitrage / note |
|---|---|---|---|
| Orchestrateur de startup / bootstrap | `lib/src/core/startup/` | P0 | Alignement direct (P0 §23.1) : démarrage = priorité absolue |
| Guards d’accès (routing/redirect, reconnect guards) | `lib/src/core/router/` | P0 (core/auth) | Arbitrage : routage/redirect participe à la sécurité de flux (auth gating) |
| Auth/session + disponibilité backend | `lib/src/core/` | P0 (core/auth) | Alignement direct P0 §23.2 |
| Subscription / premium gating | `lib/src/core/subscription/` + `lib/src/features/subscription/` | P0 (core/auth) | Arbitrage : gating “premium” = autorisation ; le plan liste core/auth en P0/P1 |
| Stockage local & chiffrement | `lib/src/core/preferences/` (+ stockage sécurisé si présent) | P0 (core/storage) | Alignement direct P0 §23.3 |
| Sanitization des messages | `lib/src/core/logging/sanitizer/` | P0 (core/security) | Interprétation conservative : réduit risque sécurité (fuites/PII) |
| Parental gating | `lib/src/core/parental/` + resolveurs IPTv metadata | P0 (core/parental) | Alignement direct P0 §23.6 |
| Client réseau & accès Supabase (répos & sync) | `lib/src/shared/data/services/` + `lib/src/features/*/data/` | P0 (core/network) | Alignement P0 §23.4 |
| IPTV integration | `lib/src/features/iptv/` | P0/P1 (features/iptv) | Alignement P0 §23.8 |
| Pipeline player (tracks/subtitles, sync) | `lib/src/features/player/` | P0/P1 (features/player) | Alignement P0 §23.7 |
| Résolution playback (movies) | `lib/src/features/movie/` | P3 | Divergence maîtrisée : L/C “supporting/modéré” car l’erreur tend vers UX/lecture, pas sécurité |
| Résolution playback (episodes TV) | `lib/src/features/tv/` | P3 | Même arbitrage que movie : contenu/lecture plutôt que safety |
| Bibliothèque / historique playback | `lib/src/features/library/` | P2 | Alignement P2 §23.11 |
| Settings & preferences | `lib/src/features/settings/` | P2 | Alignement P2 §23.10 ; note : services potentiellement critiques, UI pages plutôt L3 |
| Recherche / discovery / category browsing | `lib/src/features/search/` | P2 | Alignement P2 §23.12 |
| UI pages / widgets (présentation) | `lib/src/features/*/presentation/pages/` | P3 | Alignement par “feature de niveau” ; granularité UI assignée L4 quand aucun service critique n’est impliqué |

### Divergences / arbitrages clés (résumé)

- Le plan est orienté “core area / feature”, alors que notre grille est orientée “unités fonctionnelles” : certaines unités transverses (ex. routing guards, subscription gating, sanitization) sont rattachées à la priorité core/auth/core/security par rôle sécurité.
- Les pages UI `features/settings` sont classées plus bas (L3) que les services, tandis que le plan les met en P2 au niveau “feature/settings” : arbitrage volontaire pour refléter le couplage (sûreté localisée en service).

---

---

## 5) Statut (pour traceabilité)

- Étage : phase 0
- Étape : **6.3**
- Lot : `PH0-LOT-008` clôturé (6.1–6.3).

