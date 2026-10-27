class_name GameBoard
extends Node2D

## Handles 2D grid rendering, arrow layout, collision checking, touch dispatch,
## and authentic ArrowFlow Long-Press Guidance trajectory preview.

signal move_succeeded(arrow: Arrow)
signal move_failed(arrow: Arrow)
signal board_cleared()
signal guidance_activated(is_clear: bool)
signal guidance_dismissed()
signal zoom_changed(zoom_factor: float)

@export var arrow_scene: PackedScene = preload("res://scenes/game/Arrow.tscn")
@export var board_area_size: Vector2 = Vector2(640, 720)

var grid_size: Vector2i = Vector2i(5, 5)
var cell_size: float = 64.0
var board_origin: Vector2 = Vector2.ZERO
var board_pixel_w: float = 0.0
var board_pixel_h: float = 0.0

var active_arrows: Array[Arrow] = []
var _undo_stack: Array[Dictionary] = []
var is_input_locked: bool = false
var _last_tap_msec: int = 0
var _last_touch_msec: int = -9999
var _active_pointer_id: int = -999 # -999 = none, -1 = mouse, >=0 = touch index

# --- Smooth Zoom & Pan System (Images 2, 3, 4) ---
var current_zoom: float = 1.0
var target_zoom: float = 1.0
var current_pan: Vector2 = Vector2.ZERO
var target_pan: Vector2 = Vector2.ZERO

const MIN_ZOOM: float = 1.0
const MAX_ZOOM: float = 2.8

var _touches: Dictionary = {} # pointer_id -> Vector2 (position in board_holder)
var _is_pinching: bool = false
var _is_panning: bool = false
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 1.0
var _pinch_start_mid: Vector2 = Vector2.ZERO
var _pan_start_pos: Vector2 = Vector2.ZERO
var _pan_start_target: Vector2 = Vector2.ZERO
var _last_double_tap_msec: int = 0
var _last_tap_holder_pos: Vector2 = Vector2.ZERO

var _cached_grid_dots: PackedVector2Array = PackedVector2Array()

# --- Long-Press Guidance State (Signature feature of ArrowFlow) ---
const LONG_PRESS_THRESHOLD_MSEC: int = 220
var _held_arrow: Arrow = null
var _touch_start_time: int = 0
var _touch_start_pos: Vector2 = Vector2.ZERO
var _is_guidance_active: bool = false
var _guidance_clear: bool = false
var _guidance_blocker_arrow: Arrow = null
var _guidance_stop_cell: Vector2i = Vector2i(-1, -1)
var _guidance_anim_offset: float = 0.0

# Hint preview timer
var _hint_active: bool = false
var _hint_arrow: Arrow = null
var _hint_timer: float = 0.0

# Theme cache
var current_theme: Dictionary = {
	"dots": Color(0.75, 0.68, 0.58, 0.45),
	"guide_clear": Color("#2E7D32"),
	"guide_blocked": Color("#E53935"),
	"arrow_line": Color("#4A3525"),
	"arrow_blocked": Color("#E53935"),
	"arrow_hint": Color("#FFB300")
}

func _ready() -> void:
	z_index = 10
	set_process(true)
	if ThemeManager.instance:
		current_theme = ThemeManager.instance.get_current_theme()

func _process(delta: float) -> void:
	# 0. Smooth animated zoom & pan interpolation for button clicks / wheel (skipped during direct finger touches)
	if not _is_pinching and not _is_panning:
		if absf(current_zoom - target_zoom) > 0.001 or current_pan.distance_to(target_pan) > 0.5:
			current_zoom = lerpf(current_zoom, target_zoom, clampf(delta * 18.0, 0.0, 1.0))
			current_pan = current_pan.lerp(target_pan, clampf(delta * 18.0, 0.0, 1.0))
			_apply_zoom_transform()
		elif current_zoom != target_zoom or current_pan != target_pan:
			current_zoom = target_zoom
			current_pan = target_pan
			_apply_zoom_transform()

	# 1. Update long-press hold detection for Guidance
	if _held_arrow != null and is_instance_valid(_held_arrow) and not _is_guidance_active and not _is_panning and not _is_pinching:
		var elapsed = Time.get_ticks_msec() - _touch_start_time
		if elapsed >= LONG_PRESS_THRESHOLD_MSEC:
			_activate_guidance(_held_arrow)

	# 2. Advance guidance marching dots animation
	if _is_guidance_active or _hint_active:
		_guidance_anim_offset += delta * 70.0
		if _guidance_anim_offset > 24.0:
			_guidance_anim_offset -= 24.0
		queue_redraw()

	# 3. Handle hint countdown
	if _hint_active:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			_hint_active = false
			_hint_arrow = null
			queue_redraw()

func apply_theme(theme: Dictionary) -> void:
	current_theme = theme
	for arrow in active_arrows:
		if is_instance_valid(arrow):
			arrow.apply_theme(theme)
	queue_redraw()

func setup_level(level_data: Dictionary, display_size: Vector2 = Vector2.ZERO) -> void:
	clear_board()

	if display_size != Vector2.ZERO:
		board_area_size = display_size

	grid_size = level_data.get("grid_size", Vector2i(5, 5))
	var arrow_objs: Array = level_data.get("arrow_objects", [])

	# Proportional grid sizing filling available screen space cleanly
	var padding = 16.0
	var avail_w = maxf(board_area_size.x - padding * 2.0, 100.0)
	var avail_h = maxf(board_area_size.y - padding * 2.0, 100.0)
	var step_x = maxi(1, grid_size.x - 1)
	var step_y = maxi(1, grid_size.y - 1)
	var max_cell_w = avail_w / float(step_x)
	var max_cell_h = avail_h / float(step_y)
	cell_size = floorf(minf(max_cell_w, max_cell_h))
	cell_size = clampf(cell_size, 18.0, 88.0)

	board_pixel_w = float(step_x) * cell_size
	board_pixel_h = float(step_y) * cell_size

	board_origin = Vector2(
		floorf((board_area_size.x - board_pixel_w) * 0.5),
		floorf((board_area_size.y - board_pixel_h) * 0.5)
	)

	# Instantiate and setup each arrow
	for a_data in arrow_objs:
		var arrow_node: Arrow = arrow_scene.instantiate() as Arrow
		add_child(arrow_node)

		var a_id = int(a_data.get("arrow_id", a_data.get("id", 0)))
		var a_pos: Vector2i = a_data.get("grid_position", a_data.get("pos", Vector2i.ZERO))
		var a_dir: CollisionChecker.Direction = a_data.get("direction", a_data.get("dir", CollisionChecker.Direction.UP))
		var a_len = int(a_data.get("length", 1))

		var p_occ: Array[Vector2i] = []
		if a_data.has("occupied_cells"):
			for c in a_data["occupied_cells"]:
				p_occ.append(c)

		var p_pts = PackedVector2Array()
		if a_data.has("points"):
			for pt in a_data["points"]:
				if pt is Vector2:
					p_pts.append(pt)
				elif pt is Array and pt.size() >= 2:
					p_pts.append(Vector2(float(pt[0]), float(pt[1])))

		var a_head = a_data.get("head_cell", Vector2i.ZERO)
		arrow_node.setup(a_id, a_pos, a_dir, a_len, cell_size, board_origin, p_occ, p_pts, a_head)
		arrow_node.apply_theme(current_theme)
		arrow_node.arrow_exit_completed.connect(_on_arrow_exit_completed)
		active_arrows.append(arrow_node)

	is_input_locked = false
	_active_pointer_id = -999
	_cancel_guidance()
	_recalculate_grid_dots()
	queue_redraw()

func update_board_size(new_size: Vector2) -> void:
	if new_size.x < 50 or new_size.y < 50:
		return
	board_area_size = new_size
	var padding = 16.0
	var avail_w = maxf(board_area_size.x - padding * 2.0, 100.0)
	var avail_h = maxf(board_area_size.y - padding * 2.0, 100.0)
	var step_x = maxi(1, grid_size.x - 1)
	var step_y = maxi(1, grid_size.y - 1)
	var max_cell_w = avail_w / float(step_x)
	var max_cell_h = avail_h / float(step_y)
	cell_size = floorf(minf(max_cell_w, max_cell_h))
	cell_size = clampf(cell_size, 18.0, 88.0)

	board_pixel_w = float(step_x) * cell_size
	board_pixel_h = float(step_y) * cell_size

	board_origin = Vector2(
		floorf((board_area_size.x - board_pixel_w) * 0.5),
		floorf((board_area_size.y - board_pixel_h) * 0.5)
	)

	for arrow in active_arrows:
		if is_instance_valid(arrow):
			arrow.update_grid_scale(cell_size, board_origin)
	_recalculate_grid_dots()
	queue_redraw()

func _recalculate_grid_dots() -> void:
	_cached_grid_dots.clear()
	if cell_size > 4.0 and grid_size.x > 0 and grid_size.y > 0:
		for gx in range(grid_size.x):
			var px = board_origin.x + float(gx) * cell_size
			for gy in range(grid_size.y):
				var py = board_origin.y + float(gy) * cell_size
				_cached_grid_dots.append(Vector2(px, py))

func clear_board() -> void:
	reset_zoom()
	_touches.clear()
	_is_pinching = false
	_is_panning = false
	for arrow in active_arrows:
		if is_instance_valid(arrow):
			arrow.queue_free()
	active_arrows.clear()
	_undo_stack.clear()
	is_input_locked = false
	_active_pointer_id = -999
	_cancel_guidance()
	queue_redraw()

## Converts position in board_holder (parent Control) to board-local coordinate.
func holder_pos_to_local(holder_pos: Vector2) -> Vector2:
	return transform.affine_inverse() * holder_pos

## Converts board-local coordinate to board_holder (parent Control) position.
func local_to_holder_pos(local_pos: Vector2) -> Vector2:
	return transform * local_pos

## Finds the arrow whose visible path or arrowhead is closest to local_pos,
## provided it is within the maximum hit threshold.
func get_arrow_at_local_pos(local_pos: Vector2) -> Arrow:
	var best_arrow: Arrow = null
	var hit_threshold = maxf(52.0 / maxf(current_zoom, 0.5), cell_size * 0.75)
	var best_dist = hit_threshold

	for arrow in active_arrows:
		if is_instance_valid(arrow) and arrow.state == Arrow.ArrowState.IDLE:
			var d = arrow.get_distance_to_local_point(local_pos)
			if d <= best_dist:
				best_dist = d
				best_arrow = arrow
	return best_arrow

## Converts global/world coordinates to board-local coordinates and performs exact hit testing.
func get_arrow_at_world_pos(world_pos: Vector2) -> Arrow:
	return get_arrow_at_local_pos(to_local(world_pos))

# --- ZOOM & PAN CONTROL METHODS (Images 2, 3, 4) ---

func _apply_zoom_transform() -> void:
	scale = Vector2(current_zoom, current_zoom)
	position = current_pan + (board_area_size * 0.5) * (1.0 - current_zoom)
	zoom_changed.emit(current_zoom)

func _clamp_pan(pan: Vector2, zoom: float) -> Vector2:
	if zoom <= 1.02:
		return Vector2.ZERO
	var max_x = (zoom - 1.0) * (board_area_size.x * 0.5) + 40.0
	var max_y = (zoom - 1.0) * (board_area_size.y * 0.5) + 40.0
	return Vector2(
		clampf(pan.x, -max_x, max_x),
		clampf(pan.y, -max_y, max_y)
	)

func set_target_zoom(new_zoom: float, screen_focus: Vector2 = Vector2.INF) -> void:
	new_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	if new_zoom <= 1.02:
		target_zoom = 1.0
		target_pan = Vector2.ZERO
		return

	target_zoom = new_zoom
	target_pan = _clamp_pan(target_pan, target_zoom)

func zoom_in(factor: float = 1.25, screen_focus: Vector2 = Vector2.INF) -> void:
	set_target_zoom(target_zoom * factor, screen_focus)

func zoom_out(factor: float = 1.25, screen_focus: Vector2 = Vector2.INF) -> void:
	set_target_zoom(target_zoom / factor, screen_focus)

func reset_zoom() -> void:
	target_zoom = 1.0
	target_pan = Vector2.ZERO
	current_zoom = 1.0
	current_pan = Vector2.ZERO
	_apply_zoom_transform()

func smooth_reset_zoom() -> void:
	target_zoom = 1.0
	target_pan = Vector2.ZERO

# --- TOUCH / INPUT DISPATCHING WITH ZOOM & PINCH SUPPORT ---

func handle_holder_touch_down(holder_pos: Vector2, pointer_id: int = -1) -> void:
	if is_input_locked:
		return

	var now = Time.get_ticks_msec()
	# Strict mobile deduplication: drop any emulated mouse events following recent touch
	if pointer_id >= 0:
		_last_touch_msec = now
	elif (now - _last_touch_msec) < 450:
		return

	# If real touch arrives, erase any leftover mouse pointer from dictionary
	if pointer_id >= 0 and _touches.has(-1):
		_touches.erase(-1)

	_touches[pointer_id] = holder_pos

	# Multi-touch pinch detection (strictly 2 or more physical screen touches)
	var touch_indices: Array = []
	for k in _touches.keys():
		if int(k) >= 0:
			touch_indices.append(k)

	if touch_indices.size() >= 2:
		_is_pinching = true
		_is_panning = false
		_cancel_guidance()
		var p1: Vector2 = _touches[touch_indices[0]]
		var p2: Vector2 = _touches[touch_indices[1]]
		_pinch_start_dist = p1.distance_to(p2)
		_pinch_start_zoom = current_zoom
		_pinch_start_mid = (p1 + p2) * 0.5
		_pan_start_target = current_pan
		return

	_is_pinching = false
	_is_panning = false
	_pan_start_pos = holder_pos
	_pan_start_target = current_pan

	var local_board_pos = holder_pos_to_local(holder_pos)
	var arrow = get_arrow_at_local_pos(local_board_pos)

	# Only test double-tap zoom if touching empty space (so arrow taps are never swallowed!)
	if arrow == null:
		if (now - _last_double_tap_msec) < 280 and holder_pos.distance_to(_last_tap_holder_pos) < 32.0:
			_last_double_tap_msec = 0
			_cancel_guidance()
			if current_zoom > 1.15:
				smooth_reset_zoom()
			else:
				set_target_zoom(1.85, holder_pos)
			return
		_last_double_tap_msec = now
		_last_tap_holder_pos = holder_pos

	handle_touch_down_local(local_board_pos, pointer_id)

func handle_holder_touch_move(holder_pos: Vector2, pointer_id: int = -1) -> void:
	var now = Time.get_ticks_msec()
	if pointer_id >= 0:
		_last_touch_msec = now
	elif (now - _last_touch_msec) < 450:
		return

	_touches[pointer_id] = holder_pos

	# Pinch-to-zoom in progress (2 fingers)
	var touch_indices: Array = []
	for k in _touches.keys():
		if int(k) >= 0:
			touch_indices.append(k)

	if _is_pinching and touch_indices.size() >= 2:
		var p1: Vector2 = _touches[touch_indices[0]]
		var p2: Vector2 = _touches[touch_indices[1]]
		var current_dist = p1.distance_to(p2)
		if _pinch_start_dist > 16.0:
			var scale_factor = current_dist / _pinch_start_dist
			var new_zoom = clampf(_pinch_start_zoom * scale_factor, MIN_ZOOM, MAX_ZOOM)
			var cur_mid = (p1 + p2) * 0.5
			# Direct real-time responsive 1:1 zoom (zero lag):
			current_zoom = new_zoom
			target_zoom = new_zoom
			target_pan = _clamp_pan(_pan_start_target + (cur_mid - _pinch_start_mid), current_zoom)
			current_pan = target_pan
			_apply_zoom_transform()
		return

	# Single-finger dragging:
	var pan_deadzone = 34.0 if _held_arrow != null else 12.0
	if current_zoom > 1.05 and not _is_pinching:
		var drag_dist = holder_pos.distance_to(_pan_start_pos)
		if drag_dist > pan_deadzone or _is_panning:
			if not _is_panning:
				_is_panning = true
				_cancel_guidance()
				_held_arrow = null
			# Direct real-time tracking (zero lag):
			target_pan = _clamp_pan(_pan_start_target + (holder_pos - _pan_start_pos), current_zoom)
			current_pan = target_pan
			_apply_zoom_transform()
			return

	var local_board_pos = holder_pos_to_local(holder_pos)
	handle_touch_move_local(local_board_pos, pointer_id)

func handle_holder_touch_up(holder_pos: Vector2, pointer_id: int = -1) -> void:
	var now = Time.get_ticks_msec()
	if pointer_id >= 0:
		_last_touch_msec = now
	elif (now - _last_touch_msec) < 450:
		return

	_touches.erase(pointer_id)

	if _is_pinching:
		var touch_indices: Array = []
		for k in _touches.keys():
			if int(k) >= 0:
				touch_indices.append(k)
		if touch_indices.size() < 2:
			_is_pinching = false
			# Smooth anchor handoff to remaining finger (prevents sudden jump/lag on release):
			if touch_indices.size() == 1:
				_pan_start_pos = _touches[touch_indices[0]]
				_pan_start_target = current_pan
				_is_panning = false
			if target_zoom < 1.05:
				smooth_reset_zoom()
		return

	if _is_panning:
		_is_panning = false
		_held_arrow = null
		return

	var local_board_pos = holder_pos_to_local(holder_pos)
	handle_touch_up_local(local_board_pos, pointer_id)

# --- DIRECT LOCAL TOUCH METHODS (Preserved for Unit Tests & Automation) ---

func handle_touch_down_local(local_pos: Vector2, pointer_id: int = -1) -> void:
	if is_input_locked:
		return

	var now = Time.get_ticks_msec()
	# Deduplicate emulated mouse events following touch within 450ms
	if pointer_id == -1 and (now - _last_touch_msec) < 450:
		return

	# Only allow one active pointer at a time (ignore secondary multi-touch fingers)
	if _active_pointer_id != -999 and _active_pointer_id != pointer_id:
		return

	_active_pointer_id = pointer_id
	if pointer_id >= 0:
		_last_touch_msec = now
	_last_tap_msec = now

	var target = get_arrow_at_local_pos(local_pos)
	if target and target.state == Arrow.ArrowState.IDLE:
		_held_arrow = target
		_touch_start_time = now
		_touch_start_pos = local_pos
		_is_guidance_active = false
		_held_arrow.scale = Vector2(0.96, 0.96) # Subtle tactile depression feedback

func handle_touch_move_local(local_pos: Vector2, pointer_id: int = -1) -> void:
	if _held_arrow == null:
		return
	if _active_pointer_id != -999 and _active_pointer_id != pointer_id:
		return

	# If dragged too far, cancel hold safely
	if local_pos.distance_to(_touch_start_pos) > 60.0:
		_cancel_guidance()

func handle_touch_up_local(local_pos: Vector2, pointer_id: int = -1) -> void:
	var now = Time.get_ticks_msec()
	# Deduplicate emulated mouse up following touch up
	if pointer_id == -1 and (now - _last_touch_msec) < 450:
		return

	if _active_pointer_id != -999 and _active_pointer_id != pointer_id:
		return
	_active_pointer_id = -999

	if pointer_id >= 0:
		_last_touch_msec = now

	if is_input_locked:
		_cancel_guidance()
		return

	var arrow = _held_arrow
	var is_guidance = _is_guidance_active
	var is_clear = _guidance_clear

	_cancel_guidance()

	# High-reliability fallback: if _held_arrow was cleared but player completed a quick tap over an arrow
	if arrow == null and (now - _touch_start_time) < 350:
		arrow = get_arrow_at_local_pos(local_pos)

	if arrow == null or arrow.state != Arrow.ArrowState.IDLE:
		return

	if is_guidance:
		# Guidance was active:
		if is_clear:
			# Player held, saw clear path, released to launch!
			_execute_arrow_tapped(arrow)
		else:
			# Blocked obstacle preview: released safely to cancel without penalty
			pass
	else:
		# Quick tap (< 220ms)
		_execute_arrow_tapped(arrow)

## World-coordinate variants for backwards compatibility with tests and top-level events
func handle_touch_down(world_pos: Vector2) -> void:
	handle_touch_down_local(to_local(world_pos), -1)

func handle_touch_move(world_pos: Vector2) -> void:
	handle_touch_move_local(to_local(world_pos), -1)

func handle_touch_up(world_pos: Vector2) -> void:
	handle_touch_up_local(to_local(world_pos), -1)

## Direct tap dispatch (supports automated tests & quick clicks)
func handle_touch_at_world_pos(world_pos: Vector2) -> void:
	if is_input_locked:
		return

	var now = Time.get_ticks_msec()
	if now - _last_tap_msec < 45:
		return
	_last_tap_msec = now

	var tapped = get_arrow_at_world_pos(world_pos)
	if tapped:
		_execute_arrow_tapped(tapped)

func _on_arrow_tapped(arrow: Arrow) -> void:
	_execute_arrow_tapped(arrow)

func _execute_arrow_tapped(arrow: Arrow) -> void:
	if is_input_locked or arrow == null or arrow.state != Arrow.ArrowState.IDLE:
		return

	var a_id = arrow.arrow_id
	var head_pos = CollisionChecker.get_arrow_head(arrow)
	var dir_name = _get_dir_name(arrow.direction)
	var exit_cells = CollisionChecker.get_exit_path(arrow, grid_size)

	print("[GameBoard] Arrow selected: ID=%d at grid_pos=%s" % [a_id, arrow.grid_position])
	print("[GameBoard] Arrow direction: %s, arrowhead: %s" % [dir_name, head_pos])
	print("[GameBoard] Cells checked for obstacles: %s" % [exit_cells])

	# Check forward path for obstacles
	var occ_map = CollisionChecker.build_occupancy_map(active_arrows)
	var blocked_by_id: int = -1
	var blocked_at_cell: Vector2i = Vector2i(-1, -1)
	for cell in exit_cells:
		if occ_map.has(cell) and occ_map[cell] != a_id:
			blocked_by_id = occ_map[cell]
			blocked_at_cell = cell
			break

	var can_exit = (blocked_by_id == -1)

	if can_exit:
		print("[GameBoard] Path is CLEAR for Arrow ID=%d! Animating exit." % a_id)
		# Record snapshot for undo functionality
		var p_pts = PackedVector2Array()
		if arrow.raw_points:
			p_pts = arrow.raw_points.duplicate()
		var p_occ = arrow.occupied_cells.duplicate()
		_undo_stack.append({
			"id": arrow.arrow_id,
			"pos": arrow.grid_position,
			"dir": arrow.direction,
			"len": arrow.length,
			"occ": p_occ,
			"pts": p_pts,
			"head": arrow.head_cell
		})

		# Arrow is immediately erased from active list, ensuring it cannot be tapped again:
		active_arrows.erase(arrow)
		move_succeeded.emit(arrow)
		is_input_locked = false

		var dir_vec = CollisionChecker.direction_to_vector(arrow.direction)
		var exit_distance = maxf(board_area_size.x, board_area_size.y) * 1.5
		var target_pos = arrow.global_position + Vector2(float(dir_vec.x), float(dir_vec.y)) * exit_distance

		print("[GameBoard] Animation started for Arrow ID=%d towards %s." % [a_id, target_pos])
		arrow.animate_exit(target_pos)
	else:
		print("[GameBoard] Path is BLOCKED for Arrow ID=%d by Arrow ID=%d at cell %s! Deducting heart." % [a_id, blocked_by_id, blocked_at_cell])
		is_input_locked = true
		move_failed.emit(arrow)
		arrow.animate_blocked(func():
			# Unlock only if not permanently locked by level failure
			if active_arrows.size() > 0:
				is_input_locked = false
		)

func _on_arrow_exit_completed(arrow: Arrow) -> void:
	var a_id = arrow.arrow_id
	print("[GameBoard] Animation completed for Arrow ID=%d." % a_id)
	arrow.queue_free()

	print("[GameBoard] Arrow ID=%d removed successfully." % a_id)
	print("[GameBoard] Remaining arrow count: %d" % active_arrows.size())

	if active_arrows.is_empty():
		print("[GameBoard] All arrows removed! Level complete.")
		is_input_locked = true
		board_cleared.emit()

func undo_move() -> bool:
	if is_input_locked or _undo_stack.is_empty():
		return false
	var snap = _undo_stack.pop_back()
	var restored_arrow: Arrow = null
	if arrow_scene:
		restored_arrow = arrow_scene.instantiate() as Arrow
	else:
		restored_arrow = Arrow.new()
	add_child(restored_arrow)
	restored_arrow.setup(
		int(snap["id"]),
		snap["pos"],
		snap["dir"],
		int(snap["len"]),
		cell_size,
		board_origin,
		snap["occ"],
		snap["pts"],
		snap["head"]
	)
	restored_arrow.apply_theme(current_theme)
	restored_arrow.arrow_exit_completed.connect(_on_arrow_exit_completed)
	active_arrows.append(restored_arrow)

	# Gentle pop-in animation
	restored_arrow.scale = Vector2.ZERO
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(restored_arrow, "scale", Vector2.ONE, 0.22)
	queue_redraw()
	print("[GameBoard] Undid move for Arrow ID=%d. Remaining active: %d" % [snap["id"], active_arrows.size()])
	return true

# --- GUIDANCE ACTIVATION & TRAJECTORY ---

func _activate_guidance(arrow: Arrow) -> void:
	_is_guidance_active = true
	var a_id = arrow.arrow_id
	var exit_cells = CollisionChecker.get_exit_path(arrow, grid_size)
	var occ_map = CollisionChecker.build_occupancy_map(active_arrows)

	_guidance_clear = true
	_guidance_blocker_arrow = null
	_guidance_stop_cell = Vector2i(-1, -1)

	for cell in exit_cells:
		if occ_map.has(cell) and occ_map[cell] != a_id:
			_guidance_clear = false
			_guidance_stop_cell = cell
			var bid = occ_map[cell]
			for other in active_arrows:
				if other.arrow_id == bid:
					_guidance_blocker_arrow = other
					break
			break

	var col_clear = current_theme.get("guide_clear", Color("#2E7D32"))
	var col_blocked = current_theme.get("guide_blocked", Color("#E53935"))
	arrow.set_guidance_highlight(true, _guidance_clear, col_clear, col_blocked)

	if _guidance_blocker_arrow and is_instance_valid(_guidance_blocker_arrow):
		_guidance_blocker_arrow.set_guidance_highlight(true, false, col_clear, col_blocked)

	if SoundManager.instance:
		SoundManager.instance.play_guidance_hum()

	guidance_activated.emit(_guidance_clear)
	queue_redraw()

func _cancel_guidance() -> void:
	if _held_arrow and is_instance_valid(_held_arrow):
		_held_arrow.scale = Vector2.ONE
		_held_arrow.set_guidance_highlight(false, true)

	if _guidance_blocker_arrow and is_instance_valid(_guidance_blocker_arrow):
		_guidance_blocker_arrow.set_guidance_highlight(false, true)

	_held_arrow = null
	_guidance_blocker_arrow = null
	_is_guidance_active = false
	guidance_dismissed.emit()
	queue_redraw()

# --- HINT SYSTEM ---

func show_hint() -> Arrow:
	var candidate = get_hint_arrow()
	if candidate:
		_hint_active = true
		_hint_arrow = candidate
		_hint_timer = 2.4
		candidate.animate_hint()
		if SoundManager.instance:
			SoundManager.instance.play_hint()
		queue_redraw()
		return candidate
	return null

func get_hint_arrow() -> Arrow:
	var occ_map = CollisionChecker.build_occupancy_map(active_arrows)
	for arrow in active_arrows:
		if arrow.state == Arrow.ArrowState.IDLE and CollisionChecker.can_arrow_exit_with_map(arrow, occ_map, grid_size):
			return arrow
	return null

func _get_dir_name(dir: CollisionChecker.Direction) -> String:
	match dir:
		CollisionChecker.Direction.UP: return "UP"
		CollisionChecker.Direction.DOWN: return "DOWN"
		CollisionChecker.Direction.LEFT: return "LEFT"
		CollisionChecker.Direction.RIGHT: return "RIGHT"
	return "UNKNOWN"

# --- DRAWING: GRID DOTS & GUIDANCE BEAM ---

func _draw() -> void:
	# 1. Clean ambient paper dots drawn from cached positions (ultra-fast 60fps rendering)
	var dot_color: Color = current_theme.get("dots", Color(0.72, 0.65, 0.55, 0.45))
	var dot_radius = 2.4

	for pt in _cached_grid_dots:
		draw_circle(pt, dot_radius, dot_color)

	# 2. Draw Guidance Beam if active (Long-Press Guidance or Hint Preview)
	var active_target: Arrow = _held_arrow if _is_guidance_active else (_hint_arrow if _hint_active else null)
	if active_target != null and is_instance_valid(active_target):
		_draw_guidance_beam(active_target)

func _draw_guidance_beam(arrow: Arrow) -> void:
	var head_grid: Vector2i = CollisionChecker.get_arrow_head(arrow)
	var start_pos = board_origin + Vector2(head_grid) * cell_size

	var dir_vec = CollisionChecker.direction_to_vector(arrow.direction)
	var f_dir = Vector2(float(dir_vec.x), float(dir_vec.y))
	var s_dir = Vector2(-f_dir.y, f_dir.x)

	var is_clear = _guidance_clear if _is_guidance_active else true
	var beam_col = current_theme.get("guide_clear", Color("#2E7D32")) if is_clear else current_theme.get("guide_blocked", Color("#E53935"))

	var end_pos: Vector2
	if is_clear:
		var max_dim = maxf(board_area_size.x, board_area_size.y)
		end_pos = start_pos + f_dir * (max_dim + 120.0)
	else:
		if _guidance_stop_cell.x >= 0:
			var stop_center = board_origin + Vector2(_guidance_stop_cell) * cell_size
			end_pos = stop_center - f_dir * (cell_size * 0.45)
		else:
			end_pos = start_pos + f_dir * cell_size

	# Glowing background beam line
	var glow_col = Color(beam_col.r, beam_col.g, beam_col.b, 0.28)
	draw_line(start_pos, end_pos, glow_col, 8.0, true)
	draw_line(start_pos, end_pos, Color(beam_col.r, beam_col.g, beam_col.b, 0.75), 3.0, true)

	# Animated marching dots along the trajectory
	var total_dist = start_pos.distance_to(end_pos)
	var dot_step = 22.0
	var d = fmod(_guidance_anim_offset, dot_step)
	while d < total_dist:
		var dot_pt = start_pos + f_dir * d
		draw_circle(dot_pt, 3.2, beam_col)
		d += dot_step

	# Visual indicator at end:
	if is_clear:
		# Gentle exit chevron at board boundary
		var tip = end_pos
		var w1 = tip - f_dir * 14.0 + s_dir * 9.0
		var w2 = tip - f_dir * 14.0 - s_dir * 9.0
		draw_polyline(PackedVector2Array([w1, tip, w2]), beam_col, 3.0, true)
	else:
		# Warning stop ring at the blocker
		draw_circle(end_pos, 7.0, beam_col)
		draw_arc(end_pos, 12.0, 0, TAU, 16, glow_col, 2.5)
