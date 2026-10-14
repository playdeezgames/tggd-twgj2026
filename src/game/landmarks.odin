package game

// Things Grandma names. Read from map characters at the start of a level, then they can move,
// walk a scripted path, or vanish while the map under them stays put.
Landmark_Kind :: enum u8 {
	Barn,
	Ruin,
	Cow,
	Oak,
	House,
	Yellow_House,
}

Landmark :: struct {
	present: bool,
	pos:     [2]int,
	path:    []([2]int), // a walk in progress: one step per tile the player drives
	path_i:  int,
}

landmark_from_char :: proc(c: u8) -> (Landmark_Kind, bool) {
	switch c {
	case 'B': return .Barn, true
	case '~': return .Ruin, true
	case 'C': return .Cow, true
	case 'O': return .Oak, true
	case 'H': return .House, true
	case 'Y': return .Yellow_House, true
	}
	return {}, false
}

// Called once per tile the player moves.
walk_landmarks :: proc(g: ^Game) {
	for &lm in g.landmarks {
		if lm.present && lm.path_i < len(lm.path) {
			lm.pos = lm.path[lm.path_i]
			lm.path_i += 1
		}
	}
}

// Sabotage the player's controls for a number of turns. Flags stack by taking the longer time.
Control_Flag :: enum u8 {
	Input_Delay,     // steering is applied after the next command
	Swap_Brake_Horn, // the brake and horn keys exchange roles
	Flip_Left_Right, // left and right turns are swapped
	Sticky_Turn,     // a turn repeats once (turns twice)
}
