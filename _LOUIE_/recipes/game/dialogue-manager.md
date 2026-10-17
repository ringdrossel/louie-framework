Dialogue Manager 4 integration for Godot: game-state object wired to flags.md, emotion tags mapped to portraits, translations.

**Requires profile:** game

# Dialogue Manager

## Overview

Integrates Nathan Hoad's **Dialogue Manager 4** into a Godot game so Mira can write dialogue as `.dialogue` files and the game can play them: a single game-state object that mirrors `_LOUIE-output/story/flags.md`, a dialogue balloon that maps line tags to character portrait expressions, and a translation setup that follows the in-game language decision in `story-bible.md`.

**Use it** in a Godot 4.6+ project that needs branching dialogue, support conversations, or cutscene scripts.

**Don't use it** on Godot 4.5 or older (Dialogue Manager 4 requires 4.6+; see Variations), or for a dialogue system built in-house.

**Prerequisites:** project profile `game`; `game:godot-project` (or an equivalent Godot setup) in place; `story/flags.md` exists.

## Verified Versions

Verified on 2026-10-17. Re-check before applying.

| Component | Version | Source |
|-----------|---------|--------|
| Dialogue Manager | 4 — "an addon for Godot 4.6+" (`plugin.cfg` on `main` reads `version="4.1.0"`) | README and `addons/dialogue_manager/plugin.cfg`: https://github.com/nathanhoad/godot_dialogue_manager |
| Older lines | v3.10 for Godot 4.4 / 4.5; v3.3 for 4.3 | README § Older versions |
| Asset Store listing | https://store.godotengine.org/asset/nathanhoad/dialogue-manager/ | check the listed version there before installing |

Godot 4.7.x satisfies the 4.6+ requirement.

## Requirements Seed

**Functional**

- Dialogue files live in a declared content path (`dialogue/`) and are played by the game through Dialogue Manager.
- Every story flag in `story/flags.md` exists as a typed property with its default on one game-state autoload; dialogue reads and writes flags only through it.
- Flags are saved and loaded with the game save.
- Each line's emotion tag selects the speaking character's portrait expression; an unknown tag falls back to the neutral portrait and is reported in debug builds.
- Dialogue text goes through Godot's translation system in the in-game languages listed in `story-bible.md`.
- Mira's content files can be checked automatically (see Test Guidance and `game:content-integrity`).

**Out of scope**

- Writing dialogue content (that's `louie-content` with Mira).
- Voice acting pipeline (see Variations).

## Architecture Notes

For Sophie to validate and record in `architecture.md`:

- **State model.** Dialogue Manager's runtime is stateless — "your game is the authority of any game state". Godot autoloads are available to dialogue directly; `DialogueStateContext` nodes expose scene-local objects; `extra_game_states` is described as "the most brittle" option. Source: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/State.md
- **Recommendation:** one autoload (e.g. `GameState`) owns every story flag as a typed property named exactly as in `flags.md`. This is the code mirror of the registry that `architecture.md` § Content Pipeline names. Dialogue files add `using GameState` at the top (or the project sets a global state shortcut in Dialogue Manager's settings) so flags read as plain names. Source: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Conditions_Mutations.md (§ State shortcuts)
- **Content Pipeline row:** `dialogue/**/*.dialogue` — owner Mira — format "Dialogue Manager 4 script" — validator: the dialogue tests in `test/` plus `game:content-integrity`.
- **Localization section:** source language and target languages from `story-bible.md`; CSV or PO translation files; whether static line IDs are used.
- **Save format:** flags are part of the save data and covered by the save version.

## Implementation Guidance

**Install:** via the Godot Asset Store or by downloading a copy from GitHub (README); move `addons/dialogue_manager/` into the project's `addons/` folder and enable the plugin under **Project > Project Settings > Plugins**. Source: README and https://docs.godotengine.org/en/4.7/tutorials/plugins/editor/installing_plugins.html

**Dialogue syntax Mira writes** (source: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Basic_Dialogue.md):

```
using GameState

~ start
Lyra: [#happy] You made it!
if ch03_village_saved
    Bram: [#neutral] The villagers won't forget this.
- Thank him
    $> sup_lyra_bram_points += 1
    Lyra: [#happy] Thank you, Bram.
- Say nothing => quiet
=> END

~ quiet
Bram: [#sad] ...right.
=> END
```

- Cues start with `~ name`; jumps are `=> cue`, `=> END` ends the conversation, `=>< cue` jumps and returns, `=> END!` force-ends.
- Speaker lines are `Name: text`; responses start with `- `.
- Tags: `[#happy, #surprised]` → the line's `tags` property is `["happy", "surprised"]`; valued tags `[#mood=happy]` are read with `line.get_tag_value("mood")`.
- Conditions: `if` / `elif` / `else`. Response conditions are self-closing in v4: `- Text [if some_condition /]`. Mutations: `$> some_flag = true`. Values inside lines: `{{some_value}}`. Source: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Conditions_Mutations.md and `docs/State.md`

**Playing dialogue** (source: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Using_Dialogue.md and `docs/API.md`):

- Simplest: `DialogueManager.show_dialogue_balloon(resource, cue)` shows the example balloon (configurable in Dialogue Manager's settings to use your own balloon scene).
- Custom balloon: `await DialogueManager.get_next_dialogue_line(resource, cue)` returns a `DialogueLine`; continue with `dialogue_line.next_id`; responses carry their own `next_id`. The `DialogueLabel` node types out a line and handles its bbcode, waits, speed changes, and inline mutations.

**Emotion tags → portraits:**

- The balloon reads the line's character and its emotion tag (one of the tags in `story-bible.md` § Dialogue Style Guide), looks up the portrait in a per-character resource (one entry per expression listed in `story/characters/<name>.md` § Portrait Expressions), and falls back to `neutral` with a debug warning when the expression is missing.
- Keep the mapping data-driven (a resource per character in `data/`), so adding an expression never needs code.

**Translations** (source: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Translations.md):

- Dialogue and response text runs through Godot's `tr` by default; CSV and PO files are supported (`DialogueManager.translation_source` overrides the auto-guess).
- Static line IDs: `Lyra: You made it! [ID:CH03_LYRA_ARRIVAL]` — useful for voice lines and stable translation keys.
- `.dialogue` files are added to **Project Settings > Localization > Template Generation** automatically; export a POT or CSV template from there.
- A `##` comment before a line becomes a translator note in POT/PO files.
- Policy: write dialogue in the source language from `story-bible.md`; translations are separate files. The `louie-language` Documents setting does not apply to dialogue.

**Upgrading from v3** (source: https://github.com/nathanhoad/godot_dialogue_manager/blob/main/docs/Upgrading_Version.md): Godot 4.6 is the minimum; "Titles" are now "Cues"; response conditions are self-closing; `DialogueLine.translation_key` is now `static_id`; the bespoke CSV exporter was removed in favour of Godot's template exporter. Commit first, delete the `.godot` cache folder, and restart the editor a couple of times.

## Test Guidance

- Unit-test the game-state autoload: every flag from `flags.md` exists with the registered type and default; saving and loading round-trips all flags; loading an older save fills new flags with their defaults.
- For each `.dialogue` file: it loads as a resource, and walking it from its entry cue with fixed responses reaches `END` without errors (use `get_next_dialogue_line` with a test game state).
- Portrait mapping: every tag used in dialogue resolves to a portrait for its speaker; an unknown tag falls back to neutral.
- Run `game:content-integrity` for the cross-file checks (flags registry, characters, unreachable cues).

## Variations

- **Godot 4.4 / 4.5:** use Dialogue Manager v3.10 (README § Older versions); "cues" are "titles" there and response conditions aren't self-closing.
- **Voice acting:** add static line IDs to every line and key voice files by ID (see the voices-and-translations example project linked in the README).
- **C#:** Dialogue Manager ships a C# wrapper (`docs/CSharp.md`).
