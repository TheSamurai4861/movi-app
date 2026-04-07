# Workflow Mermaid - Accueil / Entree App (Version professionnelle)

## Intent

Cette version vise une lecture plus produit et plus executive du parcours d'entree.
Elle conserve les decisions importantes sans melanger tous les details d'implementation.

## Mermaid

```mermaid
flowchart TD
    A[Ouverture app] --> B[Splashscreen]

    subgraph SYS[Verification systeme]
        B --> C{Reseau disponible ?}
        C -->|Non| W[Ecran reseau requis<br/>Wifi necessaire + Retry]
        W --> B
        C -->|Oui| D{Session connectee ?}
    end

    subgraph AUTH[Compte et profil]
        D -->|Non| E[Auth code 8 chiffres]
        E --> F{Premiere connexion ?}
        F -->|Oui| G[Creation profil]
        F -->|Non| H[Choix profil obligatoire]

        D -->|Oui| I[Sync Supabase<br/>Profils + bibliotheque + sources]
        I --> J{Sync complete ?}
        J -->|Oui| K{Profil selectionne ?}
        J -->|Non| L[Retry ou mode local]
        L -->|Retry| I
        L -->|Mode local| M[Creation profil local]
        K -->|Non| H
        K -->|Oui| N[Profil pret]
        G --> N
        H --> N
        M --> N
    end

    subgraph SRC[Source et catalogue]
        N --> O{Source active exploitable ?}
        O -->|Oui| P{Maj medias necessaire ?}
        O -->|Non| Q[Choix / ajout source<br/>avec message explicatif]

        Q --> R{Source valide ?}
        R -->|Non| S[Erreur source en rouge<br/>Retry ou retour arriere]
        S --> Q
        R -->|Oui| T{Catalogue exploitable ?}

        T -->|Non| U[Home vide<br/>message explicatif]
        T -->|Oui| P
    end

    subgraph LOAD[Preparation finale avant Home]
        P -->|Oui| V[Chargement des derniers films / series]
        P -->|Non| Y[Home pret]
        V --> X{Chargement termine ?}
        X -->|Oui| Y
        X -->|Trop long| Z[Explication + Retry]
        Z -->|Retry| V
        Z -->|Attendre| X
    end
```

## Notes

- `Home` n'apparait qu'une fois l'etat juge suffisant.
- En cas de source valide mais vide, `Home` s'affiche quand meme avec un message explicatif.
- Le flow TV par QR code reste volontairement hors de ce diagramme.
