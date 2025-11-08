# Documentation du protocole Xtream API

## Introduction à l'API Xtream Codes

L’**API Xtream Codes** (souvent appelée simplement **Xtream API**) est une interface utilisée par de nombreux services IPTV pour exposer leurs contenus (chaînes TV en direct, films VOD et séries TV) aux applications clientes. En interrogeant cette API, un développeur peut obtenir les listes de chaînes, de films et de séries d’un fournisseur IPTV, ainsi que des informations détaillées sur chaque média. L’API retourne généralement des données au format JSON, ce qui facilite leur traitement dans des applications.

Deux approches existent pour récupérer les données d’un service IPTV basé sur Xtream Codes :

* **Récupération via playlist M3U** : Une URL du type get.php permet de télécharger en une fois une playlist M3U contenant tous les flux (Live, VOD, séries) et leurs catégories. Par exemple :

* http://serveur:port/get.php?username=USER\&password=PASS\&type=m3u\_plus\&output=ts

* Cette méthode fournit tout d’un bloc, mais peut produire des fichiers très volumineux.

* **Utilisation de l’API JSON (Xtream API)** : Permet de *naviguer* et de récupérer progressivement les données via des requêtes HTTP sur player\_api.php. Cette méthode est plus flexible et adaptée aux applications interactives. C’est cette approche qui est détaillée dans la suite de la documentation.

## Vue d’ensemble du fonctionnement de l’API

Lorsqu’une application utilise l’API Xtream, elle effectue typiquement une série de requêtes dans un ordre logique pour récupérer toutes les informations nécessaires. Un flux de travail courant pour obtenir toutes les données est le suivant :

1. **Authentification de l’utilisateur** – Vérifier les identifiants et récupérer les infos de compte :

* http://serveur:port/player\_api.php?username=USER\&password=PASS

2. **Catégories des chaînes Live** – Obtenir la liste des catégories de TV en direct :

* http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_live\_categories

3. **Liste des chaînes Live** – Obtenir la liste de toutes les chaînes TV en direct (éventuellement filtrée par catégorie) :

* http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_live\_streams

4. **Catégories de Séries** – Obtenir la liste des catégories de séries TV :

* http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_series\_categories

5. **Liste des Séries** – Obtenir la liste de toutes les séries disponibles (éventuellement par catégorie) :

* http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_series

6. **Catégories VOD (films)** – Obtenir la liste des catégories de contenus VOD (films) :

* http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_vod\_categories

7. **Liste des Films VOD** – Obtenir la liste de tous les films disponibles (éventuellement par catégorie) :

* http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_vod\_streams

8. **(Optionnel) Détails d’un média spécifique** – Obtenir des informations détaillées sur un film ou une série donnée (synopsis, acteurs, durée, etc.) via des requêtes spécifiques que nous verrons plus loin.

Chaque requête retourne un document JSON contenant les données demandées. L’application peut alors présenter ces données à l’utilisateur (par ex. afficher les catégories, puis les listes de contenus dans chaque catégorie, etc.). Dans la suite, nous décrivons chaque étape plus en détail.

## 1\. Authentification et informations utilisateur

La première étape consiste à appeler l’API sans paramètre action, uniquement avec le nom d’utilisateur (username) et le mot de passe (password). Cela permet de vérifier que les identifiants sont valides et de récupérer des informations sur le compte et le serveur.

**Requête d’authentification :**

http://serveur:port/player\_api.php?username=USER\&password=PASS

(Remplacez serveur:port par le domaine/IP et port du fournisseur IPTV, et USER/PASS par vos identifiants.)

**Réponse JSON attendue :** Si les identifiants sont corrects, le serveur renvoie un objet JSON contenant deux sections principales : user\_info (informations du compte utilisateur) et server\_info (informations sur le serveur). Par exemple :

{  
  "user\_info": {  
    "username": "demo\_user",  
    "password": "demo\_pass",  
    "message": "User authenticated successfully",  
    "auth": 1,  
    "status": "Active",  
    "exp\_date": "1672531199",  
    "is\_trial": "0",  
    "active\_cons": "1",  
    "created\_at": "1577836800",  
    "max\_connections": "3",  
    "allowed\_output\_formats": \["m3u8", "ts", "rtmp"\]  
  },  
  "server\_info": {  
    "url": "http://votre.serveur",  
    "port": "8080",  
    "https\_port": "443",  
    "server\_protocol": "http",  
    "rtmp\_port": "1935",  
    "timezone": "Europe/Paris",  
    "timestamp\_now": 1730977200,  
    "time\_now": "2025-11-07 08:00:00"  
  }  
}

Dans cet exemple :

* **user\_info** comprend les détails du compte utilisateur :

* username et password : rappel des identifiants utilisés pour la requête.

* message : message d’état, par ex. *« User authenticated successfully »* (peut être vide ou différent selon les cas d’erreur).

* auth : drapeau d’authentification (1 si la connexion est réussie, 0 en cas d’échec)[\[1\]](http://ottpanel.tv/player_api.html#:~:text=,3).

* status : statut du compte (souvent "Active" si l’abonnement est actif)[\[1\]](http://ottpanel.tv/player_api.html#:~:text=,3).

* exp\_date : date d’expiration de l’abonnement, au format timestamp Unix (peut être "0" ou absent si pas de date d’expiration définie).

* is\_trial : indique si le compte est un essai gratuit ( "1" pour oui, "0" pour non).

* active\_cons : nombre de connexions actuellement actives sur ce compte.

* created\_at : date de création du compte (timestamp Unix).

* max\_connections : nombre maximal de connexions simultanées autorisées pour ce compte.

* allowed\_output\_formats : liste des formats de streaming supportés par le serveur pour ce compte (ex. "ts", "m3u8", "rtmp" etc., ce qui permet de savoir quel type de flux on pourra utiliser)[\[2\]](http://ottpanel.tv/player_api.html#:~:text=,http%3A%2F%2Fyour.dns).

* **server\_info** fournit des informations sur le serveur et les URLs de base :

* url : l’URL de base du serveur API (souvent répète le domaine ou l’IP fournis).

* port : le port utilisé pour le streaming *HTTP* (souvent le même que dans l’URL de base).

* https\_port : le port pour HTTPS si disponible (sinon cette valeur peut être absente ou différente).

* server\_protocol : le protocole utilisé par le serveur (par ex. "http" ou "https").

* rtmp\_port : port du service RTMP si le serveur en propose un (sinon valeur par défaut, ex: "1935").

* timezone : le fuseau horaire du serveur.

* timestamp\_now : l’heure actuelle sur le serveur, en timestamp Unix.

* time\_now : l’heure actuelle formatée (chaine lisible).

**Remarque :** Si les identifiants sont invalides, le champ auth vaudra 0 et il se peut que le JSON ne contienne qu’un message d’erreur ou soit vide. Assurez-vous donc de vérifier user\_info.auth avant de continuer.

Cette étape d’authentification est indispensable : elle valide l’accès et donne également des informations utiles (ex. formats disponibles, nombre de connexions autorisées) dont l’application peut tenir compte.

## 2\. Récupération des catégories de contenu

Les contenus IPTV sont généralement organisés en catégories (par exemple : catégories de chaînes par langue ou par thème, catégories de films par genre, catégories de séries, etc.). L’API propose trois points de terminaison pour récupérer ces listes de catégories, en fonction du type de média :

* **Catégories des chaînes TV (Live)** : action=get\_live\_categories

* **Catégories des films (VOD)** : action=get\_vod\_categories

* **Catégories des séries TV** : action=get\_series\_categories

**Exemple de requête pour les catégories Live :**

http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_live\_categories

Chacune de ces requêtes renvoie une liste d’objets JSON représentant les catégories disponibles. Par exemple, une catégorie est décrite ainsi :

{  
  "category\_id": "2105",  
  "category\_name": "Films Science Fiction",  
  "parent\_id": "0"  
}

**Signification des champs :**

* category\_id : l’identifiant numérique de la catégorie. Cet ID servira pour filtrer les contenus par catégorie si nécessaire.

* category\_name : le nom de la catégorie (par exemple "Chaînes Françaises", "Films Action", "Séries Netflix", etc.), tel que défini par le fournisseur.

* parent\_id : identifiant du parent dans une hiérarchie de catégories. En pratique, la plupart des fournisseurs n’organisent pas les catégories de manière imbriquée, et ce champ vaut généralement "0" (aucun parent). S’il est différent de 0, cela signifie que la catégorie est une sous-catégorie d’une autre dont l’ID est donné par parent\_id.

En utilisant ces listes, une application peut afficher la liste des catégories à l’utilisateur. Par exemple, les catégories de chaînes Live pourraient être "Sport", "Actualités", "Divertissement", etc., tandis que les catégories de VOD pourraient être "Nouveautés", "Comédies", "Science-Fiction", etc.

## 3\. Récupération des listes de contenus (flux)

Une fois les catégories obtenues, on peut récupérer les listes de contenus (aussi appelés *flux* ou *streams*) pour chaque type de média. L’API fournit des actions pour lister tous les éléments ou filtrer par catégorie spécifique :

* **Liste des chaînes TV en direct (Live)** : action=get\_live\_streams (avec éventuellement \&category\_id=X pour filtrer une catégorie spécifique).

* **Liste des films VOD** : action=get\_vod\_streams (optionnellement avec \&category\_id=X).

* **Liste des séries TV** : action=get\_series (optionnellement avec \&category\_id=X).

### 3.1 Chaînes TV en direct (Live)

**Requête pour toutes les chaînes :**

http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_live\_streams

Cette requête retourne un tableau JSON où chaque élément représente une chaîne TV disponible. Si vous souhaitez limiter aux chaînes d’une catégorie particulière, vous pouvez ajouter \&category\_id=ID\_DE\_CAT à la requête. Par exemple ...\&action=get\_live\_streams\&category\_id=3 pour obtenir les chaînes de la catégorie 3[\[3\]](http://ottpanel.tv/player_api.html#:~:text=Retrieve%20all%20live%20streams).

**Exemple d’un objet chaîne Live :**

{  
  "num": 1,  
  "name": "CSPAN",  
  "stream\_type": "live",  
  "stream\_id": 135754,  
  "stream\_icon": "http://logo.com/cspan1.png",  
  "epg\_channel\_id": "cspan1.us",  
  "added": "1593343679",  
  "custom\_sid": "",  
  "tv\_archive": 0,  
  "direct\_source": "",  
  "tv\_archive\_duration": 0,  
  "category\_id": "3"  
}

Voici la signification des principaux champs pour une chaîne TV :

* num : Numéro index de l’élément dans la liste (commence à 1 et s’incrémente pour chaque chaîne). Ce n’est pas un identifiant permanent, juste un index de tri.

* name : Nom de la chaîne tel que fourni (par ex. le nom de la chaîne TV).

* stream\_type : Type de flux \= "live" dans ce cas (chaîne en direct).

* stream\_id : Identifiant unique du flux de la chaîne. **C’est cet identifiant qu’il faudra utiliser pour construire l’URL de lecture du stream.**

* stream\_icon : URL du logo ou de l’icône de la chaîne (s’il est fourni par le fournisseur).

* epg\_channel\_id : Identifiant de la chaîne pour l’EPG (guide TV) si disponible, sinon peut être vide. C’est utile pour faire correspondre la chaîne à un programme TV dans un guide électronique.

* added : Date d’ajout de la chaîne sur le serveur, exprimée en timestamp Unix.

* custom\_sid : Identifiant personnalisé du service (généralement vide ou inutilisé pour les flux live).

* tv\_archive : Indique si la chaîne a une fonction de **catch-up** (TV archive/enregistrements disponibles). 0 \= non, 1 \= oui.

* tv\_archive\_duration : Durée de la catch-up (en jours par ex) si tv\_archive est actif.

* direct\_source : Source directe du flux si fournie (souvent vide car le flux passe par le serveur Xtream).

* category\_id : Identifiant de la catégorie à laquelle appartient cette chaîne (fait le lien avec les catégories obtenues plus haut).  
  *(Dans l’exemple, "category\_id": "3" signifie que cette chaîne figure dans la catégorie ID 3 — on peut vérifier quel nom de catégorie correspond à l’ID 3 via la liste des catégories.)*

La réponse peut contenir de nombreux canaux (selon l’abonnement, parfois des centaines ou milliers de chaînes). L’application peut par exemple filtrer/organiser ces chaînes par catégorie en s’aidant du champ category\_id.

### 3.2 Films VOD (Video on Demand)

**Requête pour tous les films :**

http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_vod\_streams

Comme pour les live, on peut ajouter \&category\_id=X pour ne récupérer que les films d’une catégorie donnée[\[4\]](http://ottpanel.tv/player_api.html#:~:text=GET%20VOD%20Streams).

La réponse est un tableau JSON listant les films disponibles. Chaque film est décrit par un ensemble de champs similaires, adaptés aux contenus VOD :

**Exemple d’un objet film VOD :**

{  
  "num": 5,  
  "name": "Inception",  
  "stream\_type": "movie",  
  "stream\_id": 771597,  
  "cover": "http://images.server/cover/inception.jpg",  
  "rating": "7.8",  
  "rating\_5based": 3.9,  
  "added": "1722268584",  
  "category\_id": "2105",  
  "container\_extension": "mkv",  
  "custom\_sid": null,  
  "direct\_source": "",  
  "tmdb\_id": "27205",  
  "youtube\_trailer": "8hP9D6kZseM"  
}

Explication des champs spécifiques aux films :

* num : Index dans la liste (comme pour les chaînes).

* name : Titre du film.

* stream\_type : "movie" pour indiquer qu’il s’agit d’un film (contenu VOD).

* stream\_id : Identifiant unique du film dans la base du fournisseur. **C’est l’ID à utiliser pour demander le flux vidéo du film.**

* cover : URL de la pochette/affiche du film (image d’illustration).

* rating : Note du film (souvent sur 10, en chaîne de caractères).

* rating\_5based : Note du film sur 5 (dans l’exemple 3.9 sur 5, ce qui correspond à 7.8/10).

* added : Date d’ajout du film sur le serveur (timestamp Unix).

* category\_id : ID de la catégorie du film (pour savoir quel genre ou section ce film occupe).

* container\_extension : Extension/format du fichier vidéo sur le serveur (par ex. "mkv", "mp4"...). Ceci indique le format du conteneur que le flux utilisera.

* custom\_sid : (laissé vide ou null dans la plupart des cas pour les VOD).

* direct\_source : (souvent vide ; parfois l’URL directe vers la source si fournie, mais généralement non renseigné pour les films).

* tmdb\_id : Identifiant du film sur **TheMovieDB** (un site de base de données de films). Ici "27205" correspond à *Inception*. Ce champ est très utile pour les applications qui souhaitent récupérer des métadonnées supplémentaires (résumé, affiches haute résolution, etc.) via l’API de TheMovieDB, par exemple.

* youtube\_trailer : Identifiant YouTube de la bande-annonce du film, s’il est fourni. Dans l’exemple "8hP9D6kZseM" correspond à l’URL YouTube https://www.youtube.com/watch?v=8hP9D6kZseM.

On voit que l’information fournie pour les films est déjà assez riche (affiche, notes, bande-annonce, etc.). Une application peut afficher ces données à l’utilisateur dans une interface de type catalogue.

**Contenus récents :** Notez que l’API offre aussi des variantes comme action=get\_vod\_latest pour obtenir, par exemple, les 100 derniers films ajoutés[\[5\]](http://ottpanel.tv/player_api.html#:~:text=GET%20Latest%20VOD%20Streams), et de même get\_series\_latest pour les séries[\[6\]](http://ottpanel.tv/player_api.html#:~:text=GET%20Latest%20SERIES%20Streams). Cela peut servir à mettre en avant les nouveautés.

### 3.3 Séries TV

Les séries TV ont un comportement un peu différent car, à la différence des films, une série contient plusieurs épisodes (et saisons). L’API gère cela en deux temps : d’abord obtenir la liste des séries disponibles, puis récupérer le détail d’une série (y compris la liste de ses épisodes) via une requête séparée.

**Requête pour toutes les séries :**

http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_series

(On peut aussi filtrer par catégorie avec \&category\_id=X si on veut les séries d’un genre particulier[\[7\]](http://ottpanel.tv/player_api.html#:~:text=GET%20SERIES%20Streams).)

La réponse à get\_series est une liste JSON de séries. Chaque série inclut des informations générales :

**Exemple d’un objet série (dans la liste) :**

{  
  "name": "Nom de la série",  
  "cover": "http://images.server/covers/serie.jpg",  
  "year": "2024",  
  "stream\_type": "series",  
  "series\_id": 1157,  
  "plot": "Résumé de la série...",  
  "cast": "Acteur1, Acteur2, ...",  
  "director": "Réalisateur Nom",  
  "genre": "Action, Drame",  
  "release\_date": "2024",  
  "last\_modified": "1607910711",  
  "rating": "7",  
  "rating\_5based": 3.5,  
  "backdrop\_path": \[  
      "http://images.server/backdrops/serie\_bg1.jpg",  
      "http://images.server/backdrops/serie\_bg2.jpg"  
  \],  
  "youtube\_trailer": "wjOF95yYPH0",  
  "episode\_run\_time": "40",  
  "category\_id": "3075",  
  "category\_ids": \["3075"\],  
  "tmdb\_id": "3845"  
}

Champs principaux pour une série :

* name : Titre de la série.

* cover : URL de l’image de couverture (affiche) de la série.

* year : Année de sortie (souvent l’année de la première saison).

* stream\_type : "series" indique qu’il s’agit d’une série.

* series\_id : Identifiant unique de la série. **C’est cet ID qui sera utilisé pour aller chercher la liste des épisodes.**

* plot : Synopsis de la série.

* cast : Liste des acteurs principaux.

* director : Réalisateur ou créateur de la série.

* genre : Genres de la série.

* release\_date : Date de sortie initiale (parfois redondant avec year).

* last\_modified : Timestamp Unix de la dernière modification (peut indiquer la dernière mise à jour de la série sur le serveur).

* rating / rating\_5based : Note de la série (même principe que pour les films).

* backdrop\_path : Liste d’URL d’images d’arrière-plan / fonds d’écran pour la série (souvent utilisées dans les applications pour une bannière ou un fond).

* youtube\_trailer : Identifiant YouTube d’une bande-annonce de la série.

* episode\_run\_time : Durée moyenne d’un épisode (en minutes).

* category\_id / category\_ids : Identifiant(s) de catégorie auxquels appartient la série (similaire au champ pour les films).

* tmdb\_id : Identifiant de la série sur TheMovieDB (pour enrichir les infos si besoin).

**Remarque :** On constate que la réponse de get\_series fournit déjà pas mal de détails sur la série elle-même (synopsis, casting, etc.), mais **pas le détail des épisodes**. Pour obtenir la liste des épisodes d’une série, il faut utiliser une autre requête get\_series\_info comme expliqué ci-dessous.

### 3.4 Détail des épisodes d’une série

Pour une série donnée (identifiée par son series\_id), l’API propose :

**Requête d’infos d’une série (épisodes) :**

http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_series\_info\&series\_id=1157

(en remplaçant 1157 par l’ID de la série voulue).

Cette requête retourne un objet JSON contenant typiquement deux sections : des infos sur la série (series\_info reprenant possiblement les infos déjà vues) et surtout la liste des épisodes organisés par saisons.

La structure pour les épisodes peut varier un peu selon les versions de l’API, mais généralement on obtient un champ episodes qui peut être soit un dictionnaire (un objet JSON) où chaque clé est un numéro de saison, soit un tableau de tableaux[\[8\]](https://github.com/K4L4Uz/SFVIP-Player/issues/12#:~:text=%7B%20,%5D%2C%20%7D)[\[9\]](https://github.com/K4L4Uz/SFVIP-Player/issues/12#:~:text=But%20it%20sometimes%20uses%20this,format%20too). Dans le cas le plus courant, on a :

{  
  "series\_info": { /\* ... infos de la série ... \*/ },  
  "episodes": {  
      "1": \[   
         { /\* Épisode 1 de la saison 1 \*/ },  
         { /\* Épisode 2 de la saison 1 \*/ },  
         ...  
      \],  
      "2": \[  
         { /\* Épisode 1 de la saison 2 \*/ },  
         ...  
      \],  
      ...  
  }  
}

Ici, les clés "1", "2", etc. sous episodes représentent les numéros de saison[\[8\]](https://github.com/K4L4Uz/SFVIP-Player/issues/12#:~:text=%7B%20,%5D%2C%20%7D). Par exemple "1" pour la saison 1, "2" pour la saison 2, etc. Chaque valeur est un tableau listant les épisodes de cette saison. Dans certains cas, l’API peut renvoyer directement un tableau imbriqué (par ex. episodes: \[ \[ep1\_s1,...\], \[ep1\_s2,...\] \]), mais le principe reste que les épisodes sont groupés par saison.

**Chaque épisode** est décrit par un objet contenant notamment :

* un identifiant d’épisode (souvent nommé id ou episode\_id – qui est en fait l’identifiant de stream pour cet épisode),

* le titre de l’épisode (title),

* éventuellement le numéro d’épisode (episode\_num),

* la date de diffusion (releaseDate),

* et possiblement une URL d’image ou d’autres métadonnées.

Par exemple, un épisode peut ressembler à :

{  
  "id": 83550,  
  "episode\_num": 1,  
  "title": "Episode 1",  
  "container\_extension": "mkv",  
  "info": {  
    "duration\_secs": 3600,  
    "releaseDate": "2024-01-01",  
    "plot": "Description de l'épisode..."  
  }  
}

* id : Identifiant du flux de l’épisode (**c’est l’équivalent d’un stream\_id pour un épisode**).

* episode\_num : Numéro de l’épisode dans la saison.

* title : Titre de l’épisode.

* container\_extension : Format/extension du fichier de l’épisode (ex. "mkv", "mp4", etc.).

* info : un sous-objet avec des détails comme la durée duration\_secs, la date de sortie releaseDate, le résumé plot, etc.

Ainsi, pour récupérer une série complète, l’application pourrait d’abord lister les séries via get\_series, puis lorsqu’un utilisateur choisit une série particulière, appeler get\_series\_info\&series\_id=X pour obtenir les épisodes de cette série. On peut ensuite afficher les saisons et les épisodes correspondants.

**Note technique :** Le format JSON des épisodes peut nécessiter quelques adaptations dans le code, car il n’est pas toujours uniforme (dictionnaire vs tableau). Certains parseurs doivent gérer les deux cas. Par exemple, il a été noté que parfois episodes est renvoyé comme un tableau indexé par saison plutôt qu’un objet, ce qui peut perturber certains logiciels[\[8\]](https://github.com/K4L4Uz/SFVIP-Player/issues/12#:~:text=%7B%20,%5D%2C%20%7D)[\[9\]](https://github.com/K4L4Uz/SFVIP-Player/issues/12#:~:text=But%20it%20sometimes%20uses%20this,format%20too). Il faut donc prendre en compte cette possible variation.

## 4\. Informations détaillées sur un média (optionnel)

Dans de nombreux cas, les informations fournies par les listes (chaînes, films, séries) suffisent pour afficher un catalogue. Cependant, l’API permet d’obtenir des détails supplémentaires sur un contenu spécifique via des actions dédiées :

* **Détails d’un film (VOD)** : action=get\_vod\_info\&vod\_id=X – retourne des informations détaillées sur le film dont l’identifiant est X.

* **Détails d’une série** : action=get\_series\_info\&series\_id=Y – (nous l’avons vu ci-dessus, cela donne surtout les épisodes de la série Y, ainsi que quelques infos possiblement redondantes sur la série).

La requête get\_vod\_info est particulièrement utile si on veut des détails techniques sur le fichier vidéo ou des métadonnées complètes. Par exemple :

http://serveur:port/player\_api.php?username=USER\&password=PASS\&action=get\_vod\_info\&vod\_id=771597

(peut être utilisée pour le film d’ID 771597 dans notre exemple précédent).

**Exemple de réponse pour get\_vod\_info :**

{  
  "movie\_data": {  
    "stream\_id": 771597,  
    "name": "|FR| Matchmaking (VOST)",  
    "added": "1722268584",  
    "category\_id": "2105",  
    "container\_extension": "mkv"  
    /\* ...autres champs... \*/  
  },  
  "movie\_image": "http://.../posters/771597.jpg",  
  "backdrop\_path": \["http://.../backdrops/771597\_bg.jpg"\],  
  "youtube\_trailer": "w5O1MXQm4qA",  
  "genre": "Comedy, Romance",  
  "plot": "Résumé du film ...",  
  "cast": "Acteur1, Acteur2, ...",  
  "director": "Erez Tadmor",  
  "rating": "7",  
  "releasedate": "15 September 2022",  
  "tmdb\_id": 1027974,  
  "duration\_secs": 5636,  
  "duration": "01:33:56",  
  "video": {  
     "width": 1280,  
     "height": 720,  
     "codec\_name": "h264",  
     /\* ... d’autres détails techniques vidéo ... \*/  
  },  
  "audio": {  
     "codec\_name": "ac3",  
     "sample\_rate": "48000",  
     "channels": 2,  
     /\* ... d’autres détails audio ... \*/  
  },  
  "bitrate": 3264  
}

On le voit, get\_vod\_info renvoie beaucoup d’informations : images (affiche, backdrop), trailer, genre, synopsis, casting, réalisateur, note, date de sortie, durée totale, et même des informations techniques sur la vidéo et l’audio (codec, résolution, bitrate, etc.). Toutes ces données peuvent être utilisées pour afficher une fiche détaillée du film dans l’application. Les champs comme video et audio contiennent les métadonnées techniques issues du fichier vidéo sur le serveur (résolution, codec vidéo, codec audio, nombre de canaux, etc.).

Il n’est généralement pas nécessaire d’afficher toutes ces informations à l’utilisateur final, mais pour un développeur elles peuvent servir à adapter le lecteur (par ex. savoir que la vidéo est en 720p H.264 avec son AC3) ou simplement enrichir l’expérience (montrer la durée exacte du film, la bande-annonce, etc.).

Pour les séries, comme déjà expliqué, l’action get\_series\_info fournit essentiellement la liste des épisodes et quelques infos de la série. Il n’existe pas d’action get\_live\_info pour les chaînes live (les informations des chaînes étant fixes et généralement toutes contenues dans la liste des chaînes ou via l’EPG séparé).

## 5\. Récupérer l’URL de streaming (lecture du flux)

Jusqu’ici, nous avons vu comment obtenir les listes de contenus et leurs métadonnées. La question cruciale pour un développeur d’application IPTV est : **comment lire le flux vidéo** d’une chaîne, d’un film ou d’un épisode une fois qu’on a son identifiant ?

La réponse est qu’il faut construire une URL directe vers le flux en utilisant le **type de contenu** et l’identifiant du flux, combinés aux identifiants utilisateur. Les formats d’URL sont standards dans Xtream Codes :

* **Chaînes TV (live)** :

* http://serveur:port/live/USER/PASS/stream\_id.ts

* Par exemple, pour la chaîne de stream\_id 135754, cela donne :  
  http://serveur:port/live/USER/PASS/135754.ts[\[10\]](https://stackoverflow.com/questions/78847811/how-to-build-a-playable-url-from-xtream-codes-api#:~:text=stream%20URL%20as%20follows%3A).  
  Cette URL retourne le flux vidéo de la chaîne en direct (généralement en MPEG-TS). L’extension .ts est la plus courante pour un flux live en direct, mais certains serveurs peuvent supporter .m3u8 pour fournir un playlist HLS. En général, .ts fonctionne comme un flux continu MPEG-TS[\[10\]](https://stackoverflow.com/questions/78847811/how-to-build-a-playable-url-from-xtream-codes-api#:~:text=stream%20URL%20as%20follows%3A).

* **Films (VOD)** :

* http://serveur:port/movie/USER/PASS/stream\_id.extension

* Ici, extension doit être remplacée par le **container\_extension** du film en question (par ex. .mkv, .mp4, etc., tel que fourni dans la liste des films). En reprenant l’exemple du film *Inception* avec stream\_id=771597 et container\_extension="mkv", l’URL serait :  
  http://serveur:port/movie/USER/PASS/771597.mkv[\[11\]](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895#:~:text=The%20file%27s%20actual%20location%20can,into%20a%20simple%20http%20link).  
  En ouvrant cette URL (par exemple dans un lecteur vidéo), on devrait être redirigé vers le flux du film en question.

* **Épisodes de séries** :

* http://serveur:port/series/USER/PASS/episode\_stream\_id.extension

* Pour les séries, on utilise le chemin /series/ et on indique l’identifiant de l’épisode (et non de la série) suivi de son extension. Par exemple, si un épisode a id=83550 et container\_extension="mkv", l’URL sera :  
  http://serveur:port/series/USER/PASS/83550.mkv[\[12\]](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895#:~:text=Similarly%20to%20VOD%2C%20a%20series,into%20a%20simple%20http%20link).  
  Cela correspond à un épisode particulier (par ex. saison 1 épisode 1 d’une série, si cet épisode a cet ID). L’API ne requiert pas de spécifier la saison/épisode dans l’URL, juste l’identifiant unique de l’épisode.

En général, dès qu’on connaît l’URL du flux, on peut soit lancer la lecture dans un lecteur vidéo intégré, soit rediriger l’utilisateur vers cette URL. Par exemple, dans une application web, cela pourrait servir à alimenter une balise vidéo ou une redirection; dans une application native, on ouvrirait ce lien avec un player approprié.

**Résumé des patterns d’URL de lecture :**

* Live : .../live/username/password/stream\_id.ts (flux TV en direct)

* Movie : .../movie/username/password/stream\_id.\<ext\> (film à la demande)

* Series : .../series/username/password/episode\_id.\<ext\> (épisode de série)

Ces URL respectent les limitations du compte : si, par exemple, max\_connections est 1 et qu’une connexion est déjà en cours, ouvrir une nouvelle URL pourra couper la première. De même, si l’abonnement expire (exp\_date dépassée), le serveur refusera la connexion.

**Remarque sur la sécurité :** Les identifiants étant inclus dans l’URL, il est important de ne pas les exposer inconsidérément (par ex. évitez de les laisser dans des journaux ou des messages). De plus, l’utilisation de HTTPS (si le serveur le supporte via https\_port) est recommandée pour éviter que des tiers interceptent les identifiants en clair.

**Exemple pratique (Live)** : Supposons qu’on ait récupéré la liste des chaînes et que l’utilisateur choisisse la chaîne avec name \= "CSPAN" de l’exemple plus haut (ID 135754). L’application construira l’URL de flux comme indiqué. Dès que l’application ou le lecteur ouvre http://serveur:port/live/USER/PASS/135754.ts, le serveur commencera à envoyer le flux vidéo en direct correspondant à CSPAN[\[10\]](https://stackoverflow.com/questions/78847811/how-to-build-a-playable-url-from-xtream-codes-api#:~:text=stream%20URL%20as%20follows%3A).

**Exemple pratique (VOD)** : L’utilisateur choisit *Inception*. L’application sait (via get\_vod\_streams) que le stream\_id du film est 771597 et le format est MKV. Elle peut directement ouvrir http://serveur:port/movie/USER/PASS/771597.mkv pour lire le film[\[11\]](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895#:~:text=The%20file%27s%20actual%20location%20can,into%20a%20simple%20http%20link). Alternativement, elle pourrait d’abord appeler get\_vod\_info\&vod\_id=771597 pour obtenir par exemple la durée ou s’assurer que le flux est disponible, mais ce n’est pas obligatoire pour la lecture – on peut aller directement à l’URL de streaming si l’on connaît l’ID et l’extension.

**Exemple pratique (Séries)** : L’utilisateur choisit *une série* puis un épisode particulier (par exemple *Saison 1, Épisode 1*). L’application aura obtenu l’id de cet épisode via get\_series\_info. Disons que c’est 83550 en MKV. En ouvrant http://serveur:port/series/USER/PASS/83550.mkv, le flux de l’épisode commencera[\[13\]](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895#:~:text=http%3A%2F%2F).

## 6\. Autres fonctionnalités de l’API

Le protocole Xtream Codes propose également d’autres actions et fonctionnalités que les développeurs peuvent exploiter selon les besoins :

* **EPG (Guide TV)** : Via l’endpoint xmltv.php ou les actions get\_short\_epg et get\_simple\_data\_table, il est possible de récupérer les données de programme télé (horaires des émissions) pour les chaînes live. Par exemple:

* xmltv.php?username=USER\&password=PASS renvoie un fichier XMLTV complet avec l’EPG de toutes les chaînes[\[14\]](https://github.com/AndreyPavlenko/Fermata/discussions/434#:~:text=EPG%20%28xmltv)[\[15\]](https://github.com/AndreyPavlenko/Fermata/discussions/434#:~:text=%3E%20%20%20,X%3E%60%20param%20%28default%3D4%29).

* player\_api.php?username=USER\&password=PASS\&action=get\_short\_epg\&stream\_id=X\&limit=Y renvoie un extrait du guide (Y prochains programmes) pour la chaîne X[\[16\]](https://github.com/AndreyPavlenko/Fermata/discussions/434#:~:text=Get%20short%20EPG%20for%20a,dedicated%20live%20streams). Ces données EPG peuvent être utilisées pour afficher le programme en cours, suivant, etc., sur l’interface utilisateur.

* **Filtrage par catégorie dès la requête de streams** : comme mentionné, on peut ajouter un paramètre category\_id aux requêtes get\_live\_streams, get\_vod\_streams et get\_series pour ne récupérer que les éléments d’une catégorie précise[\[17\]](http://ottpanel.tv/player_api.html#:~:text=http%3A%2F%2Fyour)[\[18\]](http://ottpanel.tv/player_api.html#:~:text=Retrieve%20all%20series). Utile pour éviter de charger trop de données si l’application présente les contenus catégorie par catégorie.

* **Derniers ajouts** : get\_vod\_latest et get\_series\_latest permettent d’obtenir rapidement les nouveautés (par exemple pour une section "Derniers films ajoutés").

* **Validation de code actif** : L’action getactivecodepass (sans authentification) est mentionnée dans certaines docs[\[19\]](http://ottpanel.tv/player_api.html#:~:text=GET%20ActiveCode%20Password), mais elle est spécifique à certaines implémentations (Xtream-Masters par ex.) et sert à récupérer un mot de passe d’ActiveCode. Elle est peu utilisée côté clients standard.

La plupart des applications IPTV tierces (lecteurs vidéo, apps mobiles, etc.) qui supportent "Xtream Codes" utilisent en coulisse ces mêmes appels pour récupérer les playlists et flux. En tant que développeur, vous pouvez donc reproduire ce comportement pour intégrer un service compatible Xtream dans votre application.

## Conclusion

En résumé, l’API Xtream Codes fournit un moyen structuré pour **authentifier un utilisateur** puis **naviguer** à travers l’offre IPTV d’un fournisseur : listes de catégories, listes de chaînes TV, de films, de séries, et détails associées. Une fois les identifiants de flux obtenus, la construction des URLs de streaming est directe (/live/, /movie/, /series/ avec username/password et l’identifiant du contenu).

Cette API est très pratique pour les développeurs d'applications IPTV, car elle évite d’avoir à parser des playlists M3U brutes et permet de présenter une interface plus riche (avec affiches, résumés, etc.). Il faut toutefois garder à l’esprit que chaque fournisseur peut avoir des particularités mineures (par ex. certaines valeurs manquantes ou des limitations de taux de requêtes). Mais globalement, le protocole est standardisé et la plupart des services basés sur Xtream Codes réagiront de la même manière aux requêtes décrites dans cette documentation.

En suivant les étapes décrites (authentification, catégories, contenus, détails, puis construction des URLs de lecture), un développeur devrait être en mesure d’exploiter pleinement une API Xtream pour créer son propre lecteur ou intégrer ces contenus dans une plateforme existante.

---

[\[1\]](http://ottpanel.tv/player_api.html#:~:text=,3) [\[2\]](http://ottpanel.tv/player_api.html#:~:text=,http%3A%2F%2Fyour.dns) [\[3\]](http://ottpanel.tv/player_api.html#:~:text=Retrieve%20all%20live%20streams) [\[4\]](http://ottpanel.tv/player_api.html#:~:text=GET%20VOD%20Streams) [\[5\]](http://ottpanel.tv/player_api.html#:~:text=GET%20Latest%20VOD%20Streams) [\[6\]](http://ottpanel.tv/player_api.html#:~:text=GET%20Latest%20SERIES%20Streams) [\[7\]](http://ottpanel.tv/player_api.html#:~:text=GET%20SERIES%20Streams) [\[17\]](http://ottpanel.tv/player_api.html#:~:text=http%3A%2F%2Fyour) [\[18\]](http://ottpanel.tv/player_api.html#:~:text=Retrieve%20all%20series) [\[19\]](http://ottpanel.tv/player_api.html#:~:text=GET%20ActiveCode%20Password) Xtream-Masters \- API Documentation

[http://ottpanel.tv/player\_api.html](http://ottpanel.tv/player_api.html)

[\[8\]](https://github.com/K4L4Uz/SFVIP-Player/issues/12#:~:text=%7B%20,%5D%2C%20%7D) [\[9\]](https://github.com/K4L4Uz/SFVIP-Player/issues/12#:~:text=But%20it%20sometimes%20uses%20this,format%20too) Sfvip Player sometimes fails to list the episodes in a serie · Issue \#12 · K4L4Uz/SFVIP-Player · GitHub

[https://github.com/K4L4Uz/SFVIP-Player/issues/12](https://github.com/K4L4Uz/SFVIP-Player/issues/12)

[\[10\]](https://stackoverflow.com/questions/78847811/how-to-build-a-playable-url-from-xtream-codes-api#:~:text=stream%20URL%20as%20follows%3A) iptv \- How to build a playable url from Xtream Codes API? \- Stack Overflow

[https://stackoverflow.com/questions/78847811/how-to-build-a-playable-url-from-xtream-codes-api](https://stackoverflow.com/questions/78847811/how-to-build-a-playable-url-from-xtream-codes-api)

[\[11\]](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895#:~:text=The%20file%27s%20actual%20location%20can,into%20a%20simple%20http%20link) [\[12\]](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895#:~:text=Similarly%20to%20VOD%2C%20a%20series,into%20a%20simple%20http%20link) [\[13\]](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895#:~:text=http%3A%2F%2F) Rclone xtream codes backend \- Feature \- rclone forum

[https://forum.rclone.org/t/rclone-xtream-codes-backend/41895](https://forum.rclone.org/t/rclone-xtream-codes-backend/41895)

[\[14\]](https://github.com/AndreyPavlenko/Fermata/discussions/434#:~:text=EPG%20%28xmltv) [\[15\]](https://github.com/AndreyPavlenko/Fermata/discussions/434#:~:text=%3E%20%20%20,X%3E%60%20param%20%28default%3D4%29) [\[16\]](https://github.com/AndreyPavlenko/Fermata/discussions/434#:~:text=Get%20short%20EPG%20for%20a,dedicated%20live%20streams) Xtream Code API implementation · AndreyPavlenko Fermata · Discussion \#434 · GitHub

[https://github.com/AndreyPavlenko/Fermata/discussions/434](https://github.com/AndreyPavlenko/Fermata/discussions/434)