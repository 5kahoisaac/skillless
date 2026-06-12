# CLI / script example — compressed Phase 0–5 trace (Mode A: static verification)

Prompt: **"build me a CLI expense tracker with categories and monthly summaries, data saved locally"**

This trace shows the *shape* of the work. In a real run, every file is written in full; here Phase 3 is summarized.

## Plan (Phase 0)

Definition of done: a single command lets the user record an expense, and another prints per-category totals for a given month, with data surviving between runs.

Requirements:
1. Command-line interface (explicit)
2. Record an expense with amount and category (explicit)
3. Monthly summaries, grouped by category (explicit)
4. Data saved locally (explicit)
5. A documented entry point and run command (implicit)
6. Survives the first run with no data file; rejects bad input such as a non-numeric amount (implicit)

Self-interview:
1. A local CLI expense tracker for one user who wants quick capture and month-end category totals.
2. `python -m expenses add 12.50 food "lunch"` followed by `python -m expenses summary 2026-06` printing a category breakdown.
3. (a) It doesn't run with the stated command; (b) the summary groups or filters the month incorrectly; (c) data is lost between runs.
4. Out of scope: budgets, editing or deleting entries, multiple currencies, charts, multi-user.

## Assumptions

1. Python 3.9+, standard library only.
2. Data stored as JSON in `expenses.json` in the working directory.
3. Amounts are plain floats, currency-agnostic.
4. Months are addressed as `YYYY-MM`; an expense's date defaults to today and can be overridden with `--date YYYY-MM-DD`.

(GATE A: four answers written, six requirements numbered → PASS.)

## Scope and stack (Phase 1)

In scope: `add`, `list`, `summary`. Out of scope: as listed above. Stack: Python `argparse` + `json` — boring, zero dependencies, runs anywhere.

## File tree & contracts (Phase 2)

```
expenses/
├── __init__.py
├── __main__.py     # argparse CLI; parses args, dispatches to storage/summary
├── storage.py      # load(path) -> list[dict]; save(path, items) -> None
└── summary.py      # monthly_totals(items, month: "YYYY-MM") -> dict[str, float]
README.md
```

Record shape: `{"date": "YYYY-MM-DD", "amount": float, "category": str, "note": str}`

Build order (by dependency): `storage.py` → `summary.py` → `__main__.py` → `README.md`.

## Build (Phase 3 — summarized here, full in a real run)

Each file is preceded by its one-line contract, then written completely (~120 lines total). While writing `__main__.py`, its imports are re-checked against what `storage.py` and `summary.py` actually export. Handled inline: missing data file on first run, corrupt JSON, non-numeric amount, unknown subcommand, empty data on `summary`.

(GATE B: output scanned for banned strings → zero hits → PASS.)

## Verification (Phase 4 — checklist re-copied, evidence quoted)

1. ✅ CLI — evidence: `parser = argparse.ArgumentParser(prog="expenses")` in `__main__.py`.
2. ✅ Record amount + category — evidence: `add_parser.add_argument("amount", type=float)` and `("category")` in `__main__.py`.
3. ✅ Monthly summaries by category — evidence: `def monthly_totals(items, month):` in `summary.py`; sample output block `food   42.50`.
4. ✅ Saved locally — evidence: `json.dump(items, f, indent=2)` in `storage.py`.
5. ✅ Entry point documented and real — evidence: README says `python -m expenses …` and `expenses/__main__.py` exists in the tree.
6. ✅ First-run and bad-input handling — evidence: `except FileNotFoundError: return []` in `storage.py`; `type=float` raises a clean argparse error.

Happy path traced end to end: run command → argparse → `storage.load` → append → `storage.save` → `summary.monthly_totals` → printed table. Dependency list (none) matches imports (stdlib only).

(GATE C: all six ticked with quotes → PASS.)

## Delivery (Phase 5)

**How to run.** Requires Python 3.9+. No install step.
`python -m expenses add 12.50 food "lunch"` · `python -m expenses summary 2026-06`

Assumptions restated in two lines. No commentary about how hard it was — the deliverable speaks for itself.
