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

4. **After Ivy presents ideas:**
   - Ask the user which ideas they'd like to pursue
   - For any idea the user picks, suggest running `louie-feature` to turn it into proper requirements and kick off the full development chain

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
