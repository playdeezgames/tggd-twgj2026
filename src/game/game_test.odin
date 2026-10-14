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
