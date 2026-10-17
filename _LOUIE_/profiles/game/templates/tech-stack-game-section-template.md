## Game Engine & Tooling

> **Usage:** in game-profile projects, Sophie uses this section in `_LOUIE-output/tech-stack.md` **instead of** the template's Backend and Frontend sections. Keep Key Libraries, Development Tools, and Version Requirements from the base template. Every version and command must come from the tool's official documentation at the time of writing — cite the source URL in the Rationale or Source column, never write versions from memory. For a specific engine or tool, the `game:` recipes (`louie-recipe list game`) are the reference.

- **Engine:** [name]
  - **Version:** [exact version]
  - **Rationale:** [why]
- **Language:** [scripting language(s)]
- **Rendering / art style constraints:** [e.g. 2D pixel art, base resolution, integer scaling]

### Addons / Plugins

| Addon | Version | Purpose | Source |
|-------|---------|---------|--------|
| [name] | [x.y.z] | [what it does] | [official URL] |

### Content Formats

| Content | Format | Path | Validator |
|---------|--------|------|-----------|
| [dialogue] | [format] | [content path, as in architecture.md § Content Pipeline] | [how it's checked] |
| [stat tables] | [...] | [...] | [...] |

### Asset Tools

| Tool | Purpose | Output path | Notes |
|------|---------|-------------|-------|
| [name] | [sprites / audio / tilesets] | [...] | [style references, import settings] |

### MCP Servers (dev-time tooling)

| Server | Purpose | Setup | Source |
|--------|---------|-------|--------|
| [name] | [what the assistant uses it for] | [config location, no secrets] | [official URL] |

### Export Targets

| Target | Export preset | Notes |
|--------|---------------|-------|
| [Windows / Linux / macOS / Web / console] | [...] | [...] |

### Testing

- **Test framework:** [name + version]
- **Headless test command:** [exact command — also in runbook § Common Commands]
- **Content validation command:** [exact command, if separate]
- **Balancing simulation command:** [exact command, if any]
