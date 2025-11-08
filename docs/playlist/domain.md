# Journal – Feature Playlist / Domain Layer

## 2024-XX-XX — Modélisation des entités
- `Playlist` : id, titre, description, cover, items, dates, owner, statut public, durée totale optionnelle.
- `PlaylistItem` : référence contenu (`ContentReference`), position, date d’ajout, runtime, notes.
- `PlaylistSummary` : aperçu (id, titre, cover, nombre d’items, owner).

## 2024-XX-XX — Contrat de repository
- Interface `PlaylistRepository` avec :
  - `getPlaylist`, `getUserPlaylists`, `getFeaturedPlaylists`,
    `searchPlaylists`, `addItem`, `removeItem`.

## 2024-XX-XX — Use cases
- `GetPlaylistDetail`, `GetUserPlaylists`, `GetFeaturedPlaylists`,
  `SearchPlaylists`, `AddPlaylistItem`, `RemovePlaylistItem`.

## TODO prochains steps
- Définir les DTO/mappers côté data.
- Gérer l’ordre des items (drag/drop) et la collaboration (playlist partagée) dans de futurs use cases.
