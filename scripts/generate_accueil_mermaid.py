#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
from urllib import error, request


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = (
    ROOT
    / "docs"
    / "roadmap"
    / "phase_1_parcours_ux_ideal"
    / "02_workflow_accueil_mermaid_professional.md"
)
DEFAULT_PNG_OUTPUT = (
    ROOT
    / "docs"
    / "roadmap"
    / "phase_1_parcours_ux_ideal"
    / "02_workflow_accueil_mermaid_professional.png"
)

TITLE = "# Workflow Mermaid - Accueil / Entree App"

SCOPE_LINES = [
    "Ce workflow couvre le parcours d'entree depuis l'ouverture de l'app jusqu'a l'affichage de `home`.",
]

ASSUMPTION_LINES = [
    "`home` ne s'affiche qu'apres chargement termine des medias requis",
    "si aucun profil n'est selectionne, la selection est obligatoire",
    "si la source active est invalide ou absente, passage par choix / ajout de source avec message explicatif",
    "en cas de Supabase partiellement indisponible, on propose `retry` ou mode local",
    "en absence de reseau, affichage d'un ecran indiquant que le wifi est necessaire",
    "si une source est valide mais le catalogue est vide, `home` s'affiche vide avec message explicatif",
    "le flow TV par QR code est reporte a plus tard",
]

MERMAID_LINES = [
    "flowchart TD",
    "    A[Ouverture app] --> B[Splashscreen]",
    "",
    "    subgraph SYS[Verification systeme]",
    "        B --> C{Reseau disponible ?}",
    "        C -->|Non| W[Ecran reseau requis<br/>Wifi necessaire + Retry]",
    "        W --> B",
    "        C -->|Oui| D{Session connectee ?}",
    "    end",
    "",
    "    subgraph AUTH[Compte et profil]",
    "        D -->|Non| E[Auth code 8 chiffres]",
    "        E --> F{Premiere connexion ?}",
    "        F -->|Oui| G[Creation profil]",
    "        F -->|Non| H[Choix profil obligatoire]",
    "",
    "        D -->|Oui| I[Sync Supabase<br/>Profils + bibliotheque + sources]",
    "        I --> J{Sync complete ?}",
    "        J -->|Oui| K{Profil selectionne ?}",
    "        J -->|Non| L[Retry ou mode local]",
    "        L -->|Retry| I",
    "        L -->|Mode local| M[Creation profil local]",
    "        K -->|Non| H",
    "        K -->|Oui| N[Profil pret]",
    "        G --> N",
    "        H --> N",
    "        M --> N",
    "    end",
    "",
    "    subgraph SRC[Source et catalogue]",
    "        N --> O{Source active exploitable ?}",
    "        O -->|Oui| P{Maj medias necessaire ?}",
    "        O -->|Non| Q[Choix / ajout source<br/>avec message explicatif]",
    "",
    "        Q --> R{Source valide ?}",
    "        R -->|Non| S[Erreur source en rouge<br/>Retry ou retour arriere]",
    "        S --> Q",
    "        R -->|Oui| T{Catalogue exploitable ?}",
    "",
    "        T -->|Non| U[Home vide<br/>message explicatif]",
    "        T -->|Oui| P",
    "    end",
    "",
    "    subgraph LOAD[Preparation finale avant Home]",
    "        P -->|Oui| V[Chargement des derniers films / series]",
    "        P -->|Non| Y[Home pret]",
    "        V --> X{Chargement termine ?}",
    "        X -->|Oui| Y",
    "        X -->|Trop long| Z[Explication + Retry]",
    "        Z -->|Retry| V",
    "        Z -->|Attendre| X",
    "    end",
]

DEFERRED_LINES = [
    "flow TV avec QR code",
    "expiration / timeout / refus QR",
    "reprise de parcours si fermeture app en cours de tunnel",
    "logique detaillee de transfert local -> Supabase au retour du cloud",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Genere le document Mermaid du workflow d'accueil."
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Chemin du fichier markdown de sortie.",
    )
    parser.add_argument(
        "--png-output",
        type=Path,
        default=DEFAULT_PNG_OUTPUT,
        help="Chemin du fichier PNG de sortie.",
    )
    parser.add_argument(
        "--png",
        action="store_true",
        help="Genere aussi un PNG via le service Kroki.",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Affiche le markdown sur stdout au lieu d'ecrire le fichier.",
    )
    return parser.parse_args()


def build_markdown() -> str:
    parts: list[str] = [TITLE, "", "## Perimetre", ""]
    parts.extend(SCOPE_LINES)
    parts.append("")
    parts.append("Hypotheses integrees:")
    for line in ASSUMPTION_LINES:
        parts.append(f"- {line}")
    parts.extend(["", "## Mermaid", "", "```mermaid"])
    parts.extend(MERMAID_LINES)
    parts.extend(["```", "", "## Points deferes", ""])
    for line in DEFERRED_LINES:
        parts.append(f"- {line}")
    parts.append("")
    return "\n".join(parts)


def build_mermaid_source() -> str:
    return "\n".join(MERMAID_LINES) + "\n"


def write_png(output_path: Path, mermaid_source: str) -> None:
    endpoint = "https://kroki.io/mermaid/png"
    req = request.Request(
        endpoint,
        data=mermaid_source.encode("utf-8"),
        headers={
            "Content-Type": "text/plain; charset=utf-8",
            "Accept": "image/png",
            "User-Agent": "movi-mermaid-generator/1.0",
        },
        method="POST",
    )
    try:
        with request.urlopen(req, timeout=30) as response:
            content_type = response.headers.get("Content-Type", "")
            payload = response.read()
    except error.URLError as exc:
        raise RuntimeError(f"PNG render failed via Kroki: {exc}") from exc

    if not content_type.startswith("image/png"):
        raise RuntimeError(
            f"PNG render failed via Kroki: unexpected content type {content_type!r}"
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(payload)


def main() -> int:
    args = parse_args()
    content = build_markdown()
    mermaid_source = build_mermaid_source()

    if args.stdout:
        print(content, end="")
        return 0

    output_path = args.output.resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8")
    print(f"Generated {output_path}")

    if args.png:
        png_output_path = args.png_output.resolve()
        write_png(png_output_path, mermaid_source)
        print(f"Generated {png_output_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
