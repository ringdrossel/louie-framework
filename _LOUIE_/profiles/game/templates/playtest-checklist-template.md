## Playtest Checklist

> **Usage:** Ava adds this section to the feature's `feature.md` in game-profile projects. It replaces automated end-to-end tests through the rendered game: scenarios a human plays through before the feature ships. Tick items as they pass; note failures with the build or commit they were seen on.

**Build / commit:** [short SHA] — **Tester:** [name] — **Date:** YYYY-MM-DD

### Input Devices

- [ ] Gamepad
- [ ] Keyboard
- [ ] Mouse / touch (if supported)

### Scenarios

| # | Scenario | Steps | Expected | Result |
|---|----------|-------|----------|--------|
| 1 | [happy path] | [...] | [...] | [ ] |
| 2 | [edge case from mechanics.md] | [...] | [...] | [ ] |
| 3 | [save mid-feature, quit, load] | [...] | [identical state] | [ ] |

### Feel & Readability

- [ ] [the player can tell what will happen before confirming]
- [ ] [feedback (animation, sound) for every action]
- [ ] [no UI element unreachable by gamepad]

### Accessibility

- [ ] [remapped controls work in this feature]
- [ ] [text speed / font size options apply]
- [ ] [information is not conveyed by color alone]

### Findings

- [issue — severity — build/commit seen on]
