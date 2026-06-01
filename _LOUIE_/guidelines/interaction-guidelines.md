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
