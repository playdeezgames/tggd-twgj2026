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
	verdicts = {
		.Nowhere = "Well. I suppose we'll go another day.",
		.Somehow_Arrived = "That wasn't what I said, but it was lovely.",
		.Good_Enough = "Good enough, dear. The Hendersons will understand.",
		.Exactly_As_Told = "Just as I remembered it. You are a good driver.",
	},
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
	verdicts = {
		.Nowhere = "I think we must have missed the funeral.",
		.Somehow_Arrived = "Well, that's the church. I was thinking of the other church.",
		.Good_Enough = "A lovely service, whoever it was for.",
		.Exactly_As_Told = "Right on time. Nobody was expecting us, but still.",
	},
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


// ---------------------------------------------------------------------------------------------
// Level 3: Pratt's Field. See LEVELS.md. Everything is on: flipped steering, swapped brake and
// horn, a delay, a field that becomes road, a dead end, and a drive that ends back home.
// Start (5,13) and goal (3,13) are different tiles so the drive has to happen.

LEVEL_3 := Level {
	name = "Pratt's Field",
	rows = {
		"........................",
		"...............T........",
		"........................",
		".....H=============.....",
		"........,.........=.....",
		"........,.....~...=.....",
		"........,.........=.....",
		"..C.....,.........=.....",
		"........,.=========.....",
		"........,.=.............",
		"........,.=..........W..",
		"........,.=.T...........",
		"........,.=.............",
		"..YG=S=======...........",
		"........................",
		"........................",
	},
	start        = {5, 13},
	heading      = .East,
	goal         = {3, 13},
	patience     = 40,
	regions      = LEVEL_3_REGIONS[:],
	instructions = LEVEL_3_INSTRUCTIONS[:],
	verdicts = {
		.Nowhere = "We'll just sit here a minute, dear. I'm sure it's close.",
		.Somehow_Arrived = "You've brought me home. I do like that you knew.",
		.Good_Enough = "That's my own house. I'd know it anywhere.",
		.Exactly_As_Told = "Straight home, the whole way round. You are a marvel.",
	},
}

L3_CORNER_1 :: 0
L3_CORNER_2 :: 1
L3_CORNER_3 :: 2
L3_CORNER_4 :: 3
L3_MOUTH :: 4
L3_FIELD :: 5
L3_CORNER_5 :: 6
L3_NEAR_HOME :: 7
L3_HOME :: 8
L3_DEAD_END :: 9

LEVEL_3_REGIONS := [?]Region {
	L3_CORNER_1  = {10, 13, 10, 13},
	L3_CORNER_2  = {10, 8, 10, 8},
	L3_CORNER_3  = {18, 8, 18, 8},
	L3_CORNER_4  = {18, 3, 18, 3},
	L3_MOUTH     = {8, 3, 8, 3},
	L3_FIELD     = {8, 4, 8, 12},
	L3_CORNER_5  = {8, 13, 8, 13},
	L3_NEAR_HOME = {3, 13, 4, 13},
	L3_HOME      = {3, 13, 3, 13},
	L3_DEAD_END  = {6, 3, 6, 3},
}

LEVEL_3_INSTRUCTIONS := [?]Instruction {
	{ 	// 0: steering is flipped for the whole drive, so the key she names makes the turn
		text = "Right at the big tree, dear.",
		intent = "Turn N at (10,13): a left turn for the car, so with flipped steering press right",
		cue = {kind = .At_Start},
		on_start = {{kind = .Control, flag = .Flip_Left_Right, n = 60}},
		expects = {{kind = .Turn_At, region = L3_CORNER_1, turn = .Left}},
		timeout = 14,
		on_wrong = {{kind = .Patience, n = -3}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 1
		text = "Straight on past the pond.",
		intent = "Turn E at (10,8), then N at (18,8)",
		cue = {kind = .At_Region, region = L3_CORNER_2},
		expects = {{kind = .Face, region = L3_CORNER_3, heading = .North}},
		timeout = 14,
		on_wrong = {{kind = .Patience, n = -3}, {kind = .Say, text = "We don't go that way."}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 2
		text = "Left, and mind the wires.",
		intent = "Turn W at (18,3)",
		cue = {kind = .At_Region, region = L3_CORNER_4},
		expects = {{kind = .Turn_At, region = L3_CORNER_4, turn = .Left}},
		timeout = 10,
		on_obey = {{kind = .Control, flag = .Swap_Brake_Horn, n = 18}, {kind = .Retint, n = 2}},
		on_wrong = {{kind = .Patience, n = -3}},
		on_timeout = {{kind = .Patience, n = -5}, {kind = .Control, flag = .Swap_Brake_Horn, n = 18}, {kind = .Retint, n = 2}},
	},
	{ 	// 3: the field becomes road the moment she remembers it, whether or not you turn in
		text = "Oh! Pratt's field! I always go through Pratt's field.",
		intent = "Turn S into the field at (8,3)",
		cue = {kind = .At_Region, region = L3_MOUTH},
		on_start = {{kind = .Set_Tiles, region = L3_FIELD, tile = .Road}, {kind = .Retint, n = 3}},
		expects = {{kind = .Turn_At, region = L3_MOUTH, turn = .Left}},
		timeout = 6,
		on_wrong = {{kind = .Patience, n = -3}},
	},
	{ 	// 4: enters the field by any route, so a missed turn can still recover
		text = "Straight down, straight down, you'll see the house.",
		intent = "Drive S to (8,13) and turn W; the turn is held back by the delay, so press it a tile early",
		cue = {kind = .At_Region, region = L3_FIELD},
		on_start = {{kind = .Control, flag = .Input_Delay, n = 12}},
		expects = {{kind = .Turn_At, region = L3_CORNER_5, turn = .Right}},
		timeout = 16,
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 5: missed the field and ran on to the Hendersons' dead end
		text = "Oh, they've moved. Back we go.",
		intent = "Recover from the Hendersons' dead end",
		cue = {kind = .At_Region, region = L3_DEAD_END},
		on_start = {{kind = .Turn_Around}, {kind = .Patience, n = -6}},
		timeout = 1,
	},
	{ 	// 6: re-offers the field
		text = "Pratt's field, dear. I told you. Pratt's field.",
		intent = "Turn S into the field at (8,3) now that you are heading E",
		cue = {kind = .After, id = 5},
		expects = {{kind = .Turn_At, region = L3_MOUTH, turn = .Right}},
		timeout = 10,
		on_timeout = {{kind = .Patience, n = -5}},
	},
	{ 	// 7
		text = "Here we are, here we are! ... Oh. This is my house.",
		intent = "Reach home at (3,13)",
		cue = {kind = .At_Region, region = L3_NEAR_HOME},
		expects = {{kind = .Reach, region = L3_HOME}},
		timeout = 10,
		on_obey = {{kind = .Say, text = "Well. You drove beautifully. Do come in."}, {kind = .Score, n = 1}},
		on_timeout = {{kind = .Patience, n = -5}},
	},
}

LEVELS := [?]^Level{&LEVEL_1, &LEVEL_2, &LEVEL_3}
