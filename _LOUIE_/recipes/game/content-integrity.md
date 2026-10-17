Audit dialogue and content files against story/flags.md and story/characters/ — unregistered flags, unknown speakers, missing portraits, dangling and unreachable cues.

**Requires profile:** game

**Recipe type:** audit. This recipe produces a report and roadmap entries. It never edits content or code and never runs an agent chain — see `_LOUIE_/recipes/README.md` § Recipe Types.

# Content Integrity

## Overview

Measures whether the game's content files agree with the narrative contract: every flag a dialogue file reads or writes is registered in `_LOUIE-output/story/flags.md`, every speaker has a character doc, every emotion tag has a portrait, and every jump lands on a cue that exists. These breaks are silent until a player hits them.

**Run it** after a batch of `louie-content` runs, before a playtest or release build, or after importing an existing project.

**Don't run it** to judge story quality, voice, or continuity — that is Mira's consistency check inside `louie-content`. Don't use it for code health (`louie-evaluate`).

**What it does not do:** fix anything. Fixes go through `louie-content` (content) or `louie-update` / `louie-feature` (code).

## Threshold / Standard

The standard is the profile's narrative contract, read at run time — never restated here:

- `_LOUIE-output/story/flags.md` § Rules and § Registry — names, types, defaults, set-by / read-by, `intentional` markers, `## Retired`.
- `_LOUIE-output/story/characters/<name>.md` § Portrait Expressions — the allowed emotion tags per character.
- `_LOUIE-output/story/story-bible.md` § Dialogue Style Guide — the shared emotion-tag list.
- `_LOUIE-output/architecture.md` § Content Pipeline — which paths are content, in which format, and the game-state object flags are accessed through.

A run may be scoped to a path or chapter (`louie-recipe game:content-integrity dialogue/ch03`). A scoped run says so in its report and never closes findings outside its scope.

## Audit Procedure

1. **Resolve scope.** Read `architecture.md` § Content Pipeline. Content paths owned by Mira with a dialogue format are in scope. If the section is missing, stop: "No content pipeline declared — Sophie needs to add `## Content Pipeline` to `architecture.md` first."
2. **Resolve the format.** This procedure has rules for **Dialogue Manager 4** (`.dialogue`, syntax: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Basic_Dialogue.md and `docs/Conditions_Mutations.md`). For another format, ask the user for the equivalent markers (speaker line, tag, condition, mutation, cue, jump) before scanning, and state them in the report.
3. **Enumerate candidates** with `git ls-files` under the in-scope paths, filtered by the format's extension. Untracked files are excluded and listed as such.
4. **Exclude with reasons:** files under a folder with a `.gdignore`, fixtures under `test/`, and files the user names. Every exclusion appears in the report.
5. **Extract, per file** (Dialogue Manager 4):
   - **Speakers:** lines of the form `Name: text` (outside conditions and responses' leading `- `). `{{...}}` speaker names are dynamic — listed, not checked.
   - **Tags:** `[#tag]` / `[#a, #b]` / `[#key=value]` on speaker lines.
   - **Flag reads:** identifiers in `if` / `elif` lines and in response conditions `[if ... /]`; **flag writes:** `$> name = ...` / `$> name += ...`. Resolve `GameState.name` and plain `name` (when the file has `using GameState`, or the project sets a global state shortcut) to the flag `name`. Method calls and non-state objects are listed, not checked.
   - **Cues and jumps:** `~ cue` defines a cue; `=> cue`, `=>< cue`, and `- response => cue` jump; `END` / `END!` are built-in; `import "res://…" as alias` makes `alias/cue` valid.
6. **Compare:**
   - **F1 Unregistered flag** — read or written in content, missing from the registry (or only in `## Retired`).
   - **F2 Type mismatch** — compared or assigned in a way that contradicts the registered type (e.g. a `bool` flag compared to a number).
   - **F3 Write-only / read-only flag** — set but never read (or read but never set) across content and the code paths named in the registry's set-by / read-by, unless marked `intentional`.
   - **F4 Unknown speaker** — no `story/characters/<name>.md` for that speaker.
   - **F5 Missing portrait** — tag not in that character's portrait list (or not in the story bible's tag list).
   - **F6 Dangling jump** — jump to a cue that doesn't exist in the file or its imports.
   - **F7 Unreachable cue** — cue never jumped to and not an entry cue (entry cues are the ones named in the chapter docs' Scenes tables, plus `start`).
7. **Measure the same way twice:** sort files and findings by path, then line, so two runs on an unchanged repo produce the same report.

## Findings Report

```
Content integrity — <scope>, <format>, at <short-sha> on YYYY-MM-DD
Scanned: <N> files   Excluded: <M> (reasons below)   With findings: <K>

F1 unregistered flags:   <count>   F5 missing portraits:  <count>
F2 type mismatches:      <count>   F6 dangling jumps:      <count>
F3 write/read-only:      <count>   F7 unreachable cues:    <count>
F4 unknown speakers:     <count>

<path>:<line>  F<n>  <detail>
...

Excluded:
<path> — <reason>
```

A **clean result** says "No findings" with the scanned/excluded counts — and writes nothing.

## Outcome

Report first, ask second, in two turns (`_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second).

### Granularity

One roadmap entry per **chapter** (findings grouped by the chapter whose scenes list the file; files without a chapter group under "unassigned content"). Flag-registry findings (F1–F3) that span chapters get one entry titled for the registry.

### Entry shape

Add via `louie-roadmap add` semantics (`_LOUIE_/commands/louie-roadmap.md` § add).

- **Title:** `Content integrity: <chapter or "flag registry"> — <N> findings`
- **Source:** `audit`
- **Effort:** `S` for ≤ 5 findings, `M` above.
- **Notes:** `Measured YYYY-MM-DD at <short-sha>: F1×a, F4×b, …` plus the finding lines (path:line, code, detail). End with `Fix via louie-content; re-run this audit to verify.`

### Re-run safety (required)

Before adding, scan `## Captured` and `## Promoted` for an entry with the same title prefix (`Content integrity: <chapter>`).

- **Exists, findings remain** → append the new measurement with `louie-roadmap-change <id> note "…"`; no second entry.
- **Exists, now clean** → report it as resolved and *offer* `louie-roadmap-change <id> status Done`. Never close automatically.
- **No entry** → add one.

## Follow-Up

- Content fixes (wrong flag name, missing cue, unregistered flag, missing portrait reference) → `louie-content` for the chapter or character — Mira fixes and re-runs her consistency check.
- A missing portrait *asset* → the asset pipeline (`game:spritecook-pipeline` or the artist), then `louie-content` to record it in the character doc.
- A flag the code reads that content never sets → `louie-update` / `louie-bugfix` on the owning feature.

## Variations

- **CI mode:** run the extraction in a gdUnit4 test that fails on F1, F4, F6 (hard breaks) and reports F3, F5, F7 as warnings.
- **Single file:** `louie-recipe game:content-integrity dialogue/ch03/intro.dialogue` — report only, no roadmap entry unless the user asks.
