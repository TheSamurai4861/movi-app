# Contrat de cycle de vie des sources IPTV

Ce document fixe le comportement attendu autour des sources IPTV locales et
cloud. Il sert de référence produit et technique pour éviter les ambiguïtés du
type "j'ai vidé les données mais mes anciennes sources reviennent".

## 1. Principes

- Le stockage local et le stockage cloud n'ont pas la même responsabilité.
- Une déconnexion ou un nettoyage de session n'est pas un reset complet.
- Une source supprimée localement n'est considérée définitivement supprimée que
  si la suppression cloud a aussi abouti ou si aucune ligne cloud ne
  correspondait déjà.

## 2. Sémantique attendue

### 2.1 Déconnexion / invalidation de session

- Le nettoyage de session est limité à l'état sensible lié à l'auth.
- Les profils, sources IPTV, playlists et caches locaux peuvent être conservés
  pour préserver le mode local-first/offline.
- Ce flux ne doit pas être présenté comme une suppression complète des sources.

### 2.2 Suppression d'une source depuis Settings

- La suppression locale est immédiate.
- Une suppression cloud best-effort est tentée pour le compte authentifié.
- Si la suppression cloud échoue, ou n'a pas pu être tentée, la source peut
  réapparaître après reconnexion tant que sa ligne Supabase existe encore.
- L'application doit le rendre explicite dans son feedback utilisateur.

### 2.3 Reconnexion / bootstrap

- Au login, les sources cloud du compte authentifié peuvent être réhydratées en
  local.
- Une source encore présente dans Supabase peut donc revenir même après
  nettoyage local, réinstallation ou suppression des données de l'application.

## 3. Contrat UX

- "Supprimer la source" signifie supprimer la source de l'appareil, avec une
  tentative de suppression cloud associée.
- Si la suppression cloud n'est pas confirmée, l'utilisateur doit être averti
  que la source peut réapparaître après reconnexion.
- "Vider les données" côté OS ne doit pas être interprété comme une suppression
  des sources cloud.

## 4. Hors périmètre actuel

- Le projet ne propose pas encore de "reset total" explicite local + cloud en
  une seule action.
- Si ce besoin produit est ajouté, il devra être implémenté comme un flux
  distinct, nommé explicitement et couvert par des tests dédiés.
