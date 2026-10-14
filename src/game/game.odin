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
}

Tile :: enum u8 {
	Grass,
	Road,
	Tree,
	Barn,
	Ruin,
	Cow,
	House,
	Yellow_House,
	Oak,
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
	case 'B': return .Barn
	case '~': return .Ruin
	case 'C': return .Cow
	case 'H': return .House
	case 'Y': return .Yellow_House
	case 'O': return .Oak
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
			g.tiles[y][x] = tile_from_char(level.rows[y][x])
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

// One player command, one turn: apply it, evaluate the active instruction (engine.odin), fire the next cue, drain patience.
step :: proc(g: ^Game, cmd: Command) {
	if g.won || g.lost {
		return
	}
	a: Action
	switch cmd {
	case .Turn_Left:
		g.heading = Heading((int(g.heading) + 3) % 4)
		a.turn = .Left
	case .Turn_Right:
		g.heading = Heading((int(g.heading) + 1) % 4)
		a.turn = .Right
	case .Forward:
		next := g.car + DELTA[g.heading]
		if passable(g, next) {
			g.car = next
			a.moved = true
		}
	case .Brake:
	case .Horn:
		a.honk = true
	}
	g.turn += 1
	g.since_active += 1
	g.since_resolved += 1
	g.still = a.moved ? 0 : g.still + 1
	evaluate_active(g, a)
	fire_cue(g)
	if g.turn % DRAIN_EVERY == 0 {
		g.patience -= 1
	}
	if g.car == g.level.goal {
		g.won = true
	} else if g.patience <= 0 {
		g.lost = true
	}
}
