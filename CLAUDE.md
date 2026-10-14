# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status

Entry for the itch.io jam "The WORST Game Jam" (https://itch.io/jam/your-worst-ideas), remote `https://github.com/playdeezgames/tggd-twgj2026.git`. Planning docs: `SCOPE.md` (game and decisions), `ENGINE.md` (instruction engine design), `LEVELS.md` (the three levels). The Odin/wasm game is feature-complete for the three levels (keys 1 to 3 switch; Enter advances after a win). Implemented from ENGINE.md: cues, expects (including `Avoid`), effects (including `Set_Tiles`, `Retint`, `Turn_Around`, landmark moves and walks), timeouts, control sabotage (`Input_Delay`, `Swap_Brake_Horn`, `Flip_Left_Right`, `Sticky_Turn`), a sound-event queue with a WebAudio shim (jsfxr samples in `assets/sfx/`, in `Sound` enum order) and an unstoppable off-key radio (M plays a louder sound instead of muting), and a verdict screen with four tiers (`verdict.odin`, per-level lines in `levels.odin`). Open work is polish: the Day 5 bad-art pass (tile picks, cow, car, Grandma portrait), playtesting, the itch page text and the credits/AI-disclosure lines. `Near` and `Pass` cue/expect kinds from ENGINE.md were not needed and are not implemented.

## Commands

```bash
./build.sh   # odin build to build/web (game.wasm, odin.js, index.html, assets/)
./serve.sh   # http://localhost:8000 serving build/web (wasm needs http)
./test.sh    # native tests of src/game, plus wasm type-checks of both packages
```

Odin is at `/home/yermom/ODIN/odin` (`ODIN=...` overrides). Run one test: `odin test src/game -collection:tggd=src -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_NAMES=game.level_1_scripted_solution_wins`.

## Architecture

- `src/game` (package `game`): pure rules, no platform imports, so it tests natively. Level data (map, regions, instructions) is in `levels.odin`; `engine.odin` holds the instruction types and evaluation; `landmarks.odin` holds landmarks and the sabotage flags; map characters `B ~ C O H Y` become landmarks, not tiles; `step(game, command)` in `game.odin` is one turn. Tests (`#+build !js`) include each level's scripted solution.
- `src/web` (package `main`, `#+build js`): input, frame loop, and drawing. It imports `game` through `-collection:tggd=src`.
- `web/index.html`: the canvas shim. Odin calls two imports, `fill_rect` and `blit(sheet, sx, sy, w, h, dx, dy, rgb)`. JS loads the PNG sheets in `assets/` and tints them at draw time (sheet order must match `Sheet` in `web.odin`). The art is 1-bit, so all colour is tint.
- Screen is 240 by 192 logical pixels: a 24 by 16 map of 10 px tiles plus a 4-row HUD in 6 by 8 DINOBYTE glyphs. CSS scales it with `image-rendering: pixelated`.
- The car is code-drawn; no top-down vehicle exists in the chosen tile sets.

## Jam rules ("The WORST Game Jam", theme "Grandma's Instructions")

- Goal is the **worst** game: worse ranks higher. Theme: well-meant but amazingly unclear directions; tricking the player is allowed.
- Scored on Worst Controls, Ugliest Art, Worst Sound, Creative Badness, and Theme (fit; higher is better). Final rank is the average. Every entrant rates others, so the game must be quick to understand and finish.
- Jam runs Oct 14 to Oct 26, 2026 (Pacific); the page also says cutoff 2026-10-27 06:59 UTC. Treat the evening of Oct 26 Pacific as the deadline. Voting to Nov 9.
- Web builds strongly recommended. Premade assets allowed with credit on the game page. AI content allowed if disclosed on the game page (art, code, sound).
- Must not harm the computer (no fake viruses, file deletion), flashing lights need a warning, "bad" must not be offensive, hateful, sexual or shocking.
- Chosen game: "Grandma Drives (Turn Left at the Cow)". Scope is in `SCOPE.md`.

## Knowledge vault

The user's Obsidian vault of prior game documentation ("SPLORR!! Knowledge Base") lives at `/home/yermom/git/bok-of-splorr/splorr` (added as an additional working directory). Start at `Home.md`. Consult it before choosing a stack or making design decisions:

- `Tech/Odin wasm recipe.md`: the user's standard browser-game stack (Odin `js_wasm32`, 2D canvas via a JS shim, not WebGL).
- `Tech/Shipping to itch.io.md`: butler/`shippit.sh` conventions.
- `Gotchas.md`: hard-won lessons (WebGL unavailable on the user's Chrome and the in-app browser; cap every retry loop; infinite loops freeze the tab).
- `Jams/` and `Games/`: how earlier jam entries were scoped and shipped; font and tileset notes are under `Tech/`, sheets under `Assets/`.

Vault conventions to carry over: the vault is read-mostly context here, so do not edit it unless asked. Never publish (`butler push`) unless the user explicitly says to, and build first because the script only uploads what is in the build folder.
