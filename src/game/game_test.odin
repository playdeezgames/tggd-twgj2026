#+build !js
package game

import "core:testing"

@(private = "file")
play :: proc(g: ^Game, cmd: Command, n := 1) {
	for _ in 0 ..< n {
		step(g, cmd)
	}
}

@(test)
level_maps_are_well_formed :: proc(t: ^testing.T) {
	for level in LEVELS {
		for row, y in level.rows {
			testing.expectf(t, len(row) == W, "%s row %d has %d columns", level.name, y, len(row))
		}
		g := new_game(level)
		testing.expect(t, g.tiles[level.start.y][level.start.x] == .Road, "start is on road")
		testing.expect(t, g.tiles[level.goal.y][level.goal.x] == .Road, "goal is on road")
	}
}

@(test)
level_1_scripted_solution_wins :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	play(&g, .Forward, 5)
	play(&g, .Turn_Right)
	play(&g, .Forward, 10)
	play(&g, .Turn_Left)
	play(&g, .Forward, 6)
	play(&g, .Turn_Right)
	play(&g, .Forward, 9)
	testing.expect(t, g.won, "reached the goal")
	testing.expect(t, !g.lost, "did not lose")
	testing.expect(t, g.patience > 0, "patience left")
}

@(test)
car_cannot_leave_the_road :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	play(&g, .Turn_Left)
	start := g.car
	play(&g, .Forward, 3)
	testing.expect(t, g.car == start, "grass blocks the car")
}

@(test)
doing_nothing_loses_without_hanging :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	for _ in 0 ..< 1000 {
		step(&g, .Brake)
		if g.lost {
			break
		}
	}
	testing.expect(t, g.lost, "patience runs out")
	testing.expect(t, !g.won, "not won")
}

@(private = "file")
solve_level_1 :: proc(g: ^Game) {
	play(g, .Forward, 5)
	play(g, .Turn_Right)
	play(g, .Forward, 10)
	play(g, .Turn_Left)
	play(g, .Forward, 6)
	play(g, .Turn_Right)
	play(g, .Forward, 9)
}

@(test)
level_1_opening_line_is_spoken_at_start :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	testing.expect(t, g.active == 0, "first instruction active")
	testing.expect(t, g.said == LEVEL_1_INSTRUCTIONS[0].text, "she says it")
}

@(test)
level_1_solution_obeys_every_instruction :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	solve_level_1(&g)
	for i in 0 ..< len(LEVEL_1_INSTRUCTIONS) {
		testing.expectf(t, g.outcomes[i] == .Obeyed, "instruction %d outcome %v", i, g.outcomes[i])
	}
	testing.expect(t, g.said == "There it is. Just as I remembered.", "arrival line")
	testing.expect(t, g.score == 2, "score from obeying")
}

@(test)
wrong_turn_costs_patience_and_the_level_continues :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	play(&g, .Forward, 5) // at the corner, instruction 1 obeyed, instruction 2 active
	before := g.patience
	play(&g, .Turn_Left) // faces West instead of East
	testing.expect(t, g.outcomes[1] == .Wrong, "marked wrong")
	testing.expect(t, g.patience == before - 3 - (1 if g.turn % DRAIN_EVERY == 0 else 0), "paid for it")
	play(&g, .Turn_Right, 2) // fix heading to East
	play(&g, .Forward, 10)
	testing.expect(t, g.car == [2]int{12, 9}, "still reaches the junction")
	testing.expect(t, g.active == 2, "the next line is active")
}

@(test)
silence_times_out_and_chains_on :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	play(&g, .Brake, 12)
	testing.expect(t, g.outcomes[0] == .Timed_Out, "first line timed out")
	testing.expect(t, g.active == 1, "next line follows a timeout")
}

@(test)
no_instruction_is_spoken_twice :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	solve_level_1(&g)
	count := 0
	for s in g.spoken {
		if s {
			count += 1
		}
	}
	testing.expect(t, count == len(LEVEL_1_INSTRUCTIONS), "each spoken once")
}

@(private = "file")
drive_to_fork :: proc(g: ^Game) {
	play(g, .Forward, 7)
	play(g, .Turn_Right)
	play(g, .Forward, 4)
	play(g, .Turn_Left)
}

@(test)
level_2_solution_reaches_the_church :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_2)
	drive_to_fork(&g)
	play(&g, .Forward, 6)
	play(&g, .Turn_Left) // held back by the delay
	play(&g, .Forward) // the turn lands after this move, at x = 7
	testing.expect(t, g.heading == .South, "the late turn landed")
	play(&g, .Forward, 4)
	play(&g, .Brake, 2)
	for i in 0 ..< 5 {
		testing.expectf(t, g.outcomes[i] == .Obeyed, "instruction %d outcome %v", i, g.outcomes[i])
	}
	testing.expect(t, g.won, "won")
	testing.expect(t, g.said == "Lovely. Now, which funeral is this?", "church line")
}

@(test)
cow_walks_ahead_one_tile_per_move :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_2)
	drive_to_fork(&g)
	testing.expect(t, g.landmarks[.Cow].pos == [2]int{10, 8}, "starts in its field")
	play(&g, .Forward) // enters the cue region at (13,10); the walk starts with the next move
	testing.expect(t, g.active == 2, "cow line active")
	testing.expect(t, g.landmarks[.Cow].pos == [2]int{10, 8}, "not moving yet")
	play(&g, .Forward)
	testing.expect(t, g.landmarks[.Cow].pos == [2]int{10, 9}, "cow left the field")
	play(&g, .Forward)
	testing.expect(t, g.landmarks[.Cow].pos == [2]int{10, 10}, "cow joined the road")
	play(&g, .Brake) // a turn without moving does not move the cow
	testing.expect(t, g.landmarks[.Cow].pos == [2]int{10, 10}, "cow waits for the car")
}

@(test)
first_left_is_a_dead_end_that_turns_you_around :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_2)
	drive_to_fork(&g)
	play(&g, .Forward, 4) // now at (10,10)
	play(&g, .Turn_Left) // held back
	play(&g, .Forward) // to (9,10); the turn lands: facing south
	play(&g, .Forward) // into the dead end
	testing.expect(t, g.outcomes[3] == .Wrong, "marked wrong")
	testing.expect(t, g.heading == .North, "turned around")
	testing.expect(t, g.car == [2]int{9, 11}, "at the dead end")
	play(&g, .Forward)
	testing.expect(t, g.car == [2]int{9, 10}, "back on the road")
}

@(test)
east_branch_dead_end_recovers :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_2)
	play(&g, .Forward, 7)
	play(&g, .Turn_Right)
	play(&g, .Forward, 4)
	play(&g, .Turn_Right) // east instead of west
	testing.expect(t, g.outcomes[1] == .Wrong, "wrong")
	play(&g, .Forward, 6)
	testing.expect(t, g.car == [2]int{20, 10}, "at the east end")
	testing.expect(t, g.heading == .West, "turned around by the line")
}

@(test)
control_flags_sabotage_input :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	g.control_turns[.Flip_Left_Right] = 2
	play(&g, .Turn_Left)
	testing.expect(t, g.heading == .East, "left became right")
	g.control_turns[.Flip_Left_Right] = 0
	g.control_turns[.Sticky_Turn] = 1
	play(&g, .Turn_Right)
	testing.expect(t, g.heading == .West, "sticky turn turned twice")
}

@(test)
input_delay_applies_steering_after_the_next_command :: proc(t: ^testing.T) {
	g := new_game(&LEVEL_1)
	g.control_turns[.Input_Delay] = 5
	play(&g, .Turn_Right)
	testing.expect(t, g.heading == .North, "nothing yet")
	play(&g, .Brake)
	testing.expect(t, g.heading == .East, "applied after the next command")
}
