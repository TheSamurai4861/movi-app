# Strategie de versioning

## But

Definir une regle simple et stable pour la version applicative de `Movi`.

Ce document formalise ce qui etait jusqu'ici seulement implicite dans `pubspec.yaml`.

---

## Source de verite

La source de verite de la version distribuee est :

- [`pubspec.yaml`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml)

Le projet utilise le format Flutter standard :

```yaml
version: build-name+build-number
```

Exemple courant :

```yaml
version: 1.0.1+4
```

Ce format signifie :

- `build-name` = `1.0.1`
- `build-number` = `4`

---

## Regle retenue

`build-name` suit SemVer :

- `MAJOR.MINOR.PATCH`

Interpretation retenue pour `Movi` :

- incrementer `PATCH` pour une correction ou un ajustement sans rupture produit ;
- incrementer `MINOR` pour une evolution fonctionnelle compatible ;
- incrementer `MAJOR` pour un changement de cap produit ou une rupture assumee.

`build-number` suit une regle monotone :

- incrementer ce nombre a chaque build distribuable ou candidate de livraison ;
- ne jamais le decrementar ;
- garder un entier simple pour rester compatible avec Android et Apple.

---

## Application aux flavors

Les flavors `dev`, `staging` et `prod` reutilisent la meme version semantique cible.

Regle retenue :

- la version applicative de reference reste `1.0.1` tant qu'aucun bump de release n'est decide ;
- les metadonnees internes peuvent distinguer les environnements avec un suffixe de build non distribue publiquement, par exemple `4-dev` ou `4-staging` ;
- la version bundle distribuee reste celle de `pubspec.yaml`.

---

## Gouvernance

Quand la version change :

1. mettre a jour `pubspec.yaml`
2. aligner les metadonnees internes de configuration si elles sont codees en dur
3. verifier que Android et iOS relaient bien la version Flutter
4. documenter la decision si le bump n'est pas trivial

---

## Etat actuel valide

Au 17 mars 2026, la version de reference du projet est :

- `build-name` : `1.0.1`
- `build-number` : `4`

Cette regle remplace l'ancien etat ou une version existait sans strategie explicite.
