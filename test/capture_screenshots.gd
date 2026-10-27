extends SceneTree

func _init() -> void:
	print("Starting comprehensive screenshot capture for AdMob & Progression...")
	var main_scene = load("res://scenes/main/Main.tscn")
	if not main_scene:
		print("Failed to load Main.tscn")
		quit(1)
		return

	var root_node = main_scene.instantiate() as Main
	root.add_child(root_node)

	# Prevent cold start auto-timer from firing mid-capture
	if AdMobManager.instance:
		AdMobManager.instance.has_shown_cold_start_ad = true

	for i in range(10):
		await process_frame

	# 1. Capture Home Screen with AdMob Banner Ad at bottom
	var img = root.get_texture().get_image()
	if img:
		img.save_png("res://test/screenshot_home_banner.png")
		print("Saved screenshot_home_banner.png successfully!")

	# 2. Show App Open Ad and capture
	if AdMobManager.instance:
		AdMobManager.instance.show_app_open_ad(true)
		for i in range(8):
			await process_frame
		var img_app_open = root.get_texture().get_image()
		if img_app_open:
			img_app_open.save_png("res://test/screenshot_app_open_ad.png")
			print("Saved screenshot_app_open_ad.png successfully!")
		AdMobManager.instance._close_mock_app_open()
		for i in range(8):
			await process_frame

	# 3. Complete Level 1 to capture Level Selection Screen with status & Next Level button
	root_node.show_game_screen(1)
	for i in range(8):
		await process_frame

	# Mark level completed to navigate to LevelSelectScreen
	root_node._on_level_completed(1, 3, 3)
	for i in range(10):
		await process_frame

	var img_lvl_select = root.get_texture().get_image()
	if img_lvl_select:
		img_lvl_select.save_png("res://test/screenshot_level_select.png")
		print("Saved screenshot_level_select.png successfully!")

	# 4. Trigger Level Failed popup (3 wrong moves) to show Restart & Continue buttons
	root_node.show_game_screen(1)
	for i in range(8):
		await process_frame
	root_node._on_level_failed(1)
	for i in range(12):
		await process_frame

	var img_failed = root.get_texture().get_image()
	if img_failed:
		img_failed.save_png("res://test/screenshot_level_failed.png")
		print("Saved screenshot_level_failed.png successfully!")

	# 5. Tap Continue to trigger Rewarded Ad and capture
	if AdMobManager.instance and root_node.level_failed_screen:
		root_node.level_failed_screen._on_continue_pressed()
		for i in range(10):
			await process_frame
		var img_rewarded = root.get_texture().get_image()
		if img_rewarded:
			img_rewarded.save_png("res://test/screenshot_rewarded_ad.png")
			print("Saved screenshot_rewarded_ad.png successfully!")

	print("All screenshots captured successfully!")
	quit(0)
