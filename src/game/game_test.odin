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
