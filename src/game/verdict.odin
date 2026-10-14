package game

// How the drive went, as Grandma sees it. She rewards both doing what she said and arriving
// somewhere clearly wrong, so a messy win is still funny.
Tier :: enum u8 {
	Nowhere,         // patience ran out before arriving
	Somehow_Arrived, // won, but did little of what she said
	Good_Enough,     // won, mixed
	Exactly_As_Told, // won, every line obeyed
}

TIER_TITLES := [Tier]string {
	.Nowhere         = "SHE HAS GONE QUIET",
	.Somehow_Arrived = "WRONG, BUT DELIGHTED",
	.Good_Enough     = "GOOD ENOUGH, DEAR",
	.Exactly_As_Told = "EXACTLY AS TOLD",
}

Outcome_Counts :: struct {
	obeyed, wrong, timed_out: int,
}

count_outcomes :: proc(g: ^Game) -> Outcome_Counts {
	c: Outcome_Counts
	for i in 0 ..< len(g.level.instructions) {
		switch g.outcomes[i] {
		case .Obeyed: c.obeyed += 1
		case .Wrong: c.wrong += 1
		case .Timed_Out: c.timed_out += 1
		case .Pending:
		}
	}
	return c
}

verdict_tier :: proc(g: ^Game) -> Tier {
	if !g.won {
		return .Nowhere
	}
	c := count_outcomes(g)
	resolved := c.obeyed + c.wrong + c.timed_out
	switch {
	case c.wrong + c.timed_out == 0:
		return .Exactly_As_Told
	case c.obeyed * 2 < resolved:
		return .Somehow_Arrived
	}
	return .Good_Enough
}

verdict_line :: proc(g: ^Game) -> string {
	return g.level.verdicts[verdict_tier(g)]
}

// The game is over once she has arrived or given up.
finished :: proc(g: ^Game) -> bool {
	return g.won || g.lost
}
