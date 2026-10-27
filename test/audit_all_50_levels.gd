extends SceneTree

func _init() -> void:
	print("--- Auditing all 50 levels in data/levels.json ---")
	var path = "res://data/levels.json"
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	json.parse(text)
	var levels: Array = json.data

	var failed_solves: Array = []
	var weird_bounds: Array = []

	for lvl in levels:
		var lid = int(lvl["id"])
		var lname = lvl.get("name", "")
		var bounds = lvl.get("bounds", {})
		var w = int(bounds.get("width", 0))
		var h = int(bounds.get("height", 0))
		var min_x = int(bounds.get("min_x", 0))
		var min_y = int(bounds.get("min_y", 0))
		var max_x = int(bounds.get("max_x", 0))
		var max_y = int(bounds.get("max_y", 0))

		if w <= 0 or h <= 0 or max_x <= min_x or max_y <= min_y:
			weird_bounds.append(lid)

		var converted = PuzzleGenerator._convert_json_level(lvl)
		var res = PuzzleSolver.solve(converted["arrow_objects"], converted["grid_size"], 2000)
		if not res["solvable"]:
			failed_solves.append({"id": lid, "name": lname, "arrows": converted["arrow_objects"].size(), "grid": converted["grid_size"]})

	print("Audited %d levels." % levels.size())
	print("Weird bounds count: ", weird_bounds.size(), weird_bounds)
	print("Failed solves count: ", failed_solves.size())
	for f in failed_solves:
		print("  Level %d ('%s') failed solver! Arrows: %d, Grid: %s" % [f["id"], f["name"], f["arrows"], f["grid"]])

	quit(0)
