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


// ---------------------------------------------------------------------------------------------
// Level 2: The Cow Moved. See LEVELS.md. Teaches stale landmarks, a self-correcting line,
// the steering delay, and a dead end that costs patience.

LEVEL_2 := Level {
	name = "The Cow Moved",
	rows = {
		"........................",
		"........................",
		"........................",
		"...........T............",
		"........................",
		"..................T.....",
		"....T...................",
		"........................",
		"..........C.............",
		".............~..........",
		"......===============...",
		".......===....=.........",
		".......==.....=H....T...",
		".......=......=.........",
		"......YG......=======S..",
		"........................",
	},
	start        = {21, 14},
	heading      = .West,
	goal         = {7, 14},
	patience     = 30,
	regions      = LEVEL_2_REGIONS[:],
	instructions = LEVEL_2_INSTRUCTIONS[:],
}

L2_CORNER_1 :: 0
L2_FORK :: 1
L2_ROW10_WEST :: 2
L2_LEFT_ZONE :: 3
L2_LEFT_2 :: 4
L2_LEFT_3 :: 5
L2_DEAD_END :: 6
L2_CHURCH :: 7
L2_EAST_END :: 8

LEVEL_2_REGIONS := [?]Region {
	L2_CORNER_1   = {14, 14, 14, 14},
	L2_FORK       = {14, 10, 14, 10},
	L2_ROW10_WEST = {11, 10, 13, 10},
	L2_LEFT_ZONE  = {7, 10, 9, 10},
	L2_LEFT_2     = {8, 10, 8, 10},
	L2_LEFT_3     = {7, 10, 7, 10},
	L2_DEAD_END   = {9, 11, 9, 11},
	L2_CHURCH     = {7, 14, 7, 14},
	L2_EAST_END   = {20, 10, 20, 10},
}

// The cow leaves its field, joins the road and leads the way to the church.
L2_COW_PATH := [?][2]int{{10, 9}, {10, 10}, {9, 10}, {8, 10}, {7, 10}, {7, 11}, {7, 12}, {7, 13}}

LEVEL_2_INSTRUCTIONS := [?]Instruction {
	{ 	// 0
		text = "Down to the end, then right at the Hendersons'.",
		intent = "Turn N at (14,14)",
		cue = {kind = .At_Start},
		expects = {{kind = .Turn_At, region = L2_CORNER_1, turn = .Right}},
		timeout = 10,
		on_wrong = {{kind = .Patience, n = -3}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 1
		text = "Left where the barn used to be.",
		intent = "Turn W at the fork (14,10); the ruin marks it",
		cue = {kind = .After, id = 0},
		expects = {{kind = .Turn_At, region = L2_FORK, turn = .Left}},
		timeout = 8,
		on_obey = {
			{kind = .Control, flag = .Input_Delay, n = 14},
			{kind = .Say, text = "Let's get a move on!"},
		},
		on_wrong = {{kind = .Patience, n = -3}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 2
		text = "Where's that cow got to? Follow the cow.",
		intent = "The cow walks the road ahead of the car and turns S at x = 7",
		cue = {kind = .At_Region, region = L2_ROW10_WEST},
		on_start = {{kind = .Walk_Landmark, landmark = .Cow, path = L2_COW_PATH[:]}},
		expects = {{kind = .Reach, region = L2_LEFT_ZONE}},
		timeout = 10,
		on_obey = {{kind = .Score, n = 1}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 3
		text = "Second left. No, third. Oh, you've gone past it.",
		intent = "The second or third left reaches the church; the first is Mr. Pratt's drive",
		cue = {kind = .After, id = 2},
		expects = {
			{kind = .Turn_At, region = L2_LEFT_2, turn = .Left},
			{kind = .Turn_At, region = L2_LEFT_3, turn = .Left},
			{kind = .Avoid, region = L2_DEAD_END},
		},
		timeout = 12,
		on_wrong = {
			{kind = .Patience, n = -9},
			{kind = .Say, text = "Not that one, that's Mr. Pratt's drive."},
			{kind = .Turn_Around},
		},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 4
		text = "Park by the place, dear. Mind the step.",
		intent = "Stop at the church door",
		cue = {kind = .At_Region, region = L2_CHURCH},
		expects = {{kind = .Stop, region = L2_CHURCH, n = 2}},
		timeout = 8,
		on_obey = {{kind = .Say, text = "Lovely. Now, which funeral is this?"}, {kind = .Score, n = 1}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 5: the east branch at the fork is a dead end
		text = "Oh, not this way, there's nothing here but the dump.",
		intent = "Recover from the east dead end",
		cue = {kind = .At_Region, region = L2_EAST_END},
		on_start = {{kind = .Turn_Around}, {kind = .Patience, n = -6}},
		timeout = 1,
	},
}

LEVELS := [?]^Level{&LEVEL_1, &LEVEL_2}
