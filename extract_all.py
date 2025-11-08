#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Concatène le contenu de tous les fichiers texte sous un dossier `lib/`
dans un unique fichier, en préfixant chaque bloc par le chemin du fichier.

Usage basique (depuis la racine du projet) :
    python concat_lib.py

Options :
    python concat_lib.py --lib lib --output lib_concat.txt --ext .dart .md .yaml .json

- Détection binaire simple : les fichiers contenant des octets NUL sont ignorés.
- Encodage lecture : UTF-8 (errors='replace' pour éviter les plantages).
- Chemins écrits relatifs au dossier `lib`.
"""

import argparse
import sys
from pathlib import Path

SEPARATOR = "=" * 80

def is_binary(path: Path, probe_size: int = 2048) -> bool:
    """Heuristique simple pour détecter un fichier binaire."""
    try:
        with path.open("rb") as f:
            chunk = f.read(probe_size)
        # Octet NUL présent -> binaire probable
        if b"\x00" in chunk:
            return True
        # Ratio de caractères non imprimables (hors \t\r\n)
        textish = sum(c in b"\t\r\n\f\b" or 32 <= c <= 126 for c in chunk)
        # Si quasi aucun caractère texte dans l'échantillon, probablement binaire
        return (len(chunk) > 0 and (textish / len(chunk) < 0.5))
    except Exception:
        # En cas d'erreur d'accès, on considère binaire pour le skipper
        return True

def should_skip_hidden(path: Path) -> bool:
    """Ignore les fichiers/dossiers cachés (nom commençant par '.')"""
    return any(part.startswith(".") for part in path.parts)

def main():
    parser = argparse.ArgumentParser(description="Concaténer tous les fichiers texte de lib/ dans un seul fichier.")
    parser.add_argument("--lib", default="lib", help="Dossier racine à analyser (par défaut: lib)")
    parser.add_argument("--output", "-o", default="lib_concat.txt", help="Fichier de sortie (par défaut: lib_concat.txt)")
    parser.add_argument(
        "--ext",
        nargs="*",
        default=None,
        help="Extensions à inclure (ex: --ext .dart .md .yaml). Par défaut: toutes les extensions."
    )
    parser.add_argument("--skip-hidden", action="store_true", default=True, help="Ignorer fichiers/dossiers cachés (défaut: True)")
    parser.add_argument("--max-size-kb", type=int, default=None, help="Ignorer les fichiers > taille (kio). Par défaut: illimité.")

    args = parser.parse_args()

    lib_dir = Path(args.lib).resolve()
    out_path = Path(args.output).resolve()

    if not lib_dir.exists() or not lib_dir.is_dir():
        print(f"[ERREUR] Dossier introuvable: {lib_dir}", file=sys.stderr)
        sys.exit(1)

    # Normalise la liste d'extensions
    exts = None
    if args.ext:
        exts = {e.lower() if e.startswith(".") else f".{e.lower()}" for e in args.ext}

    files = sorted([p for p in lib_dir.rglob("*") if p.is_file()])

    total = 0
    written = 0
    skipped_bin = 0
    skipped_ext = 0
    skipped_hidden = 0
    skipped_size = 0

    # Écriture en streaming
    with out_path.open("w", encoding="utf-8", newline="\n") as out:
        for fp in files:
            total += 1

            if args.skip_hidden and should_skip_hidden(fp.relative_to(lib_dir)):
                skipped_hidden += 1
                continue

            if exts is not None and fp.suffix.lower() not in exts:
                skipped_ext += 1
                continue

            if args.max_size_kb is not None:
                try:
                    if fp.stat().st_size > args.max_size_kb * 1024:
                        skipped_size += 1
                        continue
                except Exception:
                    # Si on ne peut pas lire la taille, on essaye quand même
                    pass

            if is_binary(fp):
                skipped_bin += 1
                continue

            rel = fp.relative_to(lib_dir).as_posix()

            # Écriture de l'en-tête + contenu
            out.write(f"{SEPARATOR}\n")
            out.write(f"FILE: {rel}\n")
            out.write(f"{SEPARATOR}\n")
            try:
                text = fp.read_text(encoding="utf-8", errors="replace")
            except Exception as e:
                text = f"[ERREUR DE LECTURE: {e}]"
            out.write(text)
            if not text.endswith("\n"):
                out.write("\n")
            out.write("\n")  # espace entre fichiers

            written += 1

    print(f"[OK] Fichier généré : {out_path}")
    print(f" - Fichiers trouvés     : {total}")
    print(f" - Écrits               : {written}")
    print(f" - Ignorés (cachés)     : {skipped_hidden}")
    print(f" - Ignorés (extension)  : {skipped_ext}")
    print(f" - Ignorés (taille)     : {skipped_size}")
    print(f" - Ignorés (binaires)   : {skipped_bin}")

if __name__ == "__main__":
    main()
