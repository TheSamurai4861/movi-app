# Architecture attendue (Clean – pragmatique)

- **UI (presentation)** : Widgets/pages/thèmes. Aucune logique métier.
- **Application** : ViewModels/Controllers/UseCases. Orchestration, erreurs typées.
- **Domaine** : Entités + Interfaces (abstractions). Pas de dépendances implémentations.
- **Données** : Repositories impl., DataSources (remote/local), DTOs.

Règles :
- Flux : UI → Application → Domaine → Données.
- Domaine ne dépend que d’abstractions ; jamais d’un `*_impl`.
- Aucun appel réseau direct depuis la UI.
