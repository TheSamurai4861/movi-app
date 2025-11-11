# CHANGELOG

## 2025-11-11

- Hero: réduit la taille des images pour améliorer les performances et le temps de chargement.
  - `poster`: passe de `w500` à `w342`.
  - `backdrop`: conservé à `w780` (compromis qualité/poids pour fond plein écran).
  - Ajout de `cacheWidth` dynamique (basé sur la largeur écran × DPR) pour limiter la résolution décodée côté client.

- Overlay Home: ajuste le délai d’attente maximum à `5s`.
  - L’overlay se masque après précache du hero ou du premier viewport visible (premier à terminer).
  - Timeout de `5s` en garde-fou pour éviter de bloquer l’UI en cas de réseau lent.