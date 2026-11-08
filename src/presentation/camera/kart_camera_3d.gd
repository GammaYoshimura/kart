class_name KartCamera3D
extends Node3D

@export var target_path: NodePath = NodePath("../Kart")
@export var camera_profile: Resource

var _target: KartSimBody
var _camera: Camera3D
var _shape_cast: ShapeCast3D
var _noise: FastNoiseLite = FastNoiseLite.new()
var _follow_position: Vector3 = Vector3.ZERO
var _trauma: float = 0.0
var _noise_time: float = 0.0
var _last_boost_ticks: int = 0
var _boost_punch_remaining: float = 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path) as KartSimBody
	if camera_profile == null:
		camera_profile = load("res://resources/tracks/camera_default.tres") as Resource
	if _target == null:
		push_error("KartCamera3D requires a KartSimBody target.")
		set_process(false)
		return
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = _profile_float(&"base_fov", 70.0)
	_camera.current = true
	add_child(_camera)
	_shape_cast = ShapeCast3D.new()
	_shape_cast.name = "CameraCollisionCast"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.25
	_shape_cast.shape = sphere
	_shape_cast.collision_mask = (1 << 0) | (1 << 1)
	_shape_cast.enabled = true
	add_child(_shape_cast)
	_follow_position = _target.state.position
	global_position = _follow_position
	_last_boost_ticks = _target.state.boost_ticks_left
	_noise.seed = 473829
	_noise.frequency = 2.2
	var wall_connection_error: int = EventBus.kart_wall_collision.connect(_on_wall_collision)
	var landing_connection_error: int = EventBus.kart_landed.connect(_on_kart_landed)
	if wall_connection_error != OK or landing_connection_error != OK:
		push_error("KartCamera3D could not connect impact signals.")


func _process(delta: float) -> void:
	if _target == null:
		return
	var state: KartSimState = _target.state
	var xz_weight: float = 1.0 - exp(-_profile_float(&"position_stiffness_xz", 16.0) * delta)
	var y_weight: float = 1.0 - exp(-_profile_float(&"position_stiffness_y", 9.0) * delta)
	_follow_position.x = lerpf(_follow_position.x, state.position.x, xz_weight)
	_follow_position.z = lerpf(_follow_position.z, state.position.z, xz_weight)
	_follow_position.y = lerpf(_follow_position.y, state.position.y, y_weight)
	global_position = _follow_position
	var looking_back: bool = _target.last_command_frame.is_button_pressed(InputCommandFrame.BIT_LOOK_BACK)
	var camera_distance: float = _profile_float(&"distance_behind", 5.2)
	if state.boost_ticks_left > 0 and _last_boost_ticks == 0:
		_boost_punch_remaining = 0.18
	_last_boost_ticks = state.boost_ticks_left
	_boost_punch_remaining = maxf(_boost_punch_remaining - delta, 0.0)
	if _boost_punch_remaining > 0.0:
		camera_distance -= 0.4
	var desired_offset: Vector3
	if looking_back:
		desired_offset = state.forward_dir * 5.0 + Vector3.UP * _profile_float(&"height_above", 2.1)
	else:
		desired_offset = -state.forward_dir * camera_distance + Vector3.UP * _profile_float(&"height_above", 2.1)
	_shape_cast.target_position = desired_offset
	_shape_cast.force_shapecast_update()
	var safe_offset: Vector3 = desired_offset
	if _shape_cast.is_colliding():
		var safe_fraction: float = maxf(_shape_cast.get_closest_collision_safe_fraction() - 0.04, 0.08)
		safe_offset *= safe_fraction
	_camera.position = safe_offset
	var look_target: Vector3 = _follow_position + Vector3.UP * _profile_float(&"look_at_height_offset", 0.85)
	if not looking_back and state.drift_state == 2:
		look_target += state.right_dir * float(state.drift_dir) * 0.85
	var previous_camera_rotation: Quaternion = _camera.global_basis.get_rotation_quaternion()
	_camera.look_at(look_target)
	var desired_camera_rotation: Quaternion = _camera.global_basis.get_rotation_quaternion()
	var rotation_weight: float = 1.0 - exp(-_profile_float(&"rotation_stiffness", 11.0) * delta)
	_camera.global_basis = Basis(previous_camera_rotation.slerp(desired_camera_rotation, rotation_weight))
	_update_fov(delta)
	_update_trauma(delta)


func add_camera_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _on_wall_collision(racer: int, impact_strength: float, _contact_point: Vector3) -> void:
	if racer == _target.racer_id:
		add_camera_trauma(impact_strength * 0.55)


func _on_kart_landed(racer: int, impact_speed: float) -> void:
	if racer == _target.racer_id and impact_speed > 2.0:
		add_camera_trauma(impact_speed * 0.025)


func _update_fov(delta: float) -> void:
	var state: KartSimState = _target.state
	var speed_ratio: float = clampf(absf(state.forward_speed) / maxf(_target.stats.max_speed_forward, 0.01), 0.0, 1.0)
	var target_fov: float = lerpf(
		_profile_float(&"base_fov", 70.0),
		_profile_float(&"max_speed_fov", 82.0),
		speed_ratio
	)
	if state.boost_ticks_left > 0:
		target_fov = _profile_float(&"boost_fov", 92.0)
	_camera.fov = lerpf(_camera.fov, target_fov, 1.0 - exp(-_profile_float(&"rotation_stiffness", 11.0) * delta))


func _update_trauma(delta: float) -> void:
	_trauma = maxf(_trauma - delta * 0.8, 0.0)
	_noise_time += delta
	var shake: float = _trauma * _trauma * 0.045
	_camera.rotation += Vector3(
		_noise.get_noise_1d(_noise_time) * shake,
		_noise.get_noise_1d(_noise_time + 37.0) * shake,
		_noise.get_noise_1d(_noise_time + 91.0) * shake
	)


func _profile_float(property_name: StringName, fallback: float) -> float:
	if camera_profile == null:
		return fallback
	var value: Variant = camera_profile.get(property_name)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return fallback
