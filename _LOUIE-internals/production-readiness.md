# Production Readiness — Design

**What:** `_LOUIE_/guidelines/production-readiness.md` (Core + Web) and `_LOUIE_/profiles/game/guidelines/production-readiness.md` (Game) define rules that every chain agent applies by default: bounded/unbounded data, pagination, list virtualization, content robustness, three responsive layouts, and the game equivalents. Source: ProjectWB task #473.

## Why default-on, not a recipe

The failures (all rows loaded on the first page, client-side paging, card grids blown open by one long text, mobile as stacked desktop) were found in production, again and again, after the user forgot to ask. A recipe only helps when someone remembers to load it. Agents design against what they see in development, an empty database and short sample strings, so nothing in the normal chain would surface these failures. The rules therefore live in a guideline that agents read in their Context step, like `coding-guidelines.md`.

## The trigger: bounded vs unbounded

Rules that fire on every collection would be over-applied (paginating a settings list). Rules that wait for "large data" never fire, because dev data is never large. The trigger is a property you can know at requirements time: **does this grow with usage?** Tom records it per entity in `requirements.md` § Data Entities (template table: entity, class, expected volume after one year). Sophie, Leo, Nina, Max and Ava key off that table. A missing entity counts as unbounded, so a gap fails safe.

## The architect wording

`architect.md` said "Design for the project's actual scale, not hypothetical future scale." That line was meant against infrastructure over-engineering, but it read as "don't paginate". It now separates the two cases. Infrastructure scale stays YAGNI. Data growth of an unbounded entity is not hypothetical. The architecture template gains § Scaling Considerations → List Contract, so pagination, page-size limits, indexes and N+1 avoidance are decided once for the project instead of per endpoint.

## Placement

- **Hooks are short.** Each agent gets a reference in its existing guideline-read Context item, plus 1–4 bullets where its output is produced (Tom: interview topic; Sophie: guideline line, doc requirement, subsequent-run check; Leo: responsibilities, output items 6–7; Nina: implementation bullet; Max: checklist § 8 and the Critical tier; Ava: coverage priority 6). The rules themselves exist only in the guideline file. Folding the read into the existing item avoids renumbering Context lists.
- **Severity mapping:** the concept said "Major". Max's tiers are Critical / Should Fix / Suggestions, so "at least Major" became "at least Should Fix".
- **Game rules live in the profile folder.** Lint check 6 forbids ungated `_LOUIE_/profiles/` references from always-loaded files, and `profiles.md` keeps game material out of the shared folders. The base guideline names the game file behind a profile-check line. The game file replaces only the Web section, and Core still applies. The game overlays of Leo (output item 8, text fit) and Max (§ 8 against the game file) carry the game-side hooks, because those overlays replace the base sections that hold the web hooks.
- **Numbers are defaults.** A project may change a threshold in `architecture.md` with a one-line reason (List Contract → Deviations). A silent drop is a review finding.

## Out of scope

No retrofit of existing projects (`louie-evaluate` could grow a production-readiness lens later), and no infrastructure guidance.
