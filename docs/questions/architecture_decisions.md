# Questions – Architecture & Organisation

1. Confirme-t-on l’utilisation d’une architecture clean (layered): presentation → domain → data → infrastructure ?
Oui bien sûr, avec des features
2. Riverpod doit-il rester l’outil principal de gestion d’état ou doit-on basculer vers GetIt seul / bloc ?
Je veux utiliser l'outil le plus adapté à l'envergure du projet
3. Comment structurer les dossiers : `features/<feature>/{domain,data,presentation}` ou autre ? Oui c'est bon
4. Quel est le niveau de modularisation attendu pour le MVP (package Flutter séparé ou monolithique) ? Je sais pas
5. Souhaitons-nous partager certains modules (authentification, analytics, streaming) entre plusieurs applis ? Non je ne pense pas
6. Quelles sont les conventions (naming, suffixes, generics) à appliquer pour entités/usecases/repositories ? les standards
7. Faut-il introduire des bundles spécifiques pour les tests (fixtures, fake data sources) ? non par pour l'instant
8. Comment gère-t-on la configuration (flavors, env vars) entre plateformes (mobile, desktop, web) ? au mieux
9. Y a-t-il des contraintes fortes sur la taille de l’app ou la performance (TV, set-top-box) ? Non dabord un app pour mobile 
10. Comment documenter les décisions (ADR, wiki interne, README) ? docs/
