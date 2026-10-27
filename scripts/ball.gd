class_name Ball
extends Node3D

## Ball Controller for ArrowFlow
## Handles swipe & keyboard inputs, continuous corridor sliding, roll rotation,
## wall-impact squash & stretch, paint trail triggering, and camera shake.

signal move_started(direction: Vector2i)
signal move_ended(final_pos: Vector2i)
signal wall_hit(direction: Vector2i)

@export var move_speed: float = 14.0 # Tiles per second
@export var ball_radius: float = 0.38
@export var swipe_threshold: float = 28.0

var grid_pos: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var input_enabled: bool = true

# Input tracking
var touch_start: Vector2 = Vector2.ZERO
var is_touching: bool = false
var pending_input_dir: Vector2i = Vector2i.ZERO

# Visual nodes
var model_node: Node3D
var sphere_mesh_instance: MeshInstance3D
var ball_material: StandardMaterial3D
var hit_particles: CPUParticles3D

# Movement state
var current_path: Array[Vector2i] = []
var path_target_index: int = 0
var last_move_dir: Vector2i = Vector2i.ZERO
var slide_combo: int = 0

func _ready() -> void:
	_setup_visuals()

func _setup_visuals() -> void:
	# Model pivot for squash/stretch
	model_node = Node3D.new()
	model_node.name = "ModelPivot"
	add_child(model_node)

	# Sphere mesh
	sphere_mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	sphere_mesh_instance.mesh = sphere
	sphere_mesh_instance.position = Vector3(0, ball_radius + 0.05, 0)
	model_node.add_child(sphere_mesh_instance)

	# Material with glossy sheen
	ball_material = StandardMaterial3D.new()
	ball_material.roughness = 0.15
	ball_material.metallic = 0.05
	ball_material.metallic_specular = 0.8
	ball_material.albedo_color = Color(1.0, 0.38, 0.16)
	sphere_mesh_instance.material_override = ball_material

	# Wall hit particles
	hit_particles = CPUParticles3D.new()
	hit_particles.emitting = false
	hit_particles.one_shot = true
	hit_particles.explosiveness = 0.95
	hit_particles.amount = 16
	hit_particles.lifetime = 0.35
	hit_particles.position = Vector3(0, ball_radius, 0)
	hit_particles.direction = Vector3(0, 1, 0)
	hit_particles.spread = 70.0
	hit_particles.initial_velocity_min = 2.5
	hit_particles.initial_velocity_max = 5.0
	hit_particles.gravity = Vector3(0, -9.8, 0)
	hit_particles.scale_amount_min = 0.10
	hit_particles.scale_amount_max = 0.22

	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.08
	p_mesh.height = 0.16
	p_mesh.radial_segments = 8
	p_mesh.rings = 4
	hit_particles.mesh = p_mesh

	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = ball_material.albedo_color
	p_mat.roughness = 0.3
	hit_particles.material_override = p_mat

	add_child(hit_particles)

func set_ball_color(color: Color) -> void:
	if ball_material:
		ball_material.albedo_color = color
	if hit_particles and hit_particles.material_override is StandardMaterial3D:
		(hit_particles.material_override as StandardMaterial3D).albedo_color = color

func teleport_to_grid(new_pos: Vector2i) -> void:
	grid_pos = new_pos
	position = Vector3(float(grid_pos.x), 0.0, float(grid_pos.y))
	is_moving = false
	current_path.clear()
	model_node.scale = Vector3.ONE
	sphere_mesh_instance.rotation = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or is_moving:
		return

	# Touch & Mouse Swipe
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				touch_start = mb.position
				is_touching = true
			else:
				if is_touching:
					_evaluate_swipe(mb.position)
				is_touching = false

	elif event is InputEventMouseMotion and is_touching:
		var mm = event as InputEventMouseMotion
		if mm.position.distance_to(touch_start) >= swipe_threshold:
			_evaluate_swipe(mm.position)
			# Reset start to current for fluid multi-swipes
			touch_start = mm.position

	elif event is InputEventScreenTouch:
		var st = event as InputEventScreenTouch
		if st.pressed:
			touch_start = st.position
			is_touching = true
		else:
			if is_touching:
				_evaluate_swipe(st.position)
			is_touching = false

	elif event is InputEventScreenDrag and is_touching:
		var sd = event as InputEventScreenDrag
		if sd.position.distance_to(touch_start) >= swipe_threshold:
			_evaluate_swipe(sd.position)
			touch_start = sd.position

	# Keyboard (WASD & Arrows)
	elif event is InputEventKey:
		var ik = event as InputEventKey
		if ik.pressed and not ik.echo:
			var dir = Vector2i.ZERO
			match ik.keycode:
				KEY_UP, KEY_W:
					dir = Vector2i(0, -1)
				KEY_DOWN, KEY_S:
					dir = Vector2i(0, 1)
				KEY_LEFT, KEY_A:
					dir = Vector2i(-1, 0)
				KEY_RIGHT, KEY_D:
					dir = Vector2i(1, 0)

			if dir != Vector2i.ZERO:
				try_move(dir)

func _evaluate_swipe(current_pos: Vector2) -> void:
	var delta = current_pos - touch_start
	if delta.length() < swipe_threshold:
		return

	var dir = Vector2i.ZERO
	if absf(delta.x) > absf(delta.y):
		dir = Vector2i(1 if delta.x > 0 else -1, 0)
	else:
		dir = Vector2i(0, 1 if delta.y > 0 else -1)

	try_move(dir)

func try_move(dir: Vector2i) -> bool:
	if is_moving or not input_enabled:
		return false

	var lm = LevelManager.instance
	if lm == null:
		return false

	# Check if immediate neighbor is blocked by wall
	var next_cell = grid_pos + dir
	if lm.is_wall(next_cell):
		_play_wall_bump_wiggle(dir)
		return false

	# Build continuous slide path until wall
	current_path.clear()
	var test_pos = next_cell
	while not lm.is_wall(test_pos):
		current_path.append(test_pos)
		test_pos += dir

	if current_path.is_empty():
		return false

	last_move_dir = dir
	path_target_index = 0
	slide_combo = 0
	is_moving = true

	if SoundManager.instance:
		SoundManager.instance.play_swipe()

	move_started.emit(dir)
	_step_next_tile()
	return true

func _step_next_tile() -> void:
	if path_target_index >= current_path.size():
		_finish_move()
		return

	var target_cell = current_path[path_target_index]
	var target_world_pos = Vector3(float(target_cell.x), 0.0, float(target_cell.y))

	# Duration per cell based on move_speed
	var dur = 1.0 / move_speed

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", target_world_pos, dur).set_trans(Tween.TRANS_LINEAR)

	# Physical roll rotation around perpendicular axis
	var roll_axis = Vector3(float(-last_move_dir.y), 0.0, float(last_move_dir.x)).normalized()
	if roll_axis != Vector3.ZERO:
		var current_rot = sphere_mesh_instance.rotation
		var roll_angle = (1.0 / ball_radius)
		tween.tween_property(sphere_mesh_instance, "rotation", current_rot + roll_axis * roll_angle, dur)

	tween.chain().tween_callback(func():
		grid_pos = target_cell
		slide_combo += 1

		# Paint tile
		if LevelManager.instance:
			var newly_painted = LevelManager.instance.paint_tile(grid_pos)
			if newly_painted and SoundManager.instance:
				SoundManager.instance.play_paint(1.0 + float(slide_combo) * 0.05)

		path_target_index += 1
		_step_next_tile()
	)

func _finish_move() -> void:
	is_moving = false
	move_ended.emit(grid_pos)

	# Wall impact squash & stretch
	_play_wall_impact_squash(last_move_dir)

	# Audio & Particles
	if SoundManager.instance:
		SoundManager.instance.play_hit()

	if hit_particles:
		hit_particles.direction = Vector3(float(-last_move_dir.x), 0.4, float(-last_move_dir.y)).normalized()
		hit_particles.restart()
		hit_particles.emitting = true

	wall_hit.emit(last_move_dir)

func _play_wall_impact_squash(dir: Vector2i) -> void:
	if model_node == null:
		return

	var squash_dir = Vector3(float(abs(dir.x)), 0.0, float(abs(dir.y)))
	# Squash in impact direction, stretch perpendicular and up
	var squashed_scale = Vector3(
		0.65 if dir.x != 0 else 1.25,
		1.30,
		0.65 if dir.y != 0 else 1.25
	)

	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(model_node, "scale", squashed_scale, 0.07)
	tween.chain().tween_property(model_node, "scale", Vector3(1.15, 0.88, 1.15), 0.08)
	tween.chain().tween_property(model_node, "scale", Vector3.ONE, 0.12)

func _play_wall_bump_wiggle(dir: Vector2i) -> void:
	var offset = Vector3(float(dir.x) * 0.12, 0.0, float(dir.y) * 0.12)
	var origin_pos = position
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", origin_pos + offset, 0.05)
	tween.chain().tween_property(self, "position", origin_pos, 0.08)
	if SoundManager.instance:
		SoundManager.instance.play_hit()
