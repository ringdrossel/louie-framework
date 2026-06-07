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

## Content first, choice second (approval gates)

A structured choice renders as a compact dialog — on most runtimes it takes over the screen and shows **only** the question and its options. Anything you "presented" some other way is invisible at decision time:

- **A file you just wrote is not a presentation.** File-write results render collapsed in the transcript; the user has *not* read `feature.md` because you wrote it.
- **Long prose streamed in the same response as the choice call can get pushed out of view** by the dialog. Don't rely on it for anything the user must read to decide.

So every approval gate (playback, proposal, document confirmation) follows this order:

1. **Present the content in chat as a normal message** — the playback summary, the design proposal, the document digest. Compact: 5–15 bullets or a short section, not a full document dump. Name the file where the full version lives ("full doc: `_LOUIE-output/implementations/<feature>/feature.md`"), but never *rely* on the user opening it.
2. **Then ask.** Keep the structured choice short and self-contained — one line naming *what* is being approved (e.g. "Approve the preview-panel feature doc (summary above)?"). The dialog must make sense even if the user saw nothing else.
3. **If the user asks to "see it again"** or has clearly decided blind: re-present the summary as plain message text **without any tool call in the same response**, let them read it, and only then re-ask.

Never chain *write file → ask approval* with no chat presentation in between.

## Authoring rules (regardless of rendering)

- **2–4 options.** More than four means the question is really several questions — split it.
- **Label + one short line** per option. No paragraphs.
- **Mark the recommended / default option** explicitly.
- **Always allow a free-form "other."** Never trap the user in the list.
- **Single-select by default.** Say so explicitly when multiple selections are allowed.
- Keep the **question itself to one line** above the options.

## Optional upgrade (tool-agnostic)

On runtimes without a built-in tool (Gemini CLI, Codex CLI, opencode, pi), users can install a portable structured-choice add-on to get a selectable UI instead of the lettered fallback:

- **`ask-user-questions` (AUQ) MCP server** — works with opencode, Cursor, and any MCP client.
- **pi `ask_user` extension** (e.g. `pi-ask-user`).

LOUIE **does not require** any of these — the lettered fallback works everywhere. They're a quality-of-life upgrade. Don't instruct the user to install anything mid-task; mention it only if they ask how to get selectable choices on their tool.
