#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Génère un INDEX numéroté des fichiers du dossier `lib/`, affiche l'arborescence
`assets/` et `lib/`, et pour chaque fichier sélectionné, liste SEULEMENT :
- les classes top-level
- et, pour chaque classe, les méthodes (constructeurs, méthodes, getters, setters, operators)
SANS leur contenu.

Améliorations clés :
- Parsing sensible aux commentaires/chaînes pour le comptage des accolades.
- Détection Dart 3 : abstract/base/final/sealed/interface + `mixin class`.
- Méthodes multi-lignes (annotations, params éclatés, async/sync*, fin `{`/`=>`/`;`).
- Constructeurs `const`/`factory`, nommés, redirections `=`, listes d’initialisation `:`.
- Getters/setters/operators détectés proprement.
"""

import argparse
import sys
import json
import re
from pathlib import Path

# -------------------- Regex & helpers pour classes/méthodes --------------------

# Modificateurs Dart 3 avant 'class'
CLASS_DECL_RE = re.compile(
    r'^\s*(?:(?:abstract|base|interface|final|sealed)\s+)*(?:mixin\s+)?class\s+([A-Za-z_]\w*)\b'
)

# Annotations
_ANN = r'(?:@[\w.()<>\[\],\s]+?\s+)*'
# Modifs autorisés sur méthodes
_MODS = r'(?:external\s+)?(?:static\s+)?'
# Type de retour optionnel (génériques approximatifs + ? nullable)
_TYPE_OPT = r'(?:void|dynamic|[A-Za-z_]\w*(?:<[^<>]*>)*\??)?'

_RET_TYPE = r'(?:void|dynamic|[^\s(][^(\n]*?)'

# Méthodes (avec type optionnel), fin par {, => ou ;
CLASS_METHOD_RE = re.compile(
    rf'^\s*{_ANN}{_MODS}(?:{_RET_TYPE}\s+)?'
    r'(?P<name>[A-Za-z_]\w*)'
    r'(?:\s*<[^>]*>)?\s*\((?P<params>.*)\)\s*'
    r'(?:async\*?|sync\*?)?\s*(?:=>|\{{|;)\s*$'
)


# Getters / setters
CLASS_GETTER_RE = re.compile(
    rf'^\s*{_ANN}{_MODS}(?:{_TYPE_OPT}\s+)?get\s+([A-Za-z_]\w*)\s*(?:=>|\{{|;)\s*$'
)

CLASS_SETTER_RE = re.compile(
    rf'^\s*{_ANN}{_MODS}set\s+([A-Za-z_]\w*)\s*\((?P<params>.*)\)\s*(?:=>|\{{|;)\s*$'
)

# Operators
CLASS_OPERATOR_RE = re.compile(
    rf'^\s*{_ANN}{_MODS}(?:{_TYPE_OPT}\s+)?operator\s+([^\s(]+)\s*\((?P<params>.*)\)\s*(?:=>|{{|;)\s*$'
)

# Fallback très permissif pour les méthodes à bloc (async { ... })
CLASS_METHOD_BLOCK_RE = re.compile(
    rf'^\s*{_ANN}{_MODS}(?:{_RET_TYPE}\s+)?'
    r'(?P<name>[A-Za-z_]\w*)\s*'          # nom méthode
    r'(?:<[^>]*>)?\s*\((?P<params>.*)\)\s*'
    r'(?:async\*?|sync\*?)?\s*\{{\s*$'    # termine par '{' (échap f-string)
)

# --- Pré-nettoyage des signatures (profondeur == 1) ---
_PRE_END_RE = re.compile(r'\s*(?:async\*?|sync\*?)?\s*(?:=>|\{|\;)\s*$')
_PRE_ANNOTS_RE = re.compile(r'^(?:@[\w.()<>\[\],\s]+\s+)+')
_PRE_MODS_RE = re.compile(r'^(?:override\s+)?(?:(?:external|static|covariant|required|late|final)\s+)*')

def _preclean_signature(s: str) -> str:
    # retire suffixe de fin
    s = _PRE_END_RE.sub('', s.strip())
    # retire annotations en tête
    s = _PRE_ANNOTS_RE.sub('', s)
    # retire modificateurs usuels
    s = _PRE_MODS_RE.sub('', s)
    # si getter/setter/operator → garder tel quel
    head = s.lstrip()
    if head.startswith('get ') or head.startswith('set ') or head.startswith('operator '):
        pass
    else:
        s = _strip_return_type(s)

    # compacter les espaces
    s = re.sub(r'\s+', ' ', s).strip()
    return s

# --- Matchers simples sur signature nettoyée ---
SIMPLE_METHOD_RE   = re.compile(r'^(?P<name>[A-Za-z_]\w*)\s*(?:<[^>]*>)?\s*\((?P<params>.*)\)$')
SIMPLE_GETTER_RE   = re.compile(r'^get\s+([A-Za-z_]\w*)$')
SIMPLE_SETTER_RE   = re.compile(r'^set\s+([A-Za-z_]\w*)\s*\((?P<params>.*)\)$')
SIMPLE_OPERATOR_RE = re.compile(r'^operator\s+([^\s(]+)\s*\((?P<params>.*)\)$')



# Constructeurs (simples / nommés / factory / const / redirigés)
def make_ctor_res(class_name: str):
    return [
        re.compile(
            rf'^\s*{_ANN}(?:external\s+)?(?:const\s+)?(?:factory\s+)?{class_name}'
            rf'(?:\s*\((?P<params>.*)\))\s*(?:=>|{{|;|=|:)\s*$'
        ),
        re.compile(
            rf'^\s*{_ANN}(?:external\s+)?(?:const\s+)?(?:factory\s+)?{class_name}\.'
            rf'([A-Za-z_]\w*)\s*\((?P<params>.*)\)\s*(?:=>|{{|;|=|:)\s*$'
        ),
    ]

INVALID_NAMES = {"if","for","while","switch","try","catch","else","do","case","default","return"}

def _strip_return_type(s: str) -> str:
    """Retire un type de retour au début de s, en gérant les génériques imbriqués (<...>)."""
    s = s.lstrip()
    if s.startswith(('get ', 'set ', 'operator ')):
        return s.strip()

    m = re.match(r'^(void|dynamic|[A-Za-z_]\w*)', s)
    if not m:
        return s.strip()

    j = m.end()
    n = len(s)

    # Génériques imbriqués <...>
    if j < n and s[j] == '<':
        depth = 0
        while j < n:
            ch = s[j]
            if ch == '<':
                depth += 1
            elif ch == '>':
                depth -= 1
                if depth == 0:
                    j += 1  # consomme le dernier '>'
                    break
            j += 1
        # consomme d'éventuels '>' résiduels (ex: '>>')
        while j < n and s[j] == '>':
            j += 1

    # nullable '?'
    if j < n and s[j] == '?':
        j += 1

    # espaces avant le nom
    while j < n and s[j].isspace():
        j += 1

    return s[j:].strip()


# -------------------- Scanner commentaires/chaînes + comptage accolades --------------------

class _LexState:
    __slots__ = ("block_depth", "in_string", "string_delim", "triple", "raw")
    def __init__(self):
        self.block_depth = 0   # peut être imbriqué en Dart
        self.in_string = False
        self.string_delim = "" # ' ou "
        self.triple = False
        self.raw = False

def _process_line_code(line: str, st: _LexState):
    """
    Parcourt une ligne en ignorant commentaires et chaînes.
    Retourne: (opens, closes, cleaned_code_line, state)
    - cleaned_code_line: code sans commentaires/chaînes (utile pour match regex)
    """
    opens = closes = 0
    out = []
    i = 0
    n = len(line)
    # les commentaires // se réinitialisent à chaque ligne
    while i < n:
        c = line[i]
        # Dans commentaire bloc
        if st.block_depth > 0:
            if c == '/' and i+1 < n and line[i+1] == '*':
                st.block_depth += 1
                i += 2
                continue
            if c == '*' and i+1 < n and line[i+1] == '/':
                st.block_depth -= 1
                i += 2
                continue
            i += 1
            continue

        # Dans chaîne
        if st.in_string:
            if st.triple:
                # fin triple """ ou '''
                if c == st.string_delim and i+2 < n and line[i+1] == c and line[i+2] == c:
                    st.in_string = False
                    st.triple = False
                    i += 3
                else:
                    i += 1
                continue
            else:
                if not st.raw and c == '\\':  # escape
                    i += 2
                    continue
                if c == st.string_delim:
                    st.in_string = False
                    i += 1
                else:
                    i += 1
                continue

        # Début commentaire ligne
        if c == '/' and i+1 < n and line[i+1] == '/':
            break
        # Début commentaire bloc
        if c == '/' and i+1 < n and line[i+1] == '*':
            st.block_depth += 1
            i += 2
            continue
        # Début chaîne
        if c in ("'", '"'):
            # triple ?
            if i+2 < n and line[i+1] == c and line[i+2] == c:
                st.in_string = True
                st.string_delim = c
                st.triple = True
                st.raw = (i > 0 and line[i-1] == 'r')
                i += 3
            else:
                st.in_string = True
                st.string_delim = c
                st.triple = False
                st.raw = (i > 0 and line[i-1] == 'r')
                i += 1
            continue

        # Compte accolades en code
        if c == '{':
            opens += 1
        elif c == '}':
            closes += 1

        out.append(c)
        i += 1

    return opens, closes, "".join(out), st

# -------------------- Parcours des blocs de classe --------------------

def _scan_class_blocks(text: str):
    """Yield (class_name, decl_line, open_line, close_line)."""
    lines = text.splitlines()
    n = len(lines)
    st = _LexState()

    i = 0
    while i < n:
        _, _, code, st = _process_line_code(lines[i], st)
        m = CLASS_DECL_RE.match(code)
        if not m:
            i += 1
            continue

        cls = m.group(1)

        # Cherche la première '{' de la classe et son bloc équilibré
        depth = 0
        open_line = None
        close_line = None

        j = i
        # on repart de la ligne de la déclaration incluse
        while j < n:
            o, c, code_j, st = _process_line_code(lines[j], st)
            # détecte la première '{' rencontrée en code
            if open_line is None and o > 0:
                open_line = j + 1  # 1-based
                depth = o - c
            else:
                depth += o - c

            if open_line is not None and depth == 0:
                close_line = j + 1
                break
            j += 1

        if open_line is not None and close_line is not None:
            yield (cls, i + 1, open_line, close_line)
            i = j + 1
        else:
            # classe incomplète ; on avance pour éviter boucle
            i += 1

# -------------------- Détection des méthodes dans les classes --------------------

def _aggregate_signatures_in_depth1(lines, start_l, end_l):
    """
    Agrège les signatures (multi-lignes) uniquement quand on est à profondeur locale == 1.
    Retourne une liste de tuples (sig_str, first_line_no)
    """
    st = _LexState()
    depth = 0
    collecting = False
    buf = []
    first_line = None
    paren = 0

    results = []

    for lno in range(start_l, end_l + 1):
        o, c, code, st = _process_line_code(lines[lno - 1], st)

        if not collecting and depth == 1:
            stripped = code.strip()
            if stripped:
                # heuristique de départ : présence de '(' ou mot-clé get/set/operator
                if ('(' in stripped) or stripped.startswith('get ') or stripped.startswith('set ') or ' operator ' in f' {stripped} ' or stripped.startswith('operator '):
                    collecting = True
                    buf = [stripped]
                    first_line = lno
                    # parens de la ligne
                    paren = stripped.count('(') - stripped.count(')')
                    # final possible immédiat
                    if paren <= 0 and ('=>' in stripped or '{' in stripped or ';' in stripped):
                        results.append((" ".join(buf), first_line))
                        collecting = False
                        buf = []
                        first_line = None
                        paren = 0
        elif collecting and depth == 1:
            piece = code.strip()
            if piece:
                buf.append(piece)
                paren += piece.count('(') - piece.count(')')
                if paren <= 0 and ('=>' in piece or '{' in piece or ';' in piece):
                    results.append((" ".join(buf), first_line))
                    collecting = False
                    buf = []
                    first_line = None
                    paren = 0

        # mise à jour profondeur locale
        depth += o
        depth -= c

    return results

def outline_methods_in_classes(text: str):
    """
    Retourne une liste de dict: {'kind','class','name','extra','line'}
    pour methods/get/set/ctors/operators uniquement au niveau 1 (dans la classe)
    """
    out = []
    lines = text.splitlines()

    for cls, decl_line, open_line, close_line in _scan_class_blocks(text):
        ctor_res = make_ctor_res(cls)

        signatures = _aggregate_signatures_in_depth1(lines, open_line, close_line)
        for sig, lno in signatures:
            s = sig.strip()

            # Constructeurs
            matched_ctor = False
            for cre in ctor_res:
                m2 = cre.match(s)
                if m2:
                    # 2e regex = constructeur nommé (className.named)
                    if m2.lastindex and m2.lastindex >= 2 and m2.group(1):
                        out.append({"kind": "ctor", "class": cls, "name": f"{cls}.{m2.group(1)}", "extra": "(…)", "line": lno})
                    else:
                        out.append({"kind": "ctor", "class": cls, "name": cls, "extra": "(…)", "line": lno})

                    matched_ctor = True
                    break
            if matched_ctor:
                continue

            # Getters (avec pré-nettoyage)
            s_clean = _preclean_signature(s)

            m = SIMPLE_GETTER_RE.match(s_clean)
            if m:
                name = m.group(1)
                if name not in INVALID_NAMES:
                    out.append({"kind": "getter", "class": cls, "name": name, "extra": "", "line": lno})
                continue

            m = SIMPLE_SETTER_RE.match(s_clean)
            if m:
                name = m.group(1)
                if name not in INVALID_NAMES:
                    params = re.sub(r'\s+', ' ', (m.group('params') or '').strip())
                    if len(params) > 120: params = params[:117] + '...'
                    out.append({"kind": "setter", "class": cls, "name": name, "extra": f"({params})", "line": lno})
                continue

            m = SIMPLE_OPERATOR_RE.match(s_clean)
            if m:
                op = m.group(1)
                params = re.sub(r'\s+', ' ', (m.group('params') or '').strip())
                if len(params) > 120: params = params[:117] + '...'
                out.append({"kind": "operator", "class": cls, "name": f"operator {op}", "extra": f"({params})", "line": lno})
                continue

            # Méthodes "normales" (après nettoyage)
            m = SIMPLE_METHOD_RE.match(s_clean)
            if m:
                name = m.group('name')
                if name not in INVALID_NAMES:
                    params = re.sub(r'\s+', ' ', (m.group('params') or '').strip())
                    if len(params) > 120: params = params[:117] + '...'
                    out.append({"kind": "method", "class": cls, "name": name, "extra": f"({params})", "line": lno})
                continue



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

# -------------------- Parsing OUTLINE (top-level classes uniquement) --------------------

def outline_file_text(text: str) -> list[dict]:
    """
    Symboles top-level: {kind, name, extra, line}, seulement les CLASSES à profondeur 0.
    """
    symbols = []
    lines = text.splitlines()
    st = _LexState()
    depth = 0
    for i, raw in enumerate(lines, start=1):
        o, c, code, st = _process_line_code(raw, st)
        if depth == 0:
            m = CLASS_DECL_RE.match(code)
            if m:
                name = m.group(1)
                if name not in INVALID_NAMES:
                    symbols.append({"kind": "class", "name": name, "extra": "", "line": i})
        depth += o
        depth -= c
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

# -------------------- Programme principal --------------------

def main():
    parser = argparse.ArgumentParser(
        description="Index + arbo + OUTLINE (classes + méthodes) des fichiers ../lib/ sans contenu."
    )

    # Script dans scripts/ → on remonte à la racine du projet
    parser.add_argument("--lib", default="lib", help="Dossier racine (défaut: ../lib)")
    parser.add_argument("--assets", default="assets", help="Dossier assets à afficher (défaut: ../assets)")
    parser.add_argument("--output", "-o", default="scripts/output/lib_outline.txt",
                        help="Fichier de sortie OUTLINE (défaut: output/lib_outline.txt)")

    parser.add_argument("--ext", nargs="*", default=None, help="Extensions à inclure (ex: --ext .dart .md)")

    # Par défaut: on ignore les fichiers/dossiers cachés
    parser.add_argument("--skip-hidden", action="store_true", default=True,
                        help="Ignorer fichiers/dossiers cachés (défaut: True)")
    # (Option propre si tu veux pouvoir l'annuler)
    parser.add_argument("--no-skip-hidden", action="store_false", dest="skip_hidden",
                        help="Ne PAS ignorer les fichiers/dossiers cachés")

    parser.add_argument("--max-size-kb", type=int, default=None, help="Ignorer les fichiers > taille (kio).")
    parser.add_argument("--exclude-globs", nargs="*", default=[], help="Exclusions (ex: **/*.g.dart build/** .dart_tool/**)")
    parser.add_argument("--git-only", action="store_true", help="Inclure uniquement les fichiers suivis par Git")

    parser.add_argument("--list-only", action="store_true", help="Afficher l'INDEX uniquement et quitter")
    parser.add_argument("--select", default=None, help='Sélection par numéros ex: "1,4-7,12"')

    # Par défaut: on écrit le JSON, sauf si --no-index-json
    parser.add_argument("--index-json", action="store_true", default=True,
                        help="Écrire <output>.index.json (défaut: True)")
    parser.add_argument("--no-index-json", action="store_false", dest="index_json",
                        help="Désactiver l’écriture du JSON d’index")

    parser.add_argument("--methods-in-classes", action="store_true",
                        help="Inclure les méthodes à l'intérieur des classes (sans contenu)")

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

    # Liste des fichiers candidates
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

    num_to_path = {num: (lib_dir / rel) for num, rel, *_ in index_list}

    # Écriture OUTLINE
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

            # Classes top-level uniquement
            symbols = outline_file_text(text)

            # Méthodes à l'intérieur des classes (optionnel)
            class_methods = outline_methods_in_classes(text) if args.methods_in_classes else []

            out.write(f"{SUBSEP}\nFILE #{num}: {rel}\n{SUBSEP}\n")

            # Regroupement lisible
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

            # Méthodes orphelines (si la classe n'a pas été reconnue top-level)
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

    print(f"[OK] Outline généré : {out_path}")
    print(f" - Fichiers indexés (lib) : {len(index_list)}")
    print(f" - Fichiers dans l'outline : {len(selected_nums)}")

if __name__ == "__main__":
    main()
