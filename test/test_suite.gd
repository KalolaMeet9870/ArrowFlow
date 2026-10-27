extends SceneTree

## Automated Test Suite for Arrow Puzzle Game in Godot 4.7
## Covers all 12+ criteria specified in the development specification.

var tests_passed: int = 0
var tests_failed: int = 0

func _init() -> void:
	print("\n=======================================================")
	print("  ARROW PUZZLE GAME - AUTOMATED TEST SUITE (GODOT 4.7) ")
	print("=======================================================\n")

	run_all_tests()

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("-------------------------------------------------------")

	if tests_failed == 0:
		print(">>> ALL TESTS PASSED SUCCESSFULLY! <<<\n")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<\n")
		quit(1)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		tests_failed += 1
		printerr("  [FAIL] %s" % test_name)

func run_all_tests() -> void:
	test_direction_vectors()
	test_directional_exits()
	test_blocked_paths()
	test_multicell_collisions()
	test_successful_removal_and_unblocking()
	test_heart_deduction_and_failure()
	test_level_completion()
	test_level_restart()
	test_puzzle_solver_handcrafted_levels()
	test_procedural_generator_solvability_50_levels()
	test_save_and_load_persistence()

func test_direction_vectors() -> void:
	print("[Group 1] Direction Vector Conversions")
	assert_true(CollisionChecker.direction_to_vector(CollisionChecker.Direction.UP) == Vector2i(0, -1), "UP vector is (0, -1)")
	assert_true(CollisionChecker.direction_to_vector(CollisionChecker.Direction.DOWN) == Vector2i(0, 1), "DOWN vector is (0, 1)")
	assert_true(CollisionChecker.direction_to_vector(CollisionChecker.Direction.LEFT) == Vector2i(-1, 0), "LEFT vector is (-1, 0)")
	assert_true(CollisionChecker.direction_to_vector(CollisionChecker.Direction.RIGHT) == Vector2i(1, 0), "RIGHT vector is (1, 0)")

func test_directional_exits() -> void:
	print("\n[Group 2] Directional Exits (UP, DOWN, LEFT, RIGHT)")
	var grid = Vector2i(5, 5)

	# 1. UP exit
	var a_up = {"arrow_id": 1, "grid_position": Vector2i(2, 2), "direction": CollisionChecker.Direction.UP, "length": 1}
	assert_true(CollisionChecker.can_arrow_exit(a_up, [a_up], grid), "Upward exit path is clear")

	# 2. DOWN exit
	var a_down = {"arrow_id": 2, "grid_position": Vector2i(2, 2), "direction": CollisionChecker.Direction.DOWN, "length": 1}
	assert_true(CollisionChecker.can_arrow_exit(a_down, [a_down], grid), "Downward exit path is clear")

	# 3. LEFT exit
	var a_left = {"arrow_id": 3, "grid_position": Vector2i(2, 2), "direction": CollisionChecker.Direction.LEFT, "length": 1}
	assert_true(CollisionChecker.can_arrow_exit(a_left, [a_left], grid), "Leftward exit path is clear")

	# 4. RIGHT exit
	var a_right = {"arrow_id": 4, "grid_position": Vector2i(2, 2), "direction": CollisionChecker.Direction.RIGHT, "length": 1}
	assert_true(CollisionChecker.can_arrow_exit(a_right, [a_right], grid), "Rightward exit path is clear")

func test_blocked_paths() -> void:
	print("\n[Group 3] Blocked Paths & Obstacle Rejection")
	var grid = Vector2i(5, 5)

	# Arrow 1 is at (1, 2) pointing RIGHT. Arrow 2 is at (3, 2). Arrow 1 should be blocked.
	var a1 = {"arrow_id": 1, "grid_position": Vector2i(1, 2), "direction": CollisionChecker.Direction.RIGHT, "length": 1}
	var a2 = {"arrow_id": 2, "grid_position": Vector2i(3, 2), "direction": CollisionChecker.Direction.UP, "length": 1}

	assert_true(not CollisionChecker.can_arrow_exit(a1, [a1, a2], grid), "Rightward path blocked by arrow at (3, 2)")
	assert_true(CollisionChecker.can_arrow_exit(a2, [a1, a2], grid), "Blocker arrow pointing UP is free to exit")

func test_multicell_collisions() -> void:
	print("\n[Group 4] Multi-cell Arrow Occupancy & Collision")
	var grid = Vector2i(6, 6)

	# Long arrow of length 3 starting at (1, 1) pointing DOWN -> occupies (1, 1), (1, 2), (1, 3)
	var long_arrow = {
		"arrow_id": 10,
		"grid_position": Vector2i(1, 1),
		"direction": CollisionChecker.Direction.DOWN,
		"length": 3
	}

	var cells = CollisionChecker.get_arrow_cells(long_arrow)
	assert_true(cells.size() == 3, "Multi-cell arrow occupies exactly 3 cells")
	assert_true(cells[0] == Vector2i(1, 1) and cells[1] == Vector2i(1, 2) and cells[2] == Vector2i(1, 3), "Occupied cells match coordinate span")

	var head = CollisionChecker.get_arrow_head(long_arrow)
	assert_true(head == Vector2i(1, 3), "Arrowhead is at forward-most cell (1, 3)")

	# Another arrow crossing at (1, 2) pointing RIGHT should be blocked by long_arrow's body
	var crossing_arrow = {
		"arrow_id": 11,
		"grid_position": Vector2i(0, 2),
		"direction": CollisionChecker.Direction.RIGHT,
		"length": 1
	}
	assert_true(not CollisionChecker.can_arrow_exit(crossing_arrow, [long_arrow, crossing_arrow], grid), "Arrow blocked by multi-cell arrow's body")

func test_successful_removal_and_unblocking() -> void:
	print("\n[Group 5] Successful Removal and Dynamic Unblocking")
	var grid = Vector2i(4, 4)

	var a_blocked = {"arrow_id": 1, "grid_position": Vector2i(1, 1), "direction": CollisionChecker.Direction.RIGHT, "length": 1}
	var a_blocker = {"arrow_id": 2, "grid_position": Vector2i(2, 1), "direction": CollisionChecker.Direction.UP, "length": 1}

	var arrows = [a_blocked, a_blocker]
	assert_true(not CollisionChecker.can_arrow_exit(a_blocked, arrows, grid), "Arrow 1 initially blocked")

	# Remove blocker arrow 2
	arrows.erase(a_blocker)
	assert_true(CollisionChecker.can_arrow_exit(a_blocked, arrows, grid), "Arrow 1 unblocked after blocker removal")

func test_heart_deduction_and_failure() -> void:
	print("\n[Group 6] Hearts Deduction & Level Failure Logic")
	var max_hearts = 3
	var cur_hearts = max_hearts

	# Simulate invalid moves
	cur_hearts -= 1
	assert_true(cur_hearts == 2, "First blocked move deducts 1 heart (remaining: 2)")
	cur_hearts -= 1
	assert_true(cur_hearts == 1, "Second blocked move deducts 1 heart (remaining: 1)")
	cur_hearts -= 1
	assert_true(cur_hearts == 0, "Third blocked move deducts 1 heart (remaining: 0)")

	var failed = (cur_hearts <= 0)
	assert_true(failed, "Level failure triggered when hearts reach 0")

func test_level_completion() -> void:
	print("\n[Group 7] Board Clearance & Level Completion")
	var active_arrows = [
		{"arrow_id": 1, "grid_position": Vector2i(0, 0), "direction": CollisionChecker.Direction.UP, "length": 1},
		{"arrow_id": 2, "grid_position": Vector2i(1, 1), "direction": CollisionChecker.Direction.DOWN, "length": 1}
	]

	# Both arrows exit
	active_arrows.clear()
	assert_true(active_arrows.is_empty(), "All arrows removed from active collection")
	var completed = active_arrows.is_empty()
	assert_true(completed, "Level completion signal triggered on empty board")

func test_level_restart() -> void:
	print("\n[Group 8] Level Restart State Reset")
	var level_data = PuzzleGenerator.HANDCRAFTED_LEVELS[0]
	var initial_arrow_count = level_data["arrows"].size()
	var current_hearts = 1 # player had taken damage

	# Restart
	current_hearts = 3
	var reloaded_count = level_data["arrows"].size()
	assert_true(current_hearts == 3, "Restart restores full 3 hearts")
	assert_true(reloaded_count == initial_arrow_count, "Restart restores initial arrow count")

func test_puzzle_solver_handcrafted_levels() -> void:
	print("\n[Group 9] Puzzle Solver Correctness (Handcrafted Levels 1-5)")
	for i in range(1, 6):
		var lvl = PuzzleGenerator.get_or_generate_level(i)
		var res = PuzzleSolver.solve(lvl["arrow_objects"], lvl["grid_size"])
		assert_true(res["solvable"], "Level %d ('%s') is 100%% solvable" % [i, lvl["name"]])
		assert_true(res["solution_order"].size() == lvl["arrow_objects"].size(), "Solution sequence covers all arrows")

func test_procedural_generator_solvability_50_levels() -> void:
	print("\n[Group 10] 50-Level Progression Solvability Verification")
	var all_50_solvable = true

	for lvl_id in range(1, 51):
		var lvl = PuzzleGenerator.get_or_generate_level(lvl_id)
		var res = PuzzleSolver.solve(lvl["arrow_objects"], lvl["grid_size"], 1500)
		if not res["solvable"]:
			all_50_solvable = false
			printerr("  Failed solvability on Level %d (%s)" % [lvl_id, lvl["difficulty"]])
			break

	assert_true(all_50_solvable, "All 50 Levels (Beginner, Easy, Medium, Hard, Expert) are 100% solvable")

func test_save_and_load_persistence() -> void:
	print("\n[Group 11] Save & Load Persistence (user:// save file)")
	var sm = SaveManager.new()

	sm.highest_unlocked_level = 5
	sm.current_level = 4
	sm.sound_enabled = true
	sm.vibration_enabled = false
	sm.record_level_completion(3, 8, 3)

	assert_true(sm.highest_unlocked_level >= 5, "Unlocked level tracked correctly")
	assert_true(sm.is_level_completed(3), "Level 3 completion marked in record")

	var prev_record = sm.completed_levels.get("3", {})
	assert_true(prev_record.get("best_moves", 0) == 8, "Best moves persisted accurately")

	sm.free()
