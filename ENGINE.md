# Instruction engine design

Design for the heart of Grandma Drives. See `SCOPE.md` for the game. Sketches are Odin-flavoured but not final.

## Goals

- Directions are **data**, so a level is a list of records and no level needs bespoke code.
- Grandma's directions must be **unclear but solvable**: every level has a verified solution.
- Instructions can **change the world** (move landmarks, swap tiles, flip controls), which is the Creative Badness hook.
- The whole thing is a pure, deterministic step function, so a headless test can play a level from a script.

## Model

Grandma speaks one **instruction** at a time. An instruction says three things:

1. **When** to speak (cue).
2. **What she wants** (expectations, any of which counts as obeying).
3. **What happens** when the player obeys, disobeys, or dithers (effects).

Her wording is flavour text in front of a precise hidden meaning. The ambiguity lives in the gap between the words and the expectation, and in the map being out of date relative to her memory.

## State

```odin
Game :: struct {
    level:        ^Level,
    map:          [H][W]Tile,
    player:       Car,              // pos, facing
    landmarks:    [dynamic]Landmark, // named things that can move or vanish
    controls:     Controls,         // sabotage flags and the 1-turn input buffer
    patience:     int,              // Grandma's patience, the loss clock
    turn:         int,
    active:       Maybe(InstructionId),
    since_active: int,              // turns since the active instruction began
    done:         map[InstructionId]Outcome,
    verdict:      Verdict,          // running score for the ending
}

Landmark :: struct {
    id:      LandmarkId,   // .Barn, .Cow, .Hendersons, .Old_Oak ...
    pos:     [2]int,
    exists:  bool,         // false: Grandma still names it, the map shows a ruin
    stale:   bool,         // true: her name no longer matches what is here
    path:    []([2]int),   // optional scripted route, one step per player move
    path_i:  int,
}
```

Landmarks are the key trick. Grandma's text refers to `.Barn`; where the barn is, or whether it still exists, is state that effects change. "Turn left at the barn that burned down" is solvable because the ruin tile is still on the map.

## Instruction record

```odin
Instruction :: struct {
    id:       InstructionId,
    text:     string,            // what Grandma says
    cue:      Cue,
    expects:  []Expect,          // any one satisfied counts as obeying
    timeout:  int,               // turns before she gives up waiting; 0 = never
    on_obey:  []Effect,
    on_wrong: []Effect,          // an expect-violating move
    on_timeout: []Effect,
    next:     Next,              // which instruction follows, per outcome
}
```

### Cues (when she speaks)

| Cue | Meaning |
|---|---|
| `At_Start` | First line of a level |
| `After(id, outcome)` | After an earlier instruction resolves, with that outcome |
| `At_Region(region)` | The first time the player enters a region |
| `Near(landmark, dist)` | Within a distance of a landmark |
| `After_Turns(n)` | A delay since the previous line |
| `Patience_Below(n)` | Nagging when patience is low |

### Expectations (what counts as obeying)

| Expect | Meaning |
|---|---|
| `Reach(region)` | Be on any tile in a region |
| `Turn_At(dir, region)` | Change heading to `dir` while inside a region |
| `Pass(landmark)` | Move adjacent to a landmark, then away |
| `Avoid(region)` | Do not enter a region before the timeout |
| `Stop(turns)` | Remain on a tile for N turns (the brake) |
| `Honk` | Press the horn while in a region |
| `Face(dir)` | Face a heading on a tile |

`dir` may be **relative** (`Left`, `Right`, `Back`) or **absolute** (`North`, ...). Relative directions are evaluated against the car's facing when the instruction became active, which is the standard source of "no, *my* left".

### Effects (what changes)

| Effect | Meaning |
|---|---|
| `Say(text)` | An extra remark, no state change |
| `Patience(+/-n)` | Adjust the patience clock |
| `Move_Landmark(id, pos)` | Grandma "remembers" it was elsewhere; the map follows |
| `Walk_Landmark(id, path)` | Start a landmark walking a scripted path, one tile per player move (the cow that leads the way) |
| `Turn_Around` | Free U-turn for the car, used to recover from a dead end (the car cannot otherwise reverse) |
| `Remove_Landmark(id)` | It is gone; the ruin tile appears |
| `Set_Tiles(region, tile)` | Rewrite the map, for example a road becomes a field |
| `Swap_Tiles(region_a, region_b)` | Exchange two areas |
| `Control(flag, turns)` | Apply a sabotage for a number of turns |
| `Retint(palette)` | Change the clashing palette |
| `Reverse_Expects(id)` | "No, the other left": flip the expectation of a pending instruction |
| `Goto(id)` | Force the next instruction |
| `Score(+/-n)` | Contribute to the end verdict |

### Control sabotage flags

| Flag | Behaviour |
|---|---|
| `Input_Delay` | Steering is applied one turn late (a one-slot buffer) |
| `Swap_Brake_Horn` | The brake and horn keys exchange roles |
| `Flip_Left_Right` | Left and right turn commands are swapped |
| `Sticky_Turn` | A turn input repeats once |
| `Fake_Mute` | The mute key plays a loud sound |

Flags are timed (`turns`) so a level can say "from here until the second junction". Flags stack.

## Turn loop

One call, `step(game, input) -> Events`, in a fixed order:

1. Translate the raw key into a command through the control sabotage (delay buffer, swaps, flips).
2. Apply the command: turn the car, or move one tile if the destination is passable.
3. Tick landmarks (advancing any walking landmark one step along its path) and timed control flags.
4. Evaluate the **active** instruction's expects against the new state:
   - obeyed → run `on_obey`, mark outcome, pick `next`
   - violated (a `Turn_At` in the wrong direction, entering an `Avoid` region) → run `on_wrong`
   - timed out → run `on_timeout`
5. Look for the next cue that fires and activate it, emitting its text.
6. Tick patience (a small constant drain plus effects).
7. Check end conditions: reached the destination, patience at zero, or the level script's own end.

All randomness is seeded from the level, so the sim is deterministic.

## Outcomes and the verdict

Each instruction resolves to `Obeyed`, `Wrong`, or `Timed_Out`. The verdict combines patience left, outcomes, and `Score` effects into a pick from a list of Grandma's closing lines. The player's best result is a tie between *did what she said* and *ended up somewhere clearly wrong but she is delighted*; the verdict table should reward both so the game stays funny whichever way someone plays.

## Making unclear things solvable

- **Every instruction has a stated intent** that is printed in the level data as a comment, so the author can check that the words plausibly lead there.
- **Corrections arrive.** If the player is wrong, a follow-up cue (`After(id, Wrong)`) clarifies in a different, equally unhelpful way. No instruction chain is a dead end: every `on_wrong` leads to a recoverable state or an explicit failure line.
- **Redundancy.** Important turns have a landmark cue *and* a distance cue, so a player who ignores one still gets there.
- **Landmark visibility.** The ruin or the replacement tile is always visible when the player gets near, so a stale name can be reasoned about.
- **Dead ends recover.** The car cannot reverse, so any dead end a wrong turn can reach must fire `Turn_Around` (with a patience cost) through its `on_wrong`.
- **Timeouts are generous** in level 1 and tighten in level 3.

## Level data

```odin
Level :: struct {
    name:         string,
    map:          [H][W]Tile,
    start, goal:  [2]int,
    landmarks:    []Landmark,
    regions:      map[RegionId]Rect,
    instructions: []Instruction,
    patience:     int,
    palette:      Palette,
}
```

Levels are Odin compile-time constants. Regions are named rectangles, so an instruction can say `Reach(.Hendersons_Yard)` and the map can be redrawn without touching text.

## Testing

- **Scripted solution per level:** a test feeds a recorded input list into `step` and asserts it reaches the goal with patience above zero. If a map edit breaks the route, the test fails.
- **No-input test:** doing nothing must end in a timeout loss, never a hang.
- **Fuzz:** random inputs for a fixed number of turns must terminate without panics and with patience monotonic under the constant drain.
- Run with `odin test src` (headless; no canvas).

## Not in the engine

- Rendering, audio and the canvas shim (separate package files).
- Free-text parsing. Grandma's lines are strings; matching is entirely by the authored expectations.
- Branching story state beyond `Goto`. If a level needs more, split it into two levels.

## Decisions

- **One active instruction at a time.** A second slot is only worth building if level 3 playtests flat.
- **`Reverse_Expects` affects pending instructions only,** never an already-obeyed one, so outcomes and the verdict stay deterministic. It is not used by any level yet.
- **`Input_Delay` holds back steering only** (left and right); the horn and brake respond immediately. The held turn lands after the next command.

## Open questions

None at the moment.
