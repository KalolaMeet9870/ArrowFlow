extends SceneTree

## Verification Suite: Redesigned ArrowFlow UI matching Reference Screenshots (Images 2 & 3).

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
	print("  TEST: REDESIGNED ARROWFLOW UI (REFERENCE SCREENSHOTS 2 & 3)    ")
	print("==================================================================\n")

	# -------------------------------------------------------------
	# 1. HOME SCREEN REDESIGN VERIFICATION (Reference Image 2)
	# -------------------------------------------------------------
	print("[Group 1] Home Screen: Top App Bar & Safe Areas")
	var home = HomeScreen.new()
	home.size = Vector2(720, 1280)
	root.add_child(home)
	for i in range(3):
		await process_frame

	_assert_test(home.main_margin != null, "Main safe area margin container exists")
	_assert_test(home.lbl_coins != null and home.lbl_coins.text == "2", "Coin pill displays correct coin count '2'")

	# Check avatar button
	var avatar_btn = home.find_child("AvatarBtn", true, false)
	_assert_test(avatar_btn != null, "Profile avatar button exists in top bar")

	print("\n[Group 2] Home Screen: Featured Horizontal Carousel Cards")
	# Emerald League Card
	_assert_test(home.emerald_league_popup != null, "EmeraldLeaguePopup component exists in HomeScreen")
	home.emerald_league_popup.show_popup()
	_assert_test(home.emerald_league_popup.visible, "Emerald League popup opens upon selection")
	home.emerald_league_popup.hide_popup()
	await create_timer(0.2).timeout
	_assert_test(not home.emerald_league_popup.visible, "Emerald League popup closes cleanly")

	# Check Daily Streak Popup
	_assert_test(home.daily_streak_popup != null, "DailyStreakPopup exists in HomeScreen")

	print("\n[Group 3] Home Screen: Game Title, Progression Track & Primary CTA")
	_assert_test(home.lbl_title != null and home.lbl_title.text == "ArrowFlow", "Game title 'ArrowFlow' is prominently displayed")
	_assert_test(home.level_track_container != null, "Horizontal Level Track container exists")
	_assert_test(home.level_track_container.get_child_count() > 0, "Level Track populated with connecting rail and circular nodes")

	_assert_test(home.cta_btn != null, "Primary Play CTA button exists")
	_assert_test(home.cta_title != null and home.cta_title.text == "Play", "CTA displays bold 'Play' title")
	_assert_test(home.cta_sub != null and home.cta_sub.text == "Level 1", "CTA displays 'Level 1' subtitle")

	# Check CTA styling
	var cta_sb = home.cta_btn.get_theme_stylebox("normal") as StyleBoxFlat
	_assert_test(cta_sb != null and cta_sb.bg_color.r > 0.7 and cta_sb.bg_color.g > 0.4, "CTA has warm golden-caramel styling matching Reference Image 2")
	_assert_test(cta_sb.corner_radius_top_left >= 20, "CTA has rounded pill corners (radius=%d)" % cta_sb.corner_radius_top_left)

	home.queue_free()
	for i in range(2):
		await process_frame

	# -------------------------------------------------------------
	# 2. GAMEPLAY SCREEN REDESIGN VERIFICATION (Reference Image 3)
	# -------------------------------------------------------------
	print("\n[Group 4] Gameplay Screen: Clean Top Navigation Bar")
	var game = GameScreen.new()
	game.size = Vector2(720, 1280)
	root.add_child(game)
	for i in range(3):
		await process_frame

	var lvl1 = PuzzleGenerator.get_or_generate_level(1)
	game.start_level(lvl1)
	for i in range(3):
		await process_frame

	_assert_test(game.lbl_level_title != null and game.lbl_level_title.text == "Level 1", "Level title cleanly displays 'Level 1'")
	_assert_test(game.lbl_subtitle != null and not game.lbl_subtitle.visible, "Subtitle is hidden to keep navigation bar clean and uncluttered")

	_assert_test(game.btn_theme != null, "Theme switch palette button 🎨 exists")
	_assert_test(game.btn_settings != null, "Settings button ⚙ exists")

	print("\n[Group 5] Gameplay Screen: Lives Droplets & Hint Lightbulb")
	_assert_test(game.heart_display != null, "HeartDisplay container exists")
	_assert_test(game.heart_display.drop_labels.size() == 3, "Exactly 3 life water droplets (💧 💧 💧) displayed")
	_assert_test(game.btn_hint != null, "Hint button with lightbulb 💡 exists")
	_assert_test(game.hint_badge_lbl != null and (game.hint_badge_lbl.text == "3" or game.hint_badge_lbl.text == "AD"), "Hint lightbulb has orange badge pill attached")

	print("\n[Group 6] Gameplay Screen: Centered Puzzle Grid & Dotted Geometry")
	var board = game.board
	_assert_test(board != null, "GameBoard exists")
	_assert_test(board.active_arrows.size() > 0, "Puzzle arrows instantiated and active (count=%d)" % board.active_arrows.size())
	_assert_test(board.board_pixel_w > 0 and board.board_pixel_h > 0, "Puzzle dimensions calculated (%.0fx%.0f)" % [board.board_pixel_w, board.board_pixel_h])
	_assert_test(board._cached_grid_dots.size() == board.grid_size.x * board.grid_size.y, "Dotted grid texture contains exactly %d puzzle intersection dots (%dx%d)" % [board.grid_size.x * board.grid_size.y, board.grid_size.x, board.grid_size.y])

	print("\n[Group 7] Gameplay Screen: Floating Zoom Controls")
	var zoom_dock = game.find_child("ZoomDock", true, false)
	_assert_test(zoom_dock != null, "Floating ZoomDock exists on gameplay screen")
	var zoom_margin = game.find_child("ZoomMargin", true, false)
	_assert_test(zoom_margin != null, "ZoomMargin exists with on-screen anchors")
	if zoom_margin:
		_assert_test(zoom_margin.grow_horizontal == Control.GROW_DIRECTION_BEGIN, "Zoom dock grows inwards horizontally")
		_assert_test(zoom_margin.grow_vertical == Control.GROW_DIRECTION_BEGIN, "Zoom dock grows inwards vertically")

	game.queue_free()

	print("\n-------------------------------------------------------")
	print("TEST RESULTS SUMMARY:")
	print("  Passed: %d" % passed_count)
	print("  Failed: %d" % failed_count)
	print("-------------------------------------------------------")
	if failed_count == 0:
		print(">>> ALL REDESIGN TESTS PASSED SUCCESSFULLY! <<<\n")

	quit(0 if failed_count == 0 else 1)
