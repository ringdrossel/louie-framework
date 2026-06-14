# louie-language

When the user says **`louie-language`**, view or change the project-wide language setting that controls which natural language LOUIE's agents converse in and which language generated documents are written in.

## What this controls

Two independent settings, stored together. Splitting them lets you talk to LOUIE in your own language while keeping the deliverables portable.

| Setting | Controls | Values |
|---------|----------|--------|
| **Conversation** | The language agents **talk to you in** — greetings, questions, playbacks, summaries, every chat message. | `auto` *(default)* — detect the language you write in and reply in kind; ask and remember your pick if it's ambiguous. Or a specific language, e.g. `German`. |
| **Documents** | The language **generated artifacts** are written in — `requirements.md`, `feature.md`, `architecture.md`, `tech-stack.md`, `runbook.md`, etc. | `English` *(default)* — keeps deliverables portable for mixed teams and reviewers. Or `follow` — write artifacts in the conversation language. Or a specific language. |

**Always English regardless of this setting:** code, identifiers, file names, `// WHY` comments, and commit messages. These follow the industry-standard convention in `_LOUIE_/guidelines/coding-guidelines.md` (§ Naming) and are never localized.

**How `auto` behaves.** When Conversation is `auto`, LOUIE detects the language from your messages and replies in it. On a clear signal (a full message in another language) it switches and **saves that language** to this setting so it stays consistent across agents. If the signal is ambiguous (a short or mixed message, or a one-off quote), LOUIE asks you which language to work in — as a structured choice — and saves your answer. Full behavior spec: `_LOUIE_/guidelines/interaction-guidelines.md` § Language.

The setting is **project-wide**, stored in `_LOUIE-output/runbook.md` under the `## Language` section.

## Procedure

1. **Read the current settings:**
   - Read `_LOUIE-output/runbook.md`.
   - Look for a `## Language` section. If present, parse `Conversation:` and `Documents:`.
   - If absent or unset, treat Conversation as `auto` and Documents as `English` (the defaults) and tell the user they haven't been set explicitly yet.

2. **Show the current state and ask what to change:**
   - Present the current state (and when it was set, if recorded), e.g. "Language — conversation: `auto`, documents: `English` (set 2026-06-13)."
   - **Present the change as a structured choice** — use your runtime's structured-choice tool if it has one, otherwise a lettered list (see `_LOUIE_/guidelines/interaction-guidelines.md`). First ask **which setting** to change: `Conversation` / `Documents` / both / keep current.
   - Then ask the value for the chosen setting(s):
     - **Conversation:** `auto` (detect, ask if unclear) / a specific language (free-form — let the user name it).
     - **Documents:** `English` / `follow` (match the conversation language) / a specific language.

3. **Update the runbook:**
   - Update the `## Language` section of `_LOUIE-output/runbook.md` in place: set each changed value, bump the `Set:` date to today.
   - If the section does not exist yet, create it (place it after `## Auto-Pilot`, before `## Debugging`).
   - Do not touch any other part of the runbook.
   - If the user picks "keep current," do nothing — print a one-line confirmation and exit.

4. **Confirm the change:**
   - Print a one-line confirmation, e.g. `Language set to: conversation German, documents English.`
   - Reply in the new conversation language from this point on.
   - If Documents was set to `follow` or a non-English language, add a one-line note that existing documents are **not** retranslated — only newly written or updated artifacts use the new language.

## Usage

```
louie-language
```

No arguments — this command is always interactive. You can also just start writing in another language and LOUIE will pick it up (and save it) on its own when Conversation is `auto`.

## Related

- `_LOUIE_/guidelines/interaction-guidelines.md` § Language — the canonical detect / switch / ask / persist behavior every agent follows
- `_LOUIE_/guidelines/coding-guidelines.md` § Naming — code and comments stay English
- `_LOUIE_/templates/runbook-template.md` — the `## Language` section
- `_LOUIE_/commands/louie-setup.md` — records the defaults at project setup
- `_LOUIE-internals/language.md` — design rationale (framework-dev only)
