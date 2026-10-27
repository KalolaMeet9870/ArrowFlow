class_name ArrowCanvas
extends Control

## Custom vector canvas for rendering interlocking arrow paths with smooth
## slide-out animations, red error wiggles, golden hints, and precise touch hit-testing.

signal path_clicked(path_id: int)

class PathState extends RefCounted:
	var id: int = 0
	var points: PackedVector2Array = PackedVector2Array()
	var dir: Vector2 = Vector2.RIGHT
	var is_cleared: bool = false
	var is_sliding: bool = false
	var slide_offset: Vector2 = Vector2.ZERO
	var slide_alpha: float = 1.0
	var wiggle_offset: Vector2 = Vector2.ZERO
	var color_override: Color = Color.TRANSPARENT
	var is_hinted: bool = false

@export var line_width: float = 4.8
@export var arrow_head_size: float = 14.0
@export var hit_distance_threshold: float = 28.0

var level_data: Dictionary = {}
var paths_dict: Dictionary = {} # id -> PathState
var active_theme: Dictionary = {}

var grid_scale: float = 30.0
var grid_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(300, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_theme_colors(theme: Dictionary) -> void:
	active_theme = theme
	queue_redraw()

func load_level(data: Dictionary) -> void:
	level_data = data
	paths_dict.clear()

	var raw_paths = data.get("paths", [])
	for p in raw_paths:
		var pid = int(p["id"])
		var pts: Array = p["points"]
		var dir_arr: Array = p["dir"]

		var packed_pts = PackedVector2Array()
		for pt in pts:
			packed_pts.append(Vector2(float(pt[0]), float(pt[1])))

		var ps = PathState.new()
		ps.id = pid
		ps.points = packed_pts
		ps.dir = Vector2(float(dir_arr[0]), float(dir_arr[1])).normalized()
		paths_dict[pid] = ps

	_recalculate_transform()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_transform()
		queue_redraw()

func _recalculate_transform() -> void:
	if not level_data.has("bounds") or size.x <= 10 or size.y <= 10:
		return

	var b = level_data["bounds"]
	var min_x = float(b["min_x"])
	var max_x = float(b["max_x"])
	var min_y = float(b["min_y"])
	var max_y = float(b["max_y"])

	var span_x = maxf(max_x - min_x, 1.0)
	var span_y = maxf(max_y - min_y, 1.0)

	var margin = 36.0
	var avail_w = maxf(size.x - margin * 2.0, 50.0)
	var avail_h = maxf(size.y - margin * 2.0, 50.0)

	grid_scale = minf(avail_w / span_x, avail_h / span_y)

	var content_w = span_x * grid_scale
	var content_h = span_y * grid_scale

	var start_x = (size.x - content_w) * 0.5 - min_x * grid_scale
	var start_y = (size.y - content_h) * 0.5 - min_y * grid_scale
	grid_offset = Vector2(start_x, start_y)

func _grid_to_screen(grid_pt: Vector2) -> Vector2:
	return grid_pt * grid_scale + grid_offset

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_tap(mb.position)
	elif event is InputEventScreenTouch:
		var st = event as InputEventScreenTouch
		if st.pressed:
			_handle_tap(st.position)

func _handle_tap(screen_pos: Vector2) -> void:
	var closest_id: int = -1
	var min_dist: float = hit_distance_threshold

	for pid in paths_dict.keys():
		var p: PathState = paths_dict[pid]
		if p.is_cleared or p.is_sliding:
			continue

		var pts: PackedVector2Array = p.points
		for i in range(pts.size() - 1):
			var a = _grid_to_screen(pts[i])
			var b = _grid_to_screen(pts[i + 1])
			var dist = _dist_to_segment(screen_pos, a, b)
			if dist < min_dist:
				min_dist = dist
				closest_id = pid

	if closest_id != -1:
		path_clicked.emit(closest_id)

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq < 1e-4:
		return p.distance_to(a)
	var t = clampf((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var proj = a + ab * t
	return p.distance_to(proj)

func animate_slide_out(path_id: int, dir: Vector2, on_complete: Callable) -> void:
	if not paths_dict.has(path_id):
		return
	var p: PathState = paths_dict[path_id]
	p.is_sliding = true
	p.is_hinted = false

	var slide_target = dir * maxf(size.x, size.y) * 1.3
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(p, "slide_offset", slide_target, 0.32)
	tween.tween_property(p, "slide_alpha", 0.0, 0.28)

	tween.chain().tween_callback(func():
		p.is_cleared = true
		p.is_sliding = false
		queue_redraw()
		if on_complete.is_valid():
			on_complete.call()
	)

	# Redraw loop during animation
	var redraw_tw = create_tween().set_loops(14)
	redraw_tw.tween_interval(0.025)
	redraw_tw.tween_callback(queue_redraw)

func animate_error(path_id: int) -> void:
	if not paths_dict.has(path_id):
		return
	var p: PathState = paths_dict[path_id]
	var blocked_color = active_theme.get("blocked", Color("#E53935"))
	p.color_override = blocked_color
	queue_redraw()

	var perp = Vector2(-p.dir.y, p.dir.x) * 7.0
	var tw = create_tween()
	tw.tween_property(p, "wiggle_offset", perp, 0.05)
	tw.tween_property(p, "wiggle_offset", -perp, 0.06)
	tw.tween_property(p, "wiggle_offset", perp * 0.5, 0.05)
	tw.tween_property(p, "wiggle_offset", Vector2.ZERO, 0.05)
	tw.tween_interval(0.25)
	tw.tween_property(p, "color_override", Color.TRANSPARENT, 0.25)

	var redraw_tw = create_tween().set_loops(18)
	redraw_tw.tween_interval(0.025)
	redraw_tw.tween_callback(queue_redraw)

func animate_hint(path_id: int) -> void:
	if not paths_dict.has(path_id):
		return
	var p: PathState = paths_dict[path_id]
	p.is_hinted = true
	var hint_color = active_theme.get("hint", Color("#FFB300"))
	p.color_override = hint_color

	var tw = create_tween().set_loops(3)
	tw.tween_property(p, "color_override", hint_color, 0.2)
	tw.tween_property(p, "color_override", active_theme.get("line", Color("#4A3525")), 0.2)
	tw.chain().tween_property(p, "color_override", Color.TRANSPARENT, 0.1)

	var redraw_tw = create_tween().set_loops(24)
	redraw_tw.tween_interval(0.03)
	redraw_tw.tween_callback(queue_redraw)

func _draw() -> void:
	var default_line_color = active_theme.get("line", Color("#4A3525"))
	var default_head_color = active_theme.get("head", Color("#4A3525"))

	for pid in paths_dict.keys():
		var p: PathState = paths_dict[pid]
		if p.is_cleared:
			continue

		var pts: PackedVector2Array = p.points
		if pts.size() < 2:
			continue

		var alpha = p.slide_alpha
		var offset = p.slide_offset + p.wiggle_offset

		var col = default_line_color
		if p.color_override.a > 0.01:
			col = p.color_override
		col.a *= alpha

		# Transform points to screen coordinates
		var screen_pts = PackedVector2Array()
		for pt in pts:
			screen_pts.append(_grid_to_screen(pt) + offset)

		# Draw smooth antialiased line
		draw_polyline(screen_pts, col, line_width, true)

		# Draw rounded caps at vertices
		for s_pt in screen_pts:
			draw_circle(s_pt, line_width * 0.5, col)

		# Draw Arrow Head at final point
		var tip = screen_pts[screen_pts.size() - 1]
		var forward_dir: Vector2 = p.dir
		var side_dir = Vector2(-forward_dir.y, forward_dir.x)

		var head_size = arrow_head_size
		var wing1 = tip - forward_dir * head_size + side_dir * (head_size * 0.58)
		var wing2 = tip - forward_dir * head_size - side_dir * (head_size * 0.58)

		var head_pts = PackedVector2Array([tip, wing1, wing2])
		draw_colored_polygon(head_pts, col)
