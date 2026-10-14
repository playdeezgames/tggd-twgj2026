# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status

This repo is empty apart from `README.md`. It is the entry for the itch.io jam "Your Worst Ideas" (https://itch.io/jam/your-worst-ideas), remote `https://github.com/playdeezgames/tggd-twgj2026.git`. The project is in the **ideation phase**: there is no source, build, lint, or test tooling yet. Update this file once a stack and commands exist.

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
