class_name CollisionChecker
extends RefCounted

## Pure, independent collision validation and path checking for grid-based arrows.
## Safely handles both Arrow (Node2D/Area2D) objects and data Dictionaries.

enum Direction { UP, DOWN, LEFT, RIGHT }

static func direction_to_vector(dir: Direction) -> Vector2i:
	match dir:
		Direction.UP:
			return Vector2i(0, -1)
		Direction.DOWN:
			return Vector2i(0, 1)
		Direction.LEFT:
			return Vector2i(-1, 0)
		Direction.RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO

static func vector_to_direction(vec: Vector2i) -> Direction:
	if vec.y < 0:
		return Direction.UP
	elif vec.y > 0:
		return Direction.DOWN
	elif vec.x < 0:
		return Direction.LEFT
	else:
		return Direction.RIGHT

static func _get_arrow_id(arrow) -> int:
	if arrow is Object:
		return arrow.arrow_id if "arrow_id" in arrow else 0
	elif arrow is Dictionary:
		return int(arrow.get("arrow_id", arrow.get("id", 0)))
	return 0

static func _get_arrow_dir(arrow) -> Direction:
	if arrow is Object:
		return arrow.direction if "direction" in arrow else Direction.UP
	elif arrow is Dictionary:
		var d = arrow.get("direction", arrow.get("dir", Direction.UP))
		return d as Direction
	return Direction.UP

static func _get_arrow_pos(arrow) -> Vector2i:
	if arrow is Object:
		return arrow.grid_position if "grid_position" in arrow else Vector2i.ZERO
	elif arrow is Dictionary:
		return arrow.get("grid_position", arrow.get("pos", Vector2i.ZERO))
	return Vector2i.ZERO

## Builds a lookup map: Vector2i (cell) -> int (arrow_id)
static func build_occupancy_map(remaining_arrows: Array) -> Dictionary:
	var occ: Dictionary = {}
	for arrow in remaining_arrows:
		if arrow == null:
			continue
		var a_id = _get_arrow_id(arrow)
		var cells = get_arrow_cells(arrow)
		for cell in cells:
			occ[cell] = a_id
	return occ

## Returns the array of grid cells occupied by the arrow.
static func get_arrow_cells(arrow) -> Array[Vector2i]:
	if arrow is Object and "occupied_cells" in arrow:
		var raw = arrow.occupied_cells
		if raw.size() > 0:
			var res: Array[Vector2i] = []
			for c in raw:
				res.append(c)
			return res
	elif arrow is Dictionary and arrow.has("occupied_cells"):
		var raw = arrow["occupied_cells"]
		var res: Array[Vector2i] = []
		for c in raw:
			res.append(c)
		return res

	# Fallback: compute cells from grid_position, direction, and length
	var cells: Array[Vector2i] = []
	var start: Vector2i = _get_arrow_pos(arrow)
	var dir_enum: Direction = _get_arrow_dir(arrow)
	var dir_vec: Vector2i = direction_to_vector(dir_enum)

	var len_val: int = 1
	if arrow is Object and "length" in arrow:
		len_val = maxi(1, arrow.length)
	elif arrow is Dictionary and arrow.has("length"):
		len_val = maxi(1, int(arrow["length"]))

	for i in range(len_val):
		cells.append(start + dir_vec * i)
	return cells

## Returns the forward-most cell of the arrow (where the arrowhead is located).
static func get_arrow_head(arrow) -> Vector2i:
	if arrow is Object and "head_cell" in arrow and arrow.head_cell != Vector2i.ZERO:
		return arrow.head_cell
	elif arrow is Dictionary and arrow.has("head_cell"):
		return arrow["head_cell"]

	var cells = get_arrow_cells(arrow)
	if cells.is_empty():
		return _get_arrow_pos(arrow)
	return cells[cells.size() - 1]

## Returns all cells between the arrowhead and the relevant grid boundary.
static func get_exit_path(arrow, grid_size: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var head: Vector2i = get_arrow_head(arrow)
	var dir_enum: Direction = _get_arrow_dir(arrow)
	var step: Vector2i = direction_to_vector(dir_enum)

	var cur: Vector2i = head + step
	while cur.x >= 0 and cur.x < grid_size.x and cur.y >= 0 and cur.y < grid_size.y:
		path.append(cur)
		cur += step

	return path

## Determines whether an arrow has a clear, unblocked path to the grid boundary.
static func can_arrow_exit(arrow, remaining_arrows: Array, grid_size: Vector2i) -> bool:
	var occ_map = build_occupancy_map(remaining_arrows)
	return can_arrow_exit_with_map(arrow, occ_map, grid_size)

## Optimized overload accepting a precomputed occupancy map
static func can_arrow_exit_with_map(arrow, occ_map: Dictionary, grid_size: Vector2i) -> bool:
	var a_id = _get_arrow_id(arrow)
	var exit_cells = get_exit_path(arrow, grid_size)

	for cell in exit_cells:
		if occ_map.has(cell):
			var blocker_id: int = occ_map[cell]
			if blocker_id != a_id:
				return false

	return true
