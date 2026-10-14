package game

// Level data. Maps are checked by tests and listed in LEVELS.md.
// Legend: = road, . grass, T tree, B barn, ~ ruin, C cow, H house, Y yellow house, O oak, , field, W pond.
LEVEL_1 := Level {
	name = "Sunday Drive",
	rows = {
		"........................",
		"........................",
		"........T........Y......",
		"............=========GH.",
		"............=...........",
		".....T......=...........",
		"...........B=C.....T....",
		"............=...........",
		".O..........=...........",
		"..===========...........",
		"..=.....................",
		"..=.............T.......",
		"..=....T................",
		"..=.....................",
		"..S.....................",
		"........................",
	},
	start    = {2, 14},
	heading  = .North,
	goal     = {21, 3},
	patience = 30,
	regions      = LEVEL_1_REGIONS[:],
	instructions = LEVEL_1_INSTRUCTIONS[:],
}

// Indices into LEVEL_1_REGIONS.
L1_CORNER_A :: 0
L1_JUNCTION_B :: 1
L1_CORNER_C :: 2
L1_GOAL :: 3
L1_NEAR_GOAL :: 4

LEVEL_1_REGIONS := [?]Region {
	L1_CORNER_A   = {2, 9, 2, 9},
	L1_JUNCTION_B = {12, 9, 12, 9},
	L1_CORNER_C   = {12, 3, 12, 3},
	L1_GOAL       = {21, 3, 21, 3},
	L1_NEAR_GOAL  = {18, 3, 21, 3},
}

// See LEVELS.md, level 1. Outcomes chain with "any outcome" so a timeout never strands the level.
LEVEL_1_INSTRUCTIONS := [?]Instruction {
	{
		text = "Straight on, dear, until you see the old oak.",
		intent = "Drive N to the corner at (2,9)",
		cue = {kind = .At_Start},
		expects = {{kind = .Reach, region = L1_CORNER_A}},
		timeout = 12,
		on_timeout = {{kind = .Patience, n = -5}, {kind = .Say, text = "Are we there yet?"}},
	},
	{
		text = "Now the way the sun goes.",
		intent = "Turn E at the corner",
		cue = {kind = .After, id = 0},
		expects = {{kind = .Face, region = L1_CORNER_A, heading = .East}},
		timeout = 8,
		on_wrong = {{kind = .Patience, n = -3}, {kind = .Say, text = "The other way the sun goes."}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{
		text = "Left at the barn. Or the cow. One of them.",
		intent = "Turn N at (12,9)",
		cue = {kind = .At_Region, region = L1_JUNCTION_B},
		expects = {{kind = .Turn_At, region = L1_JUNCTION_B, turn = .Left}},
		timeout = 8,
		on_obey = {{kind = .Score, n = 1}},
		on_wrong = {{kind = .Patience, n = -3}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{
		text = "Keep on till it smells like the Hendersons'.",
		intent = "Drive N, then turn E at (12,3)",
		cue = {kind = .After, id = 2},
		expects = {{kind = .Face, region = L1_CORNER_C, heading = .East}},
		timeout = 12,
		on_timeout = {{kind = .Say, text = "You can smell it from here."}},
	},
	{
		text = "It's the one with the thing out front, dear.",
		intent = "Reach the goal, the Hendersons' at the end of the road",
		cue = {kind = .At_Region, region = L1_NEAR_GOAL},
		expects = {{kind = .Reach, region = L1_GOAL}},
		timeout = 10,
		on_obey = {{kind = .Say, text = "There it is. Just as I remembered."}, {kind = .Score, n = 1}},
		on_timeout = {{kind = .Patience, n = -5}, {kind = .Say, text = "No, dear, the other thing out front."}},
	},
}

LEVELS := [?]^Level{&LEVEL_1}
