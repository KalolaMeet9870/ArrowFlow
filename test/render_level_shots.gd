extends SceneTree

func _init() -> void:
	print("--- Capturing Level Screenshots ---")
	var scene = load("res://scenes/main/Main.tscn")
	var main_inst = scene.instantiate() as Main
	root.add_child(main_inst)

	var frames = 0
	while frames < 5:
		await process_frame
		frames += 1

	var levels_to_test = [1, 2, 4, 10, 16, 24, 40]
	for lid in levels_to_test:
		main_inst.show_game_screen(lid)
		frames = 0
		while frames < 8:
			await process_frame
			frames += 1

		var img = root.get_texture().get_image()
		var out_path = "/Users/dws-mac001/.gemini/antigravity-ide/brain/0a0bbc13-ff5b-4d57-8cd2-e5b56be2a865/inspect_level_%d.png" % lid
		img.save_png(out_path)
		print("Saved screenshot of Level %d to %s" % [lid, out_path])

	quit(0)
