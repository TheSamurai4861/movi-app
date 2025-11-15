OK, donc ton texte explique *ce qui devrait se passer* après les correctifs… mais ton comportement réel dit l’inverse :

> « L’historique reste caché lorsque je reviens avec un input vide. »

➡️ Ça veut dire qu’un des points suivants est encore vrai dans ton code :

1. **Le “switch” UI histoire / résultats n’est pas 100% basé sur le `TextEditingController`.**
2. **Le reset du provider / refresh de l’historique ne se déclenche pas au bon moment quand tu reviens sur l’onglet Recherche.**

Je te fais un diagnostic ciblé + ce que *tu dois modifier*.

---

## 1. Vérifier la condition qui choisit entre “Historique” et “Résultats”

Tu dis dans le texte :

> `hasQuery` basé sur `_textCtrl.text.trim().length >= 3` au lieu de `state.query`.

Mais en pratique, ton UI fait probablement encore quelque chose du genre :

```dart
if (state.query.isNotEmpty && state.query.length >= 3) {
  // afficher résultats
} else {
  // afficher historique
}
```

ou une variante mixte :

```dart
final hasQuery = _textCtrl.text.trim().length >= 3;
// ...
if (hasQuery || state.isSearching /* ou autre flag */) {
  // résultats
} else {
  // historique
}
```

👉 **Ce qu’il faut faire :**

* **Source de vérité unique = le `TextEditingController`.**
  Tout ce qui décide *d’afficher l’historique ou pas* doit être uniquement basé sur le texte saisi, pas sur l’état du provider.

Concrètement, dans `search_page.dart` (vers 41–144) :

* **À modifier :**

  * Remplace toutes les conditions du style :

    * `if (state.query.isNotEmpty)`
    * `if (state.query.length >= 3)`
    * ou mix `hasQuery && state.xxx`
  * Par une seule condition :

    ```dart
    final hasQuery = _textCtrl.text.trim().length >= 3;
    ```

    puis

    ```dart
    if (hasQuery) {
      // branch Résultats
    } else {
      // branch Historique (même si le provider de résultats a encore des données)
    }
    ```

Tant que ton UI regarde encore le provider, tu peux te retrouver dans le cas :

* champ texte vide (`_textCtrl.text == ''`)
* provider toujours avec `state.query = 'avengers'`
* ⇒ l’UI pense toujours être en mode “Résultats” et **cache l’historique**, même si le champ est visuellement vide.

---

## 2. S’assurer que le reset du provider est bien déclenché au retour sur l’onglet

Ton texte dit :

> “Force le provider de recherche à requête vide quand on revient sur l’onglet Recherche”

Mais deux pièges classiques ici :

1. **Le SearchPage ne sait pas vraiment quand il est “actif”.**

   * Si tu passes un booléen `isActive` dans le constructeur **mais que la page est gardée dans une `IndexedStack`**, il faut vérifier que :

     * le parent rebâtit bien l’`IndexedStack` quand tu changes l’index, **et**
     * `SearchPage` est reconstruit avec `isActive = true`, donc `build()` se relance vraiment.
   * Si `SearchPage` ne reconstruit pas, ton `addPostFrameCallback` “à l’activation” ne sera jamais rappelé.

2. **Le reset est conditionné sur de mauvaises valeurs.**
   Exemple typique :

   ```dart
   if (isActive && !hasQuery && state.query.isNotEmpty) {
     // post-frame: controller.setQuery('');
   }
   ```

   Si pour une raison X `state.query` vaut déjà `''` au moment où tu reviens, **ce bloc ne s’exécute pas**, donc :

   * le provider garde un ancien `state.results` non-nul
   * ton UI, si elle s’y fie, reste sur “Résultats”

👉 **Ce qu’il faut modifier :**

Dans `search_page.dart` (partie “post-frame quand Recherche est actif”) :

1. **Base-toi d’abord sur le tab courant, pas sur le provider.**
   La condition devrait être quelque chose comme :

   * “Onglet Recherche actif” **ET** “champ texte vide”
     ⇒ on force le provider dans un état “empty query” *sans condition sur l’état interne du provider*.

   En clair :

   * si `isSearchTabActive == true` **et** `_textCtrl.text.trim().isEmpty`
   * alors tu fais en post-frame :

     ```dart
     searchController.setQuery('');
     searchController.clearResults(); // si tu as une méthode de ce genre
     searchHistoryController.refresh(); // déjà ce que tu fais
     ```

2. **Ne conditionne pas le reset sur `state.query.isNotEmpty`.**

   * Tu veux que, **dès que le champ est vide et l’onglet actif**, l’UI soit “mode historique”, même si le provider est dans un état étrange.

---

## 3. Vérifier que le widget d’historique est toujours monté

Tu écris :

> “L’historique reste caché lorsque je reviens avec un input vide.”

Il est possible que ton widget d’historique soit dans un `if` trop strict.

Exemples à éviter :

```dart
if (!hasQuery && !historyState.isLoading && historyState.hasValue) {
  return SearchHistoryList(...);
} else {
  return SizedBox.shrink();
}
```

ou

```dart
if (!hasQuery) {
  return historyState.when(
    data: (items) => items.isEmpty
        ? SizedBox.shrink()
        : SearchHistoryList(items: items),
    loading: () => SizedBox.shrink(),  // <-- problématique
    error: (_) => SizedBox.shrink(),   // idem
  );
}
```

👉 **Ce qu’il faut modifier :**

Dans `search_page.dart` (partie historique, vers 313–351) :

* Assure-toi que **le container de l’historique est toujours présent** quand `hasQuery == false`, même en `loading` ou `error`.
* Utilise :

  * `loading` → petit loader ou placeholder dans la même colonne
  * `error` → message d’erreur + bouton “Réessayer”

Pas de `SizedBox.shrink()` qui supprime entièrement la zone, sinon tu as l’impression que “l’historique est caché”.

---

## 4. Checklist ultra concrète pour toi

Pour débugger précisément :

1. **Ajoute des `debugPrint` dans `build` de `SearchPage`** :

   * `debugPrint('[SearchPage] text="${_textCtrl.text}" hasQuery=$hasQuery');`
   * `debugPrint('[SearchPage] historyState=$historyState');`
   * `debugPrint('[SearchPage] isSearchTabActive=$isSearchTabActive');`

2. **Reproduis le bug et regarde ce qui se passe au retour sur l’onglet :**

   * `hasQuery` doit être `false`
   * `isSearchTabActive` doit être `true`
   * si malgré ça tu ne vois pas l’historique, c’est forcément :

     * soit une condition de rendu trop restrictive,
     * soit un `SizedBox.shrink()`/`Container()` vide dans la branche `when`.

3. **Teste ce scénario après corrections :**

   * Ouvrir Recherche → taper une requête ≥ 3 chars → voir résultats.
   * Aller sur un autre onglet.
   * Revenir sur Recherche **avec le champ vidé** (via clear icon ou navigation).
   * Attendu :

     * `hasQuery == false`
     * la branche Résultats n’est plus rendue du tout
     * la branche Historique est visible même si `refresh` est en cours.

---

Si tu veux, au prochain message tu peux juste me coller la partie de `search_page.dart` qui :

* calcule `hasQuery`,
* décide entre afficher historique / résultats,

et je te dirai précisément **quelle condition changer, ligne par ligne**, pour que l’historique soit *toujours* visible quand le champ est vide.
