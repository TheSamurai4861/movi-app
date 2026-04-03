BONNES PRATIQUES DE CODE ET D’ARCHITECTURE CLEAN
===============================================

1. PRINCIPES GÉNÉRAUX
---------------------
- Écris du code pour les humains d’abord, pour la machine ensuite.
- Cherche la clarté avant l’intelligence technique.
- Préfère un code simple, lisible, testable et prévisible.
- Une bonne architecture réduit le coût du changement.
- Chaque choix doit améliorer au moins un de ces points :
  lisibilité, maintenabilité, testabilité, évolutivité.

2. RÈGLES DE NOMMAGE
--------------------
- Utilise des noms explicites.
  Mauvais : data, thing, temp, obj
  Bon : userProfile, invoiceRepository, calculateTotalPrice
- Une variable doit décrire ce qu’elle contient.
- Une fonction doit décrire ce qu’elle fait.
- Une classe doit décrire sa responsabilité métier.
- Évite les abréviations floues sauf si elles sont universelles.
- Sois cohérent dans toute la base de code.

3. FONCTIONS / MÉTHODES
-----------------------
- Une fonction = une responsabilité claire.
- Garde les fonctions courtes.
- Limite le nombre de paramètres.
- Préfère passer un objet structuré si la signature devient confuse.
- Une fonction doit avoir un nom aligné avec son comportement réel.
- Évite les fonctions qui :
  - valident
  - transforment
  - sauvegardent
  - loggent
  tout en même temps.
- Si une fonction demande beaucoup d’explications, elle est souvent trop complexe.

4. CLASSES
----------
- Une classe = une seule responsabilité principale.
- Une classe ne doit pas devenir un “fourre-tout”.
- Si une classe gère trop de règles métier, trop d’états ou trop de dépendances,
  elle doit être découpée.
- Les classes doivent être petites, compréhensibles et spécialisées.

5. GOD CLASS / GOD OBJECT
-------------------------
Signaux d’alerte :
- classe énorme
- trop de méthodes
- trop d’attributs
- trop de responsabilités
- dépend de tout
- connue partout dans le projet
- difficile à tester
- modifiée en permanence

Comment corriger :
- séparer les responsabilités
- extraire des services métier
- extraire des use cases
- isoler la persistance
- isoler la logique UI
- réduire le couplage
- introduire des interfaces claires entre modules

6. COMMENTAIRES
---------------
- Le meilleur commentaire est souvent un code plus clair.
- Ne commente pas l’évidence.
  Mauvais : increment x by 1
  x = x + 1
- Commente uniquement ce que le code ne peut pas bien exprimer :
  - pourquoi un choix a été fait
  - contrainte métier
  - workaround technique
  - piège connu
  - hypothèse importante
- Les commentaires doivent rester vrais.
- Supprime ou mets à jour les commentaires obsolètes.
- Évite les blocs de commentaires inutiles et bavards.

7. STRUCTURE DU CODE
--------------------
- Regroupe le code par responsabilité métier, pas seulement par type technique.
- Préfère des modules cohérents plutôt qu’un dossier “utils” géant.
- Évite les fichiers énormes.
- Évite les dépendances circulaires.
- Organise le projet de façon à ce qu’un nouveau développeur comprenne vite :
  - où est la logique métier
  - où est l’accès aux données
  - où est l’UI/API
  - où sont les tests

8. CLEAN ARCHITECTURE
---------------------
Objectif :
- protéger la logique métier du framework, de l’UI, de la DB et des détails externes.

Séparation classique :
- Domain
  - entités
  - value objects
  - règles métier pures
  - interfaces métier
- Application
  - use cases
  - orchestration métier
  - validation applicative
- Infrastructure
  - base de données
  - API externes
  - fichiers
  - implémentations concrètes
- Presentation
  - UI
  - contrôleurs
  - routes
  - view models

Règle centrale :
- les couches internes ne doivent pas dépendre des couches externes.
- le métier ne dépend pas du framework.
- le métier ne dépend pas de la base de données.
- le métier ne dépend pas de l’interface graphique.

9. DÉPENDANCES
--------------
- Dépends des abstractions, pas des implémentations concrètes.
- Injecte les dépendances au lieu de les créer partout avec new.
- Évite le couplage fort.
- Une classe ne doit pas connaître trop de détails d’un autre module.
- Réduis les effets de bord cachés.

10. SOLID
---------
S - Single Responsibility Principle
- une classe ou un module ne doit avoir qu’une seule raison de changer

O - Open/Closed Principle
- ouvert à l’extension, fermé à la modification brutale

L - Liskov Substitution Principle
- une implémentation enfant doit pouvoir remplacer son parent sans casser le comportement attendu

I - Interface Segregation Principle
- préfère plusieurs petites interfaces qu’une grosse interface universelle

D - Dependency Inversion Principle
- les couches haut niveau ne doivent pas dépendre des détails bas niveau

11. GESTION DE LA COMPLEXITÉ
----------------------------
- Remplace la complexité implicite par une structure explicite.
- Évite les conditions imbriquées profondes.
- Préfère :
  - early returns
  - stratégies
  - polymorphisme
  - mapping clair
- Réduis les “if” métier répétitifs si une abstraction est possible.
- Découpe les traitements longs en étapes nommées.

12. DUPLICATION
---------------
- Ne duplique pas la logique métier.
- Mais n’extrais pas trop tôt juste pour “faire propre”.
- DRY ne veut pas dire fusionner des choses qui se ressemblent seulement en surface.
- Attends parfois une répétition stable avant d’abstraire.
- Préfère une duplication légère à une mauvaise abstraction.

13. GESTION DES ERREURS
-----------------------
- Ne masque pas les erreurs importantes.
- Utilise des messages d’erreur explicites.
- Différencie :
  - erreur métier
  - erreur technique
  - erreur utilisateur
- Gère les cas limites explicitement.
- Loggue ce qui aide vraiment au diagnostic.
- Ne noie pas les logs dans du bruit inutile.

14. TESTABILITÉ
---------------
- Un code difficile à tester est souvent mal conçu.
- Isole la logique métier pure du code technique.
- Teste surtout :
  - règles métier
  - cas limites
  - comportements critiques
  - régressions connues
- Les tests doivent être lisibles et fiables.
- Un test doit vérifier une intention claire.
- Évite les tests trop dépendants de l’implémentation interne.

15. LISIBILITÉ
--------------
- Préfère 10 lignes évidentes à 3 lignes “brillantes” mais opaques.
- Aère le code.
- Utilise des blocs logiques bien séparés.
- Garde une indentation simple.
- Sois cohérent dans le style.
- Un lecteur doit comprendre vite :
  - ce qui entre
  - ce qui se passe
  - ce qui sort

16. CONVENTIONS D’ÉQUIPE
------------------------
- Définis des règles partagées :
  - nommage
  - structure de dossiers
  - style de tests
  - gestion des erreurs
  - logs
  - conventions de commentaires
- Automatise avec :
  - formatter
  - linter
  - analyse statique
  - CI
- La cohérence est souvent plus importante que la préférence personnelle.

17. CODE REVIEW
---------------
En review, vérifie :
- la responsabilité est-elle claire ?
- le nommage est-il précis ?
- la logique métier est-elle au bon endroit ?
- y a-t-il une god class en train d’apparaître ?
- les dépendances sont-elles propres ?
- le code est-il testable ?
- le changement est-il localisé ou répand-il du couplage ?
- les commentaires sont-ils utiles et à jour ?

18. SMELLS À SURVEILLER
-----------------------
- classes énormes
- fichiers énormes
- méthodes trop longues
- switch/if répétés partout
- variables aux noms flous
- dépendances circulaires
- trop de paramètres
- logique métier dans l’UI
- logique SQL partout
- “utils” qui contient tout et n’importe quoi
- copier-coller massif
- commentaires qui compensent un code confus
- code impossible à tester sans lancer tout le système

19. RÈGLES PRATIQUES SIMPLES
----------------------------
- 1 module = 1 rôle clair
- 1 fonction = 1 intention claire
- 1 classe = 1 responsabilité principale
- le métier au centre
- les détails techniques à l’extérieur
- nomme précisément
- commente le “pourquoi”, pas le “quoi”
- évite les god classes
- évite les dépendances inutiles
- fais des abstractions seulement quand elles sont utiles
- écris du code que tu comprendras encore dans 6 mois

20. OBJECTIF FINAL
------------------
Un bon projet n’est pas celui qui paraît “sophistiqué”.
C’est celui où :
- on comprend vite où modifier
- on casse peu de choses en changeant
- on teste facilement
- on sépare bien le métier du technique
- on peut faire évoluer le système sans douleur majeure