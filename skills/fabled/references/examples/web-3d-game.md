# Web / visual / game example — compressed Phase 0–5 trace (Mode B: executed verification)

Prompt: **"I want to create a webbed Flappy Bird video game, but 3D and I want it to look pretty and playable."**

This trace comes from a real run. It shows the *shape* of the work; in the real run every file was written in full and every check was actually executed.

## Plan (Phase 0)

Definition of done: opening one HTML file in a modern browser shows a polished 3D scene where tap/click/Space flaps a bird through pipe gaps, score rises per pipe, collisions end the run with a restart — at a smooth frame rate.

Requirements — note 4 and 5 translate the subjective adjectives into checkable items:
1. Runs in a browser (explicit: "webbed")
2. Flappy Bird mechanics: gravity, flap impulse, pipe gaps, score on pass, pipe/floor collision ends the run, restart loop (explicit)
3. Real 3D rendering (explicit)
4. "Pretty" → cohesive named palette; gradient sky; consistent low-poly flat-shaded style; real lighting with soft shadows; depth cues (fog, parallax clouds, distant terrain); polished typographic UI (translated)
5. "Playable" → responsive input (tap + click + Space); fixed-timestep physics; slightly forgiving hitboxes; difficulty ramps with a cap; all three UI states (title / HUD / game over); instant restart (translated)
6. Single self-contained file, zero build step (implicit)
7. Window resize handled (implicit)
8. On-screen instructions (implicit)
9. Runtime guards: CDN failed to load, WebGL unavailable, runtime error → friendly overlay, never a blank page (implicit)

Self-interview:
1. A browser 3D Flappy Bird, pretty and immediately playable, for someone who will open the file and judge it in the first thirty seconds.
2. Open the file → tap → clear three pipes → score reads 3.
3. (a) Blank page (CDN/WebGL/JS failure); (b) feels bad (unfair hitboxes, jerky or frame-rate-dependent physics); (c) looks flat (no lighting/depth, template styling).
4. Out of scope: external art assets, leaderboards, sound files (procedural audio only), portrait-phone layout tuning, post-processing effects.

## Assumptions

1. Three.js **pinned to a specific release** on a major CDN — a version known to exist and to work inside sandboxed preview iframes. Floating "latest" URLs are how one-shot pages die later.
2. One network fetch for the CDN script is acceptable; everything else is procedural (geometry, gradient sky, ground texture from a canvas, oscillator sound effects).
3. Best score is **in-memory only**: embedded preview sandboxes commonly block storage APIs, and a crash beats a missing feature.
4. Audio initializes on the first user gesture (browser autoplay policy).

## Scope and stack (Phase 1)

Category row: *web page / app / game* → one self-contained HTML file. Stack: vanilla JS + pinned Three.js from CDN; HTML/CSS overlay for UI (crisper text than in-scene text). In: core loop, score + session best, SFX, flap particles, reduced-motion respect. Out: as listed above.

## File tree & contracts (Phase 2)

One file, two script blocks with **marked boundaries** so the logic can be extracted and tested headlessly:

```
flappy-bird-3d.html
├── <style>                     UI: HUD, title card, game-over panel, fatal overlay
├── <script game-logic>         PURE: no DOM, no THREE  ← between ==LOGIC-START/END== markers
│     C (tuning constants), makeRng(seed), nextGapY(prev, rng),
│     createState(seed?) -> state, flap(state),
│     collide(birdY, pipe) -> bool,
│     step(state, dt) -> { scored: int, died: bool }
└── <script game-render>        THREE scene + UI + input; consumes ONLY the logic API
```

Cross-contract invariant: the renderer pools 8 pipe meshes ⇄ the logic must never keep more than 8 live pipes. (Invariants that span the boundary become test assertions.)

Build order: logic → render (guards first: missing THREE, no WebGL, window.onerror overlay).

## Build (Phase 3 — summarized; full in the real run)

~620 lines, every function complete. Renderer reads logic state each frame (fixed-timestep accumulator, dt 1/120) and never mutates it except through `flap`/`createState`. First-five-minutes handling: CDN failure message, WebGL failure message, audio wrapped in try/catch, key-repeat ignored, resize handler.

(GATE B: `check.py` over the output directory → 0 findings → PASS.)

## Verification (Phase 4, Mode B — executed, evidence = command output)

- `node --check` on both extracted script blocks → both parse.
- **36 unit assertions against the extracted, exact shipped logic**: initial state and even pipe spacing; ready-state idling; flap starts game and lifts; gravity sign and fall cap mid-flight; a pipe scores exactly once and ramps speed; collision geometry at gap edges; pipe-body death; floor death and corpse rest; ceiling clamps without killing; a 60-simulated-second deterministic "ghost pilot" run holding the invariants (no false collisions, spacing stable, **live pipes ≤ 8 pool bound**, speed within [base, cap], gaps within bounds); same seed ⇒ identical world; dead birds can't flap.
- Static cross-checks: every `THREE.*` identifier exists in the pinned release; CDN URL pinned; zero `localStorage`/`sessionStorage`.
- **Instructive failure:** one assertion failed — "velocity is negative 1.5 s after a flap". Diagnosis showed the *test* was wrong: by 1.5 s the unflapped bird had landed, and the dead-state handler correctly zeroes velocity. The requirement list was the arbiter; the test was changed to sample mid-fall, the code untouched. Fixing correct code to satisfy a broken check is a real failure mode — always decide which side is wrong first.
- Residual risk stated honestly: visual quality and frame rate are confirmed on open; everything mechanically checkable was checked.

(GATE C: all 9 requirements ticked with test output or quoted lines → PASS.)

## Delivery (Phase 5)

**How to run.** Any modern desktop or mobile browser with internet (one CDN fetch). Open `flappy-bird-3d.html` — or serve it (`python -m http.server`) and browse to it. Tap / click / Space to flap.

Assumptions restated in three lines. No commentary about the effort.
