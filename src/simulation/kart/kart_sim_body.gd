class_name KartSimBody
extends CharacterBody3D

@export var stats: KartStatsResource
@export_range(0.1, 2.0, 0.05) var surface_speed_mult: float = 1.0
@export_range(0.1, 2.0, 0.05) var surface_acceleration_mult: float = 1.0
@export_range(0.1, 2.0, 0.05) var surface_grip_mult: float = 1.0

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
	_update_ground_and_surface_sensors()
	_update_status_and_boost_timers()
	_update_hop_and_drift_state(command)
	_update_steering_and_heading(command, delta)
	_update_longitudinal_velocity(command, delta)
	_update_lateral_velocity(delta)
	_apply_gravity_and_slopes(delta)
	velocity = (
		state.forward_dir * state.forward_speed
		+ state.right_dir * state.lateral_speed
		+ Vector3.UP * state.vertical_speed
	)
	_move_and_resolve_collisions()


func _update_ground_and_surface_sensors() -> void:
	state.is_grounded = is_on_floor()
	if state.is_grounded:
		state.ground_normal = get_floor_normal()
		state.up_normal = state.ground_normal
		if state.vertical_speed < 0.0:
			state.vertical_speed = 0.0
	state.current_surface_id = 0


func _update_status_and_boost_timers() -> void:
	if state.boost_ticks_left > 0:
		state.boost_ticks_left -= 1
		if state.boost_ticks_left == 0:
			state.boost_speed_bonus = 0.0
	if state.wall_contact_cooldown > 0:
		state.wall_contact_cooldown -= 1
	if state.kart_bump_cooldown > 0:
		state.kart_bump_cooldown -= 1


func _update_hop_and_drift_state(command: InputCommandFrame) -> void:
	var drift_pressed: bool = command.is_button_pressed(InputCommandFrame.BIT_DRIFT_HOP)
	if state.drift_state == 0 and state.consume_drift_hop_buffer(command.tick, state.is_grounded):
		state.drift_state = 1
		state.hop_ticks_left = stats.hop_duration_ticks
		state.vertical_speed = stats.hop_upward_velocity
	if state.drift_state == 1:
		state.hop_ticks_left = maxi(state.hop_ticks_left - 1, 0)
		if state.hop_ticks_left == 0 and state.is_grounded and drift_pressed:
			var steer: float = command.get_steer_float()
			if absf(steer) > 0.2 and state.forward_speed >= stats.max_speed_forward * stats.min_drift_entry_speed_ratio:
				state.drift_state = 2
				state.drift_dir = int(signf(steer))
	if state.drift_state == 2:
		var steer_strength: float = absf(command.get_steer_float())
		state.mt_charge += stats.mt_charge_base_per_tick * lerpf(1.0, stats.mt_charge_tight_steer_multiplier, steer_strength)
		if not drift_pressed:
			_release_drift()


func _release_drift() -> void:
	if state.mt_charge >= stats.mt_level_3_threshold:
		state.mt_level = 3
		state.boost_ticks_left = stats.mt_3_duration_ticks
		state.boost_speed_bonus = stats.mt_3_speed_bonus
	elif state.mt_charge >= stats.mt_level_2_threshold:
		state.mt_level = 2
		state.boost_ticks_left = stats.mt_2_duration_ticks
		state.boost_speed_bonus = stats.mt_2_speed_bonus
	elif state.mt_charge >= stats.mt_level_1_threshold:
		state.mt_level = 1
		state.boost_ticks_left = stats.mt_1_duration_ticks
		state.boost_speed_bonus = stats.mt_1_speed_bonus
	else:
		state.mt_level = 0
	state.mt_charge = 0.0
	state.drift_state = 0
	state.drift_dir = 0


func _update_steering_and_heading(command: InputCommandFrame, delta: float) -> void:
	var target_steer: float = command.get_steer_float()
	var steer_rate: float = stats.steer_input_rise_rate if absf(target_steer) > absf(state.smoothed_steer_input) else stats.steer_input_fall_rate
	state.smoothed_steer_input = move_toward(state.smoothed_steer_input, target_steer, steer_rate * delta)
	var speed_ratio: float = clampf(absf(state.forward_speed) / stats.max_speed_forward, 0.0, 1.0)
	var speed_turn_factor: float = stats.steer_speed_curve.sample_baked(speed_ratio)
	if absf(state.forward_speed) < 0.1:
		speed_turn_factor = 0.0
	var reverse_factor: float = -1.0 if state.forward_speed < -0.2 else 1.0
	state.heading_yaw -= deg_to_rad(stats.max_steer_angle_deg) * state.smoothed_steer_input * speed_turn_factor * reverse_factor * delta
	rotation.y = state.heading_yaw
	state.forward_dir = Vector3.FORWARD.rotated(Vector3.UP, state.heading_yaw).normalized()
	state.right_dir = Vector3.RIGHT.rotated(Vector3.UP, state.heading_yaw).normalized()


func _update_longitudinal_velocity(command: InputCommandFrame, delta: float) -> void:
	var throttle: float = command.get_throttle_float()
	var brake: float = command.get_brake_float()
	var active_boost_speed_bonus: float = state.boost_speed_bonus if state.boost_ticks_left > 0 else 0.0
	var effective_surface_mult: float = maxf(surface_speed_mult, 1.0) if active_boost_speed_bonus > 0.0 else surface_speed_mult
	var effective_max_speed: float = stats.max_speed_forward * effective_surface_mult + active_boost_speed_bonus
	if throttle > 0.0:
		var speed_ratio: float = clampf(state.forward_speed / effective_max_speed, 0.0, 1.0)
		var acceleration: float = stats.base_acceleration * stats.acceleration_curve.sample_baked(speed_ratio) * surface_acceleration_mult
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
	var grip: float = stats.lateral_grip_airborne
	if state.is_grounded:
		grip = stats.lateral_grip_drifting if state.drift_state == 2 else stats.lateral_grip_grounded * surface_grip_mult
	lateral_speed = move_toward(lateral_speed, 0.0, grip * delta)
	state.lateral_speed = lateral_speed


func _apply_gravity_and_slopes(delta: float) -> void:
	if state.is_grounded and state.drift_state != 1:
		state.vertical_speed = 0.0
	else:
		state.vertical_speed = maxf(state.vertical_speed - stats.gravity_airborne * delta, -stats.max_fall_speed)
		state.up_normal = state.up_normal.slerp(Vector3.UP, minf(delta * 2.0, 1.0)).normalized()


func _move_and_resolve_collisions() -> void:
	var was_grounded: bool = state.is_grounded
	var collided: bool = move_and_slide()
	if collided and is_on_wall():
		state.last_wall_normal = get_wall_normal()
	state.position = global_position
	state.linear_velocity = velocity
	state.is_grounded = is_on_floor()
	if state.is_grounded:
		state.airborne_ticks = 0
		state.ground_normal = get_floor_normal()
		state.up_normal = state.ground_normal
		if not was_grounded:
			state.just_landed_this_tick = true
			state.landing_impact_speed = absf(state.vertical_speed)
	else:
		state.airborne_ticks += 1
	state.vertical_speed = velocity.dot(Vector3.UP)
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	state.forward_speed = horizontal_velocity.dot(state.forward_dir)
	state.lateral_speed = horizontal_velocity.dot(state.right_dir)


func _ensure_collision_shape() -> void:
	var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = stats.collision_sphere_radius
	collision_shape.shape = sphere
