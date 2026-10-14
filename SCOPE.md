# Grandma Drives (Turn Left at the Cow): scope

Working title. Jam: The WORST Game Jam, theme "Grandma's Instructions". Deadline: evening of Oct 26, 2026 Pacific. Stack: Odin `js_wasm32`, 2D canvas via a JS shim (see the vault's `Tech/Odin wasm recipe.md`).

## Pitch

You drive. Grandma navigates from the passenger seat with landmark-based directions that are out of date, contradictory, and delivered with total confidence. You see only a small window of the map. You are delivering yourself to "the place", and you arrive somewhere clearly wrong, to her delight.

## Core loop

1. Grandma gives a line of directions (one at a time, in a speech bubble).
2. The player steers one grid step per input: turn-based, tile map, top-down.
3. Grandma reacts to each move: approval, "no, the other left", or a new memory that changes the instruction.
4. Reach the destination tile ("the place") or run out of patience. Each level ends with a Grandma verdict.

## Scoring targets (design to the five categories)

| Category | Plan |
|---|---|
| Worst Controls | Steering input is applied one turn late. Brake and horn keys are swapped. Left/right flips on a schedule Grandma "announces" vaguely. |
| Ugliest Art | Deliberately garish 1-bit-with-clashing-palette tiles, mismatched sprite sizes, a Grandma portrait that is wrong in a different way each level. |
| Worst Sound | Synthesised beeps and one looping, off-key "radio" that cannot be muted (the mute key plays a louder sound). Keep volume sane. |
| Creative Badness | Directions reference things that no longer exist (the barn that burned down) and the map actually changes to match her new memory. |
| Theme | Every mechanic is driven by an instruction that is well-meant and unclear. |

## Content scope

- **3 levels** of increasing nonsense, each about 2 to 3 minutes.
- 1 tile map per level (about 24 by 16), hand-authored in code.
- About 40 to 60 instruction lines, each with a validity rule (a predicate on the player's position and facing).
- 1 ending screen with a total "Grandma's verdict".
- Out of scope: saving, settings, touch controls, multiple destinations per level, music.

## Technical plan

- Single `src/` Odin package; `build.sh` builds to `build/web/` (wasm plus `index.html` and `odin.js`).
- Software framebuffer drawn through a thin JS canvas shim; text via a small bitmap font from the vault (`Assets/`, credit on the game page).
- Game state is a plain struct stepped by input events. No ECS.
- Instruction engine: each instruction is a data record (text, condition, effect on the map or controls); levels are lists of these.
- Procedural audio through a tiny WebAudio shim (square-wave beeps).

## Milestones

| When | Goal |
|---|---|
| Day 1 | Wasm build runs; map renders; car moves on the grid. |
| Day 2 | Instruction engine with one level playable end to end. |
| Day 3 to 4 | Levels 2 and 3, control sabotage, map changes. |
| Day 5 | Bad art and sound pass, verdict screen. |
| Day 6 | Playtest, rating-friendly onboarding, itch page text. |
| Buffer | Ship by Oct 25 (a day ahead of the deadline). |

## Release checklist

- AI-disclosure line on the itch page (code written by Claude).
- Credit every premade asset: the DINOBYTE line under Decisions, plus any tiles.
- Content-rules check: nothing hateful or sexual, no fake viruses, no flashing lights (or add a warning).
- Publish only when the user says to, with `butler`, after a fresh build (see the vault's `Tech/Shipping to itch.io.md`).

## Decisions

- **Font: DINOBYTE** (mby, CC BY 4.0), 6 by 8 CP437 sheet, from the vault's `Assets/dbyte_1x.png` and `dbyte_2x.png`. Chosen over the ROM 8x8 font because of the latter's provenance. Use the sheets unmodified and tint at draw time. Credit line for the itch page and credits screen:
  > DINOBYTE bitmap font by mby, https://mby.itch.io/dinobyte, CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)
- **View: top-down** (confirmed by the user).
- Ship a licence note (from the vault's `Assets/dbyte-LICENSE.txt`) beside the font in the build.

## Open questions

- Tile palette (the font is decided: see Decisions).
- Whether the late-input control joke is frustrating enough to hurt completion rates; playtest in Day 6.
