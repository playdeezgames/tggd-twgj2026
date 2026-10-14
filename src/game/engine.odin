// Instruction engine core. See ENGINE.md. One instruction is active at a time;
// each turn the active instruction's expectations are checked against what the
// player just did, and the next cue that is satisfied is activated.
package game

MAX_INSTRUCTIONS :: 32

Outcome :: enum u8 {
	Pending, // not resolved yet; in a cue, "any outcome"
	Obeyed,
	Wrong,
	Timed_Out,
}

Turn :: enum u8 {
	None,
	Left,
	Right,
}

Region :: struct {
	x0, y0, x1, y1: int,
}

Cue_Kind :: enum u8 {
	At_Start,
	After,        // after instruction `id` resolves with `outcome` (Pending means any)
	At_Region,    // the car is inside `region`
	After_Turns,  // `n` turns since the previous instruction resolved
}

Cue :: struct {
	kind:    Cue_Kind,
	id:      int,
	outcome: Outcome,
	region:  int,
	n:       int,
}

Expect_Kind :: enum u8 {
	Reach,   // car is inside `region`
	Turn_At, // player turns `turn` while inside `region`
	Face,    // player turns and ends facing `heading` while inside `region`
	Stop,    // car stays still for `n` turns inside `region`
	Honk,    // player honks inside `region`
}

Expect :: struct {
	kind:    Expect_Kind,
	region:  int,
	turn:    Turn,
	heading: Heading,
	n:       int,
}

Effect_Kind :: enum u8 {
	Say,
	Patience,
	Score,
}

Effect :: struct {
	kind: Effect_Kind,
	n:    int,
	text: string,
}

Instruction :: struct {
	text:       string, // what Grandma says when this becomes active
	intent:     string, // what she actually means (documentation for authors)
	cue:        Cue,
	expects:    []Expect, // any one satisfied counts as obeying
	timeout:    int,      // turns before she gives up waiting; 0 means never
	on_obey:    []Effect,
	on_wrong:   []Effect,
	on_timeout: []Effect,
}

in_region :: proc(g: ^Game, region: int) -> bool {
	r := g.level.regions[region]
	return g.car.x >= r.x0 && g.car.x <= r.x1 && g.car.y >= r.y0 && g.car.y <= r.y1
}

apply_effects :: proc(g: ^Game, effects: []Effect) {
	for e in effects {
		switch e.kind {
		case .Say:
			g.said = e.text
		case .Patience:
			g.patience += e.n
		case .Score:
			g.score += e.n
		}
	}
}

// What the player just did this turn.
Action :: struct {
	turn:  Turn,
	honk:  bool,
	moved: bool,
}

cue_satisfied :: proc(g: ^Game, c: Cue) -> bool {
	switch c.kind {
	case .At_Start:
		return g.turn == 0
	case .After:
		o := g.outcomes[c.id]
		return o != .Pending && (c.outcome == .Pending || c.outcome == o)
	case .At_Region:
		return in_region(g, c.region)
	case .After_Turns:
		return g.since_resolved >= c.n
	}
	return false
}

// Activate the first unspoken instruction whose cue is satisfied.
fire_cue :: proc(g: ^Game) {
	if g.active != -1 {
		return
	}
	for inst, i in g.level.instructions {
		if g.spoken[i] || !cue_satisfied(g, inst.cue) {
			continue
		}
		g.spoken[i] = true
		g.active = i
		g.since_active = 0
		g.said = inst.text
		return
	}
}

resolve :: proc(g: ^Game, outcome: Outcome) {
	inst := &g.level.instructions[g.active]
	g.outcomes[g.active] = outcome
	switch outcome {
	case .Obeyed:
		apply_effects(g, inst.on_obey)
	case .Wrong:
		apply_effects(g, inst.on_wrong)
	case .Timed_Out:
		apply_effects(g, inst.on_timeout)
	case .Pending:
	}
	g.active = -1
	g.since_resolved = 0
}

// Check the active instruction against this turn's action.
evaluate_active :: proc(g: ^Game, a: Action) {
	if g.active == -1 {
		return
	}
	inst := &g.level.instructions[g.active]
	obeyed, wrong := false, false
	for e in inst.expects {
		inside := in_region(g, e.region)
		switch e.kind {
		case .Reach:
			obeyed ||= inside
		case .Turn_At:
			if a.turn != .None && inside {
				if a.turn == e.turn {
					obeyed = true
				} else {
					wrong = true
				}
			}
		case .Face:
			if a.turn != .None && inside {
				if g.heading == e.heading {
					obeyed = true
				} else {
					wrong = true
				}
			}
		case .Stop:
			obeyed ||= inside && g.still >= e.n
		case .Honk:
			obeyed ||= inside && a.honk
		}
	}
	switch {
	case obeyed:
		resolve(g, .Obeyed)
	case wrong:
		resolve(g, .Wrong)
	case inst.timeout > 0 && g.since_active >= inst.timeout:
		resolve(g, .Timed_Out)
	}
}
