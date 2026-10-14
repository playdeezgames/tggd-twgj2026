// Menu screens: title, how to play, and about and credits. The game itself lives in web.odin.
#+build js
package main

import game "tggd:game"

Screen :: enum {
	Title,
	How_To,
	About,
	Play,
}

screen := Screen.Title
menu_cursor := 0

MENU := [?]string{"START THE DRIVE", "HOW TO PLAY", "ABOUT AND CREDITS"}

start_level :: proc(n: int) {
	level_index = n
	state = game.new_game(game.LEVELS[level_index])
	screen = .Play
}

// Returns true if the key was used.
menu_key :: proc(code: string) -> bool {
	switch screen {
	case .Title:
		switch code {
		case "ArrowUp", "KeyW":
			menu_cursor = (menu_cursor + len(MENU) - 1) % len(MENU)
		case "ArrowDown", "KeyS":
			menu_cursor = (menu_cursor + 1) % len(MENU)
		case "Enter", "Space":
			switch menu_cursor {
			case 0: start_level(0)
			case 1: screen = .How_To
			case 2: screen = .About
			}
		case "Digit1", "Digit2", "Digit3":
			start_level(int(code[5] - '1'))
		case:
			return false
		}
		return true
	case .How_To, .About:
		switch code {
		case "Escape", "Enter", "Space", "Backspace":
			screen = .Title
			return true
		}
		return false
	case .Play:
	}
	return false
}

draw_screen :: proc() {
	fill_rect(0, 0, SCREEN_W, SCREEN_H, color(.Paper))
	switch screen {
	case .Title: draw_title()
	case .How_To: draw_how_to()
	case .About: draw_about()
	case .Play:
	}
}

// Text at a whole-number scale, centred.
draw_centered :: proc(s: string, y: i32, scale: i32) {
	w := i32(len(s)) * 6 * scale
	x := (SCREEN_W - w) / 2
	cx := x
	for i in 0 ..< len(s) {
		c := i32(s[i])
		blit(i32(Sheet.Font), (c % 16) * 6, (c / 16) * 8, 6, 8, cx, y, 6 * scale, 8 * scale, color(.Text))
		cx += 6 * scale
	}
}

draw_title :: proc() {
	draw_centered("TURN LEFT", 6, 3)
	draw_centered("AT THE COW", 32, 3)

	// A road with a car and a cow on it, drawn at slightly wrong sizes.
	for x in 0 ..< game.W {
		blit(i32(Sheet.Natural), 9 * TILE, 3 * TILE, TILE, TILE, i32(x) * TILE, 72, TILE, TILE, color(.Road))
	}
	draw_car_at(40, 72, .East)
	blit(i32(Sheet.Creatures), 6 * TILE, 9 * TILE, TILE, TILE, 150, 56, 26, 26, color(.Text))
	p := PORTRAITS[0]
	blit(i32(Sheet.People), p.x * TILE, p.y * TILE, TILE, TILE, 200, 56, 26, 26, color(.House))

	draw_centered("Grandma is navigating. You are driving.", 94, 1)
	for item, i in MENU {
		y := 114 + i32(i) * 14
		if i == menu_cursor {
			draw_text(">", 52, y)
		}
		draw_text(item, 64, y)
	}
	draw_centered("UP DOWN ENTER, OR 1 2 3 FOR A LEVEL", 164, 1)
	draw_centered("A WORST GAME JAM ENTRY", 178, 1)
}

draw_how_to :: proc() {
	y: i32 = 8
	draw_text("HOW TO PLAY", 8, y)
	y += 18
	rows := [?]string {
		"Up drives forward one tile. Left and right turn the car.",
		"Space brakes. H honks. R restarts the level. Esc goes back to this menu.",
		"M mutes the radio. (Try it.)",
		"Grandma means well. Listen to what she means, not what she says.",
		"Her patience drains as you drive and wrong turns cost it. If it runs out, you are done.",
		"The controls are bad on purpose. Some turns will be flipped, held back or swapped.",
	}
	for r in rows {
		y += i32(draw_wrapped(r, 8, y, 6, SCREEN_W - 8)) * 8 + 5
	}
	draw_text("ESC TO GO BACK", 8, SCREEN_H - 12)
}

draw_about :: proc() {
	y: i32 = 6
	draw_text("ABOUT AND CREDITS", 8, y)
	y += 14
	rows := [?]string {
		"Game by TheGrumpyGameDev, with Claude (Anthropic). Code, colours, sizes and sound choices by Claude.",
		"Tiles: Bountiful Bits and Bit Bonanza by VEXED (CC0), arranged and tinted by Claude.",
		"Font: DINOBYTE bitmap font by mby, https://mby.itch.io/dinobyte, CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)",
		"Sounds: jsfxr (sfxr.me), made worse. The radio is synthesised live.",
		"Made for The WORST Game Jam. Theme: Grandma's Instructions.",
		"No flashing lights. Mind the volume: the radio cannot be turned off.",
	}
	for r in rows {
		y += i32(draw_wrapped(r, 8, y, 6, SCREEN_W - 8)) * 8 + 4
	}
	draw_text("ESC TO GO BACK", 8, SCREEN_H - 10)
}
