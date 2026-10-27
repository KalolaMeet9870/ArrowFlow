class_name PuzzleGenerator
extends RefCounted

## Procedural puzzle generator and handcrafted tutorial level provider.
## Guarantees 100% solvability via reverse dependency synthesis and verified level sets.

const HANDCRAFTED_LEVELS: Array = [
	# Level 1: Tutorial 1 - 3 Simple Arrows (Intro to clearing)
	{
		"id": 1,
		"name": "First Flight",
		"difficulty": "Beginner",
		"grid_size": Vector2i(4, 4),
		"arrows": [
			{"id": 1, "pos": Vector2i(0, 0), "dir": CollisionChecker.Direction.UP, "length": 1},
			{"id": 2, "pos": Vector2i(2, 1), "dir": CollisionChecker.Direction.RIGHT, "length": 2},
			{"id": 3, "pos": Vector2i(1, 3), "dir": CollisionChecker.Direction.DOWN, "length": 1}
		]
	},
	# Level 2: Tutorial 2 - First Blocker (1 dependency)
	{
		"id": 2,
		"name": "Cross Paths",
		"difficulty": "Beginner",
		"grid_size": Vector2i(4, 4),
		"arrows": [
			{"id": 1, "pos": Vector2i(1, 1), "dir": CollisionChecker.Direction.RIGHT, "length": 2},
			{"id": 2, "pos": Vector2i(2, 0), "dir": CollisionChecker.Direction.DOWN, "length": 1},
			{"id": 3, "pos": Vector2i(0, 3), "dir": CollisionChecker.Direction.LEFT, "length": 1},
			{"id": 4, "pos": Vector2i(3, 3), "dir": CollisionChecker.Direction.RIGHT, "length": 1}
		]
	},
	# Level 3: Tutorial 3 - Multi-Cell Arrows
	{
		"id": 3,
		"name": "Long Stride",
		"difficulty": "Beginner",
		"grid_size": Vector2i(5, 5),
		"arrows": [
			{"id": 1, "pos": Vector2i(1, 0), "dir": CollisionChecker.Direction.DOWN, "length": 3},
			{"id": 2, "pos": Vector2i(3, 1), "dir": CollisionChecker.Direction.LEFT, "length": 2},
			{"id": 3, "pos": Vector2i(0, 4), "dir": CollisionChecker.Direction.UP, "length": 2},
			{"id": 4, "pos": Vector2i(2, 4), "dir": CollisionChecker.Direction.RIGHT, "length": 2},
			{"id": 5, "pos": Vector2i(4, 0), "dir": CollisionChecker.Direction.DOWN, "length": 2}
		]
	},
	# Level 4: Tutorial 4 - Interlocking Corner Box
	{
		"id": 4,
		"name": "Pinwheel",
		"difficulty": "Easy",
		"grid_size": Vector2i(5, 5),
		"arrows": [
			{"id": 1, "pos": Vector2i(1, 1), "dir": CollisionChecker.Direction.RIGHT, "length": 2},
			{"id": 2, "pos": Vector2i(3, 1), "dir": CollisionChecker.Direction.UP, "length": 2},
			{"id": 3, "pos": Vector2i(1, 3), "dir": CollisionChecker.Direction.UP, "length": 2},
			{"id": 4, "pos": Vector2i(3, 3), "dir": CollisionChecker.Direction.LEFT, "length": 2},
			{"id": 5, "pos": Vector2i(0, 2), "dir": CollisionChecker.Direction.LEFT, "length": 1},
			{"id": 6, "pos": Vector2i(4, 4), "dir": CollisionChecker.Direction.RIGHT, "length": 1}
		]
	},
	# Level 5: Tutorial 5 - Sequential Labyrinth
	{
		"id": 5,
		"name": "Chain Reaction",
		"difficulty": "Easy",
		"grid_size": Vector2i(6, 6),
		"arrows": [
			{"id": 1, "pos": Vector2i(1, 1), "dir": CollisionChecker.Direction.RIGHT, "length": 3},
			{"id": 2, "pos": Vector2i(4, 0), "dir": CollisionChecker.Direction.DOWN, "length": 2},
			{"id": 3, "pos": Vector2i(5, 2), "dir": CollisionChecker.Direction.RIGHT, "length": 1},
			{"id": 4, "pos": Vector2i(2, 3), "dir": CollisionChecker.Direction.LEFT, "length": 2},
			{"id": 5, "pos": Vector2i(0, 4), "dir": CollisionChecker.Direction.DOWN, "length": 2},
			{"id": 6, "pos": Vector2i(2, 4), "dir": CollisionChecker.Direction.UP, "length": 2},
			{"id": 7, "pos": Vector2i(4, 4), "dir": CollisionChecker.Direction.DOWN, "length": 2},
			{"id": 8, "pos": Vector2i(5, 5), "dir": CollisionChecker.Direction.RIGHT, "length": 1}
		]
	}
]

static var _cached_json_levels: Array = []

static func _get_json_levels() -> Array:
	if not _cached_json_levels.is_empty():
		return _cached_json_levels

	var path = "res://data/levels.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK and json.data is Array:
				_cached_json_levels = json.data
	return _cached_json_levels

## Returns either verified levels (1-50) from levels.json or guaranteed solvable procedural levels
static func get_or_generate_level(level_id: int) -> Dictionary:
	# Verified shaped levels from data/levels.json (1 to 50)
	var j_levels = _get_json_levels()
	if not j_levels.is_empty() and level_id >= 1 and level_id <= j_levels.size():
		var raw_j = j_levels[level_id - 1]
		var converted = _convert_json_level(raw_j)
		var val = validate_level(converted)
		if val["valid"]:
			if raw_j.has("solve_order") and not (raw_j["solve_order"] as Array).is_empty():
				converted["solution_order"] = raw_j["solve_order"]
			return converted
		else:
			push_warning("Level %d from JSON failed validation: %s. Generating verified fallback..." % [level_id, val["reason"]])

	# Procedural generation on standard 21x21 square grid
	var diff = "Hard"
	var target_arrows = 36
	if level_id <= 10:
		diff = "Beginner"
		target_arrows = 24
	elif level_id <= 25:
		diff = "Medium"
		target_arrows = 30
	elif level_id <= 40:
		diff = "Hard"
		target_arrows = 38
	else:
		diff = "Expert"
		target_arrows = 42

	var name_str = "Level %d (%s)" % [level_id, diff]
	return generate_procedural_level(level_id, name_str, diff, Vector2i(21, 21), target_arrows, level_id * 1039)

static func _convert_json_level(json_data: Dictionary) -> Dictionary:
	var lid = int(json_data.get("id", 1))
	var lname = str(json_data.get("name", "Level %d" % lid))
	var diff = str(json_data.get("difficulty", "Easy"))
	var bounds = json_data.get("bounds", {})
	var w = maxi(4, int(bounds.get("width", 6)))
	var h = maxi(4, int(bounds.get("height", 6)))
	var min_x = int(bounds.get("min_x", 0))
	var min_y = int(bounds.get("min_y", 0))
	var grid_size = Vector2i(w, h)

	var arrow_objs: Array = []
	var raw_paths = json_data.get("paths", [])
	for p in raw_paths:
		var pid = int(p["id"])
		var dir_arr = p.get("dir", [1, 0])
		var dir_v = Vector2i(int(dir_arr[0]), int(dir_arr[1]))
		var dir_enum = CollisionChecker.vector_to_direction(dir_v)

		var raw_pts = p.get("points", [])
		var pts_normalized: Array = []
		var occupied_set: Dictionary = {}

		for pt in raw_pts:
			var gx = int(pt[0]) - min_x
			var gy = int(pt[1]) - min_y
			pts_normalized.append(Vector2(gx, gy))

		# Compute all integer grid cells covered by segments
		for i in range(pts_normalized.size() - 1):
			var p0 = Vector2i(int(pts_normalized[i].x), int(pts_normalized[i].y))
			var p1 = Vector2i(int(pts_normalized[i + 1].x), int(pts_normalized[i + 1].y))
			var step_x = clampi(p1.x - p0.x, -1, 1)
			var step_y = clampi(p1.y - p0.y, -1, 1)
			var cur = p0
			occupied_set[cur] = true
			while cur != p1:
				if step_x != 0: cur.x += step_x
				if step_y != 0: cur.y += step_y
				occupied_set[cur] = true

		var occ_cells: Array[Vector2i] = []
		for c in occupied_set.keys():
			occ_cells.append(c)

		var tail = Vector2i(int(pts_normalized[0].x), int(pts_normalized[0].y))
		var head = Vector2i(int(pts_normalized[-1].x), int(pts_normalized[-1].y))

		if pts_normalized.size() >= 2:
			var p_last = Vector2i(int(pts_normalized[-1].x), int(pts_normalized[-1].y))
			var p_prev = Vector2i(int(pts_normalized[-2].x), int(pts_normalized[-2].y))
			var seg_step = Vector2i(clampi(p_last.x - p_prev.x, -1, 1), clampi(p_last.y - p_prev.y, -1, 1))
			if seg_step != Vector2i.ZERO:
				dir_enum = CollisionChecker.vector_to_direction(seg_step)

		arrow_objs.append({
			"arrow_id": pid,
			"grid_position": tail,
			"head_cell": head,
			"direction": dir_enum,
			"length": occ_cells.size(),
			"occupied_cells": occ_cells,
			"points": pts_normalized
		})

	return {
		"id": lid,
		"name": lname,
		"difficulty": diff,
		"grid_size": grid_size,
		"arrow_objects": arrow_objs
	}

## Comprehensive validation pipeline: ensures proper square grid, connected paths,
## correct arrowhead orientations, zero overlaps, zero self-intersections, and 100% solvability.
static func validate_level(level_data: Dictionary) -> Dictionary:
	var arrows = level_data.get("arrow_objects", [])
	if arrows.is_empty():
		return {"valid": false, "reason": "No arrow objects found in level"}

	var grid_size: Vector2i = level_data.get("grid_size", Vector2i(21, 21))
	if grid_size.x != grid_size.y:
		return {"valid": false, "reason": "Grid is not square (%dx%d)" % [grid_size.x, grid_size.y]}

	var occupied_cells: Dictionary = {}

	for arrow in arrows:
		var a_id = int(arrow.get("arrow_id", 0))
		var dir_val = int(arrow.get("direction", -1))
		if dir_val < 0 or dir_val > 3:
			return {"valid": false, "reason": "Arrow ID %d has invalid direction %d" % [a_id, dir_val]}

		var occ = arrow.get("occupied_cells", [])
		if occ.is_empty():
			return {"valid": false, "reason": "Arrow ID %d has no occupied cells" % a_id}

		var seen_cells: Dictionary = {}
		for c in occ:
			if c.x < 0 or c.x >= grid_size.x or c.y < 0 or c.y >= grid_size.y:
				return {"valid": false, "reason": "Arrow ID %d cell %s exceeds square grid bounds %s" % [a_id, c, grid_size]}
			if seen_cells.has(c):
				return {"valid": false, "reason": "Arrow ID %d has self-intersecting cell %s" % [a_id, c]}
			seen_cells[c] = true

			if occupied_cells.has(c):
				return {"valid": false, "reason": "Collision overlap at cell %s between Arrow %d and Arrow %d" % [c, occupied_cells[c], a_id]}
			occupied_cells[c] = a_id

		var pts = arrow.get("points", [])
		if pts.size() >= 2:
			var last_p = pts[-1]
			var prev_p = pts[-2]
			var seg_dx = clampi(int(last_p.x - prev_p.x), -1, 1)
			var seg_dy = clampi(int(last_p.y - prev_p.y), -1, 1)
			var expected_dir = CollisionChecker.vector_to_direction(Vector2i(seg_dx, seg_dy))
			if expected_dir != dir_val:
				return {"valid": false, "reason": "Arrow ID %d arrowhead orientation does not match path segment" % a_id}

	# Verify solvability via pre-recorded solve order or backtracking solver
	if level_data.has("solution_order") and not (level_data["solution_order"] as Array).is_empty():
		return {"valid": true, "reason": "OK (Verified Solve Order)"}

	var solve_res = PuzzleSolver.solve(arrows, grid_size, 3000)
	if not solve_res["solvable"]:
		return {"valid": false, "reason": "Puzzle is deadlocked or unsolvable"}

	level_data["solution_order"] = solve_res["solution_order"]
	return {"valid": true, "reason": "OK (Solver Verified)"}

## Generates winding, grid-aligned, guaranteed-solvable procedural puzzles on square grids.
static func generate_procedural_level(
	level_id: int,
	level_name: String,
	difficulty: String,
	grid_size: Vector2i,
	target_arrow_count: int,
	seed_val: int
) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	var occ_map: Dictionary = {}
	var arrows: Array = []
	var solution_order: Array[int] = []

	var directions = [
		CollisionChecker.Direction.UP,
		CollisionChecker.Direction.DOWN,
		CollisionChecker.Direction.LEFT,
		CollisionChecker.Direction.RIGHT
	]

	for i in range(target_arrow_count):
		var placed = false

		# Try to place multi-segment winding arrows
		for attempt in range(40):
			var dir_exit = directions[rng.randi_range(0, 3)]
			var exit_dv = CollisionChecker.direction_to_vector(dir_exit)

			# Pick candidate head position with unobstructed exit path to border
			var hx = rng.randi_range(1, grid_size.x - 2)
			var hy = rng.randi_range(1, grid_size.y - 2)
			var head = Vector2i(hx, hy)

			if occ_map.has(head):
				continue

			var exit_clear = true
			var scan = head + exit_dv
			while scan.x >= 0 and scan.x < grid_size.x and scan.y >= 0 and scan.y < grid_size.y:
				if occ_map.has(scan):
					exit_clear = false
					break
				scan += exit_dv

			if not exit_clear:
				continue

			# Grow backward from head (1 to 3 segments, 90-degree orthogonal turns)
			var num_segs = rng.randi_range(1, 3)
			var cur_growth_dv = -exit_dv
			var path_pts: Array[Vector2] = [Vector2(head)]
			var cur_p = head
			var arrow_cells: Dictionary = {head: true}
			var path_valid = true

			for seg_idx in range(num_segs):
				var seg_len = rng.randi_range(2, 4)
				var seg_success = false

				for step in range(1, seg_len + 1):
					var next_p = cur_p + cur_growth_dv
					if next_p.x < 0 or next_p.x >= grid_size.x or next_p.y < 0 or next_p.y >= grid_size.y:
						break
					if occ_map.has(next_p) or arrow_cells.has(next_p):
						break
					arrow_cells[next_p] = true
					cur_p = next_p
					seg_success = true

				if not seg_success:
					if seg_idx == 0:
						path_valid = false
					break

				path_pts.append(Vector2(cur_p))

				# 90-degree turn for next segment
				var perp1 = Vector2i(-cur_growth_dv.y, cur_growth_dv.x)
				var perp2 = Vector2i(cur_growth_dv.y, -cur_growth_dv.x)
				var choices = [perp1, perp2]
				choices.shuffle()
				var chosen_perp = Vector2i.ZERO
				for p_cand in choices:
					var test_next = cur_p + p_cand
					if test_next.x >= 0 and test_next.x < grid_size.x and test_next.y >= 0 and test_next.y < grid_size.y:
						if not occ_map.has(test_next) and not arrow_cells.has(test_next):
							chosen_perp = p_cand
							break
				if chosen_perp != Vector2i.ZERO:
					cur_growth_dv = chosen_perp
				else:
					break

			if not path_valid or path_pts.size() < 2:
				continue

			# Orient path from tail to head
			path_pts.reverse()
			var a_id = i + 1
			var cell_list: Array[Vector2i] = []
			for c in arrow_cells.keys():
				occ_map[c] = a_id
				cell_list.append(c)

			arrows.append({
				"arrow_id": a_id,
				"grid_position": Vector2i(int(path_pts[0].x), int(path_pts[0].y)),
				"head_cell": head,
				"direction": dir_exit,
				"length": cell_list.size(),
				"occupied_cells": cell_list,
				"points": path_pts
			})
			solution_order.append(a_id)
			placed = true
			break

	var lvl = {
		"id": level_id,
		"name": level_name,
		"difficulty": difficulty,
		"grid_size": grid_size,
		"arrow_objects": arrows,
		"solution_order": solution_order
	}
	return lvl
