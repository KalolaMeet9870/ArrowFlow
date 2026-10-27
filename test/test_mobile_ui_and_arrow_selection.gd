extends SceneTree

## Dedicated automated test suite for Mobile UI, Safe Areas, and Arrow Selection Bugs.
## Validates all requirements from the prompt.

const SafeAreaHelper = preload("res://scripts/safe_area_helper.gd")
const GameScreen = preload("res://scripts/game_screen.gd")
const GameBoard = preload("res://scripts/game_board.gd")
const Arrow = preload("res://scripts/arrow.gd")

func _init() -> void:
	print("==================================================================")
	print("  TEST: MOBILE UI DESIGN, SAFE AREAS, AND ARROW SELECTION BUGS   ")
	print("==================================================================")

	var counters = {"passed": 0, "failed": 0}

	var test_assert = func(cond: bool, msg: String):
		if cond:
			print("  [PASS] %s" % msg)
			counters["passed"] += 1
		else:
			printerr("  [FAIL] %s" % msg)
			counters["failed"] += 1

	# -------------------------------------------------------------
	# GROUP 1: Professional Mobile UI and Safe Areas
	# -------------------------------------------------------------
	print("\n[Group 1] Safe Areas, Notches, Status Bar & Home Indicator Spacing")
	var insets = SafeAreaHelper.get_safe_insets(null)
	test_assert.call(insets["top"] >= 48.0, "Top safe margin (%.1fpx) clears mobile status bar / notch / Dynamic Island" % insets["top"])
	test_assert.call(insets["bottom"] >= 28.0, "Bottom safe margin (%.1fpx) clears home indicator / navigation bar" % insets["bottom"])
	test_assert.call(insets["left"] >= 16.0, "Left safe margin (%.1fpx) provides proper screen padding" % insets["left"])
	test_assert.call(insets["right"] >= 16.0, "Right safe margin (%.1fpx) provides proper screen padding" % insets["right"])

	var game_screen_scene = preload("res://scenes/screens/GameScreen.tscn")
	var game_screen = game_screen_scene.instantiate()
	root.add_child(game_screen)
	await process_frame
	await process_frame

	test_assert.call(game_screen.safe_margin_container != null, "GameScreen contains safe_margin_container")
	var top_m = game_screen.safe_margin_container.get_theme_constant("margin_top")
	var bot_m = game_screen.safe_margin_container.get_theme_constant("margin_bottom")
	test_assert.call(top_m >= 48, "GameScreen top margin (%dpx) respects status bar safe area" % top_m)
	test_assert.call(bot_m >= 28, "GameScreen bottom margin (%dpx) respects home indicator safe area" % bot_m)

	# -------------------------------------------------------------
	# GROUP 2: Responsive Centering & Square Aspect Ratio Across Devices
	# -------------------------------------------------------------
	print("\n[Group 2] Responsive Centering on Diverse Screen Aspect Ratios")
	var test_resolutions = [
		{"name": "iPhone 14/15 Pro (19.5:9)", "size": Vector2(393, 852)},
		{"name": "Standard Android HD (16:9)", "size": Vector2(720, 1280)},
		{"name": "Tall Android (20:9)", "size": Vector2(412, 915)},
		{"name": "iPad / Tablet (4:3)", "size": Vector2(768, 1024)},
		{"name": "Ultra-Wide Foldable (21:9)", "size": Vector2(480, 1120)}
	]

	var gb = GameBoard.new()
	root.add_child(gb)

	for res in test_resolutions:
		var board_avail = res["size"] * Vector2(0.9, 0.72)
		gb.update_board_size(board_avail)
		var is_square = (gb.board_pixel_w == gb.board_pixel_h)
		var is_centered_x = gb.board_origin.x >= 0 and absf(gb.board_origin.x - (board_avail.x - gb.board_pixel_w) * 0.5) < 2.0
		var is_centered_y = gb.board_origin.y >= 0 and absf(gb.board_origin.y - (board_avail.y - gb.board_pixel_h) * 0.5) < 2.0
		var fits = (gb.board_origin.x + gb.board_pixel_w <= board_avail.x) and (gb.board_origin.y + gb.board_pixel_h <= board_avail.y)

		test_assert.call(is_square, "%s: Puzzle grid is strictly square (%.0fx%.0f)" % [res["name"], gb.board_pixel_w, gb.board_pixel_h])
		test_assert.call(is_centered_x and is_centered_y, "%s: Puzzle is centered at %s within area %s" % [res["name"], gb.board_origin, board_avail])
		test_assert.call(fits, "%s: Entire puzzle stays within visible safe content boundaries without clipping" % res["name"])

	gb.queue_free()

	# -------------------------------------------------------------
	# GROUP 3: Exact Arrow Selection & Hit Detection (Horizontal, Vertical, L-Shaped, 1-Cell)
	# -------------------------------------------------------------
	print("\n[Group 3] Exact Arrow Selection & Hit Detection")
	var board = GameBoard.new()
	root.add_child(board)

	# Setup a comprehensive test layout on a 6x6 grid:
	# Arrow 1: Horizontal straight arrow at row 1, cols 1..3 (tail (1,1), head (3,1), dir RIGHT)
	# Arrow 2: Neighbor parallel horizontal arrow at row 0, cols 1..3 (tail (1,0), head (3,0), dir RIGHT)
	# Arrow 3: Vertical straight arrow at col 5, rows 1..4 (tail (5,1), head (5,4), dir DOWN)
	# Arrow 4: L-shaped arrow: tail (4, 4), corner (4, 2), head (2, 2), dir LEFT
	# Arrow 5: 1-cell arrow at (0, 3) pointing UP
	var test_level_data = {
		"id": 101,
		"grid_size": Vector2i(6, 6),
		"arrow_objects": [
			{
				"arrow_id": 1,
				"grid_position": Vector2i(1, 1),
				"head_cell": Vector2i(3, 1),
				"direction": CollisionChecker.Direction.RIGHT,
				"length": 3,
				"occupied_cells": [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
				"points": [Vector2(1, 1), Vector2(3, 1)]
			},
			{
				"arrow_id": 2,
				"grid_position": Vector2i(1, 0),
				"head_cell": Vector2i(3, 0),
				"direction": CollisionChecker.Direction.RIGHT,
				"length": 3,
				"occupied_cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
				"points": [Vector2(1, 0), Vector2(3, 0)]
			},
			{
				"arrow_id": 3,
				"grid_position": Vector2i(5, 1),
				"head_cell": Vector2i(5, 4),
				"direction": CollisionChecker.Direction.DOWN,
				"length": 4,
				"occupied_cells": [Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4)],
				"points": [Vector2(5, 1), Vector2(5, 4)]
			},
			{
				"arrow_id": 4,
				"grid_position": Vector2i(4, 4),
				"head_cell": Vector2i(2, 2),
				"direction": CollisionChecker.Direction.LEFT,
				"length": 5,
				"occupied_cells": [Vector2i(4, 4), Vector2i(4, 3), Vector2i(4, 2), Vector2i(3, 2), Vector2i(2, 2)],
				"points": [Vector2(4, 4), Vector2(4, 2), Vector2(2, 2)]
			},
			{
				"arrow_id": 5,
				"grid_position": Vector2i(0, 3),
				"head_cell": Vector2i(0, 3),
				"direction": CollisionChecker.Direction.UP,
				"length": 1,
				"occupied_cells": [Vector2i(0, 3)],
				"points": []
			}
		]
	}

	board.setup_level(test_level_data, Vector2(600, 600))
	var c_sz = board.cell_size
	var origin = board.board_origin

	# Helper to convert grid coord to board local position
	var to_board_pt = func(g_pos: Vector2) -> Vector2:
		return origin + g_pos * c_sz

	# Test 3.1: Tap directly on Arrow 1 (Horizontal)
	var pt_arrow1 = to_board_pt.call(Vector2(2.0, 1.0)) # center of middle cell of Arrow 1
	var sel_1 = board.get_arrow_at_local_pos(pt_arrow1)
	test_assert.call(sel_1 != null and sel_1.arrow_id == 1, "Tapping Arrow 1 selects Arrow 1 (ID=%d)" % (sel_1.arrow_id if sel_1 else 0))

	# Test 3.2: Tap neighbor Arrow 2 (only 1 cell above Arrow 1)
	var pt_arrow2 = to_board_pt.call(Vector2(2.0, 0.0))
	var sel_2 = board.get_arrow_at_local_pos(pt_arrow2)
	test_assert.call(sel_2 != null and sel_2.arrow_id == 2, "Tapping neighbor Arrow 2 selects Arrow 2 (ID=%d), not Arrow 1" % (sel_2.arrow_id if sel_2 else 0))

	# Test 3.3: Tap slightly below Arrow 2 (at Y = 0.25, closer to Arrow 2 than Arrow 1 at Y=1.0)
	var pt_near_2 = to_board_pt.call(Vector2(2.0, 0.2))
	var sel_near_2 = board.get_arrow_at_local_pos(pt_near_2)
	test_assert.call(sel_near_2 != null and sel_near_2.arrow_id == 2, "Tapping near Arrow 2 correctly selects Arrow 2 without selecting Arrow 1")

	# Test 3.4: Tap slightly above Arrow 1 (at Y = 0.8, closer to Arrow 1 than Arrow 2 at Y=0.0)
	var pt_near_1 = to_board_pt.call(Vector2(2.0, 0.8))
	var sel_near_1 = board.get_arrow_at_local_pos(pt_near_1)
	test_assert.call(sel_near_1 != null and sel_near_1.arrow_id == 1, "Tapping near Arrow 1 correctly selects Arrow 1 without selecting Arrow 2")

	# Test 3.5: Tap Vertical Arrow 3
	var pt_arrow3 = to_board_pt.call(Vector2(5.0, 2.5))
	var sel_3 = board.get_arrow_at_local_pos(pt_arrow3)
	test_assert.call(sel_3 != null and sel_3.arrow_id == 3, "Tapping vertical Arrow 3 selects Arrow 3 (ID=%d)" % (sel_3.arrow_id if sel_3 else 0))

	# Test 3.6: Tap L-shaped Arrow 4 on its vertical segment (x=4, y=3)
	var pt_l_vert = to_board_pt.call(Vector2(4.0, 3.2))
	var sel_l_vert = board.get_arrow_at_local_pos(pt_l_vert)
	test_assert.call(sel_l_vert != null and sel_l_vert.arrow_id == 4, "Tapping L-shaped arrow on vertical segment selects Arrow 4 (ID=%d)" % (sel_l_vert.arrow_id if sel_l_vert else 0))

	# Test 3.7: Tap L-shaped Arrow 4 on its horizontal segment (x=3.2, y=2)
	var pt_l_horiz = to_board_pt.call(Vector2(3.2, 2.0))
	var sel_l_horiz = board.get_arrow_at_local_pos(pt_l_horiz)
	test_assert.call(sel_l_horiz != null and sel_l_horiz.arrow_id == 4, "Tapping L-shaped arrow on horizontal segment selects Arrow 4 (ID=%d)" % (sel_l_horiz.arrow_id if sel_l_horiz else 0))

	# Test 3.8: Tap L-shaped Arrow 4 directly on its 90-degree corner (x=4, y=2)
	var pt_l_corner = to_board_pt.call(Vector2(4.0, 2.0))
	var sel_l_corner = board.get_arrow_at_local_pos(pt_l_corner)
	test_assert.call(sel_l_corner != null and sel_l_corner.arrow_id == 4, "Tapping L-shaped arrow on corner selects Arrow 4 (ID=%d)" % (sel_l_corner.arrow_id if sel_l_corner else 0))

	# Test 3.9: Tap 1-cell Arrow 5 at (0, 3)
	var pt_arrow5 = to_board_pt.call(Vector2(0.0, 3.0))
	var sel_5 = board.get_arrow_at_local_pos(pt_arrow5)
	test_assert.call(sel_5 != null and sel_5.arrow_id == 5, "Tapping 1-cell Arrow 5 selects Arrow 5 (ID=%d)" % (sel_5.arrow_id if sel_5 else 0))

	# Test 3.10: Tap in empty space (e.g. at (0, 5) where no arrows exist)
	var pt_empty = to_board_pt.call(Vector2(0.0, 5.0))
	var sel_empty = board.get_arrow_at_local_pos(pt_empty)
	test_assert.call(sel_empty == null, "Tapping in empty space does not accidentally select any arrow (result: null)")

	# -------------------------------------------------------------
	# GROUP 4: Arrow Movement, Collision Checking & Path Clearance
	# -------------------------------------------------------------
	print("\n[Group 4] Collision Checking & Path Clearance")
	# Arrow 1 is at (1..3, 1) pointing RIGHT. Col 4 is empty, Col 5 is occupied by Arrow 3 at (5, 1)!
	# Therefore, Arrow 1's exit path to boundary is BLOCKED by Arrow 3 at (5, 1)!
	var occ_map = CollisionChecker.build_occupancy_map(board.active_arrows)
	var arrow1_node: Arrow = null
	var arrow2_node: Arrow = null
	var arrow5_node: Arrow = null
	for a in board.active_arrows:
		if a.arrow_id == 1: arrow1_node = a
		if a.arrow_id == 2: arrow2_node = a
		if a.arrow_id == 5: arrow5_node = a

	test_assert.call(not CollisionChecker.can_arrow_exit_with_map(arrow1_node, occ_map, board.grid_size), "Arrow 1 forward path is correctly detected as BLOCKED by Arrow 3")
	test_assert.call(CollisionChecker.can_arrow_exit_with_map(arrow2_node, occ_map, board.grid_size), "Arrow 2 forward path is CLEAR to the right boundary")
	test_assert.call(CollisionChecker.can_arrow_exit_with_map(arrow5_node, occ_map, board.grid_size), "Arrow 5 (1-cell pointing UP) forward path is CLEAR to top boundary")

	# Execute tap on blocked Arrow 1
	var move_failed_emitted = [false]
	board.move_failed.connect(func(_a): move_failed_emitted[0] = true)
	board.handle_touch_down_local(pt_arrow1, 0)
	board.handle_touch_up_local(pt_arrow1, 0)
	await process_frame

	test_assert.call(move_failed_emitted[0], "Tapping blocked Arrow 1 triggers move_failed")
	test_assert.call(arrow1_node in board.active_arrows, "Blocked Arrow 1 remains in place on the board")

	# Wait for blocked shake animation (0.36s) to complete
	await create_timer(0.45).timeout

	test_assert.call(arrow1_node.position == origin + Vector2(1, 1) * c_sz, "Blocked Arrow 1 coordinates return to original position after shake")
	test_assert.call(not board.is_input_locked, "Input lock released after blocked feedback completes")

	# -------------------------------------------------------------
	# GROUP 5: Clear Arrow Exit & Dynamic Unblocking
	# -------------------------------------------------------------
	print("\n[Group 5] Clear Arrow Exit & Dynamic State Updates")
	var move_succeeded_emitted = [false]
	board.move_succeeded.connect(func(_a): move_succeeded_emitted[0] = true)
	board.handle_touch_down_local(pt_arrow2, 0)
	board.handle_touch_up_local(pt_arrow2, 0)
	await process_frame

	test_assert.call(move_succeeded_emitted[0], "Tapping clear Arrow 2 triggers move_succeeded")
	test_assert.call(not (arrow2_node in board.active_arrows), "Arrow 2 removed from active collection immediately upon launching")

	# Wait for exit tween animation (0.36s) to finish
	await create_timer(0.45).timeout

	test_assert.call(not board.is_input_locked, "Board input unlocked after exit completion")
	test_assert.call(board.active_arrows.size() == 4, "Remaining arrow count is now exactly 4")

	# -------------------------------------------------------------
	# GROUP 6: Deduplication & Multi-Touch Prevention
	# -------------------------------------------------------------
	print("\n[Group 6] Duplicate Input Event Deduplication & Rapid Tap Defense")
	# Tap Arrow 5 (1-cell arrow) with simulated dual touch + mouse event (same tap)
	var pt_arr5 = to_board_pt.call(Vector2(0.0, 3.0))
	var exit_tracker = [0]
	board.move_succeeded.connect(func(_a): exit_tracker[0] += 1)

	# 1. ScreenTouch pressed
	board.handle_touch_down_local(pt_arr5, 1)
	# 2. Emulated MouseButton pressed simultaneously (pointer -1, within 60ms)
	board.handle_touch_down_local(pt_arr5, -1)
	# 3. ScreenTouch released
	board.handle_touch_up_local(pt_arr5, 1)
	# 4. Emulated MouseButton released simultaneously
	board.handle_touch_up_local(pt_arr5, -1)
	await process_frame

	test_assert.call(exit_tracker[0] == 1, "Simultaneous touch + emulated mouse events trigger exactly 1 exit (count=%d)" % exit_tracker[0])

	# Wait for animation to finish
	await create_timer(0.45).timeout

	board.queue_free()
	game_screen.queue_free()

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % counters["passed"])
	print("  Failed: %d" % counters["failed"])
	print("-------------------------------------------------------")
	if counters["failed"] == 0:
		print(">>> ALL MOBILE UI & ARROW SELECTION TESTS PASSED! <<<\n")
		quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
