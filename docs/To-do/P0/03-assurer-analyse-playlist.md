# Assurer la compatibilité et l'analyse des playlists IPTV

## Problème actuel

Je ne sais pas si toutes les playlists IPTV qu'un client peut ajouter seront correctement acceptées par l'app et utilisables de manière agréable dans les différentes pages.

## Objectif

- Évaluer la robustesse de l'app face à des playlists variées
- Identifier les cas de données incomplètes, bruitées ou mal formatées
- Définir les fallbacks nécessaires pour garantir une expérience correcte
- S'assurer que l'app reste utile même quand la donnée IPTV est imparfaite

## Portée

### Inclus

- Analyse des playlists IPTV réelles ou représentatives
- Détection des limites de parsing, enrichissement et affichage
- Définition des placeholders, fallbacks et comportements dégradés
- Vérification du comportement dans les écrans principaux

### Exclu pour l'instant

- Refonte complète du pipeline IPTV
- Résolution parfaite de tous les cas d'enrichissement externe
- Nettoyage manuel playlist par playlist

## Cas à couvrir

### Métadonnées incomplètes

- Identifiant TMDB absent :
- Identifiant TMDB erroné :
- Images manquantes :
- Synopsis / informations absentes :
- Notes :

### Titres mal formatés

- Tags parasites dans le titre :
- Alias ou variantes de nom :
- Langue ou qualité intégrée au titre :
- Règles de nettoyage à prévoir :
- Notes :

### Données partiellement exploitables

- Média identifiable sans enrichissement complet :
- Données minimales nécessaires pour l'affichage :
- Fallback d'image :
- Fallback de texte :
- Notes :

### Cas non supportés

- Type de contenu problématique :
- Données incohérentes :
- Comportement attendu :
- Message utilisateur éventuel :
- Notes :

## Questions d'analyse

### Parsing et normalisation

- Quels champs sont indispensables ?
- Quels champs peuvent être reconstruits ?
- Quels nettoyages de titres doivent être centralisés ?

### Enrichissement

- Que faire sans TMDB ?
- Quels écrans dépendent trop fortement de l'enrichissement ?
- Quels niveaux de fallback sont acceptables ?

### Affichage

- Quels placeholders doivent être utilisés ?
- Quelles pages doivent rester utilisables même avec très peu de données ?
- Quels écrans doivent dégrader leur UI au lieu d'échouer ?

## Tâches et réflexions

- Analyser plusieurs playlists représentatives
- Lister les cas de données problématiques
- Identifier les points de casse dans le parsing, l'enrichissement et l'UI
- Définir une stratégie de fallback claire
- Préparer une implémentation simple et robuste
- Implémenter les adaptations nécessaires
- Vérifier le comportement avec des playlists hétérogènes

## Checklist d'exécution

- [x] Rassembler des playlists ou cas de test représentatifs
- [x] Identifier les champs réellement disponibles selon les sources
- [x] Définir les fallbacks de données et d'affichage
- [x] Prioriser les cas bloquants pour l'expérience utilisateur
- [x] Préparer l'implémentation avec une approche propre
- [x] Implémenter les correctifs ou renforcements nécessaires
- [x] Tester les parcours avec données complètes et dégradées

## Critères de validation

- L'app accepte des playlists variées sans casser les parcours principaux
- Les médias sans enrichissement complet restent affichables de manière acceptable
- Les titres bruités ou partiellement mal formatés sont mieux tolérés
- Les placeholders et fallbacks évitent une sensation d'app cassée

## Plan d'implémentation

### Étape 1 - Analyse des playlists

- Rassembler 5 à 10 cas représentatifs :
  - playlist propre
  - playlist sans TMDB
  - titres bruités
  - images absentes
  - métadonnées incohérentes
- Créer des fixtures de test dédiées plutôt que de disperser des cas dans les widgets ou les repositories
- Produire une grille d'analyse simple par item :
  - données brutes disponibles
  - données normalisées possibles
  - enrichissement possible ou non
  - fallback UI attendu
- Livrable :
  - une petite matrice de cas couverts et de cas non supportés
- Statut :
  - fait
- Sorties produites :
  - fixtures dédiées : `test/features/iptv/fixtures/playlist_analysis_fixtures.dart`
  - test de couverture minimale : `test/features/iptv/fixtures/playlist_analysis_fixtures_test.dart`

#### Matrice d'analyse

| Cas | Source | Donnees brutes disponibles | Donnees normalisables | Enrichissement possible | Fallback UI attendu | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| `xtream_clean_movie` | Xtream | `name`, `stream_id`, `category_id`, `stream_icon`, `plot`, `year`, `tmdb_id`, `imdb_id` | Titre deja exploitable | Oui, deja resolu par `tmdb_id` | Aucun fallback critique | supporte |
| `xtream_missing_tmdb_movie` | Xtream | `name`, `stream_id`, `category_id`, `stream_icon`, `year` | Titre direct | Oui, recherche par titre + annee | garder le poster source, texte generique si synopsis absent | degrade mais supporte |
| `xtream_noisy_title_movie` | Xtream | `name`, `stream_id`, `category_id` | nettoyage du titre requis | Oui, seulement apres nettoyage du titre | placeholder image + titre nettoye | degrade mais supporte |
| `stalker_missing_images_series` | Stalker | `name`, `id`, `category_id`, `description`, `year`, `tmdb_id` | Titre deja exploitable | Oui, poster recuperable via TMDB | utiliser le synopsis source, charger le poster via TMDB | supporte |
| `stalker_partial_metadata_series` | Stalker | `name`, `id`, `category_id`, `year` | Titre direct | Oui, recherche par titre + annee | placeholder image + texte generique | degrade mais supporte |
| `xtream_inconsistent_unsupported` | Xtream | donnees incoherentes ou invalides (`stream_id`, `tmdb_id`, titre) | non | Non, cas trop ambigu | masquer ou isoler du detail | non supporte pour cette iteration |

#### Lecture de l'analyse

- Champs minimaux fiables observes sur les deux sources :
  - identifiant source
  - titre brut
  - type de contenu infere par la playlist ou le provider
- Champs souvent absents ou peu fiables :
  - `tmdb_id`
  - image
  - synopsis
  - note
- Premiere conclusion :
  - l'app doit rester utile sans enrichissement TMDB complet
  - le nettoyage des titres doit etre centralise
  - un cas non supporte doit etre detecte explicitement au lieu de casser le detail

### Étape 2 - Définition des fallbacks

- Définir un contrat minimal de donnée exploitable pour l'app :
  - titre obligatoire
  - type de contenu fiable
  - identifiant source stable
- Centraliser les règles de normalisation de titre et de reconstruction légère dans un service dédié, pas dans les widgets ni dans les DTO
- Définir un fallback explicite par information :
  - image
  - synopsis
  - année
  - note
  - TMDB manquant ou invalide
- Séparer clairement :
  - erreur technique
  - donnée partielle acceptable
  - cas non supporté à masquer ou signaler
- Livrable :
  - une table de décision unique pour les comportements dégradés
- Statut :
  - fait
- Sorties produites :
  - politique centralisée : `lib/src/features/iptv/application/services/iptv_playlist_fallback_policy.dart`
  - tests de politique : `test/features/iptv/application/services/iptv_playlist_fallback_policy_test.dart`

#### Contrat minimal retenu

- Un item IPTV reste exploitable uniquement si les trois conditions suivantes sont vraies :
  - titre significatif après normalisation
  - type de contenu fiable
  - identifiant source stable (`streamId > 0` ou `tmdbId > 0`)
- Si ce contrat minimal échoue :
  - le cas est `non supporté`
  - il doit être masqué ou isolé des écrans de détail
- La normalisation du titre et la reconstruction légère ne doivent pas vivre :
  - dans les DTO
  - dans les widgets
  - dans les pages
- La source unique de cette décision est maintenant le service :
  - `IptvPlaylistFallbackPolicy`

#### Table de décision des comportements dégradés

| Information | Donnée exploitable | Fallback retenu | Décision |
| --- | --- | --- | --- |
| Titre | titre nettoyé non vide et significatif | nettoyage via `TitleCleaner`, sinon titre original si encore significatif | si aucun titre valable : `non supporté` |
| Type | type déjà porté par l'entité `XtreamPlaylistItemType` | aucun fallback permissif | si type n'est plus fiable à l'avenir : `non supporté` |
| Identifiant source | `streamId > 0` ou `tmdbId > 0` | aucun fallback artificiel | si aucun identifiant stable : `non supporté` |
| Image | poster source HTTP/HTTPS valide | sinon poster TMDB si `tmdbId` exploitable, sinon placeholder | `partiel acceptable` |
| Synopsis | synopsis source non vide | sinon texte générique indisponible | `partiel acceptable` |
| Année | `releaseYear` valide | sinon année inférée du titre, sinon masquer l'année | `partiel acceptable` |
| Note | note source entre `0` et `10` | sinon masquer la note | `partiel acceptable` |
| TMDB | `tmdbId` fourni et valide | sinon recherche par titre + année, puis titre seul si possible | `partiel acceptable` |

#### Catégories de décision retenues

- `ready`
  - donnée suffisamment complète, aucun fallback significatif requis
- `partialData`
  - donnée exploitable mais incomplète, avec rendu dégradé explicite
- `technicalFailure`
  - donnée exploitable mais enrichissement externe indisponible
- `unsupportedData`
  - contrat minimal non respecté, le cas ne doit pas être promu comme contenu normal

#### Règle d'architecture actée

- La politique de fallback IPTV est une logique métier applicative pure
- Elle doit rester testable sans Flutter, sans repository et sans réseau
- Les widgets consomment une décision déjà interprétée
- Les DTO restent limités au mapping brut des données source

### Étape 3 - Préparation d'implémentation

- Garder les mappers d'entrée simples :
  - `PlaylistMapper`
  - `StalkerPlaylistMapper`
  - ils transforment les DTOs en entités, sans concentrer toute la logique métier
- Introduire un service dédié d'analyse/normalisation IPTV dans la couche application ou domain selon le besoin :
  - responsabilité unique
  - entrée = item brut mappé
  - sortie = item analysé + diagnostic + données de fallback
- Réutiliser les services existants quand ils sont déjà au bon niveau :
  - `TitleCleaner` pour le nettoyage
  - `TmdbIdResolverService` pour la résolution externe
  - `IptvContentResolverImpl` pour la disponibilité
- Prévoir des objets explicites plutôt que multiplier les booléens dispersés
- Livrable :
  - design court des responsabilités et points d'intégration
- Statut :
  - fait
- Sorties produites :
  - service d'analyse : `lib/src/features/iptv/application/services/iptv_playlist_analysis_service.dart`
  - test du service : `test/features/iptv/application/services/iptv_playlist_analysis_service_test.dart`

#### Responsabilités retenues

- `PlaylistMapper`
  - transforme les DTO Xtream en entités métier IPTV
  - ne décide pas du fallback, du diagnostic ni de l'enrichissement
- `StalkerPlaylistMapper`
  - transforme les DTO Stalker en entités métier IPTV
  - garde la même responsabilité limitée que `PlaylistMapper`
- `IptvPlaylistFallbackPolicy`
  - applique le contrat minimal
  - décide les fallbacks image, synopsis, année, note et TMDB
  - classe le résultat en `ready`, `partialData`, `technicalFailure` ou `unsupportedData`
- `IptvPlaylistAnalysisService`
  - orchestre l'analyse d'un item déjà mappé
  - produit un objet explicite :
    - item source
    - titre affichable
    - candidats de recherche
    - année normalisée
    - résultat de fallback
    - diagnostics métier

#### Objets explicites retenus

- `IptvPlaylistAnalysisContext`
  - porte le contexte d'analyse sans empiler des booléens de paramètres
  - premier besoin identifié :
    - `tmdbLookupAvailable`
- `IptvPlaylistAnalysis`
  - sortie unique du service d'analyse
  - doit devenir l'entrée des futurs adaptateurs UI ou enrichisseurs
- `IptvPlaylistDiagnosticCode`
  - expose les problèmes détectés sous forme stable et testable
  - évite les chaînes libres et les booléens dispersés

#### Flux d'intégration retenu

1. Les mappers construisent `XtreamPlaylistItem`
2. `IptvPlaylistAnalysisService` analyse chaque item
3. `IptvPlaylistFallbackPolicy` produit les décisions métier de fallback
4. Les étapes suivantes consomment `IptvPlaylistAnalysis` :
   - enrichissement TMDB si pertinent
   - résolution de disponibilité IPTV
   - adaptation du rendu UI

#### Points d'intégration actés

- `TitleCleaner`
  - reste la brique de nettoyage de titre utilisée par la politique d'analyse
- `TmdbIdResolverService`
  - ne doit pas être appelé par les mappers
  - sera branché après analyse uniquement si `tmdbDecision` l'autorise
- `IptvContentResolverImpl`
  - reste dédié à la disponibilité d'un contenu IPTV
  - ne doit pas absorber la logique de normalisation ou de fallback

#### Séquence cible pour l'étape 4

- Lot 1 :
  - brancher `IptvPlaylistAnalysisService` au point d'entrée où les items sont préparés pour l'affichage ou la recherche
- Lot 2 :
  - déclencher la résolution TMDB seulement pour les cas `searchByTitleAndYear` ou `searchByTitleOnly`
- Lot 3 :
  - faire consommer à l'UI un objet analysé au lieu de reconstruire les règles localement
- Lot 4 :
  - brancher la disponibilité IPTV sans mélanger diagnostic, enrichissement et rendu

#### Contraintes d'architecture confirmées

- Aucun déplacement de logique métier IPTV vers les widgets
- Aucun enrichissement externe direct dans les mappers
- Aucun objet "fourre-tout" qui mélange :
  - parsing
  - fallback
  - disponibilité
  - rendu
- Toute nouvelle règle métier IPTV doit entrer :
  - soit dans `IptvPlaylistFallbackPolicy`
  - soit dans `IptvPlaylistAnalysisService`
  - pas dans les DTO ni dans les pages

### Étape 4 - Implémentation

- Implémenter par petits lots pour limiter le risque :
  - lot 1 : normalisation des titres
  - lot 2 : diagnostic des métadonnées manquantes ou invalides
  - lot 3 : fallback d'affichage
  - lot 4 : enrichissement opportuniste si TMDB est récupérable
- Éviter toute god class :
  - ne pas fusionner parsing, enrichissement, logging et rendu dans un seul service
- Garder la UI passive :
  - les pages consomment un état déjà interprété
  - elles ne décident pas elles-mêmes des règles métier IPTV
- Ajouter seulement les logs utiles au diagnostic des cas réellement non supportés
- Statut :
  - fait
- Sorties produites :
  - projection analysée des items IPTV : `lib/src/features/iptv/application/iptv_catalog_reader.dart`
  - câblage DI IPTV : `lib/src/features/iptv/data/iptv_data_module.dart`
  - enrichissement TMDB opportuniste en recherche : `lib/src/features/search/data/search_repository_impl.dart`
  - câblage DI recherche : `lib/src/features/search/data/search_data_module.dart`
  - amélioration du nettoyage centralisé : `lib/src/core/utils/title_cleaner.dart`
  - tests ciblés : `test/features/iptv/application/iptv_catalog_reader_test.dart`

#### Lots réellement livrés

- Lot 1 - normalisation des titres
  - `IptvCatalogReader` n'expose plus le titre brut aux couches UI
  - le titre affiché provient de l'analyse IPTV
  - `TitleCleaner` a été renforcé pour mieux tolérer des tags réels comme `TRUEFRENCH`
- Lot 2 - diagnostic des métadonnées manquantes ou invalides
  - chaque item passe par `IptvPlaylistAnalysisService`
  - les cas non supportés sont exclus avant projection UI
  - seuls ces cas non supportés sont loggués
- Lot 3 - fallback d'affichage
  - poster absent ou invalide :
    - pas de pseudo-valeur artificielle
    - l'UI reçoit `null` et garde son placeholder normal
  - année absente :
    - année normalisée réutilisée si disponible
    - sinon champ masqué
  - note absente ou invalide :
    - champ masqué
- Lot 4 - enrichissement opportuniste si TMDB est récupérable
  - la recherche IPTV tente désormais de résoudre un `tmdbId` manquant via `TmdbIdResolverService`
  - si un `tmdbId` est récupéré, `ContentEnrichmentService` complète poster et année
  - cette logique reste localisée à la recherche, pas aux mappers ni aux widgets

#### Points d'intégration effectivement branchés

- `IptvCatalogReader`
  - point unique de projection des `XtreamPlaylistItem` vers `ContentReference`
  - applique analyse, fallback et filtrage des cas non supportés
- `SearchRepositoryImpl`
  - enrichit opportunistement les références IPTV récupérables avant de construire `MovieSummary` ou `TvShowSummary`
- `Home` et les autres écrans
  - restent passifs
  - consomment des `ContentReference` déjà assainies

#### Règles d'architecture respectées pendant l'implémentation

- pas de logique métier IPTV ajoutée dans les widgets
- pas de surcharge des mappers d'entrée
- pas de service unique mélangeant parsing, fallback, enrichissement et rendu
- logs limités au diagnostic des éléments explicitement non supportés

### Étape 5 - Vérification

- Ajouter des tests unitaires sur les règles de normalisation et de fallback
- Ajouter des tests de service sur les cas limites :
  - TMDB absent
  - titre bruité
  - image absente
  - type ambigu
- Ajouter quelques tests widget ciblés sur les écrans critiques pour vérifier le rendu dégradé sans crash
- Vérifier au minimum :
  - import/source IPTV
  - home IPTV
  - library/playlist
  - page détail si enrichissement partiel
- Critère de fin :
  - les cas dégradés sont prévisibles, testés et localisés dans des modules clairs
- Statut :
  - fait
- Sorties produites :
  - tests unitaires de normalisation : `test/core/utils/title_cleaner_test.dart`
  - tests service IPTV existants consolidés :
    - `test/features/iptv/application/services/iptv_playlist_fallback_policy_test.dart`
    - `test/features/iptv/application/services/iptv_playlist_analysis_service_test.dart`
    - `test/features/iptv/application/iptv_catalog_reader_test.dart`
  - tests widget ciblés :
    - `test/features/home/presentation/widgets/home_iptv_section_test.dart`
    - `test/features/library/presentation/widgets/library_playlist_card_test.dart`
  - test provider playlist :
    - `test/features/library/presentation/providers/playlist_content_references_provider_test.dart`
  - test provider détail film en fallback partiel :
    - `test/features/movie/presentation/providers/movie_detail_controller_xtream_fallback_test.dart`

#### Parcours critiques vérifiés

- Import/source IPTV
  - `IptvCatalogReader` filtre les cas non supportés et projette des `ContentReference` dégradées sans casser le flux
- Home IPTV
  - `HomeIptvSection` rend une carte IPTV sans poster, année ni note sans crash
- Library/playlist
  - `LibraryPlaylistCard` garde un rendu stable sans artwork
  - `playlistContentReferencesProvider` retombe sur les références brutes si l'enrichissement TMDB échoue
- Détail film avec enrichissement partiel
  - `movieDetailControllerProvider` retombe sur les données Xtream si un `tmdbId` existe mais que le chargement TMDB échoue

#### Cas limites explicitement verrouillés

- TMDB absent
  - couvert par `iptv_playlist_fallback_policy_test.dart` et `iptv_playlist_analysis_service_test.dart`
- Titre bruité
  - couvert par `title_cleaner_test.dart` et `iptv_catalog_reader_test.dart`
- Image absente
  - couverte par `home_iptv_section_test.dart` et `iptv_playlist_fallback_policy_test.dart`
- Type ambigu ou donnée non fiable
  - couvert par `iptv_playlist_analysis_service_test.dart` via le cas `unsupportedData`

#### Règle de vérification retenue

- Les règles métier restent vérifiées dans des tests purs ou de service
- Les widgets critiques ne testent que le rendu dégradé et l'absence de crash
- Le détail film est validé au niveau provider public pour éviter un test UI trop couplé aux dépendances de page

## Risques / points d'attention

- Laisser la logique métier IPTV glisser dans les widgets ou les pages détail
- Ajouter des heuristiques de nettoyage dans plusieurs fichiers au lieu de les centraliser
- Coupler trop fortement l'expérience IPTV à TMDB alors que la donnée source est souvent incomplète
- Transformer les mappers en classes fourre-tout difficiles à tester
- Corriger un cas réel en dur sans formaliser la règle générale derrière

## Questions ouvertes

- Quel est le socle minimal pour considérer un média "affichable" sans enrichissement externe ?
- Quels écrans doivent rester utilisables avec seulement `title + type + sourceId` ?
- Faut-il exposer un diagnostic interne pour aider le support ou seulement des fallbacks silencieux côté UI ?
- Quels cas doivent être tolérés, et quels cas doivent être explicitement exclus dans cette itération ?

## Notes complémentaires

- Approche recommandée :
  - d'abord rendre les cas imparfaits prévisibles
  - ensuite enrichir les cas récupérables
- Principe d'architecture :
  - ingestion brute dans les mappers
  - interprétation dans un service dédié
  - rendu dégradé dans la présentation
- Cette to-do doit améliorer la robustesse sans refondre tout le pipeline IPTV existant
