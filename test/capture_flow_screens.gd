extends SceneTree

func _init() -> void:
	print("--- Capturing All 12 Screens Flow Screenshots ---")
	var main_scene = load("res://scenes/main/Main.tscn")
	var root_node = main_scene.instantiate() as Main
	root.add_child(root_node)

	if AdMobManager.instance:
		AdMobManager.instance.has_shown_cold_start_ad = true

	# Wait for Main and UI to initialize
	for i in range(10):
		await process_frame

	if SaveManager.instance:
		SaveManager.instance.highest_unlocked_level = 50
		SaveManager.instance.current_level = 6

	# 1. Screen 1: Splash Screen
	if root_node.splash_screen:
		root_node.splash_screen.show()
		for f in range(10):
			await process_frame
		var img_splash = root.get_texture().get_image()
		if img_splash:
			img_splash.save_png("res://test/screenshot_1_splash.png")
			print("Saved screenshot_1_splash.png")
		root_node.splash_screen.hide()

	# 2. Screen 2: Home Screen
	root_node.show_home_screen()
	for f in range(12):
		await process_frame
	var img_home = root.get_texture().get_image()
	if img_home:
		img_home.save_png("res://test/screenshot_2_home.png")
		print("Saved screenshot_2_home.png")

	# 3. Screen 3: Level Select Screen
	root_node.show_level_select_screen(-1)
	for f in range(12):
		await process_frame
	var img_lvl_select = root.get_texture().get_image()
	if img_lvl_select:
		img_lvl_select.save_png("res://test/screenshot_3_level_select.png")
		print("Saved screenshot_3_level_select.png")

	# 4. Screen 4: Gameplay Screen
	root_node.show_game_screen(1)
	for f in range(12):
		await process_frame
	var img_gameplay = root.get_texture().get_image()
	if img_gameplay:
		img_gameplay.save_png("res://test/screenshot_4_gameplay.png")
		print("Saved screenshot_4_gameplay.png")

	# 5. Screen 5: Level Complete Dialog
	root_node._on_level_completed(1, 8, 3)
	for f in range(15):
		await process_frame
	var img_complete = root.get_texture().get_image()
	if img_complete:
		img_complete.save_png("res://test/screenshot_5_level_complete.png")
		print("Saved screenshot_5_level_complete.png")
	if root_node.level_complete_screen:
		root_node.level_complete_screen.hide()

	# 6. Screen 6: Level Failed Dialog
	root_node._on_level_failed(1)
	for f in range(15):
		await process_frame
	var img_failed = root.get_texture().get_image()
	if img_failed:
		img_failed.save_png("res://test/screenshot_6_level_failed.png")
		print("Saved screenshot_6_level_failed.png")
	if root_node.level_failed_screen:
		root_node.level_failed_screen.hide()

	# 7. Screen 7: Daily Challenge Screen
	root_node.show_daily_challenge_screen()
	for f in range(12):
		await process_frame
	var img_daily = root.get_texture().get_image()
	if img_daily:
		img_daily.save_png("res://test/screenshot_7_daily_challenge.png")
		print("Saved screenshot_7_daily_challenge.png")

	# 8. Screen 8: Event Screen
	root_node.show_event_screen()
	for f in range(12):
		await process_frame
	var img_event = root.get_texture().get_image()
	if img_event:
		img_event.save_png("res://test/screenshot_8_event.png")
		print("Saved screenshot_8_event.png")

	# 9. Screen 9: Profile Screen
	root_node.show_profile_screen()
	for f in range(12):
		await process_frame
	var img_profile = root.get_texture().get_image()
	if img_profile:
		img_profile.save_png("res://test/screenshot_9_profile.png")
		print("Saved screenshot_9_profile.png")

	# 10. Screen 10: Settings Screen
	root_node._open_settings("home")
	for f in range(12):
		await process_frame
	var img_settings = root.get_texture().get_image()
	if img_settings:
		img_settings.save_png("res://test/screenshot_10_settings.png")
		print("Saved screenshot_10_settings.png")

	# 11. Screen 11: How to Play Screen
	root_node.show_how_to_play_screen("home")
	for f in range(12):
		await process_frame
	var img_how = root.get_texture().get_image()
	if img_how:
		img_how.save_png("res://test/screenshot_11_how_to_play.png")
		print("Saved screenshot_11_how_to_play.png")

	# 12. Screen 12: Theme Selection Screen
	root_node.show_theme_selection_screen("home")
	for f in range(12):
		await process_frame
	var img_theme = root.get_texture().get_image()
	if img_theme:
		img_theme.save_png("res://test/screenshot_12_theme.png")
		print("Saved screenshot_12_theme.png")

	print("\n>>> ALL 12 SCREENSHOTS CAPTURED SUCCESSFULLY! <<<\n")
	quit(0)
