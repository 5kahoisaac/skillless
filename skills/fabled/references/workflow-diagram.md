# Fabled workflow — diagram (human-facing documentation only)

The model-facing instructions in `SKILL.md` deliberately carry the gates as plain
"IF condition → action" text: graph syntax adds symbol-tracking overhead that weak
models handle poorly. This diagram exists only for humans reading the skill.

```mermaid
flowchart TD
    CAL["Calibrate rigor\n(objective signals only:\nmodel ID, optional tracker)"] --> P0["Phase 0\nReconstruct intent\n(+ translate subjective adjectives)"]
    P0 --> GA{"Gate A\ninterview + numbered\nrequirements done?"}
    GA -- FAIL --> P0
    GA -- PASS --> P1["Phase 1\nScope & stack\n(category routing table)"]
    P1 --> P2["Phase 2\nDesign before code\n(+ design for verification)"]
    P2 --> P3["Phase 3\nBuild, completely"]
    P3 --> GB{"Gate B\nzero banned strings?"}
    GB -- "FAIL: rewrite file in full" --> P3
    GB -- PASS --> CK["Checkpoint\nre-copy Phase 0 checklist"]
    CK --> VM{"Verification mode\ncan you execute code?"}
    VM -- YES --> MB["Phase 4 — Mode B\nrun real checks\nevidence = pasted output"]
    VM -- NO --> MA["Phase 4 — Mode A\nstatic end-to-end trace"]
    MB --> GC{"Gate C\nevery requirement ticked\nwith evidence?"}
    MA --> GC
    GC -- "FAIL: fix items, redo Gate B + Phase 4" --> P3
    GC -- PASS --> P5["Phase 5\nDeliver for a human"]
```
