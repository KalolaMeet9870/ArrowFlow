extends SceneTree

## Dedicated Automated Test Suite: Arrow Clicks and Smooth User-Friendly Zoom/Pan Verification.

var passed_count: int = 0
var failed_count: int = 0

func _assert_test(condition: bool, test_name: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_count += 1
		printerr("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n==================================================================")
	print("  TEST: ARROW CLICK HIT DETECTION & SMOOTH USER-FRIENDLY ZOOM     ")
	print("==================================================================\n")

	# Setup GameScreen in real scene tree
	var gs = GameScreen.new()
	root.add_child(gs)
	for i in range(4):
		await process_frame

	var lvl1 = PuzzleGenerator.get_or_generate_level(1)
	gs.start_level(lvl1)
	for i in range(4):
		await process_frame

	var board = gs.board
	var board_holder = gs.board_holder

	print("[Group 1] Screen Hierarchy & Coordinate Mapping")
	_assert_test(board != null and is_instance_valid(board), "GameBoard exists in GameScreen")
	_assert_test(board_holder != null, "BoardHolder exists in GameScreen")
	_assert_test(board_holder.global_position.y > 50.0, "BoardHolder is offset by top header (y=%d)" % int(board_holder.global_position.y))

	# Verify coordinate conversion
	var test_holder_pos = Vector2(200, 300)
	var expected_local = board.transform.affine_inverse() * test_holder_pos
	var actual_local = board.holder_pos_to_local(test_holder_pos)
	_assert_test(actual_local.is_equal_approx(expected_local), "holder_pos_to_local converts accurately to board coordinates")

	print("\n[Group 2] Arrow Click Detection via Board Holder Events")
	# Find an arrow on board
	var arrow1: Arrow = null
	for a in board.active_arrows:
		if is_instance_valid(a) and a.arrow_id == 1:
			arrow1 = a
			break
	_assert_test(arrow1 != null, "Found Arrow ID 1 on board")

	# Target point of arrow 1 in holder coordinates
	var arrow1_holder_pos = board.local_to_holder_pos(arrow1.position)

	# Simulate touch down on arrow 1 via board_holder
	board.handle_holder_touch_down(arrow1_holder_pos, 0)
	_assert_test(board._held_arrow == arrow1, "Touch down on Arrow 1 selects Arrow 1 (held_arrow=1)")

	# Simulate micro finger wobble (under 12px) during touch move
	board.handle_holder_touch_move(arrow1_holder_pos + Vector2(6, 4), 0)
	_assert_test(board._held_arrow == arrow1, "Micro finger wobble does NOT cancel arrow selection")
	# Simulate touch up
	board.handle_holder_touch_up(arrow1_holder_pos + Vector2(6, 4), 0)
	_assert_test(board._held_arrow == null, "Touch up completes tap and clears held state")

	# Wait for blocked shake animation to finish (unlocking input)
	await create_timer(0.4).timeout
	_assert_test(not board.is_input_locked, "Board input unlocked after blocked feedback completes")

	print("\n[Group 3] Smooth User-Friendly Zoom & Hit Detection While Zoomed")
	_assert_test(board.current_zoom == 1.0, "Default zoom is 1.0x")

	# Smooth Zoom in to 1.85x
	board.set_target_zoom(1.85)
	await create_timer(0.3).timeout
	_assert_test(board.current_zoom >= 1.84, "Smooth zoom in reached target (got %.2fx)" % board.current_zoom)

	# Find another idle arrow
	var target_arrow: Arrow = null
	for a in board.active_arrows:
		if is_instance_valid(a) and a.state == Arrow.ArrowState.IDLE:
			target_arrow = a
			break
	_assert_test(target_arrow != null, "Found active target arrow while zoomed in")

	# Check hit testing when zoomed in
	var zoomed_holder_pos = board.local_to_holder_pos(target_arrow.position)
	board.handle_holder_touch_down(zoomed_holder_pos, 0)
	_assert_test(board._held_arrow == target_arrow, "Zoomed-in tap on arrow selects target arrow (ID=%d)" % target_arrow.arrow_id)
	board.handle_holder_touch_up(zoomed_holder_pos, 0)

	# Reset zoom and wait for shake animation to unlock
	board.reset_zoom()
	_assert_test(board.current_zoom == 1.0, "Reset zoom restores 1.0x immediately")
	await create_timer(0.4).timeout

	print("\n[Group 4] Rapid Arrow Tap Defense (No Accidental Zoom Hijack)")
	var arrow_candidate: Arrow = null
	for a in board.active_arrows:
		if is_instance_valid(a) and a.state == Arrow.ArrowState.IDLE:
			arrow_candidate = a
			break

	if arrow_candidate:
		var cand_holder_pos = board.local_to_holder_pos(arrow_candidate.position)
		# First tap
		board.handle_holder_touch_down(cand_holder_pos, 0)
		board.handle_holder_touch_up(cand_holder_pos, 0)
		# Immediate second tap 100ms later on same arrow (rapid tapping)
		board.handle_holder_touch_down(cand_holder_pos, 0)
		_assert_test(board.current_zoom == 1.0, "Rapid taps on arrow do NOT trigger double-tap zoom")
		board.handle_holder_touch_up(cand_holder_pos, 0)

	await create_timer(0.4).timeout

	print("\n[Group 5] Mobile Touch Emulation Deduplication (No Phantom Pinch)")
	var emu_arrow: Arrow = null
	for a in board.active_arrows:
		if is_instance_valid(a) and a.state == Arrow.ArrowState.IDLE:
			emu_arrow = a
			break

	if emu_arrow:
		var emu_holder_pos = board.local_to_holder_pos(emu_arrow.position)
		# Physical touch down (index 0)
		board.handle_holder_touch_down(emu_holder_pos, 0)
		_assert_test(not board._is_pinching, "Physical touch 0 does not trigger pinch")
		# Godot Android emulated mouse event (-1) in same frame
		board.handle_holder_touch_down(emu_holder_pos, -1)
		_assert_test(not board._is_pinching, "Emulated mouse down (-1) is deduplicated (no phantom pinch!)")
		_assert_test(board._touches.size() == 1, "Only physical touch 0 is retained in touch tracking")
		# Release touch
		board.handle_holder_touch_up(emu_holder_pos, 0)
		board.handle_holder_touch_up(emu_holder_pos, -1)
		_assert_test(not board._is_pinching, "Pinch is false after release")

	print("\n[Group 6] Floating Zoom Dock Controls ([ - ], [ 100% ⟲ ], [ + ])")
	var zoom_dock = gs.find_child("ZoomDock", true, false)
	_assert_test(zoom_dock != null, "ZoomDock control found in GameScreen")
	var zoom_margin = gs.find_child("ZoomMargin", true, false)
	_assert_test(zoom_margin != null, "ZoomMargin control found in GameScreen")
	if zoom_margin:
		_assert_test(zoom_margin.grow_horizontal == Control.GROW_DIRECTION_BEGIN, "ZoomMargin grows leftwards into screen")
		_assert_test(zoom_margin.grow_vertical == Control.GROW_DIRECTION_BEGIN, "ZoomMargin grows upwards into screen")

	# Test Zoom In via board
	board.zoom_in(1.25)
	await create_timer(0.2).timeout
	_assert_test(board.current_zoom > 1.15, "zoom_in() smoothly zoomed in")

	# Test Zoom Out via board
	board.zoom_out(1.25)
	await create_timer(0.2).timeout
	_assert_test(board.current_zoom < 1.15, "zoom_out() smoothly zoomed out")

	# Test Smooth Reset Zoom
	board.set_target_zoom(2.0)
	await create_timer(0.2).timeout
	board.smooth_reset_zoom()
	await create_timer(0.25).timeout
	_assert_test(board.current_zoom <= 1.05, "smooth_reset_zoom() returned to 100%")

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % passed_count)
	print("  Failed: %d" % failed_count)
	print("-------------------------------------------------------")
	if failed_count == 0:
		print(">>> ALL ARROW CLICK & ZOOM TESTS PASSED! <<<\n")

	quit(0 if failed_count == 0 else 1)
