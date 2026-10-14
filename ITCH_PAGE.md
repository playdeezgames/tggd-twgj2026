# Itch page text: Turn Left at the Cow

Page: https://thegrumpygamedev.itch.io/turn-left-at-the-cow
Jam: The WORST Game Jam (https://itch.io/jam/your-worst-ideas), theme "Grandma's Instructions".
The text below is pasted in by hand. Nothing here is published by the repo.

## Short description

Grandma is navigating. You are driving. She means well.

## Description

Grandma has directions, and she is very sure of them. Left at the barn. Or the cow. One of them.
The barn burned down in 1987, but she remembers it fondly, and she'd like you to turn there.

Three drives, each a little more helpful than the last:

1. **Sunday Drive.** A gentle start. She is mostly right.
2. **The Cow Moved.** Landmarks have wandered off, the steering is a beat late, and "second left,
   no, third" turns out to matter.
3. **Pratt's Field.** Everything is on at once, and every road leads somewhere she didn't mean.

Each drive ends with a verdict. You can do exactly what she says, or you can arrive somewhere
clearly wrong. She will be delighted either way.

## How to play

- **Arrow keys (or WASD):** up drives forward one tile, left and right turn the car.
- **Space:** brake. **H:** honk.
- **M:** mute the radio. (Try it.)
- **R:** restart the level. **Esc:** back to the menu. **Enter:** next level after a verdict.
- On the title screen, **1, 2, 3** jump straight to a level.
- Keep Grandma's patience up. It drains as you drive, and every wrong turn costs you.
- Her directions are well meant, so listen to the *intent*, not the words.

## Notes for raters

- The controls are bad on purpose: some turns are flipped, held back or swapped. That is the game.
- Each drive is about 2 to 3 minutes. The whole game is under 10.
- There is audio: crunchy effects, and a radio you cannot turn off. Mind the volume.
- No flashing lights, no violence, and nothing that touches your computer. It runs in the browser.

## Credits

- Game, code and design: TheGrumpyGameDev, with Claude (Anthropic).
- Tiles: Bountiful Bits and Bit Bonanza by VEXED, https://v3x3d.itch.io/bountiful-bits and
  https://v3x3d.itch.io/bit-bonanza (CC0).
- Font: DINOBYTE bitmap font by mby, https://mby.itch.io/dinobyte, CC BY 4.0
  (https://creativecommons.org/licenses/by/4.0/). Used unmodified, tinted at draw time.
- Sound effects: generated with jsfxr, https://sfxr.me, then made worse. The radio is
  synthesised live by the game.

## AI disclosure

- **Code:** written by Claude (Anthropic), directed and reviewed by the developer.
- **Design and writing:** Grandma's lines and the level designs were drafted with Claude and
  chosen by the developer.
- **Art:** no AI-generated art. All tiles are premade CC0 packs (credited above); the car is
  drawn in code.
- **Sound:** no AI-generated audio. Effects come from jsfxr; the radio is a hand-written
  synthesiser.

## Page settings (the developer's)

- Kind of project: HTML, "This file will be played in the browser" ticked on the `html` upload.
- Viewport: 960 by 768 works well (the game is a 240 by 192 canvas scaled 4x).
- Tags: bad, grandma, driving, pixel art, worst game jam, short, comedy.
- Upload: `butler push build/web thegrumpygamedev/turn-left-at-the-cow:html`, via `./shippit.sh
  --push`, only when the developer says to.
