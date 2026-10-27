extends SceneTree

func _init() -> void:
	print("--- Inspecting Level Designs in data/levels.json ---")
	var path = "res://data/levels.json"
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	json.parse(text)
	var levels: Array = json.data

	for lvl in levels:
		var lid = int(lvl["id"])
		var lname = lvl.get("name", "")
		var ldiff = lvl.get("difficulty", "")
		var lshape = lvl.get("shape", "")
		var paths = lvl.get("paths", [])
		var bounds = lvl.get("bounds", {})
		print("Level %2d: %-24s | Diff: %-8s | Shape: %-10s | Arrows: %2d | Grid: %dx%d" % [
			lid, lname, ldiff, lshape, paths.size(), bounds.get("width", 0), bounds.get("height", 0)
		])

	quit(0)
