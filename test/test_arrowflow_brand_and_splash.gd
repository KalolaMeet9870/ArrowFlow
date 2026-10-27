extends SceneTree

## Verification Suite: ArrowFlow Brand, App Icon, Splash Screen & In-Game UI.

var passed: int = 0
var failed: int = 0

func _init() -> void:
	print("\n==================================================================")
	print("  TEST: ARROWFLOW BRAND, APP LOGO, SPLASH SCREEN & IN-GAME UI    ")
	print("==================================================================\n")

	await _test_project_settings_and_branding()
	await _test_splash_screen()
	await _test_ingame_screen_and_undo()

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % passed)
	print("  Failed: %d" % failed)
	print("-------------------------------------------------------")
	if failed == 0:
		print(">>> ALL ARROWFLOW BRAND & SPLASH SCREEN TESTS PASSED! <<<\n")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<\n")
		quit(1)

func _assert_test(cond: bool, test_name: String) -> void:
	if cond:
		passed += 1
		print("  [PASS] %s" % test_name)
	else:
		failed += 1
		printerr("  [FAIL] %s" % test_name)

func _test_project_settings_and_branding() -> void:
	print("[Group 1] Project Settings, Brand Name & Icon Configurations")

	var app_name = ProjectSettings.get_setting("application/config/name")
	_assert_test(app_name == "ArrowFlow", "App name is properly set to 'ArrowFlow' (got '%s')" % app_name)

	var icon_path = ProjectSettings.get_setting("application/config/icon")
	_assert_test(icon_path == "res://icon.png", "App icon is properly set to 'res://icon.png' (got '%s')" % icon_path)
	_assert_test(FileAccess.file_exists("res://icon.png"), "icon.png file exists on disk")

	var boot_splash = ProjectSettings.get_setting("application/boot_splash/image")
	_assert_test(boot_splash == "res://assets/splash/boot_splash.png", "Boot splash image is set to 'res://assets/splash/boot_splash.png'")
	_assert_test(FileAccess.file_exists("res://assets/splash/boot_splash.png"), "boot_splash.png exists on disk")

	var splash_bg = "res://assets/splash/splash_bg_waves.png"
	_assert_test(FileAccess.file_exists(splash_bg), "splash_bg_waves.png exists on disk")

	var floating_card = "res://assets/icons/app_card_floating.png"
	_assert_test(FileAccess.file_exists(floating_card), "app_card_floating.png exists on disk")

func _test_splash_screen() -> void:
	print("\n[Group 2] Splash Screen Layout, Safe Areas & Progression")

	var splash_scene = preload("res://scenes/screens/SplashScreen.tscn")
	_assert_test(splash_scene != null, "SplashScreen.tscn is loaded successfully")

	var splash = splash_scene.instantiate() as SplashScreen
	root.add_child(splash)

	for i in range(3):
		await process_frame

	_assert_test(splash.safe_margin != null, "SplashScreen contains safe_margin MarginContainer")
	_assert_test(splash.icon_rect != null and splash.icon_rect.texture != null, "App icon texture is loaded into TextureRect")
	_assert_test(splash.progress_bar != null, "Loading ProgressBar exists")
	_assert_test(splash.lbl_loading != null, "Loading status label exists")

	# Wait for loading animation to complete
	var finished_signal_emitted = [false]
	splash.splash_finished.connect(func(): finished_signal_emitted[0] = true)

	await create_timer(1.8).timeout

	_assert_test(finished_signal_emitted[0], "SplashScreen emits splash_finished signal upon loading completion")

	if is_instance_valid(splash):
		splash.queue_free()

func _test_ingame_screen_and_undo() -> void:
	print("\n[Group 3] In-Game UI Refinements, Action Cards & Undo Integration")

	var game_scene = preload("res://scenes/screens/GameScreen.tscn")
	var game = game_scene.instantiate() as GameScreen
	root.add_child(game)

	for i in range(3):
		await process_frame

	_assert_test(game.lbl_level_title != null, "lbl_level_title is present")
	_assert_test(game.lbl_subtitle != null and game.lbl_subtitle.text == "Clear all arrows from the grid", "Subtitle 'Clear all arrows from the grid' matches mockup")
	_assert_test(game.btn_restart != null, "btn_restart circular card exists")
	_assert_test(game.btn_hint != null, "btn_hint circular card exists")
	_assert_test(game.hint_badge_lbl != null and game.hint_badge_lbl.text == "3", "Hint button has orange badge '3' matching mockup")
	_assert_test(game.btn_undo != null, "btn_undo circular card exists")

	# Start level 1 via GameManager
	var gm = GameManager.new()
	var lvl1 = gm.start_level(1)
	game.start_level(lvl1)
	for i in range(3):
		await process_frame

	_assert_test(game.lbl_level_title.text == "Level 1", "Level title displays 'Level 1'")
	var initial_arrow_count = game.board.active_arrows.size()
	_assert_test(initial_arrow_count > 0, "Board initialized with %d active arrows" % initial_arrow_count)

	# Find a clear arrow to exit
	var clear_arrow: Arrow = null
	for arr in game.board.active_arrows:
		if CollisionChecker.can_arrow_exit(arr, game.board.active_arrows, game.board.grid_size):
			clear_arrow = arr
			break

	_assert_test(clear_arrow != null, "Identified clear arrow (ID=%d) to test Undo" % (clear_arrow.arrow_id if clear_arrow else -1))

	if clear_arrow:
		var target_id = clear_arrow.arrow_id
		game.board.handle_touch_down_local(clear_arrow.position, -1)
		game.board.handle_touch_up_local(clear_arrow.position, -1)

		# Wait for exit
		await create_timer(0.4).timeout
		_assert_test(game.board.active_arrows.size() == initial_arrow_count - 1, "Arrow exited board (remaining: %d)" % game.board.active_arrows.size())
		_assert_test(game.current_moves == 1, "current_moves incremented to 1")

		# Now test Undo!
		game.btn_undo.emit_signal("pressed")
		await create_timer(0.3).timeout

		_assert_test(game.board.active_arrows.size() == initial_arrow_count, "Undo restored arrow to active collection (count: %d)" % game.board.active_arrows.size())
		_assert_test(game.current_moves == 0, "Undo decremented current_moves back to 0")

		# Check that the restored arrow has the correct ID
		var found_restored = false
		for a in game.board.active_arrows:
			if a.arrow_id == target_id:
				found_restored = true
				break
		_assert_test(found_restored, "Restored arrow has identical Arrow ID=%d" % target_id)

	if is_instance_valid(gm):
		gm.queue_free()

	if is_instance_valid(game):
		game.queue_free()
