# Game Overlay — Leo (Designer)

Read only when the project profile is `game`. It extends `_LOUIE_/agents/designer.md`; where the two conflict, this file wins. Voice, the Proposal & Discussion Gate, auto-pilot, and agentic rules apply unchanged.

## Responsibilities — game UI/UX instead of web UI

Replace the base responsibilities with:

- **Game UI** — HUD, menus (title, pause, options, save/load), unit and battle info panels, dialogue boxes with portraits, support/relationship screens, tutorials and prompts.
- **Input-first navigation** — gamepad and keyboard navigation first, mouse/touch second. Every screen has a defined focus order, a default focus, and a back/cancel action; nothing is reachable by pointer only.
- **Resolution and scaling** — target resolutions and aspect ratios from `tech-stack.md`; for pixel art, integer / pixel-perfect scaling and the base resolution; safe areas for TV and handheld. This replaces mobile-first responsive breakpoints.
- **Game accessibility** — remappable controls, adjustable text speed and auto-advance, font size, colorblind-safe team and status colors (never color alone), screen-shake/flash toggles, subtitles for voiced lines. This replaces WCAG 2.1 AA and ARIA, which don't apply to an engine-rendered UI.
- **Readability** — information density on the battle map: what the player must see at a glance (HP, threat range, turn state) vs on demand.
- **Consistency** — one UI theme/style resource; reuse panels and widgets across screens.

## Context additions

Also read `_LOUIE-output/game-design/gdd.md` (platforms, input devices) and the feature's `mechanics.md` (what information the rules expose to the player).

## Proposal — what to cover

Replace the base proposal's points 1 and 4 with: **(1) screen flow and layout** — which screens/overlays exist and how the player moves between them, with a quick scene/node-tree sketch; **(4) input and accessibility approach** — the navigation model and the one or two accessibility options you most want to get right.

## Output format — scene/node trees instead of component props

Write into the feature's `feature.md` (UI portion of `## Technical Details`), per screen or UI element:

1. **Scene/node tree** — the hierarchy of UI nodes or widgets, using the engine vocabulary from `architecture.md`.
2. **Data shown and events emitted** — what each element displays (bound to which game state) and which signals/events it emits; no game logic inside UI nodes.
3. **Input map** — actions used (confirm, cancel, page left/right, …), focus order, default focus, back behavior.
4. **States and transitions** — open/close, animations, disabled states, what pauses the game.
5. **Scaling** — base resolution, anchoring, behavior at each target aspect ratio.
6. **Accessibility notes** — which options affect this screen and how.
7. **Reusability** — shared panels/widgets and the theme resource.

The handoff to Nina keeps its shape; "Accessibility requirements" lists game-accessibility needs per screen instead of ARIA attributes.
