class_name Arrow
extends Area2D

## Grid-Aligned Arrow Object with Precise Coordinate Alignment.
## Features:
## - Tail starts precisely at the tail grid dot (no offset).
## - Intermediate turns 90° precisely at grid dots with smooth corner rounding.
## - Sharp triangular arrowhead ending precisely at the head grid dot (no overshoot).
## - Smooth polyline shaft connecting seamlessly to the arrowhead base (no gap).
## - Exact Euclidean point-to-segment and arrowhead triangle hit testing matching visible path.
## - Animated sliding exit along exit trajectory.
## - Shake animation and heart deduction on blocked path.

signal arrow_tapped(arrow: Arrow)
signal arrow_exit_completed(arrow: Arrow)

enum ArrowState { IDLE, SELECTED, EXITING, REMOVED }

var arrow_id: int = 0
var grid_position: Vector2i = Vector2i.ZERO # Tail coordinate
var head_cell: Vector2i = Vector2i.ZERO     # Head coordinate
var direction: CollisionChecker.Direction = CollisionChecker.Direction.UP
var length: int = 1
var cell_size: float = 40.0
var board_origin: Vector2 = Vector2.ZERO
var state: ArrowState = ArrowState.IDLE

var occupied_cells: Array[Vector2i] = []
var raw_points: PackedVector2Array = PackedVector2Array()

var base_color: Color = Color("#3E2312")
var current_color: Color = Color("#3E2312")
var blocked_color: Color = Color("#E53935")
var hint_color: Color = Color("#FFA028")
var bg_color: Color = Color("#FAF6ED")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# GameBoard manages touch detection via exact geometric hit-testing.
	# Disable Area2D physics picking to prevent overlapping or duplicate selection events.
	input_pickable = false
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape:
		collision_shape.disabled = true
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)

func setup(
	p_id: int,
	p_pos: Vector2i,
	p_dir: CollisionChecker.Direction,
	p_len: int,
	p_cell_size: float,
	p_board_origin: Vector2,
	p_occupied: Array[Vector2i] = [],
	p_pts: PackedVector2Array = PackedVector2Array(),
	p_head: Vector2i = Vector2i.ZERO
) -> void:
	arrow_id = p_id
	grid_position = p_pos
	direction = p_dir
	length = maxi(1, p_len)
	cell_size = p_cell_size
	board_origin = p_board_origin
	state = ArrowState.IDLE
	raw_points = p_pts

	# Setup occupied cells and head cell
	occupied_cells.clear()
	if not p_occupied.is_empty():
		for c in p_occupied:
			occupied_cells.append(c)
	else:
		var dir_vec = CollisionChecker.direction_to_vector(direction)
		for i in range(length):
			occupied_cells.append(grid_position + dir_vec * i)

	if p_head != Vector2i.ZERO:
		head_cell = p_head
	elif not p_pts.is_empty():
		head_cell = Vector2i(int(p_pts[-1].x), int(p_pts[-1].y))
	elif length > 1:
		var dir_vec = CollisionChecker.direction_to_vector(direction)
		head_cell = grid_position + dir_vec * (length - 1)
	else:
		head_cell = grid_position

	# Place node exactly at the tail grid dot
	position = board_origin + Vector2(grid_position) * cell_size

	_build_collision_and_visuals()

func update_grid_scale(p_cell_size: float, p_board_origin: Vector2) -> void:
	cell_size = p_cell_size
	board_origin = p_board_origin
	position = board_origin + Vector2(grid_position) * cell_size
	_build_collision_and_visuals()
	queue_redraw()

func _build_collision_and_visuals() -> void:
	if collision_shape:
		collision_shape.disabled = true
	input_pickable = false
	current_color = base_color
	queue_redraw()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if state != ArrowState.IDLE:
		return

	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			arrow_tapped.emit(self)
	elif event is InputEventScreenTouch:
		var st = event as InputEventScreenTouch
		if st.pressed:
			arrow_tapped.emit(self)

## Checks whether a board-local coordinate is within this arrow's touch boundary
func is_local_point_inside(board_local_pos: Vector2) -> bool:
	if state != ArrowState.IDLE:
		return false
	var threshold = maxf(22.0, cell_size * 0.45)
	return get_distance_to_local_point(board_local_pos) <= threshold

## Calculates the exact minimum Euclidean distance from a board-local coordinate
## to this arrow's visible geometry (shaft polyline segments, arrowhead triangle, and corners).
func get_distance_to_local_point(board_local_pos: Vector2) -> float:
	if state != ArrowState.IDLE:
		return 999999.0

	# Arrow-local coordinate relative to arrow origin (tail dot)
	var arrow_local = board_local_pos - position
	var pts = _get_base_local_points()
	var min_d = 999999.0

	var dir_vec = CollisionChecker.direction_to_vector(direction)
	var f_dir = Vector2(float(dir_vec.x), float(dir_vec.y))
	var head_len = clampf(cell_size * 0.40, 15.0, 28.0)
	var head_half_w = head_len * 0.65

	if pts.size() >= 2:
		var tip = pts[-1]
		var last_seg = tip - pts[-2]
		if last_seg.length_squared() > 0.001:
			f_dir = last_seg.normalized()
		var s_dir = Vector2(-f_dir.y, f_dir.x)

		# 1. Distance to shaft polyline segments
		for i in range(pts.size() - 1):
			var d_seg = _dist_to_segment(arrow_local, pts[i], pts[i + 1])
			if d_seg < min_d:
				min_d = d_seg

		# 2. Arrowhead triangle test
		var base_pt = tip - f_dir * head_len
		var wing1 = base_pt + s_dir * head_half_w
		var wing2 = base_pt - s_dir * head_half_w

		if _is_point_in_triangle(arrow_local, tip, wing1, wing2):
			return 0.0

		var d_w1 = _dist_to_segment(arrow_local, tip, wing1)
		var d_w2 = _dist_to_segment(arrow_local, tip, wing2)
		var d_base = _dist_to_segment(arrow_local, wing1, wing2)
		min_d = minf(min_d, minf(d_w1, minf(d_w2, d_base)))

		# 3. Distance to corner elbows and tail
		for pt in pts:
			var d_pt = arrow_local.distance_to(pt)
			if d_pt < min_d:
				min_d = d_pt
	else:
		# Single point fallback
		var tip = Vector2.ZERO
		var s_dir = Vector2(-f_dir.y, f_dir.x)
		var base_pt = tip - f_dir * head_len
		var wing1 = base_pt + s_dir * head_half_w
		var wing2 = base_pt - s_dir * head_half_w

		if _is_point_in_triangle(arrow_local, tip, wing1, wing2):
			return 0.0

		var d_w1 = _dist_to_segment(arrow_local, tip, wing1)
		var d_w2 = _dist_to_segment(arrow_local, tip, wing2)
		var d_base = _dist_to_segment(arrow_local, wing1, wing2)
		var d_head = _dist_to_segment(arrow_local, base_pt, tip)
		min_d = minf(min_d, minf(d_w1, minf(d_w2, minf(d_base, d_head))))
		min_d = minf(min_d, arrow_local.distance_to(tip))

	return min_d

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var l2 = ab.length_squared()
	if l2 < 0.001:
		return p.distance_to(a)
	var t = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	var proj = a + ab * t
	return p.distance_to(proj)

static func _is_point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 = (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)
	var d2 = (p.x - c.x) * (b.y - c.y) - (b.x - c.x) * (p.y - c.y)
	var d3 = (p.x - a.x) * (c.y - a.y) - (c.x - a.x) * (p.y - a.y)
	var has_neg = (d1 < -0.001) or (d2 < -0.001) or (d3 < -0.001)
	var has_pos = (d1 > 0.001) or (d2 > 0.001) or (d3 > 0.001)
	return not (has_neg and has_pos)

var _is_exiting: bool = false
var _exit_track: PackedVector2Array = PackedVector2Array()
var _exit_cum_dists: PackedFloat32Array = PackedFloat32Array()
var _exit_arrow_len: float = 0.0
var _exit_total_travel: float = 1200.0
var _exit_final_dir: Vector2 = Vector2.RIGHT
var exit_progress: float = 0.0:
	set(val):
		exit_progress = val
		queue_redraw()

func _sample_track(s: float) -> Vector2:
	if s <= 0.0:
		return _exit_track[0]
	if s >= _exit_cum_dists[-1]:
		return _exit_track[-1] + _exit_final_dir * (s - _exit_cum_dists[-1])
	for i in range(_exit_cum_dists.size() - 1):
		if s <= _exit_cum_dists[i + 1]:
			var seg_l = _exit_cum_dists[i + 1] - _exit_cum_dists[i]
			if seg_l <= 0.0001:
				return _exit_track[i]
			var t = (s - _exit_cum_dists[i]) / seg_l
			return _exit_track[i].lerp(_exit_track[i + 1], t)
	return _exit_track[-1]

func apply_theme(theme: Dictionary) -> void:
	base_color = theme.get("arrow_line", Color("#4A3525"))
	blocked_color = theme.get("arrow_blocked", Color("#E53935"))
	hint_color = theme.get("arrow_hint", Color("#FFB300"))
	bg_color = theme.get("bg", Color("#FAF4E8"))
	if state == ArrowState.IDLE:
		current_color = base_color
	queue_redraw()

func set_guidance_highlight(is_active: bool, is_clear: bool, clear_col: Color = Color("#2E7D32"), block_col: Color = Color("#E53935")) -> void:
	if not is_active:
		current_color = base_color
		scale = Vector2.ONE
	else:
		current_color = clear_col if is_clear else block_col
		scale = Vector2(1.06, 1.06)
	queue_redraw()

func _get_base_local_points() -> PackedVector2Array:
	var pts = PackedVector2Array()
	if raw_points.size() >= 2:
		for pt in raw_points:
			pts.append((pt - Vector2(grid_position)) * cell_size)
	else:
		var dir_vec = CollisionChecker.direction_to_vector(direction)
		var f_dir = Vector2(float(dir_vec.x), float(dir_vec.y))
		pts.append(Vector2.ZERO)
		if length > 1:
			pts.append(f_dir * (float(length - 1) * cell_size))
		else:
			# 1-cell arrow: base and tip
			var head_len = minf(cell_size * 0.44, 15.0)
			pts.clear()
			pts.append(-f_dir * (head_len * 0.8))
			pts.append(Vector2.ZERO)
	return pts

func _get_current_draw_points() -> PackedVector2Array:
	if not _is_exiting:
		return _get_base_local_points()

	var current_travel = exit_progress * _exit_total_travel
	var s_tail = current_travel
	var s_head = current_travel + _exit_arrow_len

	var res = PackedVector2Array()
	res.append(_sample_track(s_tail))
	for i in range(1, _exit_track.size() - 1):
		var d = _exit_cum_dists[i]
		if d > s_tail + 0.5 and d < s_head - 0.5:
			res.append(_exit_track[i])
	res.append(_sample_track(s_head))
	return res

func animate_exit(target_pos: Vector2 = Vector2.ZERO, duration: float = 0.62) -> void:
	state = ArrowState.EXITING
	input_pickable = false
	if collision_shape:
		collision_shape.disabled = true
	z_index = 20

	if SoundManager.instance:
		SoundManager.instance.play_whoosh()

	var base_pts = _get_base_local_points()
	var tip = base_pts[-1]
	var dir_vec = CollisionChecker.direction_to_vector(direction)
	var f_dir = Vector2(float(dir_vec.x), float(dir_vec.y))
	if base_pts.size() >= 2:
		var last_seg = tip - base_pts[-2]
		if last_seg.length_squared() > 0.001:
			f_dir = last_seg.normalized()
	_exit_final_dir = f_dir

	# Calculate distance to viewport edge along f_dir for a smooth, natural glide
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 10.0 or vp_size.y <= 10.0:
		vp_size = Vector2(720.0, 1280.0)

	var tip_glob = global_position + tip
	var d_candidates: Array[float] = []
	if f_dir.x > 0.01:
		d_candidates.append((vp_size.x - tip_glob.x) / f_dir.x)
	elif f_dir.x < -0.01:
		d_candidates.append((0.0 - tip_glob.x) / f_dir.x)

	if f_dir.y > 0.01:
		d_candidates.append((vp_size.y - tip_glob.y) / f_dir.y)
	elif f_dir.y < -0.01:
		d_candidates.append((0.0 - tip_glob.y) / f_dir.y)

	var min_pos: float = -1.0
	for d in d_candidates:
		if d > 0.0:
			if min_pos < 0.0 or d < min_pos:
				min_pos = d

	var dist_to_edge: float = min_pos if min_pos > 0.0 else 750.0
	var exit_dist: float = dist_to_edge + 140.0

	_exit_track = base_pts.duplicate()
	_exit_track.append(tip + f_dir * exit_dist)

	_exit_cum_dists = PackedFloat32Array([0.0])
	for i in range(_exit_track.size() - 1):
		_exit_cum_dists.append(_exit_cum_dists[i] + _exit_track[i].distance_to(_exit_track[i + 1]))

	_exit_arrow_len = _exit_cum_dists[_exit_track.size() - 2]
	# Total travel distance ensures the TAIL completely clears the screen margin
	_exit_total_travel = _exit_cum_dists[-1]

	_is_exiting = true
	exit_progress = 0.0

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "exit_progress", 1.0, duration)

	tween.chain().tween_callback(func():
		state = ArrowState.REMOVED
		_is_exiting = false
		z_index = 0
		arrow_exit_completed.emit(self)
	)

func animate_blocked(on_complete: Callable = Callable()) -> void:
	if state != ArrowState.IDLE:
		return

	state = ArrowState.SELECTED
	current_color = blocked_color
	queue_redraw()

	if SoundManager.instance:
		SoundManager.instance.play_error()

	var dir_vec = CollisionChecker.direction_to_vector(direction)
	var perp = Vector2(-dir_vec.y, dir_vec.x) * 10.0
	var original_pos = position

	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + perp, 0.04)
	tween.tween_property(self, "position", original_pos - perp, 0.05)
	tween.tween_property(self, "position", original_pos + perp * 0.6, 0.04)
	tween.tween_property(self, "position", original_pos - perp * 0.4, 0.04)
	tween.tween_property(self, "position", original_pos, 0.04)
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		current_color = base_color
		state = ArrowState.IDLE
		position = original_pos
		queue_redraw()
		if on_complete.is_valid():
			on_complete.call()
	)

func animate_hint() -> void:
	var tw = create_tween().set_loops(3)
	tw.tween_callback(func():
		current_color = hint_color
		queue_redraw()
	)
	tw.tween_interval(0.2)
	tw.tween_callback(func():
		current_color = base_color
		queue_redraw()
	)
	tw.tween_interval(0.2)

func _draw() -> void:
	var pts = _get_current_draw_points()
	if pts.size() < 2:
		return

	var stroke_width = clampf(cell_size * 0.28, 9.5, 13.5)
	var head_len = clampf(cell_size * 0.58, 20.0, 32.0)
	var head_half_w = head_len * 0.65

	var tip = pts[-1]
	var last_seg = tip - pts[-2]
	var f_dir = Vector2(1, 0)
	var dir_vec = CollisionChecker.direction_to_vector(direction)
	if last_seg.length_squared() > 0.001:
		f_dir = last_seg.normalized()
	else:
		f_dir = Vector2(float(dir_vec.x), float(dir_vec.y))
	var s_dir = Vector2(-f_dir.y, f_dir.x)

	if length > 1 or raw_points.size() >= 2:
		# The shaft ends cleanly at the arrowhead base
		var shaft_pts = pts.duplicate()
		var seg_len = last_seg.length()
		var cutoff = minf(head_len * 0.78, seg_len * 0.85)
		shaft_pts[shaft_pts.size() - 1] = tip - f_dir * cutoff

		# Draw smooth continuous polyline shaft
		draw_polyline(shaft_pts, current_color, stroke_width, true)

		# Draw corner elbows at intermediate vertices and rounded tail cap
		for i in range(0, shaft_pts.size() - 1):
			draw_circle(shaft_pts[i], stroke_width * 0.5, current_color)
	else:
		# Single-cell arrow: small rounded tail cap
		draw_circle(tip - f_dir * (head_len * 0.8), stroke_width * 0.5, current_color)

	# Draw clean, sharp, symmetrical triangular arrowhead
	var base_pt = tip - f_dir * head_len
	var wing1 = base_pt + s_dir * head_half_w
	var wing2 = base_pt - s_dir * head_half_w
	draw_colored_polygon(PackedVector2Array([tip, wing1, wing2]), current_color)
