class_name MazeBuilder
extends Node3D

## MazeBuilder for ArrowFlow
## Dynamically constructs 3D maze walls, interactive floor tiles, base platform,
## smooth tile-coloring animations, particle bursts, and camera framing.

@export var camera_3d: Camera3D
@export var base_tile_size: float = 1.0

var walls_container: Node3D
var tiles_container: Node3D
var base_plate: MeshInstance3D
var confetti_particles: CPUParticles3D

var tile_nodes: Dictionary = {} # Vector2i -> MeshInstance3D
var current_theme: Dictionary = {}

var unpainted_mat: StandardMaterial3D
var wall_mat: StandardMaterial3D
var painted_mat: StandardMaterial3D

func _ready() -> void:
	_setup_containers()
	_setup_materials()
	_setup_confetti()

	var lm = LevelManager.instance
	if lm:
		lm.level_loaded.connect(_on_level_loaded)
		lm.tile_painted.connect(_on_tile_painted)
		lm.level_completed.connect(_on_level_completed)

func _setup_containers() -> void:
	walls_container = Node3D.new()
	walls_container.name = "WallsContainer"
	add_child(walls_container)

	tiles_container = Node3D.new()
	tiles_container.name = "TilesContainer"
	add_child(tiles_container)

	base_plate = MeshInstance3D.new()
	base_plate.name = "BasePlate"
	add_child(base_plate)

func _setup_materials() -> void:
	unpainted_mat = StandardMaterial3D.new()
	unpainted_mat.roughness = 0.35
	unpainted_mat.metallic = 0.02
	unpainted_mat.albedo_color = Color(0.92, 0.94, 0.97)

	wall_mat = StandardMaterial3D.new()
	wall_mat.roughness = 0.22
	wall_mat.metallic = 0.08
	wall_mat.albedo_color = Color(0.14, 0.18, 0.28)

	painted_mat = StandardMaterial3D.new()
	painted_mat.roughness = 0.18
	painted_mat.metallic = 0.04
	painted_mat.albedo_color = Color(1.0, 0.38, 0.16)

func _setup_confetti() -> void:
	confetti_particles = CPUParticles3D.new()
	confetti_particles.name = "ConfettiParticles"
	confetti_particles.emitting = false
	confetti_particles.one_shot = true
	confetti_particles.explosiveness = 0.8
	confetti_particles.amount = 120
	confetti_particles.lifetime = 1.8
	confetti_particles.direction = Vector3(0, 1, 0)
	confetti_particles.spread = 80.0
	confetti_particles.initial_velocity_min = 6.0
	confetti_particles.initial_velocity_max = 11.0
	confetti_particles.gravity = Vector3(0, -12.0, 0)
	confetti_particles.angular_velocity_min = -180.0
	confetti_particles.angular_velocity_max = 180.0
	confetti_particles.scale_amount_min = 0.12
	confetti_particles.scale_amount_max = 0.28

	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(0.18, 0.18, 0.04)
	confetti_particles.mesh = c_mesh

	var c_mat = StandardMaterial3D.new()
	c_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	c_mat.vertex_color_use_as_albedo = true
	confetti_particles.material_override = c_mat

	# Gradient for colorful confetti
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 0.2, 0.3),
		Color(1.0, 0.8, 0.1),
		Color(0.2, 0.9, 0.4),
		Color(0.1, 0.7, 1.0),
		Color(0.8, 0.3, 1.0)
	])
	confetti_particles.color_ramp = grad

	add_child(confetti_particles)

func _on_level_loaded(_level_index: int, _total_levels: int, theme: Dictionary) -> void:
	current_theme = theme

	# Update materials
	wall_mat.albedo_color = theme.get("wall", Color(0.14, 0.18, 0.28))
	unpainted_mat.albedo_color = theme.get("unpainted", Color(0.92, 0.94, 0.97))
	painted_mat.albedo_color = theme.get("paint", Color(1.0, 0.38, 0.16))

	_rebuild_maze()

func _rebuild_maze() -> void:
	# Clear previous geometry
	for child in walls_container.get_children():
		child.queue_free()
	for child in tiles_container.get_children():
		child.queue_free()
	tile_nodes.clear()

	var lm = LevelManager.instance
	if lm == null:
		return

	var w = lm.grid_width
	var h = lm.grid_height
	var wall_box = BoxMesh.new()
	wall_box.size = Vector3(0.96, 0.76, 0.96)

	var wall_cap_box = BoxMesh.new()
	wall_cap_box.size = Vector3(0.88, 0.12, 0.88)

	var cap_mat = StandardMaterial3D.new()
	cap_mat.roughness = 0.20
	cap_mat.metallic = 0.08
	cap_mat.albedo_color = wall_mat.albedo_color.lightened(0.12)

	var tile_box = BoxMesh.new()
	tile_box.size = Vector3(0.94, 0.22, 0.94)

	# Build Walls with decorative beveled caps
	for pos in lm.wall_cells.keys():
		var wall_instance = MeshInstance3D.new()
		wall_instance.mesh = wall_box
		wall_instance.material_override = wall_mat
		wall_instance.position = Vector3(float(pos.x), 0.38, float(pos.y))
		walls_container.add_child(wall_instance)

		var cap_instance = MeshInstance3D.new()
		cap_instance.mesh = wall_cap_box
		cap_instance.material_override = cap_mat
		cap_instance.position = Vector3(float(pos.x), 0.80, float(pos.y))
		walls_container.add_child(cap_instance)

	# Build Floor Tiles
	for pos in lm.walkable_cells.keys():
		var is_painted = lm.walkable_cells[pos]
		var tile_instance = MeshInstance3D.new()
		tile_instance.mesh = tile_box
		var mat = StandardMaterial3D.new()
		mat.roughness = 0.22
		mat.albedo_color = current_theme["paint"] if is_painted else current_theme["unpainted"]
		if is_painted:
			mat.emission_enabled = true
			mat.emission = current_theme["paint"] * 0.25
		tile_instance.material_override = mat
		tile_instance.position = Vector3(float(pos.x), 0.11, float(pos.y))
		tiles_container.add_child(tile_instance)
		tile_nodes[pos] = tile_instance

	# Build Base Platform Plate
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(float(w) + 0.6, 0.35, float(h) + 0.6)
	base_plate.mesh = base_mesh

	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = current_theme.get("bg", Color(0.08, 0.10, 0.16)).lerp(wall_mat.albedo_color, 0.35)
	base_mat.roughness = 0.5
	base_plate.material_override = base_mat
	base_plate.position = Vector3((float(w) - 1.0) * 0.5, -0.15, (float(h) - 1.0) * 0.5)

	# Frame Camera
	_frame_camera(w, h)

func _frame_camera(w: int, h: int) -> void:
	if camera_3d == null:
		return

	var center_x = (float(w) - 1.0) * 0.5
	var center_z = (float(h) - 1.0) * 0.5
	# Slight forward bias in Z to center maze perfectly between top HUD and bottom hint
	var target_look = Vector3(center_x, 0.0, center_z + 0.75)

	var max_dim = maxf(float(w), float(h) * 1.25)
	var distance = maxf(max_dim * 1.15, 6.8)

	# Isometric/tilted top-down camera angle
	var camera_offset = Vector3(0.0, distance * 1.35, distance * 0.95)
	camera_3d.position = target_look + camera_offset
	camera_3d.look_at(target_look, Vector3.UP)

func _on_tile_painted(pos: Vector2i, _painted_count: int, _total_tiles: int, _pct: float) -> void:
	if not tile_nodes.has(pos):
		return

	var tile: MeshInstance3D = tile_nodes[pos]
	if tile == null:
		return

	# Juicy pop & color transition
	var mat = tile.material_override as StandardMaterial3D
	if mat:
		var p_col = current_theme.get("paint", Color(1.0, 0.38, 0.16))
		mat.albedo_color = p_col
		mat.emission_enabled = true
		mat.emission = p_col * 0.25

	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "scale", Vector3(1.04, 1.35, 1.04), 0.08)
	tween.chain().tween_property(tile, "scale", Vector3.ONE, 0.12)

func _on_level_completed(_level_index: int) -> void:
	var lm = LevelManager.instance
	if lm == null or confetti_particles == null:
		return

	var center_x = (float(lm.grid_width) - 1.0) * 0.5
	var center_z = (float(lm.grid_height) - 1.0) * 0.5
	confetti_particles.position = Vector3(center_x, 0.6, center_z)
	confetti_particles.restart()
	confetti_particles.emitting = true
