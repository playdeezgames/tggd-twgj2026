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
	opening  = "Straight on, dear, until you see the old oak.",
}

LEVELS := [?]^Level{&LEVEL_1}
