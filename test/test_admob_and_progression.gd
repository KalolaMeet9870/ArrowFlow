extends SceneTree

## Automated Verification Test for AdMob Ads & Progression Requirements:
## 1. Rewarded Ads after 3 wrong selections (Restart & Continue with progress preservation)
## 2. Home Screen Banner Ad (shown on Home, hidden on Game)
## 3. App Open Ad (cooldown, gameplay protection, lifecycle)
## 4. Level Completion Flow (navigates to LevelSelectScreen, displays status, enables Next Level)
## 5. Level Unlocking Logic (locked levels cannot be opened until previous level is completed)

var passed_count: int = 0
var failed_count: int = 0

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % msg)
	else:
		failed_count += 1
		printerr("  [FAIL] %s" % msg)

func _init() -> void:
	print("\n=======================================================")
	print("  ARROWFLOW - ADMOB & PROGRESSION VERIFICATION SUITE  ")
	print("=======================================================\n")

	# Clean save data before testing
	if FileAccess.file_exists("user://arrow_save_data.json"):
		DirAccess.remove_absolute("user://arrow_save_data.json")

	var scene = load("res://scenes/main/Main.tscn")
	var main_inst = scene.instantiate() as Main
	root.add_child(main_inst)

	for i in range(10):
		await process_frame

	print("[Test Group 1] Home Screen Banner Ad & App Open Ad (Req 2 & 3)")
	assert_true(AdMobManager.instance != null, "AdMobManager singleton is initialized")
	assert_true(main_inst.home_screen.visible, "Main starts at HomeScreen")
	assert_true(AdMobManager.instance.is_banner_visible, "AdMob Banner Ad is visible on HomeScreen")
	assert_true(not AdMobManager.instance.is_gameplay_active, "Gameplay is flagged inactive on menus")

	# Test App Open Ad cooldown and active gameplay safety
	AdMobManager.instance.show_app_open_ad(true)
	assert_true(AdMobManager.instance.is_showing_ad, "App Open Ad displays on cold start")
	AdMobManager.instance._close_mock_app_open()
	assert_true(not AdMobManager.instance.is_showing_ad, "App Open Ad closes cleanly")

	# Test that gameplay active suppresses App Open Ads
	AdMobManager.instance.set_gameplay_active(true)
	var was_showing = AdMobManager.instance.is_showing_ad
	AdMobManager.instance._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(AdMobManager.instance.is_showing_ad == was_showing, "App Open Ad is suppressed during active gameplay")
	AdMobManager.instance.set_gameplay_active(false)

	print("\n[Test Group 2] Level Unlocking Logic (Req 5)")
	var sm = SaveManager.instance
	assert_true(sm != null, "SaveManager is active")
	assert_true(sm.highest_unlocked_level == 1, "Initially highest unlocked level is 1")
	assert_true(not sm.is_level_completed(1), "Level 1 is not completed initially")
	assert_true(not sm.is_level_completed(2), "Level 2 is not completed initially")

	# Attempt to open locked Level 2
	main_inst.show_game_screen(2)
	assert_true(main_inst.game_manager.current_level_id != 2 or not main_inst.game_screen.visible, "Locked Level 2 cannot be opened")

	# Open unlocked Level 1
	main_inst.show_game_screen(1)
	assert_true(main_inst.game_screen.visible, "Unlocked Level 1 opened successfully")
	assert_true(not AdMobManager.instance.is_banner_visible, "Banner ad hidden while playing game")
	assert_true(AdMobManager.instance.is_gameplay_active, "Gameplay flagged active while playing")

	print("\n[Test Group 3] Rewarded Ad after 3 Wrong Selections (Req 1)")
	var gs = main_inst.game_screen
	var lf = main_inst.level_failed_screen
	assert_true(gs.current_hearts == 3, "Player starts with 3 drops/hearts")

	# Find a blocked arrow to trigger a wrong move
	var board = gs.board
	var blocked_arrow: Arrow = null
	for a in board.active_arrows:
		if not CollisionChecker.can_arrow_exit(a, board.active_arrows, board.grid_size):
			blocked_arrow = a
			break

	if blocked_arrow == null:
		# Artificial trigger if all initial arrows happened to be free
		blocked_arrow = board.active_arrows[0]

	var initial_arrow_count = board.active_arrows.size()

	# Clear one free arrow first to record board progress
	var free_arrow: Arrow = null
	for a in board.active_arrows:
		if CollisionChecker.can_arrow_exit(a, board.active_arrows, board.grid_size):
			free_arrow = a
			break

	if free_arrow:
		board._on_arrow_tapped(free_arrow)
		for f in range(25):
			await process_frame
		print("   One arrow cleared. Board arrows remaining: %d" % board.active_arrows.size())

	var progress_arrows_remaining = board.active_arrows.size()

	# Wrong selection 1
	board.move_failed.emit(blocked_arrow)
	assert_true(gs.current_hearts == 2, "1st wrong selection: hearts = 2")
	assert_true(not lf.visible, "Popup not shown after 1 wrong move")

	# Wrong selection 2
	board.move_failed.emit(blocked_arrow)
	assert_true(gs.current_hearts == 1, "2nd wrong selection: hearts = 1")
	assert_true(not lf.visible, "Popup not shown after 2 wrong moves")

	# Wrong selection 3
	board.move_failed.emit(blocked_arrow)
	assert_true(gs.current_hearts == 0, "3rd wrong selection: hearts = 0")
	assert_true(lf.visible, "LevelFailed popup shown after 3 wrong selections")

	# Verify popup has Restart and Continue
	assert_true(lf.btn_continue != null, "Popup contains Continue button")
	assert_true(lf.btn_restart != null, "Popup contains Restart button")
	assert_true("CONTINUE" in lf.btn_continue.text, "Continue button text verified")
	assert_true("RESTART" in lf.btn_restart.text, "Restart button text verified")

	# Test CONTINUE via Rewarded Ad
	print("   Testing Continue via AdMob Rewarded Ad...")
	lf.btn_continue.pressed.emit()
	assert_true(AdMobManager.instance.is_showing_ad, "AdMob Rewarded Ad is displayed on Continue")

	# Complete rewarded ad
	AdMobManager.instance._close_mock_rewarded(true)
	for f in range(5):
		await process_frame

	assert_true(not lf.visible, "Popup dismissed after rewarded ad")
	assert_true(gs.current_hearts == 1, "Player granted +1 drop to continue")
	assert_true(not board.is_input_locked, "Board input unlocked")
	assert_true(board.active_arrows.size() == progress_arrows_remaining, "Player continues from current board progress")

	print("\n[Test Group 4] Level Completion Flow & Next Level (Req 4 & 5)")
	# Clear remaining arrows to trigger level complete
	while board.active_arrows.size() > 0:
		var cand: Arrow = null
		for a in board.active_arrows:
			if CollisionChecker.can_arrow_exit(a, board.active_arrows, board.grid_size):
				cand = a
				break
		if cand:
			board._on_arrow_tapped(cand)
			for f in range(25):
				await process_frame
		else:
			# Remove manually if no exit in edge case
			board.active_arrows[0].queue_free()
			board.active_arrows.remove_at(0)

	for f in range(35):
		await process_frame

	# Verify navigation to LevelSelectScreen
	var lss = main_inst.level_select_screen
	assert_true(lss != null, "LevelSelectScreen exists")
	assert_true(lss.visible, "Navigated back to LevelSelectScreen on level complete")
	assert_true(not gs.visible, "GameScreen hidden after level completion")
	assert_true(lss.status_banner.visible, "Completed level status banner is displayed")
	assert_true("LEVEL 1 COMPLETED!" in lss.lbl_status_banner.text, "Status displays Level 1 Completed")

	# Verify Next Level button is enabled and points to Level 2
	assert_true(not lss.btn_next_level.disabled, "Next Level button is enabled")
	assert_true("LEVEL 2" in lss.btn_next_level.text, "Next Level button targets Level 2")

	# Verify Level 2 is now unlocked in SaveManager
	assert_true(sm.highest_unlocked_level == 2, "Level 2 is now unlocked in SaveManager")
	assert_true(sm.is_level_completed(1), "Level 1 recorded as completed")

	# Click Next Level button to launch Level 2
	lss.btn_next_level.pressed.emit()
	for f in range(5):
		await process_frame

	assert_true(main_inst.game_screen.visible, "Level 2 launched from Next Level button")
	assert_true(main_inst.game_manager.current_level_id == 2, "Current Level is now Level 2")

	# Verify Level 3 is still strictly locked
	main_inst.show_game_screen(3)
	assert_true(main_inst.game_manager.current_level_id == 2, "Locked Level 3 cannot be accessed before completing Level 2")

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % passed_count)
	print("  Failed: %d" % failed_count)
	print("-------------------------------------------------------")

	if failed_count == 0:
		print(">>> ALL ADMOB & PROGRESSION TESTS PASSED SUCCESSFULLY! <<<\n")
		quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
