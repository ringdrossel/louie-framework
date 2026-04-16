# Initial Prompt

Copy and paste this into your AI assistant to kick off a new project with LOUIE.

---

```
I want to start a new project using the LOUIE framework (Lean Orchestration for Unified Intelligent Engineering).

Please invoke the Analyst agent (`_LOUIE_/agents/analyst.md`) to interview me about my first feature/requirement. The Analyst should write its output to `_LOUIE-output/requirements/`.

After the Analyst produces requirements, invoke the Architect agent (`_LOUIE_/agents/architect.md`) to produce `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.

Then show me everything for confirmation before any code is written.

My initial idea:
[DESCRIBE YOUR IDEA HERE]
```

---

## Tips for a Good Initial Idea Description

You don't need to be super detailed — Tom (the Analyst) will interview you. But a good starting point includes:

- **What** the project does in 1-2 sentences
- **Who** it's for (even roughly: "for me", "for a small team", "public-facing")
- **Any hard constraints** you already know (must be mobile-friendly, needs to work offline, budget for hosting, etc.)

### Examples

**Minimal (Tom will ask lots of follow-ups):**
```
My initial idea:
A recipe manager for personal use.
```

**Moderate (Tom has more to work with):**
```
My initial idea:
A recipe manager where I can save recipes from URLs, organize them by tags,
and plan weekly meals. Just for me and my partner. Should work on phone and desktop.
```

**Detailed (Tom may use Light Mode):**
```
My initial idea:
A task management tool for a team of 5 developers. Need kanban boards, time tracking,
GitHub integration for linking PRs to tasks, and a simple reporting dashboard.
Self-hosted on our existing server. We're comfortable with Docker.
```
