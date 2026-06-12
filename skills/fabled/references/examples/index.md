# Example index — read this first, then exactly one example

Each example is a compressed Phase 0–5 trace: the shape of the work, not full code. Match the task to a row by category, read only that file. If no row matches, read the closest one — the shape transfers.

| File | Category | Example task | Deliverable form | What it specifically demonstrates |
|---|---|---|---|---|
| `cli-expense-tracker.md` | CLI / script | "build me a CLI expense tracker with categories and monthly summaries, data saved locally" | small Python package, stdlib only | implicit requirements, contracts-first design, **Mode A** static verification with quoted code evidence |
| `web-3d-game.md` | Web / visual / game | "create a web 3D Flappy Bird, pretty and playable" | one self-contained HTML file + pinned CDN library | translating "pretty/playable" into objective requirements, pure-logic/render split for headless testing, **Mode B** executed verification, sandbox constraints, diagnosing a wrong *test* vs wrong code |
| `document-kickoff-brief.md` | Document / plan | "write a complete kickoff brief for our SVN→Git migration, ready to circulate" | the finished document itself | one-line section contracts, prose banned-equivalents, assumptions standing in for unknown names/dates |

Notes for the reader:
- The traces compress Phase 3; in a real run every file is written in full.
- Categories not yet covered (server/API, data analysis) follow the routing table in SKILL.md; the CLI and web examples are the nearest shapes.
