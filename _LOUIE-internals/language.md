# Language

**Audience:** AI assistants working on the LOUIE framework. Design notes for the `language` feature — a per-project setting that controls which natural language LOUIE converses in and writes documents in.

## Problem

LOUIE is authored in English, but users aren't all English-first. A German user wants the agents to *talk* to them in German — without losing the portability of English deliverables, and without LOUIE silently translating code or commit messages. The request: when the user writes in another language, agents respond in it; if it's unclear, ask and **remember** the choice for the project, the same way auto-pilot mode is remembered.

## Prior art (BMAD)

BMAD-METHOD solved the same problem with **two independent config keys** in its module `config.yaml`:

- `communication_language` — the language agents chat/greet in.
- `document_output_language` — the language deliverables (PRD, architecture) are written in.

The split is the important idea: it lets you converse in German but still produce English documents, which is exactly what BMAD's own German feature request (#411) recommended — *"all of BMad's instructions and templates are in English … it makes sense for you to continue creating all of your deliverables in English."*

BMAD's **enforcement** is the cautionary tale: it repeats the `communication_language` rule inside every workflow step file's "MANDATORY EXECUTION RULES." That scatter caused issue #1457 — the help task didn't carry the rule and silently rendered English regardless of the setting. **Lesson taken:** keep the behavior in one canonical place every agent already reads, not copied into each agent/command.

## Design

Two keys, mirroring BMAD, stored together in the runbook:

| Key | Controls | Default |
|-----|----------|---------|
| **Conversation** | Every chat message to the user (greetings, questions, playbacks, summaries, structured-choice labels). | `auto` |
| **Documents** | Generated artifacts: `requirements.md`, `feature.md`, `architecture.md`, `tech-stack.md`, `runbook.md`, ADRs. | `English` |

**`auto` (Conversation default)** is the dynamic, auto-pilot-style behavior the user asked for: detect the language from the user's messages; on a clear signal switch *and persist* (write the language into runbook § Language, bump `Set:`); on an ambiguous signal raise a structured choice and persist the answer. Detect → confirm-if-unclear → remember.

**`English` (Documents default)** keeps deliverables portable even when the conversation is in another language — same reasoning as BMAD's recommendation, plus LOUIE's templates are English so English output is the path of least friction. `follow` ties documents to the conversation language; a named language forces one. Changing the key never retranslates existing files.

**Always English, never localized:** code, identifiers, file/folder names, `// WHY` comments, commit messages. Lives in `coding-guidelines.md` § Naming (the file all code agents read), with a one-line cross-reference to the language spec.

## Storage

Persisted in `_LOUIE-output/runbook.md` under a `## Language` section, placed right after `## Auto-Pilot`:

```markdown
## Language

**Conversation:** `auto` | <language>
**Documents:** English | follow | <language>
**Set:** YYYY-MM-DD
```

Same rationale as Review/Branch/Auto-Pilot modes for living in the runbook: per-project, tool-agnostic, already in the agents' context, conceptually an operational knob. Not `CLAUDE.md`/`AGENTS.md` (tool-specific), not a new preferences file.

## Canonical behavior location

The detect/switch/ask/persist spec lives **once** in `_LOUIE_/guidelines/interaction-guidelines.md` § Language — the file every agent and command already reads before interacting with the user. This is the deliberate fix for BMAD's scatter bug: there is exactly one description of the rule, and agents reference it rather than embedding their own. No per-agent edits (`analyst.md`, `coder.md`, …) were made — they inherit the behavior through the guideline. `coding-guidelines.md` § Naming carries only the "code stays English" corollary (a code rule, so it belongs there) with a back-reference.

No new Critical Rule was added. Language is a communication default, not a "never do X" guardrail; the LLM naturally mirrors the user's language, and the framework's job is to make it *consistent and persisted*, which the runbook setting + single guideline spec achieve. Adding it to the Critical Rules block of every generated `CLAUDE.md` would re-introduce exactly the scatter BMAD got bitten by.

## New command: `louie-language`

Shows the current Conversation/Documents values and lets the user change either. Updates the runbook in place. Idempotent. Not named `louie-language-mode` because it isn't a small enum of modes like review/branch/auto-pilot — Conversation accepts any language — so the shorter `louie-language` reads better while still sitting in the same "project setting" family.

## Files touched (implementation)

Framework internals:
- `_LOUIE-internals/language.md` (this file) — design
- `_LOUIE-internals/README.md` — index row
- `_LOUIE-internals/CHANGELOG.md` — Unreleased entry

Distributed framework files:
- `_LOUIE_/commands/louie-language.md` — **new command**
- `_LOUIE_/guidelines/interaction-guidelines.md` — new `## Language` section (canonical behavior)
- `_LOUIE_/guidelines/coding-guidelines.md` — § Naming: "English code, always" bullet
- `_LOUIE_/templates/runbook-template.md` — new `## Language` section
- `_LOUIE_/commands/louie-setup.md` — step 5f records the defaults (non-interactive; defaults are auto + English)
- `_LOUIE_/commands/louie-import.md` — step 10e records the same defaults at import
- `CLAUDE.md` (root), `README.md`, `_LOUIE_/workflow/ai-workflow.md`, `_LOUIE_/setup/project-setup.md` — command tables
- `QUICKSTART.md` — new step 7 ("Work in your language") in both the English and Deutsch walkthroughs (language is the most quickstart-relevant of the project settings, and the doc is already bilingual — unlike branch/auto-pilot mode, which stay out of QUICKSTART)
- the twelve `*-init.sh/.bat` scripts — command lists

## Out of scope

- Retranslating existing documents when Documents changes.
- Localizing code, comments, or commit messages.
- Per-command language overrides or a `--lang` flag (the setting is project-wide; `auto` already adapts per message).
- Setting language interactively at `louie-setup` (defaults are recorded silently, like branch/auto-pilot; `auto` adapts on first foreign-language message).
