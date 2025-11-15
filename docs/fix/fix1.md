## 1. Root cause : `FutureBuilder` + skeleton à chaque `waiting`

Dans ton `build` :

```dart
FutureBuilder<_HeroMeta?>(
  future: _metaFutures[movie.tmdbId!],
  builder: (context, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const _HeroSkeleton(overlayHeight: _overlayHeight);
    }

    final _HeroMeta? meta = snap.data;
    ...
```

Ce que ça fait réellement :

* Au **premier** chargement : OK, tu veux un skeleton → nickel.
* Mais à **chaque changement de `_index`** :

  * Le `FutureBuilder` reconstruit,
  * Le `snap.connectionState` peut être `waiting` (parce que `_loadMeta` n’a pas encore fini, ou parce que tu viens de recréer un `Future`),
  * Donc il affiche `_HeroSkeleton` pendant un instant,
  * Puis quand le futur se résout → tu reviens au hero réel.

Donc visuellement :
➡ hero A → **flash “page skeleton”** → hero B
Ce flash, c’est exactement ce que tu ressens comme “page layout intermédiaire”.

---

## 2. Fix simple : ne JAMAIS remettre le skeleton une fois lancé

On va faire ce que font les apps de streaming “pro” :

* Skeleton uniquement **au tout premier chargement** (quand on n’a rien du tout),
* Ensuite, même si la data suivante est en `waiting`, on **reste sur le précédent rendu** ou on affiche le hero en “mode dégradé” (sans meta) plutôt qu’un skeleton.

### Étape A — Suppression du skeleton sur `waiting`

Remplace ce bloc :

```dart
if (snap.connectionState == ConnectionState.waiting) {
  return const _HeroSkeleton(overlayHeight: _overlayHeight);
}

final _HeroMeta? meta = snap.data;
```

par quelque chose comme :

```dart
final _HeroMeta? meta = snap.data;
// On n'utilise plus le skeleton ici.
// Si `meta` est null, on tombe en mode "fallback" avec les données de `movie`.
```

Donc concrètement, dans ton code actuel :

```dart
: FutureBuilder<_HeroMeta?>(
    future: _metaFutures[movie.tmdbId!],
    builder: (context, snap) {
      // ❌ À SUPPRIMER :
      // if (snap.connectionState == ConnectionState.waiting) {
      //   return const _HeroSkeleton(overlayHeight: _overlayHeight);
      // }

      final _HeroMeta? meta = snap.data;

      // ... le reste inchangé
```

Comme tu as déjà des fallbacks basés sur `movie` (poster/backdrop, title, etc.),
le hero reste **toujours** affiché, même si le futur n’a pas encore renvoyé de meta.

👉 Résultat : plus de “page layout” entre deux médias.

---

### Étape B — Rendre le skeleton *seulement* au tout premier rendu (optionnel)

Si tu tiens absolument à voir `_HeroSkeleton` au très tout début, tu peux le limiter au seul cas :

* `snap.connectionState == waiting`
* **et** `_metaFutures.length == 1` **et** `_index == 0`

Exemple :

```dart
builder: (context, snap) {
  final bool isInitialLoad =
      _index == 0 &&
      _metaFutures.length == 1 &&
      snap.connectionState == ConnectionState.waiting &&
      snap.data == null;

  if (isInitialLoad) {
    return const _HeroSkeleton(overlayHeight: _overlayHeight);
  }

  final _HeroMeta? meta = snap.data;

  // ... reste
}
```

Mais honnêtement, vu que tu as déjà un `_HeroSkeleton` au niveau du `movie == null`, tu peux vivre sans ce cas spécial et faire au plus simple : **pas de skeleton dans `FutureBuilder`**.

---

## 3. Petit détail qui peut aussi créer une “coupure”

Dans ton titre, la branche fallback n’a pas de `transitionBuilder/layoutBuilder` custom :

```dart
child: hasTitle
    ? AnimatedSwitcher(
        // ... transitionBuilder + layoutBuilder OK
      )
    : AnimatedSwitcher(
        duration: _fade,
        child: Text(
          movie.title.value,
          key: ValueKey(
            '${movie.tmdbId}_titleFallback',
          ),
          ...
        ),
      ),
```

Donc dans le cas `!hasTitle`, `AnimatedSwitcher` utilise le **comportement par défaut** (Fade + SizeTransition) → petit “reflow” vertical possible.

Je te conseille d’unifier les deux :

```dart
child: hasTitle
    ? AnimatedSwitcher(
        duration: _fade,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          children: [
            ...previous,
            if (current != null) current,
          ],
        ),
        child: Text(
          meta!.title!,
          key: ValueKey('${movie.tmdbId}_title'),
          ...
        ),
      )
    : AnimatedSwitcher(
        duration: _fade,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          children: [
            ...previous,
            if (current != null) current,
          ],
        ),
        child: Text(
          movie.title.value,
          key: ValueKey('${movie.tmdbId}_titleFallback'),
          ...
        ),
      ),
```

Ce n’est pas le problème principal, mais ça supprime encore un micro-saut.

---

## 4. Résumé des modifs à faire tout de suite

Dans **ton fichier actuel** :

1. **Dans le `FutureBuilder`** :

   * supprime le `if (snap.connectionState == ConnectionState.waiting) { return _HeroSkeleton; }`.

2. (Optionnel) Ajoute le même `transitionBuilder/layoutBuilder` aussi dans le `AnimatedSwitcher` de la branche `!hasTitle`.

Une fois ça fait, le flow devrait devenir :

* hero A (slide N)
* → crossfade direct vers hero B (slide N+1)
* **sans passer par une autre “page”** au milieu.