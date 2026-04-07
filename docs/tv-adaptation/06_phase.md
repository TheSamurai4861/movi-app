# Phase 6 — Settings et formulaires

## 1. Objet de la phase

La phase 6 a pour objectif d’unifier le comportement TV des écrans dominés par :

* des réglages,
* des formulaires,
* des listes d’options,
* des écrans de configuration,
* des parcours guidés de type onboarding ou authentification.

Après le shell, les pages détail et les pages listes/résultats, cette phase doit rendre ces écrans :

* prévisibles au remote,
* homogènes entre eux,
* robustes face aux claviers, champs, erreurs et chargements,
* lisibles dans leur logique de focus,
* cohérents dans leur sortie et leur restauration.

La phase 6 ne consiste pas à “mettre des `FocusNode` partout”.
Elle consiste à définir et appliquer une **grammaire commune des pages de réglages et des formulaires TV**.

## 2. Pages couvertes

La phase 6 couvre :

* `SettingsPage` pour sa logique interne restante hors contrat shell déjà stabilisé,
* `SettingsSubtitlesPage`,
* `AboutPage`,
* `IptvConnectPage`,
* `IptvSourcesPage`,
* `IptvSourceSelectPage`,
* `IptvSourceAddPage`,
* `IptvSourceEditPage`,
* `IptvSourceOrganizePage`,
* `WelcomeUserPage`,
* `WelcomeSourcePage`,
* `WelcomeSourceSelectPage`,
* `WelcomeSourceLoadingPage`,
* `AuthOtpPage`,
* `PinRecoveryPage`. 

`MoviPremiumPage` n’appartient pas à cette phase si elle reste un écran poussé de type offre/overlay ; elle est plutôt à cheval entre settings et phase 7 selon sa forme réelle. Les dialogs, sheets et overlays de confirmation restent en phase 7. 

## 3. Résultat attendu

À la fin de la phase 6 :

* chaque page a un point d’entrée explicite,
* chaque champ utile, bouton, switch, choix ou ligne interactive est focusable proprement,
* la navigation verticale est uniforme,
* `left/right` n’est utilisé que quand cela a un vrai sens local,
* `back` a un comportement stable et documenté,
* les sous-pages de settings ne se comportent pas comme des onglets shell,
* la restauration revient au bon contrôle quand on revient d’une sous-page,
* les états `loading`, `error`, `empty` ont un fallback de focus clair,
* les composants Flutter “par défaut” non fiables au remote ne portent plus le contrat principal de navigation.

## 4. Périmètre

### 4.1 Inclus

La phase 6 couvre :

* le focus initial,
* la navigation dans les formulaires,
* la navigation dans les pages settings à sections,
* les écrans de sélection simple,
* les champs texte, OTP, toggles, selects, boutons et listes d’actions,
* les règles de sortie,
* la restauration,
* les cas `loading`, `error`, `empty`,
* la cohérence entre racine settings et sous-pages settings.

### 4.2 Exclus

La phase 6 ne couvre pas :

* les overlays complexes,
* les dialogs,
* les bottom sheets,
* le player,
* les pages détail,
* les grilles catalogue,
* les composants purement visuels non navigables seuls. 

## 5. Grammaire commune des pages settings et formulaires

## 5.1 Structure logique cible

Ces écrans doivent être pensés selon l’une de ces structures simples.

Pour une sous-page settings :

* zone 1 : header / back,
* zone 2 : sections de réglages,
* zone 3 : actions finales éventuelles.

Pour un formulaire :

* zone 1 : header / titre / back,
* zone 2 : champs,
* zone 3 : action principale puis actions secondaires.

Pour une liste de sélection :

* zone 1 : header / back,
* zone 2 : liste verticale principale,
* zone 3 : action d’ajout / validation / retour si nécessaire.

L’objectif est de rendre le flux lisible : on entre en haut ou sur le premier champ utile, on descend de manière séquentielle, et on sort par `back` ou bouton retour.

## 5.2 Point d’entrée

Règle générale :

* formulaire : premier champ utile,
* page settings : premier item interactif du niveau courant,
* page de sélection : premier élément sélectionnable,
* page d’information : premier bouton utile, souvent retour,
* écran transitoire : pas de focus libre, ou focus sur l’action de reprise si l’utilisateur peut intervenir.

## 5.3 Navigation verticale

La verticale est l’axe principal de cette phase.

Règles :

* `down` : contrôle suivant,
* `up` : contrôle précédent,
* aucune ambiguïté entre navigation de page et navigation interne d’un champ,
* l’ordre doit être déterministe et suivre la hiérarchie visuelle réelle,
* si une section est absente, on saute proprement à la suivante.

C’est la grammaire centrale de la phase 6. Elle découle directement de la règle de formulaires posée en phase 1 et de l’objectif de “navigation verticale simple” de la roadmap.

## 5.4 Navigation horizontale

`left/right` ne doit être utilisé que dans les cas suivants :

* champ OTP segmenté,
* ligne de plusieurs boutons,
* switch ou stepper avec logique locale,
* groupe horizontal de choix,
* poignée/action locale dans une page d’organisation.

Sinon :

* `left/right` = stop,
* ou comportement natif du champ si l’utilisateur édite du texte,
* mais jamais comme mécanisme implicite pour changer de ligne.

## 5.5 Règle de sortie

Il faut distinguer trois familles.

### Racine settings dans le shell

Sur la racine `SettingsPage`, `left` peut renvoyer à la sidebar si aucun mouvement local n’est possible, car elle reste un onglet shell. C’est déjà fixé par la phase 3. 

### Sous-pages settings

Sur `SettingsSubtitlesPage`, `AboutPage`, `Iptv...` :

* `back` revient à la page précédente,
* bouton retour fait la même chose,
* `left` ne renvoie pas au shell,
* sauf règle locale explicitement documentée dans un petit groupe horizontal.

### Formulaires / onboarding / auth

Sur onboarding et auth :

* `back` remonte dans le flow,
* s’il y a un clavier ou un état d’édition, il doit être fermé d’abord,
* ensuite seulement on quitte l’écran. 

## 5.6 Restauration

Règle commune :

* restaurer le dernier contrôle focusé si valide,
* sinon revenir au point d’entrée officiel,
* sinon fallback sûr,
* sinon bouton retour.

Exemples :

* retour de `SettingsSubtitlesPage` vers `SettingsPage` : retour sur le réglage déclencheur,
* retour de `IptvSourceEditPage` vers `IptvSourcesPage` : retour sur la source éditée si toujours présente,
* retour dans un formulaire après erreur : retour sur le premier champ invalide ou l’action corrective principale.

## 6. Contrat par famille d’écrans

## 6.1 SettingsPage

Cette page a déjà un contrat shell : entrée sur le premier item interactif, fallback sur le premier item fiable du niveau racine, sortie gauche vers sidebar si page settings racine, restauration du dernier réglage focusé. La phase 6 ne doit pas casser ce contrat ; elle doit seulement homogénéiser les sections internes et les widgets de réglage. 

Travail à faire :

* verrouiller l’ordre vertical des sections,
* s’assurer que chaque ligne réellement interactive a un comportement TV explicite,
* supprimer les éléments qui “semblent focusables” sans l’être réellement,
* réserver `left/right` aux lignes qui contiennent plusieurs contrôles.

## 6.2 SettingsSubtitlesPage

Point d’entrée :

* premier contrôle de sous-titres. Cette règle était déjà posée en phase 1. 

Structure cible :

* header/back,
* groupes de réglages,
* éventuellement action de reset ou sauvegarde si elle existe.

Navigation attendue :

* verticale entre groupes,
* horizontale locale dans une ligne de choix,
* stop en bord,
* `back` vers page précédente.

Objectif concret :

* en faire la page de référence des sous-pages settings simples, comme `TvDetailPage` l’a été pour les détails dans les phases précédentes. La roadmap recommande explicitement de normaliser `SettingsSubtitlesPage` en priorité avec les pages settings/formulaires. 

## 6.3 AboutPage

Point d’entrée :

* premier élément interactif ; si la page est surtout informative, bouton retour ou premier lien/action utile. Cette règle était déjà cadrée en phase 1. 

Navigation :

* verticale simple,
* horizontale seulement si une ligne d’actions existe,
* `back` revient à la page précédente.

Ici, le risque principal est d’avoir une page qui dépend trop du traversal implicite parce qu’elle contient peu d’actions. La phase 6 doit quand même lui donner un contrat explicite.

## 6.4 IPTV pages

Ces pages forment un sous-ensemble cohérent, donc la phase 6 doit les traiter comme une famille.

### IptvConnectPage

Entrée :

* premier champ de connexion ou première action principale. 

Navigation :

* verticale stricte champ → champ → action,
* `left/right` local au champ si pertinent,
* `back` ferme clavier/édition puis revient.

### IptvSourcesPage

Entrée :

* première source ou action d’ajout. 

Navigation :

* verticale entre sources,
* horizontale locale seulement si une ligne a plusieurs actions,
* sortie vers ajout, édition, organisation, sélection active ou retour settings.

### IptvSourceSelectPage

Entrée :

* première source sélectionnable. 

Navigation :

* verticale simple,
* validation claire,
* retour explicite.

### IptvSourceAddPage / IptvSourceEditPage

Entrée :

* premier champ. 

Navigation :

* verticale champ → champ → action,
* focus sur premier champ invalide en cas d’erreur,
* restauration du dernier champ si retour court dans le même écran.

### IptvSourceOrganizePage

Entrée :

* premier élément réorganisable ou première action principale. 

Navigation :

* verticale entre lignes,
* horizontale locale entre poignée et actions si présentes,
* aucune ambiguïté entre mode consultation et mode réorganisation.

Le point clé de cette famille est la cohérence : même si les écrans diffèrent, l’utilisateur doit toujours reconnaître le schéma “entrée en haut, navigation verticale, validation explicite, back cohérent”.

## 6.5 Onboarding

### WelcomeUserPage

Entrée :

* premier champ ou première action principale du formulaire. 

Navigation :

* `down` champ/action suivante,
* `up` champ/action précédente,
* `left/right` seulement si un champ ou un contrôle le justifie.

### WelcomeSourcePage

Entrée :

* première action principale d’ajout/connexion de source. 

Navigation :

* verticale entre sections,
* horizontale seulement dans une ligne d’actions.

### WelcomeSourceSelectPage

Entrée :

* première source sélectionnable. 

Navigation :

* verticale simple,
* validation ou retour.

### WelcomeSourceLoadingPage

Écran transitoire :

* pas de navigation libre,
* focus neutre,
* action de reprise seulement en cas d’erreur. 

Le flow onboarding doit être vécu comme un parcours guidé, pas comme une mini-application avec des règles qui changent à chaque écran.

## 6.6 Auth et sécurité

### AuthOtpPage

Entrée :

* premier champ OTP ou première cellule OTP. 

Navigation :

* `left/right` entre cellules si OTP segmenté,
* `down` vers action principale,
* `up` vers la zone OTP,
* focus sur premier segment invalide ou action de renvoi en cas d’erreur.

### PinRecoveryPage

Entrée :

* premier champ ou première action principale. 

Navigation :

* verticale simple,
* horizontale locale si besoin,
* sortie par validation ou retour.

Ici, l’exigence supplémentaire est la robustesse sur les erreurs : erreur de saisie, état temporaire, délai réseau, bouton renvoi, etc.

## 7. Problèmes concrets à traiter dans cette phase

Le diagnostic amont a déjà identifié plusieurs widgets trop fragiles pour porter un contrat TV : `ChoiceChip`, `GestureDetector`, `ListTile`, certains `ElevatedButton` sans nœud explicite, et des zones qui reposent encore trop sur le traversal implicite. La phase 6 est précisément celle où il faut corriger cette dette sur les pages settings et formulaires. 

Les problèmes à traiter sont donc :

### 7.1 Widgets implicitement focusables

Un contrôle ne doit pas être “atteignable par hasard”.
Chaque élément important doit avoir un comportement explicite au remote.

### 7.2 Mélange entre édition et navigation

Quand un champ texte a le focus :

* les flèches ne doivent pas casser l’édition,
* mais on doit quand même garder une règle claire pour sortir du champ.

### 7.3 Sorties incohérentes

Les sous-pages settings ne doivent jamais se comporter comme le shell racine.

### 7.4 Restauration fragile

Au retour d’une sous-page, d’un refresh ou d’une erreur, le focus doit revenir à un contrôle utile, pas disparaître.

### 7.5 États techniques mal traités

Les écrans de chargement, d’erreur ou de liste vide doivent avoir une cible de focus claire.

## 8. Travail concret à réaliser

## 8.1 Normaliser les composants interactifs de settings/formulaires

Sans créer un framework trop large, il faut disposer de quelques briques réutilisables et claires pour :

* ligne de réglage focusable,
* tuile d’option focusable,
* champ de formulaire TV-aware,
* groupe horizontal simple,
* header retour standardisé.

Cela reste cohérent avec la phase 2, qui autorisait un petit nombre de briques ciblées tant que chaque fichier garde une responsabilité claire. 

## 8.2 Rendre explicites les points d’entrée

Chaque page refactorée doit déclarer :

* `initialFocusNode`,
* `fallbackFocusNode` si utile,
* `restoreFocusOnPop`. 

## 8.3 Uniformiser le `back`

Il faut fixer une règle unique :

* si clavier/édition/état local ouvert : fermer d’abord,
* sinon revenir à la page précédente,
* jamais de fuite vers le shell sauf sur `SettingsPage` racine.

## 8.4 Uniformiser la validation et l’erreur

Pour chaque formulaire :

* focus sur premier champ invalide,
* sinon sur action corrective principale,
* messages d’erreur utiles,
* pas d’erreur silencieuse.

Cela suit aussi tes règles générales sur la gestion explicite des erreurs et sur des messages exploitables. 

## 8.5 Standardiser les listes de sélection

Pour `IptvSourcesPage`, `IptvSourceSelectPage`, `WelcomeSourceSelectPage` :

* entrée sur premier item,
* verticale stricte,
* actions locales explicites,
* restauration sur item déclencheur au retour.

## 9. Ce qu’il ne faut pas faire en phase 6

* ne pas créer un “form focus engine” universel,
* ne pas déplacer toute la logique de chaque champ dans le core,
* ne pas traiter les dialogs et overlays maintenant,
* ne pas multiplier les wrappers génériques sans rôle clair,
* ne pas casser le contrat shell de `SettingsPage`,
* ne pas réécrire toutes les pages en big bang.

Ces limites sont directement cohérentes avec les règles de simplicité, de responsabilité claire, de petits changements ciblés et d’absence d’abstraction prématurée.

## 10. Critères de sortie

La phase 6 est terminée uniquement si :

* toutes les pages settings/formulaires ciblées ont un point d’entrée officiel,
* la verticale est l’axe principal partout où elle doit l’être,
* chaque champ, choix ou action importante a un comportement remote explicite,
* `back` est cohérent et uniforme,
* les sous-pages settings ont une sortie fiable vers leur page précédente,
* la restauration revient au bon contrôle ou à un fallback sûr,
* les états `loading/error/empty` ont un comportement défini,
* les composants restent simples, locaux et compréhensibles,
* aucun framework interne lourd n’a été introduit.

## 11. Tests minimums

À vérifier au minimum :

Pour chaque formulaire :

* focus initial,
* `up/down` entre champs,
* comportement de `left/right` dans les champs spéciaux,
* validation,
* erreur sur champ invalide,
* `back` pendant édition,
* restauration après retour.

Pour chaque sous-page settings :

* entrée sur premier contrôle utile,
* navigation verticale stable,
* groupe horizontal local si présent,
* retour page précédente,
* restauration sur le réglage déclencheur.

Pour les listes de sélection :

* entrée premier item,
* navigation verticale,
* validation,
* retour,
* restauration si retour depuis édition.

Cela s’inscrit dans la logique générale de la roadmap, qui prévoit ensuite la phase 8 pour systématiser les widget tests clavier/télécommande et les non-régressions.

## 12. Ordre d’exécution recommandé

Je te conseille cet ordre :

1. `SettingsSubtitlesPage`
2. `AboutPage`
3. `IptvConnectPage`
4. `IptvSourcesPage`
5. `IptvSourceSelectPage`
6. `IptvSourceAddPage`
7. `IptvSourceEditPage`
8. `IptvSourceOrganizePage`
9. `WelcomeUserPage`
10. `WelcomeSourcePage`
11. `WelcomeSourceSelectPage`
12. `AuthOtpPage`
13. `PinRecoveryPage`

Pourquoi :

* la roadmap recommande déjà de normaliser `SettingsSubtitlesPage` et les pages settings/formulaires après les listes/résultats. 
* `SettingsSubtitlesPage` et `AboutPage` permettent de verrouiller la grammaire simple des sous-pages settings,
* les pages IPTV forment ensuite une famille homogène,
* l’onboarding et l’auth viennent après, car ils sont plus sensibles aux états transitoires et à l’édition.

## 13. Conclusion

La phase 6 doit transformer les écrans settings et formulaires en un bloc cohérent de navigation TV :

* simple,
* vertical,
* explicite,
* robuste sur les champs,
* stable sur le retour et la restauration.

En une phrase : après avoir standardisé le shell, les détails, puis les pages catalogue, la phase 6 doit standardiser les **écrans de configuration et de saisie**, sans sur-abstraction et sans dépendance au traversal implicite.