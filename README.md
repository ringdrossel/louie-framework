# LOUIE

**Lean Orchestration for Unified Intelligent Engineering**

LOUIE is a lightweight framework for feature-based AI-assisted development. It gives your AI assistant a structured workflow with specialized agents, so you go from idea to tested code without skipping steps or losing context.

> 🚀 **New here?** Read the [Quick Start](QUICKSTART.md) (🇬🇧 English / 🇩🇪 Deutsch) for a one-minute tour.

## Commands

All LOUIE commands start with `louie-`. Type any of these in your AI assistant:

| Command | What it does |
|---------|-------------|
| `louie-setup` | Initialize a new project (Tom interviews, Sophie architects) |
| `louie-import` | Import an existing project — Sophie infers architecture/tech-stack/runbook from code; Tom fills gaps. Auto-detects v1 docs (`docs/implementations/`) when present |
| `louie-migrate` | Migrate an old-layout LOUIE project to the per-feature folder layout (one-way; uses `git mv`) |
| `louie-feature` | Add a new feature (full chain: Tom → Sophie → Leo → Nina → Max → Ava) |
| `louie-extend` | Extend an existing feature |
| `louie-update` | Quick change (< 50 lines, auto-escalates to `louie-extend`) |
| `louie-bugfix` | Diagnose and fix a bug |
| `louie-continue` | Resume in-progress work after a break (reconstruct from artifacts + git) |
| `louie-review` | Code review by Max |
| `louie-review-doc` | Review + fix + update docs in one flow |
| `louie-evaluate` | Assess a whole codebase against LOUIE standards; persistent findings + optional step-by-step apply loop |
| `louie-review-mode` | View or change the project review mode (manual / auto-fix-critical / auto-fix-all) |
| `louie-branch-mode` | View or change the project branch mode (current / ask) |
| `louie-autopilot-mode` | View or change the per-command auto-pilot mode (run the chain unattended after you approve the plan, stopping before merge) |
| `louie-language` | View or change the project language (conversation language + document language) |
| `louie-test` | Write or improve tests with Ava |
| `louie-doc` | Update documentation and generate a commit message |
| `louie-ideate` | Brainstorm ideas with Ivy |
| `louie-roadmap` | Capture bigger changes (epics) in `_LOUIE-output/roadmap.md`; promote one to a full feature when ready |
| `louie-roadmap-change` | Change a roadmap entry (status / notes / effort; defer / drop) |
| `louie-recipe` | Browse or load a reusable recipe (settings, auth, Docker, etc.) |
| `louie-update-framework` | Update LOUIE to the latest version |
| `louie-from-source` | Fetch a task from a source adapter (e.g. a task tracker) and route it to the right command |

Command definitions live in [`_LOUIE_/commands/`](_LOUIE_/commands/).

## Install

### 1. Copy the framework into your project root

Copy both `_LOUIE_/` and `_LOUIE-output/` into your project.

### 2. Run the init script for your AI tool

#### Claude Code

```bash
# macOS / Linux
bash _LOUIE_/setup/claude-init.sh

# Windows
_LOUIE_\setup\claude-init.bat
```

Creates `CLAUDE.md` and installs all commands as native slash commands (`/louie-setup`, `/louie-feature`, etc.).

#### Cursor

```bash
# macOS / Linux
bash _LOUIE_/setup/cursor-init.sh

# Windows
_LOUIE_\setup\cursor-init.bat
```

Creates/updates `.cursorrules` with LOUIE command routing.

#### Codex (OpenAI)

```bash
# macOS / Linux
bash _LOUIE_/setup/codex-init.sh

# Windows
_LOUIE_\setup\codex-init.bat
```

Creates/updates `AGENTS.md` with LOUIE command routing.

#### Gemini CLI

```bash
# macOS / Linux
bash _LOUIE_/setup/gemini-init.sh

# Windows
_LOUIE_\setup\gemini-init.bat
```

Creates/updates `GEMINI.md` with LOUIE command routing.

#### opencode

```bash
# macOS / Linux
bash _LOUIE_/setup/opencode-init.sh

# Windows
_LOUIE_\setup\opencode-init.bat
```

Creates/updates `AGENTS.md` with LOUIE command routing (opencode's native convention).

#### Pi Coding Agent (pi.dev)

```bash
# macOS / Linux
bash _LOUIE_/setup/pi-init.sh

# Windows
_LOUIE_\setup\pi-init.bat
```

Creates/updates `AGENTS.md` with LOUIE command routing (pi's native convention).

#### Other AI Tools / Local AI

If your tool has a project-level instructions file, add this to it:

```
This project uses the LOUIE framework for AI-assisted development.
When the user types a louie-* command, read the matching file from
_LOUIE_/commands/ and follow the instructions. Read README.md
for the full framework overview.
```

If your tool has no config file, tell it once per session:

```
Read the project README.md to understand the LOUIE framework.
```

### 3. Start building

Type `louie-setup` (or `/louie-setup` in Claude Code) to kick off your first project.

For detailed setup instructions, see [`_LOUIE_/setup/project-setup.md`](_LOUIE_/setup/project-setup.md).

## The Team

LOUIE uses 7 specialized agents, each with a clear role:

```
Tom (Analyst) → Sophie (Architect) → Leo (Designer) → Nina (Coder) → Max (Reviewer) → Ava (Tester)

Ivy (Muse) — independent ideation, feeds ideas back to Tom
```

| Agent | What they do |
|-------|-------------|
| **Tom** the Analyst | Interviews you to turn vague ideas into structured requirements |
| **Sophie** the Architect | Defines system architecture and tech stack |
| **Leo** the Designer | Designs UI components and user experience |
| **Nina** the Coder | Implements features following the architecture and guidelines |
| **Max** the Reviewer | Reviews code for quality, security, and guideline compliance |
| **Ava** the Tester | Writes tests and gives a ship/no-ship recommendation |
| **Ivy** the Muse | Brainstorms feature ideas and improvements |

## The Two Directories

- **`_LOUIE_/`** — the framework itself (agents, templates, guidelines, workflow). This is the tool. It rarely changes after setup.
- **`_LOUIE-output/`** — artifacts produced by agents. This is the work. It grows with every feature.

Both sort to the top of file explorers thanks to the underscore prefix. Deleting `_LOUIE_/` removes the framework cleanly without touching your project artifacts.

### `_LOUIE-output/` Layout

```
_LOUIE-output/
├── architecture.md                       (Sophie's design output)
├── tech-stack.md                         (Sophie's build-time stack)
├── runbook.md                            (Sophie creates; Nina appends)
├── roadmap.md                            (bigger changes / epics list; created at setup)
├── implementations/
│   ├── overview.md                       (slim index of all features)
│   └── <feature>/                        (one folder per feature)
│       ├── feature.md                    (the implementation doc)
│       ├── requirements.md               (Tom's requirements for this feature)
│       ├── decisions.md                  (feature-scoped ADRs; created when needed)
│       └── bugfixes/
│           └── <YYYY-MM-DD>-<slug>.md    (one file per per-feature bug fix)
└── bugfixes/
    ├── overview.md                       (cross-project bug-fix index)
    └── <YYYY-MM-DD>-<slug>.md            (cross-cutting bug fixes touching multiple features)
```

This layout scales — projects with hundreds of features and thousands of bug fixes stay navigable. Each feature is self-contained in its folder; agents lazy-load only what they need.

## Key Files

| File | Purpose |
|------|---------|
| [`_LOUIE_/commands/`](_LOUIE_/commands/) | All `louie-*` command definitions |
| [`_LOUIE_/workflow/ai-workflow.md`](_LOUIE_/workflow/ai-workflow.md) | Full workflow with scenarios and prompts |
| [`_LOUIE_/workflow/agent-handoffs.md`](_LOUIE_/workflow/agent-handoffs.md) | How agents pass work to each other |
| [`_LOUIE_/guidelines/coding-guidelines.md`](_LOUIE_/guidelines/coding-guidelines.md) | Language-agnostic clean code rules |
| [`_LOUIE_/guidelines/interaction-guidelines.md`](_LOUIE_/guidelines/interaction-guidelines.md) | How agents ask the user to choose (structured choice, lettered fallback) |
| [`_LOUIE_/setup/project-setup.md`](_LOUIE_/setup/project-setup.md) | How to deploy LOUIE into a project |

## Design Principles

- **Lightweight** — lean enough to add value without overhead. No complex state machines or heavy orchestration.
- **Tech-stack agnostic** — agents read the tech stack from `_LOUIE-output/tech-stack.md`, never from hardcoded values. Works for any language, framework, or platform.
- **Two confirmation gates** — architecture must be approved before feature work; feature docs must be approved before coding. Catches mistakes early.
- **Agents hand off, not hand-wave** — every agent ends with a structured handoff summary for the next agent in the chain.

