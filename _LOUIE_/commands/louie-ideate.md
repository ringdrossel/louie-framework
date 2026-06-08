# louie-ideate

When the user says **`louie-ideate`**, invoke Ivy (Muse) for product brainstorming.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/implementations/overview.md` — understand existing features
   - Read `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md` — understand what's technically feasible
   - Skim per-feature folders under `_LOUIE-output/implementations/<feature>/` (especially `feature.md`) to avoid duplicating planned work

2. **Determine the scope:**
   - If the user specified a focus area alongside the command, use that
   - If not, ask: "Would you like ideas for the whole product, a specific area, or improvements to an existing feature?"

3. **Invoke Ivy (Muse):**
   - Read and follow `_LOUIE_/agents/muse.md`
   - Ivy brainstorms ideas across categories: quick wins, enhancements, new features, UX improvements
   - Each idea includes: what, why, effort estimate, what it builds on, and architecture fit

4. **After Ivy presents ideas, sort each one into a bucket:**
   - **Pursue now** — for any idea the user picks to act on immediately, suggest running `louie-feature` to turn it into proper requirements and kick off the full development chain.
   - **Save to roadmap** — for any idea the user wants to keep around but not pursue now, capture it via `louie-roadmap add` so it persists in `_LOUIE-output/roadmap.md`. Pass `Source: ideate` and use Ivy's full idea card (what / why / effort / builds on / fits architecture) as the Notes verbatim.
   - **Drop** — for any idea the user doesn't want, do nothing.

   Ask once, in one prompt: "Of these, which would you like to pursue now, save to the roadmap for later, or drop?" **Present the per-idea sort as a structured choice** (pursue now / save to roadmap / drop) — use your runtime's structured-choice tool if it has one, otherwise a lettered list (see `_LOUIE_/guidelines/interaction-guidelines.md`). The dialog goes **in its own response** — never in the same response as the idea cards it sorts (the dialog hides them; § Content first, choice second). Don't force the user to triage every idea — silence on an idea means drop.

## Usage

```
louie-ideate
```

or with a focus area:

```
louie-ideate
I think the dashboard could be more useful. What ideas do you have?
```

or for exploring a direction:

```
louie-ideate
We're getting feedback that onboarding is confusing.
What could we do to improve it?
```
