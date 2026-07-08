# Interaction Guidelines

How LOUIE agents ask the user to **make a choice**. Every agent and command reads this before prompting the user for a decision. Companion to `coding-guidelines.md` (which governs code, not interaction).

## When to use a structured choice

Use a structured choice when the user must pick among **2–4 discrete, enumerable options** — e.g. review mode, branch mode, which feature to build first, pursue / save / drop an idea, an apply-loop action.

**Do not** force a structured choice onto a genuinely open question. Tom's requirements interview ("what should this do?", "who's the user?") stays conversational and free-form. A structured choice is for *forks*, not for *discovery*.

## How to present it (platform-adaptive)

Use the most structured mechanism your runtime supports, and always degrade gracefully. The *authoring* is identical across platforms — discrete labelled options with a recommended default; only the *rendering* differs.

1. **If your runtime has a structured-choice tool, use it** (the user gets selectable options):
   - **Claude Code** → the built-in `AskUserQuestion` tool.
   - **Cursor** → its built-in clarifying-questions / interactive dialog (2.1+).
   - **opencode / pi / any MCP client** → the `ask-user-questions` ("AUQ") MCP server or a pi `ask_user` extension, **if installed** (see Optional upgrade below).
2. **Otherwise** (Gemini CLI, Codex CLI, or any runtime with no such tool) → render a **lettered pick-list** in plain text:

   ```
   <one-line question>
   A) <option> — <one short line>   (recommended)
   B) <option> — <one short line>
   C) <option> — <one short line>
   Reply with a letter, or tell me something else.
   ```

Pick the structured tool if there's any doubt it exists — it falls back to text naturally; the reverse doesn't.

3. **No interlocutor at all (agentic mode)** — when the run was invoked with `--agentic`, an autonomous agent is driving and *nobody will answer any rendering* of a question. Don't ask in any form. Every would-be choice resolves by policy instead: take the recommended default and record it in the run report, or — for scope-defining forks and material deviations — **halt** with `status: needs-human` and the question written into the run report as the pending decision. The full contract is `_LOUIE_/workflow/agentic-mode.md`; the rest of this document describes the human modes.

## Content first, choice second (approval gates — two-turn gate)

A structured choice renders as a compact dialog — on most runtimes it takes over the screen and shows **only** the question and its options. Anything else in the same response is invisible at decision time:

- **A file you just wrote is not a presentation.** File-write results render collapsed in the transcript; the user has *not* read `feature.md` because you wrote it.
- **Text streamed in the same response as the choice call is hidden by the dialog** — even a short summary. This is not a length problem; it's a same-response problem. "Present, then ask" inside one response is presenting to nobody.

So every content-carrying approval gate (playback, proposal, document confirmation) is a **two-turn gate**:

1. **Turn one — present, then stop.** Send the content as a normal chat message: the playback summary, the design proposal, the document digest. Compact: 5–15 bullets or a short section, not a full document dump. Name the file where the full version lives ("full doc: `_LOUIE-output/implementations/<feature>/feature.md`"), but never *rely* on the user opening it. End the message with a one-line handoff — e.g. "Take a look — I'll ask for the go/no-go next." — and **end the turn. No structured-choice call in this response.**
2. **Turn two — read the reply before reaching for the dialog.** If the user's reply already decides ("looks good", "approved", "change X first"), **treat it as the gate answer and skip the structured choice entirely** — re-asking what they just answered is noise. Only if the reply doesn't decide (a bare "ok", a question, a tangent) do you raise the structured choice — **alone in its own response**, short and self-contained, one line naming *what* is being approved (e.g. "Approve the preview-panel feature doc (summary above)?").
3. **If the user asks to "see it again" or for a summary mid-gate**, that request supersedes the pending choice. Respond with the content as plain message text and **nothing else** — no structured-choice call in the same response — and only re-ask after they've replied.

This rule targets **structured-choice tool calls** (the dialog is what hides things). A conversational, free-form ask ("Does this match what you have in mind?") may share the response with the content — plain text hides nothing. The same goes for the lettered pick-list fallback: it *is* plain text, so content + lettered question in one message is fine.

Never chain *write file → ask approval* with no chat presentation in between, and never put a structured-choice call in the same response as the content it asks about.

## Authoring rules (regardless of rendering)

- **2–4 options.** More than four means the question is really several questions — split it.
- **Label + one short line** per option. No paragraphs.
- **Mark the recommended / default option** explicitly.
- **Always allow a free-form "other."** Never trap the user in the list.
- **Single-select by default.** Say so explicitly when multiple selections are allowed.
- Keep the **question itself to one line** above the options.

## Language

Which natural language LOUIE uses is a **project setting**, stored in `_LOUIE-output/runbook.md` § Language with two keys: **Conversation** (how agents talk to the user) and **Documents** (the language generated artifacts are written in). This section is the **single source of truth** for the behavior — every agent reads it rather than each carrying its own copy, so the rule can't drift out of sync. Read the runbook's `## Language` section at the start of any work; if there is none, the defaults are Conversation `auto` and Documents `English`.

**Conversation:**

- **A specific language is set** (e.g. `German`) → talk to the user in that language in *every* message: greetings, questions, playbacks, summaries, structured-choice labels and options.
- **`auto` (the default)** → reply in whatever language the user writes in. On a **clear signal** — a full message in another language — switch to it *and persist it*: write that language into runbook § Language as `Conversation:` and bump `Set:` to today, so the choice survives across agents and sessions. On an **ambiguous signal** — a short or mixed-language message, a one-off quoted term, or you're genuinely unsure — don't guess: raise a structured choice ("Which language should we work in?") offering the language you detected and English, then persist the answer the same way. This is the auto-pilot pattern applied to language: detect, confirm if unclear, remember.

**Documents:** the `Documents` key governs the language of generated artifacts (`requirements.md`, `feature.md`, `architecture.md`, `tech-stack.md`, `runbook.md`, ADRs, etc.). Default `English` — keep deliverables English even when the conversation is in another language (portable for mixed teams and reviewers, and LOUIE's own templates are English). `follow` means write artifacts in the conversation language; a specific language name forces that one. Changing this does **not** retranslate existing documents — only newly written or updated ones.

**Always English, never localized:** code, identifiers, file and folder names, `// WHY` comments, and commit messages. These follow `coding-guidelines.md` § Naming regardless of the Conversation or Documents setting.

The user changes any of this with `louie-language` (see `_LOUIE_/commands/louie-language.md`).

## Optional upgrade (tool-agnostic)

On runtimes without a built-in tool (Gemini CLI, Codex CLI, opencode, pi), users can install a portable structured-choice add-on to get a selectable UI instead of the lettered fallback:

- **`ask-user-questions` (AUQ) MCP server** — works with opencode, Cursor, and any MCP client.
- **pi `ask_user` extension** (e.g. `pi-ask-user`).

LOUIE **does not require** any of these — the lettered fallback works everywhere. They're a quality-of-life upgrade. Don't instruct the user to install anything mid-task; mention it only if they ask how to get selectable choices on their tool.
