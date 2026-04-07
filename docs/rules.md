# Bonnes pratiques de code

## 1. Principes fondamentaux

### 1.1 Chercher la simplicité
- Préférer une solution simple, lisible et robuste à une solution “maligne” mais difficile à maintenir.
- Réduire le nombre de concepts nécessaires pour comprendre un module.
- Éviter les couches, abstractions et patterns inutiles.

### 1.2 Optimiser la lisibilité
- Le code est lu bien plus souvent qu’il n’est écrit.
- Une personne qui découvre le projet doit pouvoir comprendre rapidement l’intention du code.
- La lisibilité prime souvent sur la concision.

### 1.3 Faire du code évolutif
- Organiser le code pour permettre des changements locaux sans casser tout le système.
- Limiter l’effet domino : une modification dans une zone ne doit pas imposer des changements partout.
- Prévoir l’évolution probable, pas toutes les hypothèses futures.

### 1.4 Préférer la clarté à la magie
- Éviter les mécanismes implicites difficiles à tracer.
- Réduire les effets de bord cachés.
- Préférer des flux de données explicites.

---

## 2. Architecture

### 2.1 Séparer les responsabilités
- Chaque module, classe ou fonction doit avoir une responsabilité claire.
- Ne pas mélanger UI, logique métier, accès réseau, persistance et transformation de données dans le même composant.
- Une couche ne doit pas prendre en charge des responsabilités qui appartiennent à une autre.

### 2.2 Définir des frontières nettes
- Définir clairement les couches du système : présentation, application, domaine, infrastructure, données, etc.
- Contrôler les dépendances entre couches.
- Les couches centrales doivent être les plus stables et les moins dépendantes de détails techniques.

### 2.3 Dépendre d’abstractions utiles
- Le code métier ne doit pas dépendre directement de technologies concrètes si cela complique les tests ou l’évolution.
- Introduire des interfaces seulement lorsqu’elles apportent une vraie valeur.
- Ne pas sur-abstraire un système simple.

### 2.4 Limiter le couplage
- Réduire les dépendances directes entre composants.
- Éviter qu’un module connaisse trop de détails internes d’un autre.
- Préférer des contrats simples et stables entre modules.

### 2.5 Favoriser une forte cohésion
- Regrouper ensemble ce qui change pour les mêmes raisons.
- Éviter les modules “fourre-tout”.
- Un dossier ou package doit avoir un thème clair.

### 2.6 Concevoir pour tester
- Une architecture saine rend les tests simples.
- Limiter les singletons globaux, états partagés cachés et dépendances implicites.
- Permettre l’injection des dépendances importantes.

### 2.7 Éviter l’architecture spéculative
- Ne pas construire une architecture “pour un futur hypothétique”.
- Introduire de la complexité seulement quand un besoin réel la justifie.
- Refactoriser au bon moment plutôt que surconcevoir dès le départ.

---

## 3. Gestion des dépendances

### 3.1 Réduire les dépendances externes
- Chaque dépendance ajoute du risque : sécurité, maintenance, compatibilité, performance, dette.
- Ajouter une librairie seulement si elle apporte un vrai gain.
- Vérifier sa qualité, sa maintenance, sa licence et sa stabilité.

### 3.2 Centraliser les points d’intégration
- Encapsuler les dépendances importantes derrière une API interne quand c’est utile.
- Éviter de disséminer partout l’usage brut d’un framework ou SDK.
- Prévoir des adaptateurs pour les systèmes externes.

### 3.3 Maîtriser les versions
- Verrouiller les versions de dépendances de façon cohérente.
- Éviter les mises à jour massives non contrôlées.
- Tester les montées de version de manière ciblée.

### 3.4 Éviter les dépendances circulaires
- Les modules ne doivent pas dépendre les uns des autres en boucle.
- Une dépendance circulaire rend la compréhension, le test et l’évolution plus difficiles.
- Repenser la frontière des modules si un cycle apparaît.

### 3.5 Limiter la profondeur des chaînes de dépendances
- Plus la chaîne est longue, plus le système devient fragile.
- Réduire les cascades d’instanciation et de configuration.
- Garder les dépendances essentielles visibles.

---

## 4. Déduplication et réutilisation

### 4.1 Éviter la duplication utilement
- La duplication est un signal, pas toujours une faute immédiate.
- Dédupliquer quand deux blocs expriment vraiment la même règle métier ou le même comportement stable.
- Ne pas factoriser trop tôt des morceaux encore en évolution.

### 4.2 Ne pas créer de fausse réutilisation
- Deux codes qui se ressemblent ne doivent pas forcément être fusionnés.
- Une abstraction incorrecte coûte souvent plus cher que quelques lignes dupliquées.
- Attendre que le motif soit stable avant de généraliser.

### 4.3 Mutualiser au bon niveau
- Extraire les règles partagées au niveau le plus naturel.
- Éviter les utilitaires génériques vagues du type `helpers`, `utils`, `common` sans structure claire.
- Nommer toute réutilisation selon son rôle métier ou technique précis.

### 4.4 Préserver la clarté
- Une petite duplication explicite peut être préférable à une abstraction obscure.
- La factorisation ne doit jamais rendre le code plus difficile à lire.

---

## 5. Nommage

### 5.1 Donner des noms explicites
- Les noms doivent révéler l’intention, pas seulement le type technique.
- Préférer `calculateInvoiceTotal` à `processData`.
- Préférer `customerRepository` à `repo`.

### 5.2 Être cohérent
- Employer le même vocabulaire pour un même concept dans tout le projet.
- Éviter les synonymes multiples pour la même idée.
- Aligner le code sur le langage métier.

### 5.3 Ajuster la longueur à l’importance
- Un nom fréquent peut être un peu plus court s’il reste clair.
- Un concept métier important mérite un nom plus précis, même plus long.
- Ne jamais sacrifier le sens pour gagner quelques caractères.

### 5.4 Éviter les noms trompeurs
- Ne pas utiliser des noms trop génériques : `manager`, `service`, `data`, `handler`, `processor` sans précision.
- Ne pas appeler `get...` une fonction qui modifie l’état.
- Ne pas appeler `validate` une fonction qui normalise, transforme et persiste.

### 5.5 Rendre les collections et booléens lisibles
- Une collection doit avoir un nom pluriel ou collectif explicite.
- Un booléen doit ressembler à une question ou une propriété claire : `isActive`, `hasAccess`, `canRetry`.

---

## 6. Fonctions et méthodes

### 6.1 Faire des fonctions courtes et focalisées
- Une fonction doit faire peu de choses et les faire bien.
- Une fonction trop longue cache souvent plusieurs responsabilités.
- Découper quand des sous-intentions distinctes apparaissent.

### 6.2 Réduire le nombre de paramètres
- Trop de paramètres est un signal de conception faible.
- Regrouper les paramètres cohérents dans un objet de contexte ou de configuration si cela clarifie.
- Éviter les longues listes de booléens ou de paramètres du même type.

### 6.3 Limiter les effets de bord
- Une fonction doit idéalement soit calculer, soit agir, mais éviter de faire les deux sans nécessité.
- Les effets de bord importants doivent être visibles depuis l’appel.
- Réduire les mutations cachées.

### 6.4 Garder un contrat clair
- Définir précisément ce qu’une fonction attend et garantit.
- Gérer explicitement les cas d’erreur, les cas limites et les valeurs nulles ou absentes.
- Ne pas surprendre l’appelant.

---

## 7. Structures de données et modèles

### 7.1 Choisir la bonne structure
- Utiliser la structure adaptée au besoin : liste, ensemble, dictionnaire, file, pile, arbre, etc.
- Le choix d’une structure influe sur la lisibilité et la performance.
- Éviter les détournements de structures non adaptées.

### 7.2 Modéliser les concepts métier correctement
- Les modèles doivent refléter le domaine, pas seulement la base de données ou l’API externe.
- Séparer si nécessaire les objets de transport, objets de persistance et objets métier.
- Éviter les modèles “god objects”.

### 7.3 Encapsuler les invariants
- Les règles fondamentales d’un objet doivent être protégées par sa conception.
- Éviter les états invalides faciles à construire.
- Valider tôt les données critiques.

---

## 8. Commentaires et documentation

### 8.1 Commenter avec parcimonie
- Un bon code réduit le besoin de commentaires.
- Commenter quand l’intention, la contrainte, le compromis ou le contexte ne sont pas évidents.
- Ne pas paraphraser le code.

### 8.2 Privilégier le “pourquoi”
- Expliquer pourquoi une décision a été prise.
- Expliquer les contraintes métier, techniques ou historiques importantes.
- Documenter les comportements surprenants ou non intuitifs.

### 8.3 Tenir la documentation à jour
- Un commentaire faux est pire qu’une absence de commentaire.
- Supprimer les commentaires obsolètes.
- Synchroniser doc, exemples, README et comportement réel.

### 8.4 Documenter les API et contrats
- Les interfaces publiques doivent préciser entrées, sorties, erreurs, limites et effets importants.
- Fournir des exemples d’usage quand cela aide.

---

## 9. Gestion des erreurs

### 9.1 Gérer les erreurs explicitement
- Ne pas masquer les erreurs sans raison.
- Remonter une information exploitable.
- Différencier erreur métier, erreur technique et état attendu non trouvé.

### 9.2 Éviter les exceptions muettes
- Ne pas attraper une erreur pour l’ignorer silencieusement.
- Journaliser ou transformer l’erreur de manière utile.
- Préserver le contexte nécessaire au diagnostic.

### 9.3 Écrire des messages utiles
- Les messages d’erreur doivent aider à comprendre le problème.
- Inclure les données de contexte utiles, sans exposer d’informations sensibles.
- Permettre une action corrective quand possible.

### 9.4 Échouer tôt sur les invariants critiques
- Vérifier rapidement les préconditions importantes.
- Préférer un échec clair à un comportement incohérent plus loin.

---

## 10. Performance

### 10.1 Optimiser après compréhension
- Ne pas optimiser à l’aveugle.
- Mesurer avant d’optimiser.
- Identifier les vrais goulots d’étranglement.

### 10.2 Préserver d’abord la clarté
- Le code ultra optimisé mais incompréhensible est coûteux à maintenir.
- Une optimisation doit être justifiée par des données.
- Documenter les optimisations non évidentes.

### 10.3 Réduire le travail inutile
- Éviter les recomputations coûteuses.
- Mettre en cache seulement lorsque c’est utile et maîtrisé.
- Réduire les allocations, parcours et appels réseau inutiles.

### 10.4 Penser complexité
- Connaître le coût algorithmique global.
- Éviter les boucles imbriquées inutiles sur de gros volumes.
- Adapter les algorithmes à la taille réelle des données.

### 10.5 Concevoir pour la scalabilité raisonnable
- Anticiper les volumes probables, pas extrêmes sans raison.
- Identifier tôt les opérations potentiellement coûteuses.
- Séparer les chemins critiques des traitements secondaires.

---

## 11. Gestion d’état

### 11.1 Réduire l’état mutable
- Plus il y a d’état mutable partagé, plus le système devient difficile à raisonner.
- Favoriser les données immuables ou localisées.
- Encadrer clairement les points de mutation.

### 11.2 Éviter l’état global caché
- L’état global complique les tests et le débogage.
- Préférer l’injection ou un accès explicite aux dépendances d’état.
- Centraliser les décisions critiques d’état.

### 11.3 Rendre les transitions explicites
- Les changements d’état importants doivent être visibles, traçables et testables.
- Définir les états possibles et les transitions valides.

---

## 12. Concurrence et asynchronisme

### 12.1 Garder les flux simples
- Le code concurrent doit rester aussi simple que possible.
- Limiter les zones partagées.
- Préférer des modèles d’échange clairs plutôt qu’un accès concurrent libre.

### 12.2 Protéger les ressources partagées
- Identifier explicitement ce qui peut être accédé en parallèle.
- Prévenir courses critiques, interblocages et incohérences.
- Minimiser la durée des sections critiques.

### 12.3 Gérer l’asynchronisme comme un contrat
- Gérer timeouts, annulations, retries et erreurs de manière explicite.
- Ne pas perdre silencieusement les tâches échouées.
- Rendre clair ce qui est bloquant ou non.

---

## 13. Tests

### 13.1 Tester le comportement utile
- Tester ce qui a de la valeur fonctionnelle ou structurelle.
- Éviter les tests trop couplés à l’implémentation interne.
- Préférer des tests résistants au refactoring légitime.

### 13.2 Garder des tests lisibles
- Les tests sont du code de production pour la confiance.
- Un test doit exprimer clairement la situation, l’action et le résultat attendu.
- Le nom du test doit décrire le comportement vérifié.

### 13.3 Couvrir les cas importants
- Cas nominal.
- Cas limites.
- Cas d’erreur.
- Règles métier critiques.
- Régressions déjà rencontrées.

### 13.4 Éviter les tests fragiles
- Réduire la dépendance au temps, au hasard, au réseau, au système de fichiers et à l’ordre d’exécution.
- Isoler les effets externes.
- Stabiliser les données de test.

### 13.5 Utiliser la pyramide de tests
- Beaucoup de tests rapides et ciblés.
- Des tests d’intégration là où les interactions comptent.
- Peu de tests bout en bout, mais bien choisis.

---

## 14. Logs, observabilité et diagnostic

### 14.1 Journaliser utilement
- Les logs doivent aider à comprendre le comportement du système.
- Journaliser les événements métier ou techniques importants.
- Éviter le bruit excessif.

### 14.2 Structurer les logs
- Utiliser des messages cohérents.
- Inclure identifiants, contexte et corrélation quand nécessaire.
- Permettre une investigation rapide.

### 14.3 Respecter la confidentialité
- Ne jamais logger des secrets, mots de passe, tokens ou données sensibles inutilement.
- Masquer ou anonymiser les informations critiques.

---

## 15. Sécurité

### 15.1 Ne jamais faire confiance aux entrées
- Valider toute entrée utilisateur, externe ou système.
- Nettoyer et contraindre les données.
- Prévenir injections, dépassements, désérialisations dangereuses et usages inattendus.

### 15.2 Protéger les secrets
- Ne pas hardcoder les secrets.
- Utiliser un stockage approprié.
- Appliquer le principe du moindre privilège.

### 15.3 Réduire la surface d’attaque
- Éviter les permissions excessives.
- Désactiver les comportements non nécessaires.
- Tenir les dépendances critiques à jour.

---

## 16. Organisation du projet

### 16.1 Structurer le dépôt clairement
- La structure des dossiers doit refléter les responsabilités du projet.
- Éviter les répertoires vagues qui deviennent des zones de dépôt.
- Faciliter la navigation.

### 16.2 Standardiser les conventions
- Même style de nommage, de tests, de configuration et de structure dans tout le projet.
- Réduire les variations arbitraires d’un module à l’autre.

### 16.3 Isoler le code mort et expérimental
- Supprimer le code inutilisé.
- Éviter de laisser des branches mortes ou des fonctionnalités incomplètes dans le flux principal.
- Marquer clairement les prototypes temporaires.

---

## 17. Revue de code

### 17.1 Relire pour la compréhension
- Une revue ne sert pas seulement à détecter des bugs.
- Vérifier aussi la lisibilité, la cohérence, le design, les frontières et les impacts futurs.
- Se demander si le code sera compréhensible dans six mois.

### 17.2 Faire des changements petits et ciblés
- Les petites PR sont plus faciles à revoir et plus sûres à intégrer.
- Éviter les mélanges entre refactorings, renommages massifs et nouvelles fonctionnalités dans le même changement.

### 17.3 Argumenter les choix non évidents
- Expliquer les compromis.
- Donner le contexte de conception quand il n’est pas évident depuis le code.

---

## 18. Refactoring

### 18.1 Refactoriser régulièrement
- Ne pas attendre que le système soit déjà trop dégradé.
- Profiter des évolutions pour améliorer localement la qualité.

### 18.2 Refactoriser avec sécurité
- S’appuyer sur des tests.
- Faire des changements progressifs.
- Vérifier le comportement après chaque étape.

### 18.3 Traiter les causes, pas seulement les symptômes
- Une duplication, une complexité ou un bug récurrent révèlent souvent un problème de conception plus profond.
- Corriger la racine quand c’est possible.

---

## 19. Signaux d’alerte

### 19.1 Odeurs de code fréquentes
- Fonctions très longues.
- Classes ou fichiers gigantesques.
- Paramètres nombreux.
- Conditions imbriquées à répétition.
- Noms vagues.
- Modules couplés en chaîne.
- Helpers génériques omniprésents.
- Commentaires qui compensent un code confus.
- Requêtes réseau ou accès base disséminés.
- Logique métier dispersée dans l’UI.

### 19.2 Odeurs d’architecture
- Dépendances circulaires.
- Couche centrale dépendante d’un détail technique.
- Absence de frontières claires.
- Modules impossibles à tester sans environnement complet.
- Multiplication d’abstractions sans besoin réel.
- Système difficile à modifier localement.

---

## 20. Règles synthétiques à appliquer

- Écrire du code pour les humains avant tout.
- Une responsabilité claire par composant.
- Des frontières d’architecture nettes.
- Peu de dépendances, bien maîtrisées.
- Pas d’abstraction prématurée.
- Pas de duplication métier durable.
- Des noms précis et cohérents.
- Des fonctions courtes et explicites.
- Peu d’état global, peu d’effets de bord cachés.
- Gestion d’erreurs claire et exploitable.
- Optimiser après mesure.
- Tester le comportement important.
- Logger utilement, sans bruit ni fuite sensible.
- Refactoriser avant que la dette ne domine.
- Préférer la robustesse, la simplicité et l’évolutivité.

## 21. Checklist rapide avant validation

- Le code est-il compréhensible sans explication orale ?
- Les responsabilités sont-elles bien séparées ?
- Les dépendances sont-elles justifiées et maîtrisées ?
- Le nommage reflète-t-il vraiment l’intention ?
- Une duplication inutile existe-t-elle ?
- Le flux principal est-il facile à suivre ?
- Les erreurs sont-elles bien gérées ?
- Les performances critiques sont-elles raisonnables ?
- Les tests couvrent-ils les cas importants ?
- Le changement sera-t-il encore compréhensible dans six mois ?