class_name PuzzleSolver
extends RefCounted

## Independent solver using dependency resolution and backtracking search.
## Validates that every puzzle has at least one valid sequence that clears the board.
## Handles both Arrow (Node2D/Area2D) objects and Dictionary data structures.

## Solves the puzzle and returns solution metadata
static func solve(arrows: Array, grid_size: Vector2i, search_limit: int = 5000) -> Dictionary:
	var active_arrows = arrows.duplicate()
	var solution_order: Array[int] = []
	var visited_states: Dictionary = {}
	var step_counter: Array[int] = [0] # Array to pass by reference

	var success = _solve_recursive(active_arrows, grid_size, solution_order, visited_states, step_counter, search_limit)

	return {
		"solvable": success,
		"solution_order": solution_order,
		"steps": step_counter[0],
		"remaining_unsolved": active_arrows.size() - solution_order.size()
	}

static func _solve_recursive(
	remaining: Array,
	grid_size: Vector2i,
	solution_order: Array[int],
	visited_states: Dictionary,
	step_counter: Array[int],
	limit: int
) -> bool:
	if remaining.is_empty():
		return true

	step_counter[0] += 1
	if step_counter[0] > limit:
		return false

	# State hash based on sorted remaining arrow IDs
	var state_key = _get_state_key(remaining)
	if visited_states.has(state_key):
		return false
	visited_states[state_key] = true

	# Find all currently removable arrows
	var occ_map = CollisionChecker.build_occupancy_map(remaining)
	var free_arrows: Array = []
	for arrow in remaining:
		if CollisionChecker.can_arrow_exit_with_map(arrow, occ_map, grid_size):
			free_arrows.append(arrow)

	if free_arrows.is_empty():
		return false # Deadlock!

	for candidate in free_arrows:
		var c_id: int = CollisionChecker._get_arrow_id(candidate)
		solution_order.append(c_id)

		var next_remaining: Array = []
		for a in remaining:
			if CollisionChecker._get_arrow_id(a) != c_id:
				next_remaining.append(a)

		if _solve_recursive(next_remaining, grid_size, solution_order, visited_states, step_counter, limit):
			return true

		solution_order.pop_back()

	return false

static func _get_state_key(remaining: Array) -> String:
	var ids: Array[int] = []
	for a in remaining:
		ids.append(CollisionChecker._get_arrow_id(a))
	ids.sort()
	return str(ids)

## Returns all arrows that are currently free to exit (used by Hint system)
static func get_removable_arrows(remaining_arrows: Array, grid_size: Vector2i) -> Array:
	var occ_map = CollisionChecker.build_occupancy_map(remaining_arrows)
	var free_arrows: Array = []
	for arrow in remaining_arrows:
		if CollisionChecker.can_arrow_exit_with_map(arrow, occ_map, grid_size):
			free_arrows.append(arrow)
	return free_arrows
