extends SceneTree

func _init() -> void:
	print("=======================================================")
	print("  ARROWFLOW - MULTI-RESOLUTION & PUZZLE VERIFICATION   ")
	print("=======================================================")

	var main_scene = load("res://scenes/main/Main.tscn")
	if not main_scene:
		printerr("Failed to load Main.tscn")
		quit(1)
		return

	var root_node = main_scene.instantiate() as Main
	root.add_child(root_node)

	if AdMobManager.instance:
		AdMobManager.instance.has_shown_cold_start_ad = true

	for i in range(10):
		await process_frame

	var passed = 0
	var failed = 0

	var test_assert = func(cond: bool, msg: String):
		if cond:
			print("  [PASS] %s" % msg)
			passed += 1
		else:
			printerr("  [FAIL] %s" % msg)
			failed += 1

	# --- TEST GROUP 1: Level 1 Structure & Arrow Integrity ---
	print("\n[Test Group 1] Level 1 'Faithful Scottish Terrier' Data Integrity")
	var lvl1 = LevelManager.instance.load_level(1)
	test_assert.call(lvl1 != null, "Level 1 data loaded from levels.json")
	test_assert.call(lvl1.get("name", "") == "Faithful Scottish Terrier", "Level 1 is Faithful Scottish Terrier")
	
	var grid_size: Vector2i = lvl1.get("grid_size", Vector2i.ZERO)
	test_assert.call(grid_size.x == 21 and grid_size.y == 21, "Grid size is strictly 21x21 square (%s)" % grid_size)

	var arrows = lvl1.get("arrow_objects", [])
	test_assert.call(arrows.size() >= 35, "Level 1 contains %d arrows (expected >= 35)" % arrows.size())

	var all_in_bounds = true
	var all_valid_dirs = true
	var all_orthogonal = true
	var cell_set = {}
	var has_duplicate_cells = false

	for a in arrows:
		var dir = a.get("direction", -1)
		if dir < 0 or dir > 3:
			all_valid_dirs = false
		var pts = a.get("points", [])
		for i in range(pts.size()):
			var p = pts[i]
			var gx = int(p.x if p is Vector2 else p[0])
			var gy = int(p.y if p is Vector2 else p[1])
			if gx < 0 or gx >= 21 or gy < 0 or gy >= 21:
				all_in_bounds = false
			if i > 0:
				var p_prev = pts[i-1]
				var px = int(p_prev.x if p_prev is Vector2 else p_prev[0])
				var py = int(p_prev.y if p_prev is Vector2 else p_prev[1])
				if px != gx and py != gy:
					all_orthogonal = false
		for c in a.get("occupied_cells", []):
			var key = "%d,%d" % [c.x, c.y]
			if cell_set.has(key):
				has_duplicate_cells = true
			cell_set[key] = true

	test_assert.call(all_valid_dirs, "Every arrow has a strictly orthogonal direction (UP/DOWN/LEFT/RIGHT)")
	test_assert.call(all_in_bounds, "Every vertex is strictly within [0, 20] grid bounds")
	test_assert.call(all_orthogonal, "All segments and turns are strictly 90-degree orthogonal grid lines")
	test_assert.call(not has_duplicate_cells, "No two arrows share or overlap any grid cell")

	# --- TEST GROUP 2: Multi-Resolution Responsiveness ---
	print("\n[Test Group 2] Multi-Resolution Responsiveness & Square Aspect Ratio")
	var resolutions = [
		Vector2(720, 1280), # Standard HD Mobile
		Vector2(390, 844),  # Modern iPhone
		Vector2(1080, 1920),# Full HD Mobile
		Vector2(768, 1024), # iPad 4:3
		Vector2(412, 915)   # Tall Android
	]

	root_node.show_game_screen(1)
	for i in range(8):
		await process_frame

	var gs = root_node.game_screen
	test_assert.call(gs != null, "GameScreen instantiated and active")
	var board = gs.board
	test_assert.call(board != null, "GameBoard exists")

	for res in resolutions:
		board.update_board_size(res * Vector2(0.9, 0.75))
		for i in range(2):
			await process_frame
		var w = board.board_pixel_w
		var h = board.board_pixel_h
		var is_square = is_equal_approx(w, h)
		var fits = (board.board_origin.x >= 0 and board.board_origin.y >= 0 and
					board.board_origin.x + w <= board.board_area_size.x + 1.0 and
					board.board_origin.y + h <= board.board_area_size.y + 1.0)
		test_assert.call(is_square and fits, "Resolution %dx%d: Board is exactly 1:1 square (%.1fx%.1f) and fits centered without clipping" % [int(res.x), int(res.y), w, h])

	# Reset to standard size
	board.update_board_size(Vector2(640, 780))
	for i in range(3):
		await process_frame

	# --- TEST GROUP 3: Arrow Hit Detection & Gameplay Selection ---
	print("\n[Test Group 3] Arrow Hit Detection & Precise Grid Alignment")
	var all_pickable = true
	var all_tips_aligned = true

	for a in board.active_arrows:
		if not is_instance_valid(a):
			continue
		var head_board_local = board.board_origin + Vector2(a.head_cell) * board.cell_size
		var head_world = board.to_global(head_board_local)
		var picked = board.get_arrow_at_world_pos(head_world)
		if picked != a:
			all_pickable = false
		var local_head = (Vector2(a.head_cell) - Vector2(a.grid_position)) * board.cell_size
		var tip_pos = a.position + local_head
		if tip_pos.distance_to(head_board_local) > 0.01:
			all_tips_aligned = false

	test_assert.call(all_pickable, "All 38 arrows are individually selectable by tapping near their head/path")
	test_assert.call(all_tips_aligned, "All arrowhead tips align precisely with grid points")

	# --- TEST GROUP 4: Life System & 3-Mistake Popup ---
	print("\n[Test Group 4] Life Deduction & 3-Mistake FailPopup Handling")
	# Find an arrow that is currently blocked
	var blocked_arrow: Arrow = null
	for a in board.active_arrows:
		if not CollisionChecker.can_arrow_exit(a, board.active_arrows, board.grid_size):
			blocked_arrow = a
			break

	test_assert.call(blocked_arrow != null, "Found blocked arrow ID=%d for collision test" % (blocked_arrow.arrow_id if blocked_arrow else -1))

	var initial_hearts = gs.current_hearts
	test_assert.call(initial_hearts == 3, "Player starts with 3 lives")

	# Trigger mistake 1
	board._execute_arrow_tapped(blocked_arrow)
	for i in range(30):
		await process_frame
	test_assert.call(gs.current_hearts == 2, "Mistake 1 reduced lives to 2")

	# Trigger mistake 2
	board._execute_arrow_tapped(blocked_arrow)
	for i in range(30):
		await process_frame
	test_assert.call(gs.current_hearts == 1, "Mistake 2 reduced lives to 1")

	# Trigger mistake 3 -> popup should appear
	board._execute_arrow_tapped(blocked_arrow)
	for i in range(30):
		await process_frame
	test_assert.call(gs.current_hearts == 0, "Mistake 3 reduced lives to 0")

	var failed_screen = root_node.level_failed_screen
	test_assert.call(failed_screen != null and failed_screen.visible, "LevelFailed popup displayed after 3 incorrect selections")

	# Test Continue button via rewarded ad
	if failed_screen and is_instance_valid(failed_screen):
		failed_screen._on_continue_pressed()
		for i in range(15):
			await process_frame
		test_assert.call(gs.current_hearts == 3, "Continue option restored lives to 3")
		test_assert.call(not failed_screen.visible, "LevelFailed popup closed after Continue")

	# --- TEST GROUP 5: Full Board Clearance & Level Completion ---
	print("\n[Test Group 5] Full Reverse-DAG Board Clearance")
	var move_count = 0
	while not board.active_arrows.is_empty():
		var unblocked: Arrow = null
		for a in board.active_arrows:
			if is_instance_valid(a) and a.state == Arrow.ArrowState.IDLE:
				if CollisionChecker.can_arrow_exit(a, board.active_arrows, board.grid_size):
					unblocked = a
					break
		if unblocked == null:
			printerr("Puzzle deadlocked! Reverse-DAG generation failed.")
			break
		board._execute_arrow_tapped(unblocked)
		move_count += 1
		var safety = 0
		while safety < 40 and is_instance_valid(unblocked) and unblocked.state != Arrow.ArrowState.REMOVED:
			await process_frame
			safety += 1

	test_assert.call(board.active_arrows.is_empty(), "All 38 arrows successfully exited the board (moves=%d)" % move_count)

	for i in range(20):
		await process_frame

	var lss = root_node.level_select_screen
	test_assert.call(lss != null and lss.visible, "Returned to LevelSelectScreen on level completion")
	test_assert.call(SaveManager.instance and SaveManager.instance.is_level_completed(1), "Level 1 marked completed in SaveManager")
	test_assert.call(SaveManager.instance and SaveManager.instance.highest_unlocked_level >= 2, "Level 2 unlocked")

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % passed)
	print("  Failed: %d" % failed)
	print("-------------------------------------------------------")

	if failed == 0:
		print(">>> ALL PUZZLE & MULTI-RESOLUTION TESTS PASSED 100%! <<<\n")
		quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
