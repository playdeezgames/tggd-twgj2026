// Pure game rules for Grandma Drives. No platform imports, so it tests natively.
package game

W :: 24
H :: 16

Heading :: enum u8 {
	North,
	East,
	South,
	West,
}

Command :: enum u8 {
	Forward,
	Turn_Left,
	Turn_Right,
	Brake,
	Horn,
	Mute, // does nothing but make the radio louder; takes no turn
}

// Sounds the platform layer should play after a step. The core only says what happened.
Sound :: enum u8 {
	Putt,
	Honk,
	Brake,
	Obey,
	Wrong,
	Timeout,
	Loud_Mute,
	Arrive,
}

MAX_SOUNDS :: 8


// Scenery. Things Grandma can name are landmarks (landmarks.odin), not tiles.
Tile :: enum u8 {
	Grass,
	Road,
	Tree,
	Field,
	Pond,
}

Level :: struct {
	name:    string,
	rows:    [H]string,
	start:   [2]int,
	heading: Heading,
	goal:    [2]int,
	patience: int,
	regions:      []Region,
	instructions: []Instruction,
}

Game :: struct {
	level:    ^Level,
	tiles:    [H][W]Tile,
	car:      [2]int,
	heading:  Heading,
	patience: int,
	turn:     int,
	said:     string,
	won:      bool,
	lost:     bool,
	score:    int,
	palette:  int, // index into the platform layer's palette table

	sounds:      [MAX_SOUNDS]Sound, // events from the latest step
	sound_count: int,

	landmarks:     [Landmark_Kind]Landmark,
	control_turns: [Control_Flag]int, // turns each sabotage flag has left
	buffered:      Maybe(Command),    // a steering input held back by Input_Delay

	// Instruction engine state (engine.odin).
	active:         int, // index into level.instructions, or -1
	since_active:   int, // turns since the active instruction began
	since_resolved: int, // turns since the previous instruction resolved
	still:          int, // consecutive turns the car has not moved
	outcomes:       [MAX_INSTRUCTIONS]Outcome,
	spoken:         [MAX_INSTRUCTIONS]bool,
}

// One patience point drains every this many turns.
DRAIN_EVERY :: 2

DELTA := [Heading][2]int {
	.North = {0, -1},
	.East  = {1, 0},
	.South = {0, 1},
	.West  = {-1, 0},
}

tile_from_char :: proc(c: u8) -> Tile {
	switch c {
	case '=', 'S', 'G': return .Road
	case 'T': return .Tree
	case ',': return .Field
	case 'W': return .Pond
	}
	return .Grass
}

new_game :: proc(level: ^Level) -> Game {
	g := Game{level = level, car = level.start, heading = level.heading, patience = level.patience, active = -1}
	assert(len(level.instructions) <= MAX_INSTRUCTIONS)
	for y in 0 ..< H {
		for x in 0 ..< W {
			c := level.rows[y][x]
			g.tiles[y][x] = tile_from_char(c)
			if kind, ok := landmark_from_char(c); ok {
				g.landmarks[kind] = Landmark{present = true, pos = {x, y}}
			}
		}
	}
	fire_cue(&g)
	return g
}

in_bounds :: proc(p: [2]int) -> bool {
	return p.x >= 0 && p.x < W && p.y >= 0 && p.y < H
}

passable :: proc(g: ^Game, p: [2]int) -> bool {
	return in_bounds(p) && g.tiles[p.y][p.x] == .Road
}

// One player command, one turn: sabotage the input, apply it, evaluate the active instruction
// (engine.odin), fire the next cue, move landmarks and drain patience.
step :: proc(g: ^Game, cmd: Command) {
	if g.won || g.lost {
		return
	}
	g.sound_count = 0
	if cmd == .Mute {
		emit(g, .Loud_Mute)
		return
	}
	cmd := cmd
	if g.control_turns[.Flip_Left_Right] > 0 {
		#partial switch cmd {
		case .Turn_Left: cmd = .Turn_Right
		case .Turn_Right: cmd = .Turn_Left
		}
	}
	if g.control_turns[.Swap_Brake_Horn] > 0 {
		#partial switch cmd {
		case .Brake: cmd = .Horn
		case .Horn: cmd = .Brake
		}
	}
	// Input_Delay: a steering input is held back and applied after the next command.
	late := g.buffered
	g.buffered = nil
	if g.control_turns[.Input_Delay] > 0 && (cmd == .Turn_Left || cmd == .Turn_Right) {
		g.buffered = cmd
		cmd = .Brake
	}
	a: Action
	apply_command(g, cmd, &a)
	if late != nil {
		apply_command(g, late.?, &a)
	}
	for flag in Control_Flag {
		g.control_turns[flag] = max(0, g.control_turns[flag] - 1)
	}
	g.turn += 1
	g.since_active += 1
	g.since_resolved += 1
	g.still = a.moved ? 0 : g.still + 1
	if a.moved {
		walk_landmarks(g)
	}
	evaluate_active(g, &a)
	fire_cue(g)
	if g.turn % DRAIN_EVERY == 0 {
		g.patience -= 1
	}
	if g.car == g.level.goal && g.active == -1 {
		g.won = true
		emit(g, .Arrive)
	} else if g.patience <= 0 {
		g.lost = true
	}
}

emit :: proc(g: ^Game, s: Sound) {
	if g.sound_count < MAX_SOUNDS {
		g.sounds[g.sound_count] = s
		g.sound_count += 1
	}
}

turn_heading :: proc(g: ^Game, t: Turn) {
	repeats := 2 if g.control_turns[.Sticky_Turn] > 0 else 1
	for _ in 0 ..< repeats {
		switch t {
		case .Left: g.heading = Heading((int(g.heading) + 3) % 4)
		case .Right: g.heading = Heading((int(g.heading) + 1) % 4)
		case .None:
		}
	}
}

apply_command :: proc(g: ^Game, cmd: Command, a: ^Action) {
	switch cmd {
	case .Turn_Left:
		turn_heading(g, .Left)
		a.turn = .Left
	case .Turn_Right:
		turn_heading(g, .Right)
		a.turn = .Right
	case .Forward:
		next := g.car + DELTA[g.heading]
		if passable(g, next) {
			g.car = next
			a.moved = true
			emit(g, .Putt)
		}
	case .Brake:
		emit(g, .Brake)
	case .Horn:
		a.honk = true
		emit(g, .Honk)
	case .Mute:
	}
}
