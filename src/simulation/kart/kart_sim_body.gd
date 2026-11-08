class_name KartSimBody
extends CharacterBody3D

const GROUND_ALIGN_SPEED: float = 10.0

@export var stats: KartStatsResource
@export var racer_id: int = 0
@export_range(0.1, 2.0, 0.05) var surface_speed_mult: float = 1.0
@export_range(0.1, 2.0, 0.05) var surface_acceleration_mult: float = 1.0
@export_range(0.1, 2.0, 0.05) var surface_grip_mult: float = 1.0
@export var surface_cancels_drift_without_boost: bool = false

var state: KartSimState = KartSimState.new()
var input_source: KartInputSource
var simulation_tick: int = 0
var _ground_raycasts: Array[RayCast3D] = []


func _ready() -> void:
	if stats == null:
		stats = load("res://resources/karts/stats_balanced.tres") as KartStatsResource
	if not stats.is_valid():
		push_error("KartSimBody requires valid kart stats.")
		set_physics_process(false)
		return
	input_source = LocalHumanInputSource.new()
	floor_max_angle = deg_to_rad(stats.max_driveable_slope_deg)
	floor_snap_length = stats.ground_snap_distance
	collision_layer = 1 << 2
	collision_mask = (1 << 0) | (1 << 1) | (1 << 2)
	_ensure_collision_shape()
	_setup_ground_raycasts()
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
	var drift_hop_pressed: bool = command.is_button_pressed(InputCommandFrame.BIT_DRIFT_HOP)
	if drift_hop_pressed and not state.last_drift_hop_pressed:
		state.trick_hop_input_tick = command.tick
	state.update_drift_hop_buffer(command)
	_update_ground_and_surface_sensors(delta)
	_update_trick_ramp_boost(command.tick)
	_update_status_and_boost_timers()
	_update_hop_and_drift_state(command)
	_update_steering_and_heading(command, delta)
	_update_longitudinal_velocity(command, delta)
	_update_lateral_velocity(delta)
	_apply_gravity_and_slopes(delta)
	var ground_velocity: Vector3 = (
		state.forward_dir * state.forward_speed
		+ state.right_dir * state.lateral_speed
	)
	if state.is_grounded and state.drift_state != 1:
		ground_velocity = ground_velocity.slide(state.ground_normal)
	velocity = ground_velocity + Vector3.UP * state.vertical_speed
	_move_and_resolve_collisions()


func _update_ground_and_surface_sensors(delta: float) -> void:
	var normal_sum: Vector3 = Vector3.ZERO
	var hit_count: int = 0
	for raycast: RayCast3D in _ground_raycasts:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			normal_sum += raycast.get_collision_normal()
			hit_count += 1
	var ascending_hop: bool = state.drift_state == 1 and state.vertical_speed > 0.0
	var has_walkable_ground: bool = hit_count > 0
	if has_walkable_ground:
		var average_normal: Vector3 = (normal_sum / float(hit_count)).normalized()
		has_walkable_ground = average_normal.dot(Vector3.UP) >= cos(deg_to_rad(stats.max_driveable_slope_deg))
	state.is_grounded = has_walkable_ground and state.vertical_speed <= 2.0 and not ascending_hop
	if state.is_grounded:
		state.ground_normal = (normal_sum / float(hit_count)).normalized()
		state.up_normal = state.up_normal.slerp(state.ground_normal, minf(GROUND_ALIGN_SPEED * delta, 1.0)).normalized()
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


func _update_trick_ramp_boost(current_tick: int) -> void:
	if state.trick_hop_input_tick < 0 or current_tick - state.trick_hop_input_tick > 12:
		return
	for raycast: RayCast3D in _ground_raycasts:
		if raycast.is_colliding() and bool(raycast.get_collider().get_meta("is_trick_ramp", false)):
			state.trick_boost_armed = true
			return


func _update_hop_and_drift_state(command: InputCommandFrame) -> void:
	var drift_pressed: bool = command.is_button_pressed(InputCommandFrame.BIT_DRIFT_HOP)
	var minimum_drift_speed: float = stats.max_speed_forward * stats.min_drift_entry_speed_ratio
	if state.drift_state != 0 and (
		(command.brake_axis > 0 and state.forward_speed <= minimum_drift_speed)
		or surface_cancels_drift_without_boost
	):
		_cancel_drift()
	if state.drift_state == 0 and state.consume_drift_hop_buffer(command.tick, state.is_grounded):
		state.drift_state = 1
		state.hop_ticks_left = stats.hop_duration_ticks
		state.vertical_speed = stats.hop_upward_velocity
	if state.drift_state == 1:
		var steer: float = command.get_steer_float()
		if state.drift_dir == 0 and absf(steer) > 0.2:
			state.drift_dir = int(signf(steer))
		state.hop_ticks_left = maxi(state.hop_ticks_left - 1, 0)
		if state.hop_ticks_left == 0 and state.is_grounded:
			if drift_pressed and state.drift_dir != 0 and state.forward_speed >= minimum_drift_speed:
				state.drift_state = 2
			else:
				state.drift_state = 0
				state.drift_dir = 0
	if state.drift_state == 2:
		if state.is_grounded:
			var inward_steer: float = maxf(command.get_steer_float() * float(state.drift_dir), 0.0)
			state.mt_charge += stats.mt_charge_base_per_tick * lerpf(1.0, stats.mt_charge_tight_steer_multiplier, inward_steer)
			_update_mini_turbo_level()
		if not drift_pressed:
			_release_drift()


func _update_mini_turbo_level() -> void:
	if state.mt_charge >= stats.mt_level_3_threshold:
		state.mt_level = 3
	elif state.mt_charge >= stats.mt_level_2_threshold:
		state.mt_level = 2
	elif state.mt_charge >= stats.mt_level_1_threshold:
		state.mt_level = 1


func _release_drift() -> void:
	match state.mt_level:
		1:
			apply_boost(stats.mt_1_duration_ticks, stats.mt_1_speed_bonus)
		2:
			apply_boost(stats.mt_2_duration_ticks, stats.mt_2_speed_bonus)
		3:
			apply_boost(stats.mt_3_duration_ticks, stats.mt_3_speed_bonus)
	state.mt_level = 0
	state.mt_charge = 0.0
	state.drift_state = 0
	state.drift_dir = 0


func _cancel_drift() -> void:
	state.mt_level = 0
	state.mt_charge = 0.0
	state.drift_state = 0
	state.drift_dir = 0
	state.hop_ticks_left = 0


func apply_boost(duration_ticks: int, speed_bonus: float) -> void:
	state.boost_ticks_left = maxi(state.boost_ticks_left, duration_ticks)
	state.boost_speed_bonus = maxf(state.boost_speed_bonus, speed_bonus)
	state.forward_speed = maxf(state.forward_speed, stats.max_speed_forward + speed_bonus * 0.8)


func _update_steering_and_heading(command: InputCommandFrame, delta: float) -> void:
	var target_steer: float = command.get_steer_float()
	var steer_rate: float = stats.steer_input_rise_rate if absf(target_steer) > absf(state.smoothed_steer_input) else stats.steer_input_fall_rate
	state.smoothed_steer_input = move_toward(state.smoothed_steer_input, target_steer, steer_rate * delta)
	var speed_ratio: float = clampf(absf(state.forward_speed) / stats.max_speed_forward, 0.0, 1.0)
	var speed_turn_factor: float = stats.steer_speed_curve.sample_baked(speed_ratio)
	if absf(state.forward_speed) < 0.1:
		speed_turn_factor = 0.0
	if not state.is_grounded:
		speed_turn_factor *= stats.air_steer_factor
	var reverse_factor: float = -1.0 if state.forward_speed < -0.2 else 1.0
	var steer_angle_deg: float = stats.max_steer_angle_deg * state.smoothed_steer_input
	if state.drift_state == 2:
		var steer_direction: float = signf(state.smoothed_steer_input)
		if steer_direction == float(state.drift_dir):
			steer_angle_deg += float(state.drift_dir) * stats.drift_inward_steer_bonus_deg * absf(state.smoothed_steer_input)
		elif steer_direction != 0.0:
			steer_angle_deg -= float(state.drift_dir) * stats.drift_outward_countersteer_deg * absf(state.smoothed_steer_input)
	state.heading_yaw -= deg_to_rad(steer_angle_deg) * speed_turn_factor * reverse_factor * delta
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
		if state.drift_state == 2:
			state.forward_speed = maxf(state.forward_speed, stats.max_speed_forward * stats.drift_speed_floor_ratio)
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
	var impact_speed: float = absf(state.vertical_speed)
	var collided: bool = move_and_slide()
	if collided and is_on_wall():
		_handle_wall_collision()
	state.position = global_position
	state.linear_velocity = velocity
	state.is_grounded = is_on_floor()
	if state.is_grounded:
		state.airborne_ticks = 0
		state.ground_normal = get_floor_normal()
		state.up_normal = state.ground_normal
		if not was_grounded:
			state.just_landed_this_tick = true
			state.landing_impact_speed = impact_speed
			velocity = velocity.slide(state.ground_normal)
			EventBus.kart_landed.emit(racer_id, state.landing_impact_speed)
			if state.trick_boost_armed:
				apply_boost(45, stats.mt_1_speed_bonus)
				state.trick_boost_armed = false
	else:
		state.airborne_ticks += 1
	state.vertical_speed = velocity.dot(Vector3.UP)
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	state.forward_speed = horizontal_velocity.dot(state.forward_dir)
	state.lateral_speed = horizontal_velocity.dot(state.right_dir)


func _handle_wall_collision() -> void:
	var wall_normal: Vector3 = Vector3.ZERO
	var contact_point: Vector3 = global_position
	for collision_index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(collision_index)
		var collider: CollisionObject3D = collision.get_collider() as CollisionObject3D
		if collider != null and (collider.collision_layer & (1 << 1)) != 0:
			wall_normal = collision.get_normal()
			contact_point = collision.get_position()
			break
	wall_normal.y = 0.0
	wall_normal = wall_normal.normalized()
	if wall_normal.is_zero_approx():
		return
	state.last_wall_normal = wall_normal
	var impact_dot: float = absf(state.forward_dir.dot(wall_normal))
	if impact_dot < 0.45:
		velocity = velocity.slide(wall_normal) * 0.96
		return
	_cancel_drift()
	velocity = velocity.slide(wall_normal) * 0.65 + wall_normal * stats.wall_bounce_impulse
	state.forward_speed *= 1.0 - impact_dot * 0.35
	if state.wall_contact_cooldown == 0:
		EventBus.kart_wall_collision.emit(racer_id, impact_dot, contact_point)
		state.wall_contact_cooldown = 12


func _ensure_collision_shape() -> void:
	var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = stats.collision_sphere_radius
	collision_shape.shape = sphere


func _setup_ground_raycasts() -> void:
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		Vector3(-0.75, 0.0, -1.0),
		Vector3(0.75, 0.0, -1.0),
		Vector3(-0.75, 0.0, 1.0),
		Vector3(0.75, 0.0, 1.0),
	]
	for index: int in range(offsets.size()):
		var raycast: RayCast3D = RayCast3D.new()
		raycast.name = "GroundRay_%d" % index
		raycast.position = offsets[index]
		raycast.target_position = Vector3.DOWN * (stats.collision_sphere_radius + stats.ground_snap_distance + 0.5)
		raycast.collision_mask = 1
		raycast.enabled = true
		add_child(raycast)
		_ground_raycasts.append(raycast)
