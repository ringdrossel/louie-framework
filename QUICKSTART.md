# Quick Start

A 1-minute tour of LOUIE. For the full reference, see [`README.md`](README.md). For project-setup details, see [`_LOUIE_/setup/project-setup.md`](_LOUIE_/setup/project-setup.md).

> 🇬🇧 [English](#english) · 🇩🇪 [Deutsch](#deutsch)

---

## English

### 1. Install the framework

Run the init script for your AI tool — this wires LOUIE into your project's config file.

```bash
# Claude Code (macOS / Linux)
bash _LOUIE_/setup/claude-init.sh

# Claude Code (Windows)
_LOUIE_\setup\claude-init.bat
```

> Other tools: `cursor-init`, `codex-init`, `gemini-init`, `opencode-init`, `pi-init`. Same `.sh` / `.bat` pattern. See [`README.md`](README.md#install) for the full list.

### 2. Start your project

Open your AI tool and run one of these:

| You have... | Run | What happens |
|---|---|---|
| **No project yet** | `louie-setup` | Tom (Analyst) interviews you; Sophie (Architect) drafts architecture, tech stack, and runbook. |
| **Existing code** | `louie-import` | Sophie cold-reads your codebase and builds the specs from it; Tom fills in the gaps. |

> In Claude Code, prefix with `/` — e.g. `/louie-setup`. Other tools use `louie-setup` without the slash.

### 3. Capture ideas (optional)

Not ready to build yet? Capture the idea first.

| Use | When |
|---|---|
| `louie-ideate` | Brainstorm with Ivy — free-form, no commitment. |
| `louie-roadmap` | Save a captured idea to `_LOUIE-output/roadmap.md`; promote it to a feature later with `louie-feature --from-roadmap <id>`. |

### 4. Build features

| You want to... | Run |
|---|---|
| Add a new feature | `louie-feature` |
| Make a comprehensive change to an existing feature | `louie-extend` |
| Make a quick change (< 50 lines) | `louie-update` |

### 5. Fix bugs

```
louie-bugfix
```

Nina diagnoses, fixes, writes a per-fix doc, and updates the runbook so future-you (and future-Nina) don't trip on the same thing again.

### 6. Review your code

```
louie-review
```

Max (Reviewer) produces findings in three tiers: **Critical / Should Fix / Suggestions**.

By default, Max presents the findings and asks before changing anything (`manual` mode). On trusted projects you can switch modes so Max auto-hands fixes to Nina in a loop:

```
louie-review-mode
```

Three modes available:
- `manual` — Max asks before fixing (safe default)
- `auto-fix-critical` — auto-applies Critical + Should Fix in a loop; surfaces Suggestions at the end
- `auto-fix-all` — auto-applies everything

Per-call override: `louie-review auto`, `louie-review manual`, `louie-review auto-fix-all`.

### That's it

You now know enough to use LOUIE end-to-end. The framework will guide you through the rest — confirmation gates catch mistakes early, agents hand off cleanly, and every artifact lives in `_LOUIE-output/`.

---

## Deutsch

### 1. Framework installieren

Führe das Init-Skript für dein KI-Tool aus — das verdrahtet LOUIE mit der Projekt-Konfigurationsdatei.

```bash
# Claude Code (macOS / Linux)
bash _LOUIE_/setup/claude-init.sh

# Claude Code (Windows)
_LOUIE_\setup\claude-init.bat
```

> Andere Tools: `cursor-init`, `codex-init`, `gemini-init`, `opencode-init`, `pi-init`. Gleiches `.sh` / `.bat`-Muster. Die vollständige Liste steht in [`README.md`](README.md#install).

### 2. Projekt starten

Öffne dein KI-Tool und führe einen der folgenden Befehle aus:

| Du hast... | Befehl | Was passiert |
|---|---|---|
| **Noch kein Projekt** | `louie-setup` | Tom (Analyst) interviewt dich; Sophie (Architektin) entwirft Architektur, Tech-Stack und Runbook. |
| **Bestehenden Code** | `louie-import` | Sophie liest deinen Code ein und erstellt die Spezifikationen daraus; Tom füllt offene Stellen per Interview. |

> In Claude Code wird ein `/` vorangestellt — z. B. `/louie-setup`. Andere Tools verwenden `louie-setup` ohne Slash.

### 3. Ideen festhalten (optional)

Noch nicht bereit zu bauen? Halte die Idee erst einmal fest.

| Befehl | Wann |
|---|---|
| `louie-ideate` | Brainstorming mit Ivy — frei, ohne Verpflichtung. |
| `louie-roadmap` | Eine Idee in `_LOUIE-output/roadmap.md` speichern; später per `louie-feature --from-roadmap <id>` zu einem Feature befördern. |

### 4. Features bauen

| Du möchtest... | Befehl |
|---|---|
| Ein neues Feature hinzufügen | `louie-feature` |
| Ein bestehendes Feature umfassend ändern | `louie-extend` |
| Eine schnelle, kleine Änderung (< 50 Zeilen) | `louie-update` |

### 5. Bugs beheben

```
louie-bugfix
```

Nina diagnostiziert, behebt den Fehler, schreibt ein Bugfix-Dokument und aktualisiert das Runbook, damit du (und das nächste Nina-Future) nicht ein zweites Mal über dieselbe Stolperfalle läufst.

### 6. Code-Review

```
louie-review
```

Max (Reviewer) erstellt Befunde in drei Stufen: **Critical / Should Fix / Suggestions**.

Standardmäßig zeigt Max die Befunde und fragt vor jeder Änderung nach (`manual`-Modus). Bei Projekten, denen du vertraust, kannst du den Modus umstellen, damit Max die Korrekturen automatisch in einer Schleife an Nina übergibt:

```
louie-review-mode
```

Drei Modi:
- `manual` — Max fragt vor jeder Korrektur nach (sicherer Standard)
- `auto-fix-critical` — wendet Critical + Should Fix automatisch in einer Schleife an; Suggestions tauchen am Ende zur Bestätigung auf
- `auto-fix-all` — wendet alles automatisch an

Override pro Aufruf: `louie-review auto`, `louie-review manual`, `louie-review auto-fix-all`.

### Das war's

Damit kannst du LOUIE vom Anfang bis zum Ende benutzen. Das Framework führt dich durch den Rest — Bestätigungs-Gates fangen Fehler früh ab, Agenten übergeben sauber aneinander, und alle Artefakte liegen in `_LOUIE-output/`.
