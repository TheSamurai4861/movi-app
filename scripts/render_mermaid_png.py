#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path
from urllib import error, request


MERMAID_BLOCK_RE = re.compile(r"```mermaid\s*\n(.*?)```", re.DOTALL)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Rend le premier bloc Mermaid d'un markdown vers un PNG."
    )
    parser.add_argument("input", type=Path, help="Fichier markdown source.")
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Chemin du PNG de sortie. Par defaut: meme nom que le markdown.",
    )
    return parser.parse_args()


def extract_mermaid(markdown: str) -> str:
    match = MERMAID_BLOCK_RE.search(markdown)
    if not match:
        raise ValueError("Aucun bloc ```mermaid ... ``` trouve dans le fichier.")
    return match.group(1).strip() + "\n"


def render_png(mermaid_source: str) -> bytes:
    req = request.Request(
        "https://kroki.io/mermaid/png",
        data=mermaid_source.encode("utf-8"),
        headers={
            "Content-Type": "text/plain; charset=utf-8",
            "Accept": "image/png",
            "User-Agent": "movi-render-mermaid-png/1.0",
        },
        method="POST",
    )
    try:
        with request.urlopen(req, timeout=30) as response:
            content_type = response.headers.get("Content-Type", "")
            payload = response.read()
    except error.URLError as exc:
        raise RuntimeError(f"Rendu Mermaid PNG impossible: {exc}") from exc

    if not content_type.startswith("image/png"):
        raise RuntimeError(
            f"Reponse inattendue pendant le rendu PNG: {content_type!r}"
        )

    return payload


def main() -> int:
    args = parse_args()
    input_path = args.input.resolve()
    markdown = input_path.read_text(encoding="utf-8")
    mermaid_source = extract_mermaid(markdown)
    png = render_png(mermaid_source)

    output_path = (
        args.output.resolve()
        if args.output is not None
        else input_path.with_suffix(".png").resolve()
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(png)
    print(f"Generated {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
