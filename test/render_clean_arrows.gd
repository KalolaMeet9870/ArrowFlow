extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main/Main.tscn")
	var root_node = main_scene.instantiate() as Main
	root.add_child(root_node)

	if AdMobManager.instance:
		AdMobManager.instance.has_shown_cold_start_ad = true

	for i in range(5):
		await process_frame

	# Open Level 1 (the 4-arrow level shown in user's image)
	root_node.show_game_screen(1)
	for i in range(10):
		await process_frame

	var img = root.get_texture().get_image()
	if img:
		img.save_png("res://test/screenshot_arrows_no_dot.png")
		print("Saved screenshot_arrows_no_dot.png successfully!")

	quit(0)
