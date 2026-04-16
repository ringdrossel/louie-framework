# LOUIE

**Lean Orchestration for Unified Intelligent Engineering**

LOUIE is a lightweight framework for feature-based AI-assisted development. It gives your AI assistant a structured workflow with specialized agents, so you go from idea to tested code without skipping steps or losing context.

## Commands

All LOUIE commands start with `louie-`. Type any of these in your AI assistant:

| Command | What it does |
|---------|-------------|
| `louie-setup` | Initialize a new project (Tom interviews, Sophie architects) |
| `louie-feature` | Add a new feature (full chain: Tom → Sophie → Leo → Nina → Max → Ava) |
| `louie-extend` | Extend an existing feature |
| `louie-bugfix` | Diagnose and fix a bug |
| `louie-review` | Code review by Max |
| `louie-review-doc` | Review + fix + update docs in one flow |
| `louie-test` | Write or improve tests with Ava |
| `louie-doc` | Update documentation and generate a commit message |
| `louie-ideate` | Brainstorm ideas with Ivy |

Command definitions live in [`commands/`](commands/).

## Quick Start

1. Copy both `_LOUIE_/` and `_LOUIE-output/` into your project root
2. Type `louie-setup` in your AI assistant (optionally with your project idea)
3. Tom interviews you, Sophie sets up architecture, then you're off to the races

For detailed setup instructions, see [`setup/project-setup.md`](setup/project-setup.md).

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
- **`_LOUIE-output/`** — artifacts produced by agents (requirements, architecture, feature docs). This is the work. It grows with every feature.

Both sort to the top of file explorers thanks to the underscore prefix. Deleting `_LOUIE_/` removes the framework cleanly without touching your project artifacts.

## Key Files

| File | Purpose |
|------|---------|
| [`commands/`](commands/) | All `louie-*` command definitions |
| [`workflow/ai-workflow.md`](workflow/ai-workflow.md) | Full workflow with scenarios and prompts |
| [`workflow/agent-handoffs.md`](workflow/agent-handoffs.md) | How agents pass work to each other |
| [`guidelines/coding-guidelines.md`](guidelines/coding-guidelines.md) | Language-agnostic clean code rules |
| [`setup/project-setup.md`](setup/project-setup.md) | How to deploy LOUIE into a project |

## Design Principles

- **Lightweight** — lean enough to add value without overhead. No complex state machines or heavy orchestration.
- **Tech-stack agnostic** — agents read the tech stack from `_LOUIE-output/tech-stack.md`, never from hardcoded values. Works for any language, framework, or platform.
- **Two confirmation gates** — architecture must be approved before feature work; feature docs must be approved before coding. Catches mistakes early.
- **Agents hand off, not hand-wave** — every agent ends with a structured handoff summary for the next agent in the chain.

## What Changed from v1

LOUIE evolved from a v1 setup that had 4 agents (designer, muse, reviewer, tester) with hardcoded tech stacks and no upfront analysis phase. Key improvements:

| v1 | LOUIE |
|----|-------|
| No requirements phase | Tom (Analyst) interviews first |
| No architecture phase | Sophie (Architect) defines structure and stack |
| No implementation agent | Nina (Coder) follows the plan |
| Tech stack hardcoded in every agent | Single `tech-stack.md` referenced by all |
| No coding guidelines | Centralized `coding-guidelines.md` |
| One confirmation gate | Two gates (architecture + feature doc) |
| All artifacts mixed together | `_LOUIE_/` (tool) vs `_LOUIE-output/` (work) |

The original v1 files are preserved in the `v1/` directory for reference.
