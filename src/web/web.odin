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
	// Copy a w by h piece of a sheet at (sx, sy) to (dx, dy), tinted 0xRRGGBB.
	blit :: proc(sheet: i32, sx, sy, w, h: i32, dx, dy: i32, rgb: u32) ---
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

// A deliberately clashing palette; the art stays 1-bit and is tinted here.
PAPER :: 0x2b0a6e
GRASS_INK :: 0x00c040
ROAD_INK :: 0xffd800
TREE_INK :: 0xff00a0
HOUSE_INK :: 0x00e0ff
BARN_INK :: 0xff7000
CAR_INK :: 0xffffff
TEXT_INK :: 0xffff60

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
	case "KeyR":
		state = game.new_game(game.LEVELS[level_index])
		js.event_prevent_default()
		return
	case:
		return
	}
	js.event_prevent_default()
	game.step(&state, cmd)
}

@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	context = ctx
	draw()
	free_all(context.temp_allocator)
	return true
}

// Tile picks, as (sheet, column, row). Adjust after looking at the sheets.
tile_art :: proc(t: game.Tile) -> (sheet: Sheet, col, row: i32, ink: u32) {
	switch t {
	case .Grass:        return .Natural, 1, 5, GRASS_INK
	case .Road:         return .Natural, 9, 3, ROAD_INK
	case .Tree:         return .Natural, 24, 2, TREE_INK
	case .Oak:          return .Natural, 1, 18, TREE_INK
	case .Barn:         return .Civilized, 17, 2, BARN_INK
	case .Ruin:         return .Natural, 1, 19, BARN_INK
	case .House:        return .Civilized, 2, 1, HOUSE_INK
	case .Yellow_House: return .Civilized, 3, 1, ROAD_INK
	case .Field:        return .Natural, 1, 7, GRASS_INK
	case .Pond:         return .Natural, 1, 13, HOUSE_INK
	case .Cow:          return .Natural, 1, 14, TEXT_INK
	}
	return .Natural, 0, 0, 0
}

draw :: proc() {
	fill_rect(0, 0, SCREEN_W, SCREEN_H, PAPER)
	for y in 0 ..< game.H {
		for x in 0 ..< game.W {
			sheet, col, row, ink := tile_art(state.tiles[y][x])
			if state.tiles[y][x] != .Grass {
				draw_tile(.Natural, 1, 5, x, y, GRASS_INK)
			}
			draw_tile(sheet, col, row, x, y, ink)
		}
	}
	draw_car()
	draw_hud()
}

draw_tile :: proc(sheet: Sheet, col, row: i32, x, y: int, ink: u32) {
	blit(i32(sheet), col * TILE, row * TILE, TILE, TILE, i32(x) * TILE, i32(y) * TILE, ink)
}

// The car is code-drawn: no top-down vehicle exists in the chosen tile sets.
draw_car :: proc() {
	px := i32(state.car.x) * TILE
	py := i32(state.car.y) * TILE
	fill_rect(px + 2, py + 2, 6, 6, CAR_INK)
	switch state.heading {
	case .North: fill_rect(px + 4, py, 2, 2, CAR_INK)
	case .East:  fill_rect(px + 8, py + 4, 2, 2, CAR_INK)
	case .South: fill_rect(px + 4, py + 8, 2, 2, CAR_INK)
	case .West:  fill_rect(px, py + 4, 2, 2, CAR_INK)
	}
}

draw_hud :: proc() {
	top := i32(game.H * TILE)
	buf: [64]u8
	line := fmt.bprintf(buf[:], "PATIENCE %d   TURN %d", state.patience, state.turn)
	draw_text(line, 2, top + 1)
	draw_wrapped(state.said, 2, top + 9, 2)
	switch {
	case state.won:
		draw_text("YOU ARRIVED. R TO RESTART", 2, top + 25)
	case state.lost:
		draw_text("SHE HAS GONE QUIET. R TO RESTART", 2, top + 25)
	case:
		draw_text("ARROWS DRIVE, SPACE BRAKES, H HONKS", 2, top + 25)
	}
}

// DINOBYTE: 6 by 8 glyphs in a 16 by 16 grid, indexed by code page 437 (ASCII maps straight on).
draw_text :: proc(s: string, x, y: i32) {
	cx := x
	for i in 0 ..< len(s) {
		c := i32(s[i])
		blit(i32(Sheet.Font), (c % 16) * 6, (c / 16) * 8, 6, 8, cx, y, TEXT_INK)
		cx += 6
	}
}

// Greedy word wrap into at most `lines` rows of the screen width (6 px per glyph).
draw_wrapped :: proc(s: string, x, y: i32, lines: int) {
	cols := int((SCREEN_W - x) / 6)
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
