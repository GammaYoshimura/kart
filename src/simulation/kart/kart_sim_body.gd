class_name KartSimBody
extends CharacterBody3D

@export var stats: KartStatsResource

var state: KartSimState = KartSimState.new()
var input_source: KartInputSource
var simulation_tick: int = 0


func _ready() -> void:
	if stats == null:
		stats = load("res://resources/karts/stats_balanced.tres") as KartStatsResource
	if not stats.is_valid():
		push_error("KartSimBody requires valid kart stats.")
		set_physics_process(false)
		return
	input_source = LocalHumanInputSource.new()
	floor_max_angle = deg_to_rad(stats.max_driveable_slope_deg)
	collision_layer = 1 << 2
	collision_mask = (1 << 0) | (1 << 1) | (1 << 2)
	_ensure_collision_shape()
	state.position = global_position
	state.heading_yaw = rotation.y


func _physics_process(delta: float) -> void:
	if input_source == null:
		return
	simulate_tick(input_source.sample_input_for_tick(simulation_tick), delta)
	simulation_tick += 1


func simulate_tick(command: InputCommandFrame, delta: float) -> void:
	if stats == null or delta <= 0.0:
		return
	state.just_landed_this_tick = false
	state.update_drift_hop_buffer(command)
	_update_ground_state()
	_update_steering_and_heading(command, delta)
	_update_longitudinal_velocity(command, delta)
	_update_lateral_velocity(delta)
	_apply_gravity(delta)
	velocity = (
		state.forward_dir * state.forward_speed
		+ state.right_dir * state.lateral_speed
		+ Vector3.UP * state.vertical_speed
	)
	move_and_slide()
	state.position = global_position
	state.linear_velocity = velocity
	state.is_grounded = is_on_floor()
	if state.is_grounded:
		state.airborne_ticks = 0
	else:
		state.airborne_ticks += 1
	state.vertical_speed = velocity.dot(Vector3.UP)


func _update_ground_state() -> void:
	state.is_grounded = is_on_floor()
	if state.is_grounded:
		state.ground_normal = get_floor_normal()
		state.up_normal = state.ground_normal
		if state.vertical_speed < 0.0:
			state.vertical_speed = 0.0


func _update_steering_and_heading(command: InputCommandFrame, delta: float) -> void:
	var target_steer: float = command.get_steer_float()
	var steer_rate: float = stats.steer_input_rise_rate if absf(target_steer) > absf(state.smoothed_steer_input) else stats.steer_input_fall_rate
	state.smoothed_steer_input = move_toward(state.smoothed_steer_input, target_steer, steer_rate * delta)
	var speed_ratio: float = clampf(absf(state.forward_speed) / stats.max_speed_forward, 0.0, 1.0)
	var speed_turn_factor: float = stats.steer_speed_curve.sample_baked(speed_ratio)
	if absf(state.forward_speed) < 0.1:
		speed_turn_factor = 0.0
	var reverse_factor: float = -1.0 if state.forward_speed < -0.2 else 1.0
	state.heading_yaw += deg_to_rad(stats.max_steer_angle_deg) * state.smoothed_steer_input * speed_turn_factor * reverse_factor * delta
	rotation.y = state.heading_yaw
	state.forward_dir = Vector3.FORWARD.rotated(Vector3.UP, state.heading_yaw).normalized()
	state.right_dir = Vector3.RIGHT.rotated(Vector3.UP, state.heading_yaw).normalized()


func _update_longitudinal_velocity(command: InputCommandFrame, delta: float) -> void:
	var throttle: float = command.get_throttle_float()
	var brake: float = command.get_brake_float()
	var effective_max_speed: float = stats.max_speed_forward
	if throttle > 0.0:
		var speed_ratio: float = clampf(state.forward_speed / effective_max_speed, 0.0, 1.0)
		var acceleration: float = stats.base_acceleration * stats.acceleration_curve.sample_baked(speed_ratio)
		state.forward_speed = minf(state.forward_speed + acceleration * throttle * delta, effective_max_speed)
	elif brake > 0.0 and state.forward_speed > 0.2:
		state.forward_speed = move_toward(state.forward_speed, 0.0, stats.braking_deceleration * brake * delta)
	elif brake > 0.0:
		state.forward_speed = maxf(state.forward_speed - stats.reverse_acceleration * brake * delta, -stats.max_speed_reverse)
	else:
		state.forward_speed = move_toward(state.forward_speed, 0.0, stats.coasting_friction * delta)
	if state.forward_speed > effective_max_speed:
		state.forward_speed = move_toward(state.forward_speed, effective_max_speed, stats.overspeed_decay_rate * delta)
	if absf(state.forward_speed) < stats.min_coast_stop_speed and throttle == 0.0 and brake == 0.0:
		state.forward_speed = 0.0


func _update_lateral_velocity(delta: float) -> void:
	var lateral_speed: float = velocity.dot(state.right_dir)
	var grip: float = stats.lateral_grip_grounded if state.is_grounded else stats.lateral_grip_airborne
	lateral_speed = move_toward(lateral_speed, 0.0, grip * delta)
	state.lateral_speed = lateral_speed


func _apply_gravity(delta: float) -> void:
	if state.is_grounded:
		state.vertical_speed = 0.0
	else:
		state.vertical_speed = maxf(state.vertical_speed - stats.gravity_airborne * delta, -stats.max_fall_speed)


func _ensure_collision_shape() -> void:
	var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = stats.collision_sphere_radius
	collision_shape.shape = sphere
