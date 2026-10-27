extends SceneTree

func _init() -> void:
	print("--- Capturing Screenshots for Levels 1 to 4 ---")
	var main_scene = load("res://scenes/main/Main.tscn")
	var root_node = main_scene.instantiate() as Main
	root.add_child(root_node)

	if AdMobManager.instance:
		AdMobManager.instance.has_shown_cold_start_ad = true

	# Wait for Main and GameManager children to complete _ready() and load save data
	for i in range(10):
		await process_frame

	# Now set highest_unlocked_level to 50 so all levels can be rendered
	if SaveManager.instance:
		SaveManager.instance.highest_unlocked_level = 50

	var levels = [
		{"id": 1, "path": "res://test/screenshot_level_1_dog.png", "title": "Faithful Scottish Terrier"},
		{"id": 2, "path": "res://test/screenshot_level_2_trophy.png", "title": "Grand Championship Trophy"},
		{"id": 3, "path": "res://test/screenshot_level_3_anchor.png", "title": "Deep Ocean Anchor"},
		{"id": 4, "path": "res://test/screenshot_level_4_butterfly.png", "title": "Golden Monarch Butterfly"}
	]

	for item in levels:
		root_node.show_game_screen(item["id"])
		for f in range(12):
			await process_frame

		var img = root.get_texture().get_image()
		if img:
			img.save_png(item["path"])
			print("Saved %s -> %s" % [item["title"], item["path"]])

	print("All screenshots successfully captured!")
	quit(0)
