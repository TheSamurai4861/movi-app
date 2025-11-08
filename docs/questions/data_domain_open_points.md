# Questions ouvertes – Couche Data & Domain

1. Quelles sont les sources de données prévues ? API REST unique, services multiples (films, séries, personnes), flux IPTV ?
Flux IPTV XTREAM principalement
2. Dispose-t-on d’une documentation API (schemas de réponse, authentification, paginations) ?
Je pourrais fournir des documents
3. Faut-il supporter plusieurs environnements (dev/staging/prod) avec endpoints différents ?
Oui
4. Quels sont les modèles clés à prioriser (movie, series, season, episode, person, saga, playlist) et leurs attributs minimum pour le MVP ?
movie, serie, season, episode, person, saga, playlist, user
5. Souhaite-t-on implémenter un cache local ? Si oui, quelles sections doivent rester disponibles offline (watchlist, continue watching, favoris) ?
Je souhaiterais que les données téléchargées via l'API TMDB soit stockée dans une db locale pour les retrouver plus rapidement
6. Quelle stratégie d’erreurs est attendue (exceptions métiers, retry, fallback local) ?
Je sais pas
7. Le repository doit-il agréger plusieurs sections en une seule requête (ex : HomeFeed) ou découper les appels ?
Au mieux
8. Comment gérer la pagination et le lazy loading (scroll horizontal/vertical) ?
Au mieux
9. Quels sont les délais et contraintes de rafraîchissement du contenu (temps réel, 24h, manuel) ?
2 fois par jour
10. Doit-on prévoir des tests contractuels (ex. compatibilité avec contrats backend) ou des snapshots mocked ?
Non
