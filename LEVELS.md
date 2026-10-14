# Levels

Draft content for the three levels, in the vocabulary of `ENGINE.md`. Maps are 24 by 16 and were checked for connectivity with a small script (start to goal over road tiles, and for level 3 before and after the field becomes road).

## Conventions

- Legend: `=` road, `.` grass, `T` tree, `B` barn, `~` ruin (a landmark that no longer exists), `C` cow, `H` house, `Y` yellow house or church, `O` old oak, `,` Pratt's field (becomes road in level 3), `W` pond, `S` start, `G` goal.
- Car cannot leave the road, cannot reverse, and has controls forward, left, right, brake, horn.
- Coordinates are `(x, y)` from the top left. Headings are shown as N, E, S, W.
- Patience drains 1 per 2 turns; a wrong move costs 3, a timeout costs 5. Numbers are a first pass for playtest.
- The scripted solution for each level is listed so it becomes the headless test.

---

## Level 1: Sunday Drive

Teaches: waiting for a line, obeying a vague turn, a landmark that has two possible names. No sabotage.

Patience 30. Start `(2,14)` facing N. Goal `(21,3)` ("the thing out front").

```
........................
........................
........T........H......
............=========GY.
............=...........
.....T......=...........
...........B=C.....T....
............=...........
.O..........=...........
..===========...........
..=.....................
..=.............T.......
..=....T................
..=.....................
..S.....................
........................
```

Landmarks: Old Oak `(1,8)`, Barn `(11,6)`, Cow `(13,6)`, Hendersons' `(17,2)`, Yellow house `(22,3)`.

Scripted solution: N 5 tiles, turn E at `(2,9)`, E 10 tiles, turn N at `(12,9)`, N 6 tiles, turn E at `(12,3)`, E 9 tiles to the goal. About 30 moves.

| # | Cue | She says | Intent | Expects | Timeout | Effects |
|---|---|---|---|---|---|---|
| 1 | `At_Start` | "Straight on, dear, until you see the old oak." | Drive N to the corner | `Reach(Corner_A)` | 12 | obey: next 2; timeout: `Patience(-5)`, "Are we there yet?" |
| 2 | `After(1, Obeyed)` | "Now the way the sun goes." | Turn E at the corner | `Turn_At(E, Corner_A)` | 8 | wrong: `Patience(-3)`, "The *other* way the sun goes." (only E is open, so this is just a joke) |
| 3 | `At_Region(Junction_B)` | "Left at the barn. Or the cow. One of them." | Turn N at `(12,9)` | `Turn_At(Left, Junction_B)` | 8 | obey: `Score(+1)` |
| 4 | `After(3, Obeyed)` | "Keep on till it smells like the Hendersons'." | Drive N, then E at `(12,3)` | `Turn_At(E, Corner_C)` | 12 | timeout: "You can smell it from here." |
| 5 | `Near(Yellow_House, 3)` | "It's the one with the thing out front, dear." | Reach the goal | `Reach(Goal)` | 10 | obey: "Well, this isn't the Hendersons'. Lovely, though." verdict delighted |

Notes: line 3 is the first piece of real ambiguity, but there is only one road to take, so it cannot fail. Line 5 plants the level's punchline: the Hendersons' (`H`) is visible and is not the goal.

---

## Level 2: The Cow Moved

Teaches: stale landmarks, a line that corrects itself, steering delay. Introduces `Input_Delay`.

Patience 30. Start `(21,14)` facing W. Goal `(7,14)` (the church door).

```
........................
........................
........................
...........T............
........................
..................T.....
....T...................
........................
..........C.............
.............~..........
......===============...
.......===....=.........
.......===....=H....T...
.......=......=.........
......YG......=======S..
........................
```

Landmarks: Hendersons' `(15,12)`, Barn ruin `(13,9)` (it burned down in 1987; `exists = false`), Cow `(10,8)` in the field, Church `(6,14)`.

Three side roads leave the westbound road at `x = 9, 8, 7`. All three reach the church: `x = 7` goes straight down, `x = 8` and `x = 9` join it at `(7,12)`. They differ in length and in how long the steering delay is still active.

Scripted solution: W 7 tiles, turn N at `(14,14)`, N 4 tiles, turn W at `(14,10)`, W 7 tiles, turn S at `(7,10)`, S 4 tiles to the goal. About 22 moves.

| # | Cue | She says | Intent | Expects | Timeout | Effects |
|---|---|---|---|---|---|---|
| 1 | `At_Start` | "Down to the end, then right at the Hendersons'." | Turn N at `(14,14)` | `Turn_At(Right, Corner_1)` | 10 | wrong: `Patience(-3)` |
| 2 | `After(1, Obeyed)` | "Left where the barn used to be." | Turn W at the fork `(14,10)`; the ruin tile `~` marks it | `Turn_At(Left, Fork)` | 8 | obey: `Control(Input_Delay, 14)`, "Let's get a move on!" |
| 3 | `At_Region(Row10_West)` | "Where's that cow got to? Follow the cow." | Cow walks onto the road and drives W ahead of the car | `Pass(Cow)` | 10 | on cue: `Move_Landmark(Cow, (10,10))`, then it walks W and turns S at `x = 7`; obey: `Score(+1)` |
| 4 | `After_Turns(6)` | "Second left. No, third. Oh, you've gone past it." | Any of the three lefts works | `Turn_At(Left, Left_2)` or `Turn_At(Left, Left_3)` | 12 | on cue: `Reverse_Expects(3)`; wrong: `Patience(-3)` |
| 5 | `At_Region(Church_Front)` | "Park by the place, dear. Mind the step." | Stop at the door | `Stop(2)` in `Church_Front` | 8 | obey: "Lovely. Now, which funeral is this?" verdict delighted |

Notes: with the delay active, the turn input has to be pressed one tile early, so the player has to learn the delay from the first of the three lefts. The cow is a literal guide, but nothing says to trust it.

---

## Level 3: Pratt's Field

Teaches nothing: everything is on. Uses `Flip_Left_Right`, `Swap_Brake_Horn`, `Input_Delay`, a map rewrite, and a free U-turn. The player drives the whole loop and learns the shortcut leads home.

Patience 40. Start `(3,13)` facing E. Goal is the start tile.

```
........................
...............T........
........................
.....H=============.....
........,.........=.....
........,.....~...=.....
........,.........=.....
..C.....,.........=.....
........,.=========.....
........,.=.............
........,.=..........W..
........,.=.T...........
........,.=.............
...S=========...........
........................
........................
```

Landmarks: Hendersons' `(5,3)` (at the dead end), Barn ruin `(14,5)`, Cow `(2,7)`, pond `(21,10)`. Pratt's field `,` is the column `x = 8, y = 4..12`. It becomes road when line 4 fires.

Scripted solution: E 7 tiles, turn N at `(10,13)`, N 5 tiles, turn E at `(10,8)`, E 8 tiles, turn N at `(18,8)`, N 5 tiles, turn W at `(18,3)`, W 10 tiles to `(8,3)`, turn S into the field, S 10 tiles, turn W at `(8,13)`, W 5 tiles to the start. About 50 moves.

| # | Cue | She says | Intent | Expects | Timeout | Effects |
|---|---|---|---|---|---|---|
| 1 | `At_Start` | "Right at the big tree, dear." | Turn N at `(10,13)` (a left turn for the car) | `Turn_At(Left, Corner_1)` | 14 | on cue: `Control(Flip_Left_Right, 60)`, so pressing the key she names produces the turn |
| 2 | `At_Region(Corner_2)` | "Straight on past the pond." | Turn E at `(10,8)`, then N at `(18,8)` | `Turn_At(N, Corner_3)` | 14 | wrong: `Patience(-3)`, "We don't go that way." |
| 3 | `At_Region(Corner_4)` | "Left, and mind the wires." | Turn W at `(18,3)` | `Turn_At(Left, Corner_4)` | 10 | obey: `Control(Swap_Brake_Horn, 18)`, `Retint(Palette_2)` |
| 4 | `At_Region(Mouth)` | "Oh! Pratt's field! I always go through Pratt's field." | Turn S at `(8,3)` | `Turn_At(Left, Mouth)` | 6 | on cue: `Set_Tiles(Field, Road)`, `Retint(Palette_3)`; wrong: car runs on to the Hendersons' dead end; "Oh, they've moved. Back we go." `Turn_Around`, `Patience(-6)`, re-offer line 4 |
| 5 | `After(4, Obeyed)` | "Straight down, straight down, you'll see the house." | Drive S to `(8,13)` and turn W | `Turn_At(Right, Corner_5)` | 12 | on cue: `Control(Input_Delay, 8)` |
| 6 | `Near(Start, 2)` | "Here we are, here we are! ... Oh. This is my house." | Reach the start | `Reach(Goal)` | 10 | obey: "Well. You drove beautifully. Do come in." verdict delighted |

Notes: the player drives the whole loop (the outer road returns to the start only via the new field road), which is the level's joke. The Hendersons' dead end is a recoverable wrong path with a patience cost, not a game over.

---

## Findings for the engine

- **Needs `Turn_Around`.** The Hendersons' dead end in level 3 needs a free U-turn effect; `ENGINE.md` does not list it yet. Add it.
- **A moving landmark needs a path.** The cow in level 2 walks along the road, so `Move_Landmark` is not enough; a landmark needs an optional scripted path (a list of tiles, one step per player move).
- **Wrong is mostly about cost.** In all three levels, a wrong turn costs patience rather than ending the run, which is what keeps the game completable for raters.

## Open questions

- Level 2's three lefts all work. That keeps it forgiving, but it may make the "second left, no, third" line feel like a non-event. A variation is to make the `x = 9` side road a dead end that needs a `Turn_Around`.
- Level 3's loop is about 50 moves. If playtest shows it is too long, shorten the outer road before cutting content.
- Two of three levels end at a place that is not what she named. Level 1 could end at the right house and save the "wrong place" for 2 and 3.
