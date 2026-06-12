# Document / plan example — compressed Phase 0–5 trace (Mode A: static verification)

Prompt: **"write a complete kickoff brief for our team's SVN→Git migration, ready to circulate"**

This trace shows the *shape* of the work for a non-code deliverable. In a real run every section is drafted in full.

## Plan (Phase 0)

Definition of done: a brief the team lead can paste into email or the wiki today and circulate without editing anything first.

Requirements — note 2 ("ready to circulate") translates into the checkable items 3–8:
1. Kickoff brief for an SVN→Git migration (explicit)
2. Ready to circulate as-is, no gaps left for the sender (explicit)
3. Purpose and context: why move, why now (implicit — readers need the motivation)
4. Scope: which repos and assets migrate, which don't (implicit)
5. Timeline with phases, dates, and an owner per phase (implicit)
6. "What changes for you": concrete action items per audience (implicit)
7. Risks and mitigations, including the rollback position (implicit)
8. Sign-off and a channel for questions (implicit)

Self-interview:
1. A circulate-ready kickoff brief telling a software team what the migration is, when it happens, and what each person must do.
2. Proof: a team lead reads it top to bottom and finds no blank to fill before pressing send.
3. Failure modes: (a) placeholders like "[date TBD]" or "[insert owner]"; (b) a timeline with phases but no owners; (c) tool jargon with no plain action items for non-experts.
4. Out of scope: the technical migration runbook, Git training materials, a repo-by-repo inventory.

## Assumptions

1. No names or calendar dates were given, so the brief uses **roles** (Migration Lead, Repo Owner, Every Developer) and **relative weeks** (Week 1–4 from kickoff), and says so in its footer — the sender can substitute real names in one pass *if they want to*, but nothing requires it.
2. Target platform stated as an assumption inside the brief (self-hosted GitLab) with a one-line note on where to change it.
3. History is migrated, not discarded; large binaries move to LFS.

## Section contracts (Phase 2)

Each section gets a one-line contract — the question it must answer:
- **Why we're moving** → what concrete problem does staying on SVN cause us this year?
- **Scope** → which repos/assets move, which explicitly don't, and where the line is?
- **Timeline** → who does what in which week, ending in what state?
- **What changes for you** → what must each reader do, and by when?
- **Risks & rollback** → what could go wrong, what's the mitigation, when do we abort?
- **Sign-off & questions** → who approves this plan, and where do questions go?

Build order: Why → Scope → Timeline → What changes for you → Risks → Sign-off (each later section leans on the earlier ones).

## Build (Phase 3 — summarized; full in a real run)

Every section drafted in full prose against its contract. Zero empty headings, zero bracketed placeholders, no "etc." standing in for content. Owners are roles, dates are relative weeks, per the assumptions. The whole brief reads top to bottom as one voice.

(GATE B: scanned for the prose banned-equivalents — "[add details here]", "section left for the author", empty headings, trailing "etc." — zero hits → PASS.)

## Verification (Phase 4, Mode A — checklist re-copied, evidence quoted)

1. ✅ Kickoff brief for SVN→Git — evidence: title line "Kickoff brief: migrating from SVN to Git".
2. ✅ Circulate-ready — evidence: footer "Roles and relative weeks are used throughout; substitute names only if you prefer — nothing here requires editing before sending."
3. ✅ Purpose — evidence: "branching and code review on SVN now cost us roughly a day per release…"
4. ✅ Scope — evidence: "Moving: the three product repos, full history. Not moving: the retired prototype repo (archived read-only)."
5. ✅ Timeline with owners — evidence: "Week 2 — Repo Owners freeze SVN commits; Migration Lead runs the final sync."
6. ✅ Action items per audience — evidence: "Every developer: install Git, clone the new remote, delete local SVN checkouts by end of Week 3."
7. ✅ Risks & rollback — evidence: "If verification fails in Week 3, SVN remains the source of truth and the freeze lifts — nothing is deleted until Week 4 sign-off."
8. ✅ Sign-off & questions — evidence: "Approved by: Engineering Manager (role). Questions: the #git-migration channel."

(GATE C: all eight ticked with quoted lines → PASS.)

## Delivery (Phase 5)

**How to use this document.** Who reads it: the whole team, at the kickoff announcement. What they do: read "What changes for you", complete their action items by the stated week, raise questions in the named channel. The sender posts it as-is.

Assumptions restated in two lines at the foot of the brief. No meta-narration about the drafting.
