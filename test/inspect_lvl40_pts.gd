extends SceneTree

func _init() -> void:
	var path = "res://data/levels.json"
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	json.parse(text)
	var levels: Array = json.data
	var lvl40 = levels[39] # Level 40

	print("Level 40 bounds: ", lvl40["bounds"])
	var converted = PuzzleGenerator._convert_json_level(lvl40)
	print("Converted grid_size: ", converted["grid_size"])
	for a in converted["arrow_objects"]:
		if a["points"].size() > 0:
			for pt in a["points"]:
				if pt.y <= 1.0:
					print("Arrow %d has point near top: %s, dir: %s" % [a["arrow_id"], pt, a["direction"]])

	quit(0)
