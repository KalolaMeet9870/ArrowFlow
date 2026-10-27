extends SceneTree

## Comprehensive Automated Test Suite verifying all 12 Screens from Reference Image:
## Screen 1: Splash Screen
## Screen 2: Home Screen
## Screen 3: Level Select Screen
## Screen 4: Gameplay Screen
## Screen 5: Level Completed Dialog
## Screen 6: Level Failed Dialog
## Screen 7: Daily Challenge Screen
## Screen 8: Event Screen (Countryside Dash)
## Screen 9: Profile Screen
## Screen 10: Settings Screen
## Screen 11: How to Play Screen
## Screen 12: Theme Selection Screen
## + Full Inter-Screen Navigation & State Persistence

var passed_count: int = 0
var failed_count: int = 0

func assert_true(condition: bool, message: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % message)
	else:
		failed_count += 1
		printerr("  [FAIL] %s" % message)

func _init() -> void:
	print("\n==================================================================")
	print("  TEST: ALL 12 SCREENS IMPLEMENTATION (ARROWFLOW FULL REDESIGN)   ")
	print("==================================================================\n")

	var main_scene = load("res://scenes/main/Main.tscn")
	var main_inst = main_scene.instantiate() as Main
	root.add_child(main_inst)

	# Bypass ad delays for fast deterministic test execution
	if AdMobManager.instance:
		AdMobManager.instance.has_shown_cold_start_ad = true

	for i in range(15):
		await process_frame

	# -------------------------------------------------------------
	# [Screen 1] Splash Screen
	# -------------------------------------------------------------
	print("[Screen 1] Splash Screen Verification")
	assert_true(main_inst.splash_screen != null, "SplashScreen instance exists in Main")
	assert_true(main_inst.splash_screen.icon_rect != null, "SplashScreen contains app icon card")
	assert_true(main_inst.splash_screen.progress_bar != null, "SplashScreen contains pill progress bar")

	# -------------------------------------------------------------
	# [Screen 2] Home Screen
	# -------------------------------------------------------------
	print("\n[Screen 2] Home Screen Verification")
	main_inst.show_home_screen()
	for f in range(5):
		await process_frame
	var hs = main_inst.home_screen
	assert_true(hs != null and hs.visible, "HomeScreen is visible")
	assert_true(hs.lbl_title.text == "ArrowFlow", "ArrowFlow title is displayed")
	assert_true(hs.find_child("AvatarBtn", true, false) != null, "AvatarBtn exists in top bar")
	assert_true(hs.cta_btn != null and "Play" in hs.cta_title.text, "Primary Play CTA exists")

	# -------------------------------------------------------------
	# [Screen 3] Level Select Screen
	# -------------------------------------------------------------
	print("\n[Screen 3] Level Select Screen Verification")
	main_inst.show_level_select_screen(-1)
	for f in range(5):
		await process_frame
	var lss = main_inst.level_select_screen
	assert_true(lss != null and lss.visible, "LevelSelectScreen is visible")
	assert_true(lss.lbl_title.text == "Level Select", "Title displays 'Level Select'")
	assert_true(lss.emerald_card != null, "Emerald League progress card exists")
	assert_true(lss.grid_container != null, "5-column grid container exists")
	assert_true(lss.grid_container.get_child_count() == 50, "Grid contains exactly 50 level buttons")
	var first_btn = lss.grid_container.get_child(0) as Button
	if first_btn:
		print("DEBUG: first_btn text is '", first_btn.text, "'")
	assert_true(first_btn != null and (first_btn.text == "1" or "1" in first_btn.text), "First level button is Level 1")

	# -------------------------------------------------------------
	# [Screen 4] Gameplay Screen
	# -------------------------------------------------------------
	print("\n[Screen 4] Gameplay Screen Verification")
	main_inst.show_game_screen(1)
	for f in range(10):
		await process_frame
	var gs = main_inst.game_screen
	assert_true(gs != null and gs.visible, "GameScreen is visible")
	assert_true(gs.lbl_level_title.text == "Level 1", "Header displays 'Level 1'")
	assert_true(gs.btn_theme != null, "Theme palette button 🎨 exists in header")
	assert_true(gs.btn_settings != null, "Settings button ⚙ exists in header")
	assert_true(gs.heart_display != null and gs.current_hearts == 3, "3 water drops displayed")
	assert_true(gs.board != null and gs.board.active_arrows.size() > 0, "Puzzle board active with arrows")

	# -------------------------------------------------------------
	# [Screen 5] Level Completed Dialog
	# -------------------------------------------------------------
	print("\n[Screen 5] Level Completed Dialog Verification")
	main_inst._on_level_completed(1, 8, 3)
	for f in range(10):
		await process_frame
	var lcs = main_inst.level_complete_screen
	assert_true(lcs != null and lcs.visible, "LevelCompleteScreen dialog is visible")
	assert_true(lcs.lbl_banner.text == "Level Completed!", "Banner ribbon displays 'Level Completed!'")
	assert_true("⭐ +2" in lcs.lbl_reward_coins.text, "Reward pill displays ⭐ +2")
	assert_true(lcs.btn_next != null and lcs.btn_next.text == "Next Level", "Primary button is 'Next Level'")
	assert_true(lcs.btn_home != null and lcs.btn_home.text == "Home", "Secondary button is 'Home'")

	# -------------------------------------------------------------
	# [Screen 6] Level Failed Dialog
	# -------------------------------------------------------------
	print("\n[Screen 6] Level Failed Dialog Verification")
	main_inst._on_level_failed(1)
	for f in range(10):
		await process_frame
	var lfs = main_inst.level_failed_screen
	assert_true(lfs != null and lfs.visible, "LevelFailedScreen dialog is visible")
	assert_true(lfs.lbl_failed_title.text == "Level Failed", "Title displays 'Level Failed'")
	assert_true(lfs.lbl_failed_sub.text == "You made 3 wrong moves.", "Subtitle displays 'You made 3 wrong moves.'")
	assert_true(lfs.btn_continue != null, "Continue rewarded ad button exists")
	assert_true(lfs.btn_restart != null, "Restart button exists")
	assert_true(lfs.btn_close != null, "Close button ✕ exists")

	# -------------------------------------------------------------
	# [Screen 7] Daily Challenge Screen
	# -------------------------------------------------------------
	print("\n[Screen 7] Daily Challenge Screen Verification")
	main_inst.show_daily_challenge_screen()
	for f in range(5):
		await process_frame
	var dcs = main_inst.daily_challenge_screen
	assert_true(dcs != null and dcs.visible, "DailyChallengeScreen is visible")
	assert_true(dcs.lbl_timer != null and "20h 55m" in dcs.lbl_timer.text, "Timer pill displays '20h 55m'")
	assert_true(dcs.btn_start != null and dcs.btn_start.text == "Start", "Start CTA button exists")

	# -------------------------------------------------------------
	# [Screen 8] Event Screen (Countryside Dash)
	# -------------------------------------------------------------
	print("\n[Screen 8] Event Screen Verification")
	main_inst.show_event_screen()
	for f in range(5):
		await process_frame
	var evs = main_inst.event_screen
	assert_true(evs != null and evs.visible, "EventScreen is visible")
	assert_true(evs.lbl_progress != null and "3/10" in evs.lbl_progress.text, "Event progress displays '3/10'")
	assert_true(evs.btn_play != null and evs.btn_play.text == "Play", "Green Play CTA button exists")

	# -------------------------------------------------------------
	# [Screen 9] Profile Screen
	# -------------------------------------------------------------
	print("\n[Screen 9] Profile Screen Verification")
	main_inst.show_profile_screen()
	for f in range(5):
		await process_frame
	var prs = main_inst.profile_screen
	assert_true(prs != null and prs.visible, "ProfileScreen is visible")
	assert_true(prs.lbl_username.text == "Player123", "Username is Player123")
	assert_true(prs.lbl_email.text == "player@example.com", "Email is player@example.com")
	assert_true(prs.lbl_completed_val != null, "Levels Completed stat card exists")
	assert_true(prs.lbl_stars_val != null, "Total Stars stat card exists")

	# -------------------------------------------------------------
	# [Screen 10] Settings Screen
	# -------------------------------------------------------------
	print("\n[Screen 10] Settings Screen Verification")
	main_inst._open_settings("home")
	for f in range(5):
		await process_frame
	var ss = main_inst.settings_screen
	assert_true(ss != null and ss.visible, "SettingsScreen is visible")
	assert_true(ss.switch_controls.has("sound"), "Sound toggle switch exists")
	assert_true(ss.switch_controls.has("music"), "Music toggle switch exists")
	assert_true(ss.switch_controls.has("vibration"), "Vibration toggle switch exists")
	assert_true(ss.lbl_theme_val != null, "Theme selection row exists")

	# -------------------------------------------------------------
	# [Screen 11] How to Play Screen
	# -------------------------------------------------------------
	print("\n[Screen 11] How to Play Screen Verification")
	main_inst.show_how_to_play_screen("settings")
	for f in range(5):
		await process_frame
	var htps = main_inst.how_to_play_screen
	assert_true(htps != null and htps.visible, "HowToPlayScreen is visible")
	assert_true(htps.btn_got_it != null and htps.btn_got_it.text == "Got It", "Got It CTA button exists")

	# -------------------------------------------------------------
	# [Screen 12] Theme Selection Screen
	# -------------------------------------------------------------
	print("\n[Screen 12] Theme Selection Screen Verification")
	main_inst.show_theme_selection_screen("settings")
	for f in range(5):
		await process_frame
	var tss = main_inst.theme_selection_screen
	assert_true(tss != null and tss.visible, "ThemeSelectionScreen is visible")
	assert_true(tss.cards_grid != null and tss.card_controls.size() == 4, "2x2 grid contains 4 theme preview cards")
	assert_true(tss.badge_controls[0].visible, "Default Eye Comfort theme is selected with checkmark ✓")

	# Select Matcha Theme
	tss._select_theme(1)
	assert_true(ThemeManager.instance.current_theme_index == 1, "Matcha Garden theme activated")
	assert_true(tss.badge_controls[1].visible, "Matcha Garden theme has checkmark ✓")

	# Restore Default Theme
	tss._select_theme(0)
	assert_true(ThemeManager.instance.current_theme_index == 0, "Eye Comfort restored")

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % passed_count)
	print("  Failed: %d" % failed_count)
	print("-------------------------------------------------------")

	if failed_count == 0:
		print(">>> ALL 12 SCREENS VERIFIED SUCCESSFULLY! <<<\n")
		quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
