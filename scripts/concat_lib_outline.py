#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère un INDEX numéroté des fichiers du dossier `lib/`, affiche l'arborescence
`assets/` et `lib/`, et produit un OUTLINE (symboles) des fichiers sélectionnés.
Peut EN PLUS exporter le CONTENU INTÉGRAL des fichiers sélectionnés, avec leur chemin
affiché au-dessus de chaque bloc (option --export-content).

Ajouts principaux :
- --export-content : exporte le contenu complet des fichiers sélectionnés
- --content-output : fichier de sortie pour le dump de contenu (défaut : <output>.content.txt)
- --content-only   : ne produit que le dump de contenu (ignore arbo/index/outline)
- --code-fences    : entoure chaque fichier exporté avec des fences Markdown ```
- Robustesse E/S, options compatibles (extensions, globs, Git, etc.)

Exemples:
  python concat_lib_outline.py                         # index + outline complet
  python concat_lib_outline.py --list-only             # index uniquement
  python concat_lib_outline.py --select "1,4-7,12" -o outline_sel.txt
  python concat_lib_outline.py --methods-in-classes    # inclut les méthodes internes
  python concat_lib_outline.py --select "3,9" --export-content
  python concat_lib_outline.py --select "3,9" --export-content --content-only
"""

import argparse
import sys
import json
import re
from pathlib import Path

# -------------------- Regex & helpers pour classes/méthodes --------------------

CLASS_DECL_RE = re.compile(r'^\s*(?:abstract\s+)?class\s+([A-Za-z_]\w*)\b')

CLASS_METHOD_RE = re.compile(
    r'^\s*(?:@[\w.()<>\[\],\s]+?\s+)*'
    r'(?:external\s+)?(?:static\s+)?'
    r'(?:void|dynamic|[A-Za-z_]\w*(?:<[^>]*>)*>{0,5}(?:\s*\?)?)'
    r'\s+'
    r'([A-Za-z_]\w*)'
    r'\s*\(([^)]*)\)\s*(?:async\b)?\s*(?:=>|{)'
)

CLASS_GETTER_RE = re.compile(
    r'^\s*(?:@[\w.()<>\[\],\s]+?\s+)*(?:external\s+)?(?:static\s+)?'
    r'(?:[A-Za-z_]\w*<[^>]*>|\w[\w<>,? \[\]]+)?\s*get\s+([A-Za-z_]\w*)\s*(?:=>|{)'
)
CLASS_SETTER_RE = re.compile(
    r'^\s*(?:@[\w.()<>\[\],\s]+?\s+)*(?:external\s+)?(?:static\s+)?'
    r'set\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*(?:=>|{)'
)

def make_ctor_res(class_name: str):
    return [
        re.compile(rf'^\s*(?:@[\w.()<>\[\],\s]+?\s+)*(?:factory\s+)?{class_name}\s*\(([^)]*)\)\s*(?:{{|=\s*\w+\(|=>)'),
        re.compile(rf'^\s*(?:@[\w.()<>\[\],\s]+?\s+)*(?:factory\s+)?{class_name}\.([A-Za-z_]\w*)\s*\(([^)]*)\)\s*(?:{{|=\s*\w+\(|=>)'),
    ]

INVALID_NAMES = {"if","for","while","switch","try","catch","else","do","case","default","return"}

def _scan_class_blocks(text: str):
    """Yield (class_name, decl_line, open_line, close_line)."""
    lines = text.splitlines()
    i = 0
    n = len(lines)
    while i < n:
        m = CLASS_DECL_RE.match(lines[i])
        if not m:
            i += 1
            continue
        cls = m.group(1)

        j = i
        depth = 0
        open_line = None
        seen_open = False
        while j < n:
            line = lines[j]
            for ch in line:
                if ch == '{':
                    depth += 1
                    seen_open = True
                    if open_line is None:
                        open_line = j + 1
                elif ch == '}':
                    if seen_open:
                        depth -= 1
                        if depth == 0:
                            close_line = j + 1
                            yield (cls, i + 1, open_line, close_line)
                            i = j
                            break
            else:
                j += 1
                continue
            j += 1
            break
        i += 1

def outline_methods_in_classes(text: str):
    """
    Retourne une liste de dict: {'kind','class','name','extra','line'}
    pour methods/get/set/ctors uniquement au niveau 1 (dans la classe).
    """
    out = []
    lines = text.splitlines()

    for cls, decl_line, open_line, close_line in _scan_class_blocks(text):
        if open_line is None:
            continue

        depth = 0
        ctor_res = make_ctor_res(cls)

        for lno in range(open_line, close_line + 1):
            line = lines[lno - 1]

            if depth == 1:
                m = CLASS_METHOD_RE.match(line)
                if m:
                    name = m.group(1)
                    if name not in INVALID_NAMES:
                        params = re.sub(r'\s+', ' ', (m.group(2) or '').strip())
                        if len(params) > 120:
                            params = params[:117] + '...'
                        out.append({"kind": "method", "class": cls, "name": name, "extra": f"({params})", "line": lno})

                m = CLASS_GETTER_RE.match(line)
                if m:
                    name = m.group(1)
                    if name not in INVALID_NAMES:
                        out.append({"kind": "getter", "class": cls, "name": name, "extra": "", "line": lno})

                m = CLASS_SETTER_RE.match(line)
                if m:
                    name = m.group(1)
                    if name not in INVALID_NAMES:
                        out.append({"kind": "setter", "class": cls, "name": name, "extra": "(…)", "line": lno})

                for cre in ctor_res:
                    m2 = cre.match(line)
                    if m2:
                        if m2.lastindex == 1:
                            val = (m2.group(1) or '').strip()
                            if any(ch in val for ch in ' ,:[]<>?='):
                                out.append({"kind": "ctor", "class": cls, "name": cls, "extra": "(…)", "line": lno})
                            else:
                                out.append({"kind": "ctor", "class": cls, "name": f"{cls}.{val}" if val else cls, "extra": "(…)", "line": lno})
                        elif m2.lastindex == 2:
                            out.append({"kind": "ctor", "class": cls, "name": f"{cls}.{m2.group(1)}", "extra": "(…)", "line": lno})
                        break

            depth += line.count('{')
            depth -= line.count('}')

    return out

# -------------------- Constantes & utilitaires généraux --------------------

SEPARATOR = "=" * 80
SUBSEP = "-" * 80

def is_binary(path: Path, probe_size: int = 2048) -> bool:
    """Heuristique simple pour détecter un fichier binaire."""
    try:
        with path.open("rb") as f:
            chunk = f.read(probe_size)
        if b"\x00" in chunk:
            return True
        textish = sum(c in b"\t\r\n\f\b" or 32 <= c <= 126 for c in chunk)
        return (len(chunk) > 0 and (textish / len(chunk) < 0.5))
    except Exception:
        return True

def should_skip_hidden(path: Path) -> bool:
    return any(part.startswith(".") for part in path.parts)

def matches_any_glob(path: Path, patterns: list[str]) -> bool:
    p = path.as_posix()
    for pat in patterns:
        if Path(p).match(pat) or Path(p).name == pat:
            return True
    return False

# -------------------- Arborescence --------------------

def render_tree(root: Path, skip_hidden: bool = True) -> str:
    if not root.exists() or not root.is_dir():
        return f"{root.name}/ (introuvable)\n"
    lines = [f"{root.name}/"]

    def iter_entries(dir_path: Path):
        try:
            items = list(dir_path.iterdir())
        except Exception:
            return []
        items.sort(key=lambda p: (p.is_file(), p.name.lower()))
        if skip_hidden:
            def _rel(p: Path):
                try:
                    return p.relative_to(root)
                except Exception:
                    return p
            items = [p for p in items if not should_skip_hidden(_rel(p))]
        return items

    def walk(dir_path: Path, prefix: str):
        entries = iter_entries(dir_path)
        last_index = len(entries) - 1
        for i, entry in enumerate(entries):
            connector = "└── " if i == last_index else "├── "
            if entry.is_dir():
                lines.append(f"{prefix}{connector}{entry.name}/")
                extension_prefix = "    " if i == last_index else "│   "
                walk(entry, prefix + extension_prefix)
            else:
                lines.append(f"{prefix}{connector}{entry.name}")

    walk(root, "")
    return "\n".join(lines) + "\n"

# -------------------- Stats fichiers --------------------

def count_lines_bytes(path: Path) -> tuple[int, int]:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
        lines = text.count("\n") + (0 if text.endswith("\n") else 1 if text else 0)
        byt = len(text.encode("utf-8", errors="replace"))
        return lines, byt
    except Exception:
        try:
            size = path.stat().st_size
        except Exception:
            size = 0
        return 0, size

# -------------------- Parsing OUTLINE (top-level) --------------------

DART_SYMBOL_PATTERNS = [
    (r'^\s*(?:abstract\s+)?class\s+([A-Za-z_]\w*)', 'class'),
    (r'^\s*mix[in]\s+([A-Za-z_]\w*)', 'mixin'),
    (r'^\s*enum\s+([A-Za-z_]\w*)', 'enum'),
    (r'^\s*extension\s+([A-Za-z_]\w*)?\s+on\s+([A-Za-z_][\w<>,\s?]+)', 'extension'),
    (r'^\s*typedef\s+([A-Za-z_]\w*)\s*=\s*([^;]+);', 'typedef'),
    (
    r'^\s*(?:@[\w.()]+\s*)*(?:external\s+)?(?:static\s+)?'
    r'(?:void|dynamic|[A-Za-z_]\w*(?:<[^>]*>)*>{0,5}(?:\s*\?)?)\s+'
    r'([A-Za-z_]\w*)\s*\(([^;{)]*)\)\s*(?:=>|{)',
    'function'
    ),
    (r'^\s*(?:@[\w.()]+\s*)*(?:external\s+)?(?:static\s+)?'
     r'(?:(?:\w[\w<>,? ]*)\s+)?get\s+([A-Za-z_]\w*)\s*=>', 'getter'),
    (r'^\s*(?:@[\w.()]+\s*)*(?:external\s+)?(?:static\s+)?set\s+([A-Za-z_]\w*)\s*\(([^)]*)\)\s*(?:=>|{)', 'setter'),
    (r'^\s*final\s+([A-Za-z_]\w*Provider)\s*=\s*(?:Provider|StateProvider|FutureProvider|StreamProvider|NotifierProvider|AutoDispose\w*Provider)\b', 'provider'),
    (r'^\s*GoRoute\(\s*name:\s*["\']([^"\']+)["\']\s*,\s*path:\s*["\']([^"\']+)["\']', 'route'),
]

def outline_file_text(text: str) -> list[dict]:
    """
    Symboles top-level: {kind, name, extra, line}, seulement à profondeur 0.
    """
    symbols = []
    lines = text.splitlines()
    depth = 0
    for i, raw in enumerate(lines, start=1):
        line = raw
        if depth == 0:
            for pattern, kind in DART_SYMBOL_PATTERNS:
                m = re.match(pattern, line)
                if not m:
                    continue
                name = m.group(1) if m.lastindex else ''
                if name in INVALID_NAMES:
                    break
                extra = ''
                if kind == 'extension':
                    name = m.group(1) or '(anonymous)'
                    extra = f"on {m.group(2).strip()}"
                elif kind in ('function', 'setter'):
                    if m.lastindex and m.lastindex >= 2:
                        params = m.group(2).strip()
                        params = re.sub(r'\s+', ' ', params)
                        if len(params) > 120:
                            params = params[:117] + '...'
                        extra = f"({params})"
                elif kind == 'route':
                    name = m.group(1)
                    extra = m.group(2)
                symbols.append({"kind": kind, "name": name, "extra": extra, "line": i})
                break
        depth += line.count('{')
        depth -= line.count('}')
    return symbols

# -------------------- Sélection / index --------------------

def parse_select_ranges(sel: str, max_n: int) -> list[int]:
    selected = set()
    for part in sel.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            try:
                start = int(a); end = int(b)
            except ValueError:
                continue
            if start > end:
                start, end = end, start
            for x in range(max(1, start), min(max_n, end) + 1):
                selected.add(x)
        else:
            try:
                x = int(part)
            except ValueError:
                continue
            if 1 <= x <= max_n:
                selected.add(x)
    return sorted(selected)

def list_git_tracked(root: Path) -> set[str]:
    try:
        import subprocess
        res = subprocess.run(
            ["git", "ls-files", "--", str(root)],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, check=True
        )
        rels = set()
        for line in res.stdout.splitlines():
            p = Path(line.strip())
            try:
                rel = p.relative_to(root).as_posix()
            except Exception:
                if (root / p).exists():
                    rel = p.as_posix()
                else:
                    try:
                        rel = Path(line.strip()).as_posix()
                    except Exception:
                        continue
            rels.add(rel)
        return rels
    except Exception:
        return set()

# -------------------- Export de contenu --------------------

def export_selected_contents(lib_dir: Path, selected_nums: list[int], index_list: list[tuple], out_path: Path, use_fences: bool):
    """
    Écrit dans `out_path` le contenu intégral des fichiers sélectionnés.
    Format :
    ----------------------------------------------------------------------------
    FILE #<num>: <lib/relative/path>
    ----------------------------------------------------------------------------
    <contenu du fichier...>
    """
    num_to_rel = {num: rel for (num, rel, *_rest) in index_list}
    with out_path.open("w", encoding="utf-8", newline="\n") as out:
        out.write(f"{SEPARATOR}\nEXPORT CONTENU — {len(selected_nums)} fichier(s)\n{SEPARATOR}\n\n")
        for i, num in enumerate(selected_nums, start=1):
            rel = num_to_rel.get(num)
            if not rel:
                continue
            fp = (lib_dir / rel)
            header = f"{SUBSEP}\nFILE #{num}: {rel}\n{SUBSEP}\n"
            out.write(header)
            try:
                text = fp.read_text(encoding="utf-8", errors="replace")
            except Exception as e:
                out.write(f"[ERREUR DE LECTURE: {e}]\n\n")
                continue
            if use_fences:
                out.write("```dart\n")
                out.write(text)
                if not text.endswith("\n"):
                    out.write("\n")
                out.write("```\n\n")
            else:
                out.write(text)
                if not text.endswith("\n"):
                    out.write("\n")
                out.write("\n")
    return out_path

# -------------------- Programme principal --------------------

def main():
    parser = argparse.ArgumentParser(
        description="Index + arbo + OUTLINE (classes/fonctions) des fichiers lib/. Peut exporter le CONTENU intégral des fichiers sélectionnés."
    )
    parser.add_argument("--lib", default="lib", help="Dossier racine (défaut: ../lib)")
    parser.add_argument("--assets", default="assets", help="Dossier assets à afficher (défaut: ../assets)")
    parser.add_argument("--output", "-o", default="scripts/output/lib_outline.txt",
                        help="Fichier de sortie OUTLINE (défaut: output/lib_outline.txt)")

    parser.add_argument("--ext", nargs="*", default=None, help="Extensions à inclure (ex: --ext .dart .md)")

    # Par défaut: on skip les cachés, option pour désactiver
    parser.add_argument("--skip-hidden", dest="skip_hidden", action="store_true", default=True,
                        help="Ignorer fichiers/dossiers cachés (défaut: True)")
    parser.add_argument("--no-skip-hidden", dest="skip_hidden", action="store_false",
                        help="Ne PAS ignorer les fichiers/dossiers cachés")

    parser.add_argument("--max-size-kb", type=int, default=None, help="Ignorer les fichiers > taille (kio).")
    parser.add_argument("--exclude-globs", nargs="*", default=[], help="Exclusions (ex: **/*.g.dart build/** .dart_tool/**)")
    parser.add_argument("--git-only", action="store_true", help="Inclure uniquement les fichiers suivis par Git")

    parser.add_argument("--list-only", action="store_true", help="Afficher l'INDEX uniquement et quitter")
    parser.add_argument("--select", default=None, help='Sélection par numéros ex: "1,4-7,12"')

    # Par défaut: index json ON, option pour couper
    parser.add_argument("--index-json", dest="index_json", action="store_true", default=True,
                        help="Écrire <output>.index.json (défaut: True)")
    parser.add_argument("--no-index-json", dest="index_json", action="store_false",
                        help="Désactiver l’écriture du JSON d’index")

    parser.add_argument("--methods-in-classes", action="store_true",
                        help="Inclure les méthodes à l'intérieur des classes (sans contenu)")

    # Export contenu
    parser.add_argument("--export-content", action="store_true",
                        help="Exporter le contenu intégral des fichiers sélectionnés")
    parser.add_argument("--content-output", default=None,
                        help="Chemin du fichier de sortie pour le contenu (défaut: <output>.content.txt)")
    parser.add_argument("--content-only", action="store_true",
                        help="N’écrire QUE le dump de contenu (ignore arbo/index/outline)")
    parser.add_argument("--code-fences", action="store_true",
                        help="Encadrer chaque fichier exporté par des fences Markdown ```")

    args = parser.parse_args()

    lib_dir = Path(args.lib).resolve()
    assets_dir = Path(args.assets).resolve()
    out_path = Path(args.output).resolve()

    if not lib_dir.exists() or not lib_dir.is_dir():
        print(f"[ERREUR] Dossier introuvable: {lib_dir}", file=sys.stderr)
        sys.exit(1)

    # Normalisation extensions
    exts = None
    if args.ext:
        exts = {e.lower() if e.startswith(".") else f".{e.lower()}" for e in args.ext}

    # Liste des fichiers candidats
    all_files = sorted(
        [p for p in lib_dir.rglob("*") if p.is_file()],
        key=lambda p: p.relative_to(lib_dir).as_posix().lower()
    )

    git_tracked = None
    if args.git_only:
        git_tracked = list_git_tracked(lib_dir)

    eligible = []
    for fp in all_files:
        rel = fp.relative_to(lib_dir)
        if args.skip_hidden and should_skip_hidden(rel):
            continue
        if args.exclude_globs and matches_any_glob(rel, args.exclude_globs):
            continue
        if exts is not None and fp.suffix.lower() not in exts:
            continue
        if args.max_size_kb is not None:
            try:
                if fp.stat().st_size > args.max_size_kb * 1024:
                    continue
            except Exception:
                pass
        if is_binary(fp):
            continue
        if git_tracked is not None and rel.as_posix() not in git_tracked:
            continue
        eligible.append(fp)

    # Numérotation stable
    index_list = []
    for i, fp in enumerate(eligible, start=1):
        lines, byt = count_lines_bytes(fp)
        index_list.append((i, fp.relative_to(lib_dir).as_posix(), lines, byt))

    if args.list_only:
        print(SEPARATOR)
        print("INDEX DES FICHIERS LIB/ (numéroté)")
        print(SEPARATOR)
        for num, rel, lines, byt in index_list:
            print(f"{num:>4}. {rel}  ({lines} lignes, {byt} octets)")
        print(f"\nTotal indexés: {len(index_list)}")
        return

    # Sélection (par défaut: tous)
    selected_nums = [num for num, *_ in index_list]
    if args.select:
        selected_nums = parse_select_ranges(args.select, max_n=len(index_list))
        if not selected_nums:
            print("[INFO] Aucun numéro valide dans --select ; rien à générer.", file=sys.stderr)
            sys.exit(0)

    # Si export de contenu seulement, on fait court
    if args.export_content and args.content_only:
        content_out = Path(args.content_output) if args.content_output else out_path.with_suffix(out_path.suffix + ".content.txt")
        export_selected_contents(lib_dir, selected_nums, index_list, content_out, use_fences=args.code_fences)

        # JSON d’index minimal (utile pour rattacher les numéros → chemins)
        if args.index_json and not args.no_index_json:
            idx_path = out_path.with_suffix(out_path.suffix + ".index.json")
            data = {
                "root": str(lib_dir),
                "output": str(out_path),
                "content_output": str(content_out),
                "total_indexed": len(index_list),
                "selected_count": len(selected_nums),
                "selected_nums": selected_nums,
                "files": [
                    {"num": num, "path": rel, "lines": lines, "bytes": byt, "selected": (num in selected_nums)}
                    for (num, rel, lines, byt) in index_list
                ],
            }
            try:
                idx_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            except Exception as e:
                print(f"[WARN] Impossible d'écrire l'index JSON: {e}", file=sys.stderr)

        print(f"[OK] Contenu exporté : {content_out}")
        print(f" - Fichiers exportés : {len(selected_nums)}")
        return

    # Sinon, on génère OUTLINE standard (comme avant)
    num_to_path = {num: (lib_dir / rel) for num, rel, *_ in index_list}

    with out_path.open("w", encoding="utf-8", newline="\n") as out:
        # Arborescences
        out.write(f"{SEPARATOR}\nARBORESCENCE DU PROJET\n{SEPARATOR}\n\n")
        out.write(f"{SUBSEP}\nStructure du dossier: {assets_dir}\n{SUBSEP}\n")
        out.write(render_tree(assets_dir, skip_hidden=args.skip_hidden))
        out.write("\n")
        out.write(f"{SUBSEP}\nStructure du dossier: {lib_dir}\n{SUBSEP}\n")
        out.write(render_tree(lib_dir, skip_hidden=args.skip_hidden))
        out.write("\n")

        # INDEX
        out.write(f"{SEPARATOR}\nINDEX DES FICHIERS LIB/ (numéroté)\n{SEPARATOR}\n")
        for num, rel, lines, byt in index_list:
            mark = " *" if num in selected_nums else ""
            out.write(f"{num:>4}. {rel}  ({lines} lignes, {byt} octets){mark}\n")
        out.write(f"\nTotal indexés: {len(index_list)}\n")
        out.write(f"Marqués '*' = sélection actuelle ({len(selected_nums)} fichiers)\n\n")

        # OUTLINE des fichiers sélectionnés
        out.write(f"{SEPARATOR}\nOUTLINE DES FICHIERS SÉLECTIONNÉS ({len(selected_nums)})\n{SEPARATOR}\n\n")

        for num in selected_nums:
            fp = num_to_path[num]
            rel = fp.relative_to(lib_dir).as_posix()
            try:
                text = fp.read_text(encoding="utf-8", errors="replace")
            except Exception as e:
                out.write(f"{SUBSEP}\nFILE #{num}: {rel}\n{SUBSEP}\n[ERREUR DE LECTURE: {e}]\n\n")
                continue

            symbols = outline_file_text(text)
            class_methods = outline_methods_in_classes(text) if args.methods_in_classes else []

            out.write(f"{SUBSEP}\nFILE #{num}: {rel}\n{SUBSEP}\n")

            classes = [s for s in symbols if s.get("kind") == "class"]
            by_class = {}
            for m in class_methods:
                by_class.setdefault(m["class"], []).append(m)

            def fmt(s):
                extra = f" — {s.get('extra')}" if s.get('extra') else ""
                return f"  L{s['line']:>4}: {s['name']}{extra}"

            if classes:
                out.write("[CLASS]\n")
                for c in classes:
                    out.write(fmt(c) + "\n")
                    meths = sorted(by_class.get(c["name"], []), key=lambda x: x["line"])
                    if meths:
                        out.write(f"[METHODS {c['name']}]\n")
                        for m in meths:
                            out.write(fmt(m) + "\n")

            order = ['mixin', 'enum', 'extension', 'typedef', 'function', 'getter', 'setter', 'provider', 'route']
            kind_groups = {k: [] for k in order}
            for s in symbols:
                if s.get("kind") in kind_groups:
                    kind_groups[s["kind"]].append(s)
            for k in order:
                if kind_groups[k]:
                    out.write(f"[{k.upper()}]\n")
                    for s in kind_groups[k]:
                        out.write(fmt(s) + "\n")

            orphan_methods = []
            known_classes = {c["name"] for c in classes}
            for cls, lst in by_class.items():
                if cls not in known_classes:
                    orphan_methods.extend(lst)
            if orphan_methods:
                out.write("[METHODS (orphans)]\n")
                for m in sorted(orphan_methods, key=lambda x: (x["class"], x["line"])):
                    out.write(f"  {m['class']} :: {fmt(m)}\n")

            out.write("\n")

    # JSON d’index
    write_index_json = args.index_json and not args.no_index_json
    if write_index_json:
        idx_path = out_path.with_suffix(out_path.suffix + ".index.json")
        data = {
            "root": str(lib_dir),
            "output": str(out_path),
            "total_indexed": len(index_list),
            "selected_count": len(selected_nums),
            "selected_nums": selected_nums,
            "files": [
                {"num": num, "path": rel, "lines": lines, "bytes": byt, "selected": (num in selected_nums)}
                for (num, rel, lines, byt) in index_list
            ],
        }
        try:
            idx_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        except Exception as e:
            print(f"[WARN] Impossible d'écrire l'index JSON: {e}", file=sys.stderr)

    # Export de contenu en plus (si demandé)
    if args.export_content:
        content_out = Path(args.content_output) if args.content_output else out_path.with_suffix(out_path.suffix + ".content.txt")
        export_selected_contents(lib_dir, selected_nums, index_list, content_out, use_fences=args.code_fences)
        print(f"[OK] Contenu exporté : {content_out}")

    print(f"[OK] Outline généré : {out_path}")
    print(f" - Fichiers indexés (lib) : {len(index_list)}")
    print(f" - Fichiers dans l'outline : {len(selected_nums)}")

if __name__ == "__main__":
    main()
