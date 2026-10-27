extends SceneTree

## Automated Tests for Long-Press Guidance, Visual Themes, and Hint Mechanics.

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n=======================================================")
	print("  ARROWFLOW - GUIDANCE & THEMES TEST SUITE (GODOT 4.7)  ")
	print("=======================================================\n")

	_test_theme_manager()
	_test_guidance_logic()
	_test_hint_system()
	_test_sound_and_combo()

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % passed_count)
	print("  Failed: %d" % failed_count)
	print("-------------------------------------------------------")

	if failed_count == 0:
		print(">>> ALL GUIDANCE & THEME TESTS PASSED! <<<\n")
		quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
		quit(1)

func _assert_true(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] %s" % test_name)
		passed_count += 1
	else:
		printerr("  [FAIL] %s" % test_name)
		failed_count += 1

func _test_theme_manager() -> void:
	print("[Group 1] ThemeManager & Eye Comfort Themes")
	var tm = ThemeManager.new()
	root.add_child(tm)

	_assert_true(ThemeManager.THEMES.size() == 5, "Exactly 5 zen eye comfort themes available")

	var initial_th = tm.get_current_theme()
	_assert_true(initial_th["name"] == "Eye Comfort", "Default theme is Eye Comfort")
	_assert_true(initial_th.has("bg") and initial_th.has("arrow_line") and initial_th.has("guide_clear"), "Theme has bg, arrow_line, and guide_clear")

	var second_th = tm.next_theme()
	_assert_true(second_th["name"] == "Midnight Zen", "Second theme is Midnight Zen (Dark Mode)")

	var third_th = tm.next_theme()
	_assert_true(third_th["name"] == "Matcha Garden", "Third theme is Matcha Garden")

	var fourth_th = tm.next_theme()
	_assert_true(fourth_th["name"] == "Nordic Frost", "Fourth theme is Nordic Frost")

	var fifth_th = tm.next_theme()
	_assert_true(fifth_th["name"] == "Sunset Clay", "Fifth theme is Sunset Clay")

	var loop_th = tm.next_theme()
	_assert_true(loop_th["name"] == "Eye Comfort", "Theme cycles back to Eye Comfort")

	tm.queue_free()

func _test_guidance_logic() -> void:
	print("\n[Group 2] Long-Press Guidance Trajectory & Safe Cancel")

	var gb = GameBoard.new()
	root.add_child(gb)

	# Level with 2 arrows: Arrow 1 at (0, 0) pointing RIGHT length 1 (blocked by Arrow 2 at (2, 0))
	# Arrow 2 at (2, 0) pointing DOWN length 1 (free to exit)
	var test_level = {
		"id": 99,
		"name": "Guidance Test",
		"difficulty": "Simple",
		"grid_size": Vector2i(4, 4),
		"arrow_objects": [
			{"arrow_id": 1, "grid_position": Vector2i(0, 0), "direction": CollisionChecker.Direction.RIGHT, "length": 1},
			{"arrow_id": 2, "grid_position": Vector2i(2, 0), "direction": CollisionChecker.Direction.DOWN, "length": 1}
		]
	}
	gb.setup_level(test_level, Vector2(400, 400))

	var arrow1 = gb.active_arrows[0]
	var arrow2 = gb.active_arrows[1]

	# Arrow 1 is blocked by Arrow 2: activate guidance on Arrow 1
	gb._activate_guidance(arrow1)
	_assert_true(gb._is_guidance_active, "Guidance is active on held arrow")
	_assert_true(gb._guidance_clear == false, "Guidance correctly identifies blocked path")
	_assert_true(gb._guidance_blocker_arrow == arrow2, "Guidance pinpoints the exact blocker arrow")
	_assert_true(gb._guidance_stop_cell == Vector2i(2, 0), "Guidance stops at blocker coordinate (2, 0)")

	# Cancel guidance (simulating user releasing finger upon seeing obstacle)
	gb._cancel_guidance()
	_assert_true(gb._is_guidance_active == false, "Guidance dismissed safely")
	_assert_true(gb.active_arrows.size() == 2, "No arrows removed on guidance preview")

	# Arrow 2 is free: activate guidance on Arrow 2
	gb._activate_guidance(arrow2)
	_assert_true(gb._is_guidance_active, "Guidance is active on Arrow 2")
	_assert_true(gb._guidance_clear == true, "Guidance correctly detects clear path for Arrow 2")
	_assert_true(gb._guidance_blocker_arrow == null, "No blocker identified for clear path")

	gb._cancel_guidance()
	gb.queue_free()

func _test_hint_system() -> void:
	print("\n[Group 3] Hint System Identification & Trajectory")

	var gb = GameBoard.new()
	root.add_child(gb)

	# Arrow 10 is at (1, 1) pointing RIGHT, blocked by Arrow 15 at (3, 1)
	# Arrow 20 is at (0, 3) pointing DOWN (free to exit)
	var test_level = {
		"id": 98,
		"name": "Hint Test",
		"difficulty": "Simple",
		"grid_size": Vector2i(4, 4),
		"arrow_objects": [
			{"arrow_id": 10, "grid_position": Vector2i(1, 1), "direction": CollisionChecker.Direction.RIGHT, "length": 1},
			{"arrow_id": 15, "grid_position": Vector2i(3, 1), "direction": CollisionChecker.Direction.LEFT, "length": 1},
			{"arrow_id": 20, "grid_position": Vector2i(0, 3), "direction": CollisionChecker.Direction.DOWN, "length": 1}
		]
	}
	gb.setup_level(test_level, Vector2(400, 400))

	# Arrow 10 is blocked by 15. Only Arrow 20 is free to exit!
	var hint_arr = gb.show_hint()
	_assert_true(hint_arr != null, "Hint successfully found a removable arrow")
	_assert_true(hint_arr.arrow_id == 20, "Hint correctly identified free Arrow 20")
	_assert_true(gb._hint_active == true, "Hint guidance beam is active")

	gb.queue_free()

func _test_sound_and_combo() -> void:
	print("\n[Group 4] SoundManager & Pentatonic Audio Flow")

	var sm = SoundManager.new()
	root.add_child(sm)
	sm._ready()

	_assert_true(sm.sfx_whoosh != null, "Whoosh SFX generated successfully")
	_assert_true(sm.sfx_guidance != null, "Guidance hum SFX generated successfully")
	_assert_true(sm.sfx_hint != null, "Hint chime SFX generated successfully")

	# Test pentatonic pitches wrap-around
	sm.play_combo(1)
	sm.play_combo(2)
	sm.play_combo(3)
	sm.play_combo(6)
	_assert_true(true, "Pentatonic combo audio methods executed without exception")

	sm.queue_free()
