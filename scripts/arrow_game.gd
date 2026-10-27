class_name ArrowGame
extends Node

## Main game coordinator for Arrow Maze Escape ("Tap to Clear").
## Handles ray-segment clearance checks, lives/drops tracking, hints,
## and victory/game over transitions.

signal level_started(level_idx: int, level_data: Dictionary, theme: Dictionary)
signal drops_updated(current: int, maximum: int)
signal arrow_cleared(remaining: int, total: int)
signal level_completed(level_idx: int, level_data: Dictionary)
signal game_over(level_idx: int)
signal theme_changed(theme: Dictionary)

static var instance: ArrowGame

@export var canvas: ArrowCanvas

var current_level_data: Dictionary = {}
var active_path_ids: Array[int] = []
var cleared_count: int = 0
var total_arrows: int = 0
var drops_remaining: int = 3
var max_drops: int = 3
var combo_streak: int = 0
var is_game_active: bool = false

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	if canvas:
		canvas.path_clicked.connect(_on_path_clicked)
	call_deferred("_start_first_level")

func _start_first_level() -> void:
	var start_idx = 0
	if ArrowData.instance:
		start_idx = ArrowData.instance.current_level_idx
	load_level(start_idx)

func load_level(idx: int) -> void:
	if ArrowData.instance == null:
		return

	current_level_data = ArrowData.instance.get_level(idx)
	if current_level_data.is_empty():
		return

	max_drops = int(current_level_data.get("drops", 3))
	drops_remaining = max_drops
	combo_streak = 0
	is_game_active = true

	active_path_ids.clear()
	var raw_paths = current_level_data.get("paths", [])
	total_arrows = raw_paths.size()
	cleared_count = 0
	for p in raw_paths:
		active_path_ids.append(int(p["id"]))

	var theme = ArrowData.instance.get_current_theme()
	if canvas:
		canvas.set_theme_colors(theme)
		canvas.load_level(current_level_data)

	level_started.emit(idx, current_level_data, theme)
	drops_updated.emit(drops_remaining, max_drops)

func restart_level() -> void:
	if ArrowData.instance:
		load_level(ArrowData.instance.current_level_idx)

func next_level() -> void:
	if ArrowData.instance:
		var next_idx = (ArrowData.instance.current_level_idx + 1) % ArrowData.instance.levels.size()
		load_level(next_idx)

func prev_level() -> void:
	if ArrowData.instance:
		var prev_idx = (ArrowData.instance.current_level_idx - 1 + ArrowData.instance.levels.size()) % ArrowData.instance.levels.size()
		load_level(prev_idx)

func _on_path_clicked(path_id: int) -> void:
	if not is_game_active or not active_path_ids.has(path_id):
		return

	var is_free = check_arrow_free(path_id)

	if is_free:
		combo_streak += 1
		active_path_ids.erase(path_id)
		cleared_count += 1

		# Sound with combo pitch
		if SoundManager.instance:
			SoundManager.instance.play_paint(1.0 + float(combo_streak) * 0.05)

		# Animate slide out
		var path_data = _get_path_data(path_id)
		var dir = Vector2(float(path_data["dir"][0]), float(path_data["dir"][1])).normalized()

		canvas.animate_slide_out(path_id, dir, func():
			arrow_cleared.emit(active_path_ids.size(), total_arrows)
			if active_path_ids.is_empty() and is_game_active:
				_handle_level_won()
		)
	else:
		combo_streak = 0
		if SoundManager.instance:
			SoundManager.instance.play_error()

		canvas.animate_error(path_id)
		drops_remaining = maxi(0, drops_remaining - 1)
		drops_updated.emit(drops_remaining, max_drops)

		if drops_remaining <= 0:
			_handle_game_over()

func check_arrow_free(path_id: int) -> bool:
	var path_data = _get_path_data(path_id)
	if path_data.is_empty():
		return false

	var pts = path_data["points"]
	var head = Vector2(float(pts[-1][0]), float(pts[-1][1]))
	var dir = Vector2(float(path_data["dir"][0]), float(path_data["dir"][1]))

	for other_id in active_path_ids:
		if other_id == path_id:
			continue
		var other_data = _get_path_data(other_id)
		var other_pts = other_data["points"]
		for i in range(other_pts.size() - 1):
			var a = Vector2(float(other_pts[i][0]), float(other_pts[i][1]))
			var b = Vector2(float(other_pts[i + 1][0]), float(other_pts[i + 1][1]))
			var hit = _ray_intersects_segment(head, dir, a, b)
			if hit:
				return false
	return true

func _ray_intersects_segment(origin: Vector2, direction: Vector2, a: Vector2, b: Vector2) -> bool:
	var ox = origin.x
	var oy = origin.y
	var dx = roundi(direction.x)
	var dy = roundi(direction.y)

	var ax = a.x
	var ay = a.y
	var bx = b.x
	var by = b.y

	# Vertical segment
	if is_equal_approx(ax, bx):
		var sx = ax
		var sy_min = minf(ay, by)
		var sy_max = maxf(ay, by)
		if dx == 1 and sx > ox and sy_min <= oy and oy <= sy_max:
			return true
		elif dx == -1 and sx < ox and sy_min <= oy and oy <= sy_max:
			return true
		elif dx == 0 and is_equal_approx(sx, ox):
			if dy == 1 and sy_min > oy:
				return true
			elif dy == -1 and sy_max < oy:
				return true
	# Horizontal segment
	elif is_equal_approx(ay, by):
		var sy = ay
		var sx_min = minf(ax, bx)
		var sx_max = maxf(ax, bx)
		if dy == 1 and sy > oy and sx_min <= ox and ox <= sx_max:
			return true
		elif dy == -1 and sy < oy and sx_min <= ox and ox <= sx_max:
			return true
		elif dy == 0 and is_equal_approx(sy, oy):
			if dx == 1 and sx_min > ox:
				return true
			elif dx == -1 and sx_max < ox:
				return true

	return false

func _get_path_data(path_id: int) -> Dictionary:
	var raw_paths = current_level_data.get("paths", [])
	for p in raw_paths:
		if int(p["id"]) == path_id:
			return p
	return {}

func request_hint() -> bool:
	if not is_game_active or active_path_ids.is_empty():
		return false

	# Find any currently free arrow
	var free_id = -1
	for pid in active_path_ids:
		if check_arrow_free(pid):
			free_id = pid
			break

	if free_id != -1 and canvas:
		if SoundManager.instance:
			SoundManager.instance.play_swipe()
		canvas.animate_hint(free_id)
		return true

	return false

func toggle_theme() -> void:
	if ArrowData.instance:
		var new_theme = ArrowData.instance.toggle_theme()
		if canvas:
			canvas.set_theme_colors(new_theme)
		theme_changed.emit(new_theme)

func refill_drops() -> void:
	drops_remaining = max_drops
	is_game_active = true
	drops_updated.emit(drops_remaining, max_drops)

func _handle_level_won() -> void:
	is_game_active = false
	if ArrowData.instance:
		ArrowData.instance.mark_level_completed(int(current_level_data.get("id", 1)))
	if SoundManager.instance:
		SoundManager.instance.play_win()
	level_completed.emit(ArrowData.instance.current_level_idx, current_level_data)

func _handle_game_over() -> void:
	is_game_active = false
	game_over.emit(ArrowData.instance.current_level_idx)
