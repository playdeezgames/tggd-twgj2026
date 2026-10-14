// Browser platform layer: owns the canvas shim, input and the frame loop.
// JS loads the tile sheets and tints them at draw time; Odin only says what to draw.
#+build js
package main

import "base:runtime"
import "core:fmt"
import "core:math/rand"
import "core:sys/wasm/js"
import "core:time"
import game "tggd:game"

foreign import canvas "canvas"

@(default_calling_convention = "contextless")
foreign canvas {
	// Fill a rectangle in logical pixels with 0xRRGGBB.
	fill_rect :: proc(x, y, w, h: i32, rgb: u32) ---
	// Copy a w by h piece of a sheet at (sx, sy) to (dx, dy), scaled to dw by dh, tinted 0xRRGGBB.
	blit :: proc(sheet: i32, sx, sy, w, h: i32, dx, dy, dw, dh: i32, rgb: u32) ---
	// Plays sound effect `id` (order of game.Sound), at most `max_ms` long.
	audio_sfx :: proc(id: i32, gain: f32, max_ms: i32) ---
	// Starts the looping, slightly off-key radio. Safe to call repeatedly; it cannot be stopped.
	audio_radio :: proc(loud: bool) ---
}

Sheet :: enum i32 {
	Natural,
	Civilized,
	People,
	Creatures,
	Font,
}

TILE :: 10
HUD_ROWS :: 4
SCREEN_W :: game.W * TILE
SCREEN_H :: game.H * TILE + HUD_ROWS * 8

// Deliberately clashing palettes; the art stays 1-bit and is tinted here. Effects switch
// palette (`Retint`) as Grandma remembers things.
Ink :: enum {
	Paper,
	Grass,
	Road,
	Tree,
	House,
	Barn,
	Car,
	Text,
}

PALETTES := [?][Ink]u32 {
	{.Paper = 0x2b0a6e, .Grass = 0x00c040, .Road = 0xffd800, .Tree = 0xff00a0, .House = 0x00e0ff, .Barn = 0xff7000, .Car = 0xffffff, .Text = 0xffff60},
	{.Paper = 0x2b0a6e, .Grass = 0x00c040, .Road = 0xffd800, .Tree = 0xff00a0, .House = 0x00e0ff, .Barn = 0xff7000, .Car = 0xffffff, .Text = 0xffff60},
	{.Paper = 0x6e0a1e, .Grass = 0xff6000, .Road = 0x00ffd0, .Tree = 0xffff00, .House = 0xff40ff, .Barn = 0x40ff40, .Car = 0xffffff, .Text = 0xa0ffa0},
	{.Paper = 0x0a4a0a, .Grass = 0xff40c0, .Road = 0xffffff, .Tree = 0x4040ff, .House = 0xffa000, .Barn = 0x00ffff, .Car = 0x000000, .Text = 0xffa0ff},
}

color :: proc(ink: Ink) -> u32 {
	return PALETTES[state.palette % len(PALETTES)][ink]
}

ctx: runtime.Context
state: game.Game
level_index: int

main :: proc() {
	ctx = context
	rand.reset(u64(time.now()._nsec))
	state = game.new_game(game.LEVELS[level_index])
	js.add_window_event_listener(.Key_Down, nil, on_key)
}

on_key :: proc(e: js.Event) {
	context = ctx
	cmd: game.Command
	switch e.data.key.code {
	case "ArrowUp", "KeyW":
		cmd = .Forward
	case "ArrowLeft", "KeyA":
		cmd = .Turn_Left
	case "ArrowRight", "KeyD":
		cmd = .Turn_Right
	case "ArrowDown", "KeyS", "Space":
		cmd = .Brake
	case "KeyH":
		cmd = .Horn
	case "KeyM":
		cmd = .Mute
	case "KeyR":
		state = game.new_game(game.LEVELS[level_index])
		js.event_prevent_default()
		return
	case "KeyN", "Enter":
		// On the verdict screen, Enter or N moves on (the last level starts over).
		if game.finished(&state) {
			if state.won {
				level_index = (level_index + 1) % len(game.LEVELS)
			}
			state = game.new_game(game.LEVELS[level_index])
		}
		js.event_prevent_default()
		return
	case "Digit1", "Digit2", "Digit3":
		level_index = int(e.data.key.code[5] - '1')
		state = game.new_game(game.LEVELS[level_index])
		js.event_prevent_default()
		return
	case:
		return
	}
	js.event_prevent_default()
	audio_radio(false) // the first key press unlocks audio, and the radio never stops
	game.step(&state, cmd)
	for i in 0 ..< state.sound_count {
		play_sound(state.sounds[i])
	}
}

// Effects are jsfxr samples in assets/sfx, one file per game.Sound in enum order. The long ones
// are cut short so a per-move putt stays a putt.
play_sound :: proc(s: game.Sound) {
	gain: f32 = 0.5
	max_ms: i32 = 700
	#partial switch s {
	case .Putt:      gain, max_ms = 0.15, 110
	case .Honk:      gain, max_ms = 0.4, 450
	case .Loud_Mute: gain, max_ms = 1.0, 900
	}
	audio_sfx(i32(s), gain, max_ms)
}

@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	context = ctx
	draw()
	free_all(context.temp_allocator)
	return true
}

// Tile and landmark picks, as (sheet, column, row). Adjust after looking at the sheets.
tile_art :: proc(t: game.Tile) -> (sheet: Sheet, col, row: i32, ink: Ink) {
	switch t {
	case .Grass: return .Natural, 1, 5, .Grass
	case .Road:  return .Natural, 9, 3, .Road
	case .Tree:  return .Natural, 24, 2, .Tree
	case .Field: return .Natural, 1, 7, .Grass
	case .Pond:  return .Natural, 1, 13, .House
	}
	return .Natural, 0, 0, .Paper
}

// Landmarks are drawn at the wrong size on purpose: the barn is huge, the cow is a bit small, the
// houses lean off their tiles. Purely visual; the game still treats each as one tile.
Fit :: struct {
	size, ox, oy: i32,
}

LANDMARK_FIT := [game.Landmark_Kind]Fit {
	.Barn         = {22, -6, -12},
	.Ruin         = {12, -1, -1},
	.Cow          = {13, -2, -3},
	.Oak          = {16, -3, -6},
	.House        = {18, -4, -8},
	.Yellow_House = {14, -2, -4},
}

// The Grandma portrait is a different person from the People sheet on each level, and none of
// them is quite right.
PORTRAITS := [?][2]i32{{0, 2}, {6, 10}, {15, 22}}

landmark_art :: proc(k: game.Landmark_Kind) -> (sheet: Sheet, col, row: i32, ink: Ink) {
	switch k {
	case .Barn:         return .Civilized, 17, 2, .Barn
	case .Ruin:         return .Natural, 1, 19, .Barn
	case .Cow:          return .Creatures, 6, 9, .Text
	case .Oak:          return .Natural, 1, 18, .Tree
	case .House:        return .Civilized, 2, 1, .House
	case .Yellow_House: return .Civilized, 3, 1, .Road
	}
	return .Natural, 0, 0, .Paper
}

draw :: proc() {
	fill_rect(0, 0, SCREEN_W, SCREEN_H, color(.Paper))
	for y in 0 ..< game.H {
		for x in 0 ..< game.W {
			sheet, col, row, ink := tile_art(state.tiles[y][x])
			if state.tiles[y][x] != .Grass {
				draw_tile(.Natural, 1, 5, x, y, .Grass)
			}
			tint := ink
			if state.tiles[y][x] == .Grass && ransom(x, y) {
				tint = .Barn // a few grass tiles in the wrong colour, like a ransom note
			}
			draw_tile(sheet, col, row, x, y, tint)
		}
	}
	for lm, kind in state.landmarks {
		if lm.present {
			sheet, col, row, ink := landmark_art(kind)
			f := LANDMARK_FIT[kind]
			blit(i32(sheet), col * TILE, row * TILE, TILE, TILE, i32(lm.pos.x) * TILE + f.ox, i32(lm.pos.y) * TILE + f.oy, f.size, f.size, color(ink))
		}
	}
	draw_car()
	draw_hud()
	if game.finished(&state) {
		draw_verdict()
	}
}

// A framed panel over the map: her verdict, then how it went.
draw_verdict :: proc() {
	x, y, w, h: i32 = 20, 24, SCREEN_W - 40, 104
	fill_rect(x - 2, y - 2, w + 4, h + 4, color(.Text))
	fill_rect(x, y, w, h, color(.Paper))
	tier := game.verdict_tier(&state)
	draw_text(game.TIER_TITLES[tier], x + 6, y + 6)
	draw_wrapped(game.verdict_line(&state), x + 6, y + 22, 4, x + w - 6)
	c := game.count_outcomes(&state)
	buf: [64]u8
	draw_text(fmt.bprintf(buf[:], "LINES OBEYED %d OF %d", c.obeyed, len(state.level.instructions)), x + 6, y + 62)
	draw_text(fmt.bprintf(buf[:], "PATIENCE %d  TURNS %d", max(state.patience, 0), state.turn), x + 6, y + 72)
	draw_text("R TRY AGAIN   ENTER NEXT", x + 6, y + 88)
}

// A fixed pattern, so it does not flicker.
ransom :: proc(x, y: int) -> bool {
	return (x * 7 + y * 13 + level_index * 5) % 11 == 0
}

draw_tile :: proc(sheet: Sheet, col, row: i32, x, y: int, ink: Ink) {
	blit(i32(sheet), col * TILE, row * TILE, TILE, TILE, i32(x) * TILE, i32(y) * TILE, TILE, TILE, color(ink))
}

// The car is code-drawn: no top-down vehicle exists in the chosen tile sets. It is an ill-fitting
// body with a mismatched boot and wheels that do not agree on a colour.
draw_car :: proc() {
	px := i32(state.car.x) * TILE
	py := i32(state.car.y) * TILE
	body := color(.Car)
	boot := color(.Barn)
	wheel := color(.Tree)
	vertical := state.heading == .North || state.heading == .South
	if vertical {
		fill_rect(px + 2, py + 1, 6, 8, body)
		fill_rect(px + 1, py + 2, 1, 2, wheel)
		fill_rect(px + 8, py + 6, 1, 2, wheel)
		if state.heading == .North {
			fill_rect(px + 3, py + 8, 4, 2, boot)
			fill_rect(px + 4, py, 2, 1, color(.House))
		} else {
			fill_rect(px + 3, py, 4, 2, boot)
			fill_rect(px + 4, py + 9, 2, 1, color(.House))
		}
	} else {
		fill_rect(px + 1, py + 2, 8, 6, body)
		fill_rect(px + 2, py + 1, 2, 1, wheel)
		fill_rect(px + 6, py + 8, 2, 1, wheel)
		if state.heading == .East {
			fill_rect(px, py + 3, 2, 4, boot)
			fill_rect(px + 9, py + 4, 1, 2, color(.House))
		} else {
			fill_rect(px + 8, py + 3, 2, 4, boot)
			fill_rect(px, py + 4, 1, 2, color(.House))
		}
	}
}

draw_hud :: proc() {
	top := i32(game.H * TILE)
	buf: [64]u8
	line := fmt.bprintf(buf[:], "PATIENCE %d   TURN %d", state.patience, state.turn)
	draw_text(line, 2, top + 1)
	draw_wrapped(state.said, 2, top + 9, 2, SCREEN_W - 38)
	draw_portrait(top)
	if !game.finished(&state) {
		draw_text("ARROWS DRIVE, SPACE BRAKE, H HONK", 2, top + 25)
	}
}

// DINOBYTE: 6 by 8 glyphs in a 16 by 16 grid, indexed by code page 437 (ASCII maps straight on).
draw_text :: proc(s: string, x, y: i32) {
	cx := x
	for i in 0 ..< len(s) {
		c := i32(s[i])
		blit(i32(Sheet.Font), (c % 16) * 6, (c / 16) * 8, 6, 8, cx, y, 6, 8, color(.Text))
		cx += 6
	}
}

// Greedy word wrap into at most `lines` rows of the screen width (6 px per glyph).
draw_wrapped :: proc(s: string, x, y: i32, lines: int, width: i32 = SCREEN_W) {
	cols := int((width - x) / 6)
	start := 0
	for row in 0 ..< lines {
		if start >= len(s) {
			return
		}
		end := min(start + cols, len(s))
		if end < len(s) {
			for end > start && s[end] != ' ' {
				end -= 1
			}
			if end == start {
				end = min(start + cols, len(s))
			}
		}
		draw_text(s[start:end], x, y + i32(row) * 8)
		start = end
		for start < len(s) && s[start] == ' ' {
			start += 1
		}
	}
}

// Grandma, scaled to an awkward 3x and parked slightly off the corner of the screen.
draw_portrait :: proc(top: i32) {
	p := PORTRAITS[level_index % len(PORTRAITS)]
	x: i32 = SCREEN_W - 34
	y: i32 = top + 1
	fill_rect(x - 1, y - 1, 33, 31, color(.Barn))
	fill_rect(x, y, 31, 29, color(.House))
	blit(i32(Sheet.People), p.x * TILE, p.y * TILE, TILE, TILE, x + 1, y - 1, 30, 30, color(.Paper))
}
