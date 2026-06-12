#!/usr/bin/env python3
"""Fabled output checker — a mechanical Gate B helper.

Scans a directory (or individual files) of produced output for the banned
deferral strings from the Fabled skill, plus Python-specific stub bodies and
syntax errors. Intended for agentic environments where the model can execute
commands; in pure-text settings the model scans its own output manually.

Usage:
    python check.py <output-dir-or-file> [more paths...]

Exit code 0 = clean, 1 = findings (print them and fix), 2 = usage error.

Note: do not run this on the Fabled skill folder itself — the skill's own
WRONG/RIGHT teaching example and this script's pattern list intentionally
contain the banned strings.
"""

import ast
import re
import sys
from pathlib import Path

BANNED_PATTERNS = [
    (re.compile(r"\bTODO\b"), "TODO deferral marker"),
    (re.compile(r"\bFIXME\b"), "FIXME deferral marker"),
    (re.compile(r"rest of (the )?code", re.IGNORECASE), '"rest of the code" deferral'),
    (re.compile(r"you can implement", re.IGNORECASE), '"you can implement" deferral'),
    (re.compile(r"for brevity", re.IGNORECASE), '"for brevity" omission'),
    (re.compile(r"left as an exercise", re.IGNORECASE), '"left as an exercise" deferral'),
    (re.compile(r"\[(add|insert|fill in|expand)\s[^\]\n]*\]", re.IGNORECASE),
     "bracketed placeholder like [add details here]"),
]

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv",
             "dist", "build", ".next", ".cache"}
BINARY_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".pdf",
               ".zip", ".gz", ".tar", ".whl", ".pyc", ".so", ".dll",
               ".woff", ".woff2", ".ttf", ".eot", ".mp3", ".mp4", ".sqlite",
               ".db", ".skill"}


def iter_files(paths):
    for raw in paths:
        p = Path(raw)
        if p.is_file():
            yield p
        elif p.is_dir():
            for f in sorted(p.rglob("*")):
                if f.is_file() and not any(part in SKIP_DIRS for part in f.parts):
                    yield f


def read_text(path):
    if path.suffix.lower() in BINARY_EXTS:
        return None
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None


def scan_banned(path, text, findings):
    for lineno, line in enumerate(text.splitlines(), start=1):
        for pattern, label in BANNED_PATTERNS:
            if pattern.search(line):
                findings.append(f"{path}:{lineno}: {label}: {line.strip()[:100]}")


def _is_stub_body(body):
    """A body counts as a stub if, ignoring a leading docstring, it is only
    `pass`, `...`, or `raise NotImplementedError`."""
    stmts = list(body)
    if stmts and isinstance(stmts[0], ast.Expr) and isinstance(stmts[0].value, ast.Constant) \
            and isinstance(stmts[0].value.value, str):
        stmts = stmts[1:]  # skip docstring
    if len(stmts) != 1:
        return False
    s = stmts[0]
    if isinstance(s, ast.Pass):
        return True
    if isinstance(s, ast.Expr) and isinstance(s.value, ast.Constant) and s.value.value is Ellipsis:
        return True
    if isinstance(s, ast.Raise):
        exc = s.exc
        name = getattr(exc, "id", None) or getattr(getattr(exc, "func", None), "id", None)
        if name == "NotImplementedError":
            return True
    return False


def scan_python_stubs(path, text, findings):
    try:
        tree = ast.parse(text)
    except SyntaxError as e:
        findings.append(f"{path}:{e.lineno or 0}: Python syntax error: {e.msg}")
        return
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and _is_stub_body(node.body):
            findings.append(f"{path}:{node.lineno}: stub function body in `{node.name}` "
                            "(only pass / ... / NotImplementedError)")


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    findings = []
    checked = 0
    for f in iter_files(argv[1:]):
        text = read_text(f)
        if text is None:
            continue
        checked += 1
        scan_banned(f, text, findings)
        if f.suffix == ".py":
            scan_python_stubs(f, text, findings)
    if findings:
        print(f"GATE B: FAIL — {len(findings)} finding(s) across {checked} file(s):")
        for line in findings:
            print("  " + line)
        print("Rewrite each offending file in full, then re-run.")
        return 1
    print(f"GATE B: PASS — 0 findings across {checked} file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
