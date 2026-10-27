extends SceneTree

func _init() -> void:
	print("--- Capturing Full Flow Screenshots ---")
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

	# 1. Capture Home Screen (Screenshot 3 style)
	root_node.show_home_screen()
	for f in range(12):
		await process_frame
	var img_home = root.get_texture().get_image()
	if img_home:
		img_home.save_png("res://test/screenshot_flow_home.png")
		print("Saved screenshot_flow_home.png successfully!")

	# 2. Capture Daily Streak Popup (Screenshot 4 style)
	if root_node.home_screen and root_node.home_screen.daily_streak_popup:
		root_node.home_screen.daily_streak_popup.show_popup(1, 2)
		for f in range(12):
			await process_frame
		var img_streak = root.get_texture().get_image()
		if img_streak:
			img_streak.save_png("res://test/screenshot_flow_daily_streak.png")
			print("Saved screenshot_flow_daily_streak.png successfully!")
		root_node.home_screen.daily_streak_popup.hide_popup()
		for f in range(8):
			await process_frame

	# 2b. Capture Emerald League Popup (Reference Screenshot 5 style)
	if root_node.home_screen and root_node.home_screen.emerald_league_popup:
		root_node.home_screen.emerald_league_popup.show_popup()
		for f in range(12):
			await process_frame
		var img_league = root.get_texture().get_image()
		if img_league:
			img_league.save_png("res://test/screenshot_flow_emerald_league.png")
			print("Saved screenshot_flow_emerald_league.png successfully!")
		root_node.home_screen.emerald_league_popup.hide_popup()
		for f in range(8):
			await process_frame

	# 3. Capture Game Screen Normal
	root_node.show_game_screen(1)
	for f in range(12):
		await process_frame
	if root_node.game_screen and root_node.game_screen.board:
		root_node.game_screen.board.show_hint()
		for f in range(8):
			await process_frame
	var img_game = root.get_texture().get_image()
	if img_game:
		img_game.save_png("res://test/screenshot_flow_gameplay.png")
		print("Saved screenshot_flow_gameplay.png successfully!")

	# 3b. Capture Game Screen Zoomed In (Image 3 style)
	if root_node.game_screen and root_node.game_screen.board:
		root_node.game_screen.board.set_target_zoom(1.85)
		for f in range(20):
			await process_frame
	var img_zoomed = root.get_texture().get_image()
	if img_zoomed:
		img_zoomed.save_png("res://test/screenshot_flow_zoomed.png")
		print("Saved screenshot_flow_zoomed.png successfully!")

	# 4. Capture Level Complete Celebration Screen
	root_node._on_level_completed(4, 8, 3)
	for f in range(15):
		await process_frame
	var img_complete = root.get_texture().get_image()
	if img_complete:
		img_complete.save_png("res://test/screenshot_flow_complete.png")
		print("Saved screenshot_flow_complete.png successfully!")

	# 5. Capture Settings Screen
	root_node.show_home_screen()
	root_node._open_settings("home")
	for f in range(12):
		await process_frame
	var img_settings = root.get_texture().get_image()
	if img_settings:
		img_settings.save_png("res://test/screenshot_flow_settings.png")
		print("Saved screenshot_flow_settings.png successfully!")

	print("All full flow screenshots captured successfully!")
	quit(0)
