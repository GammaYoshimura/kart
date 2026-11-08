class_name KartStatsResource
extends Resource

@export_group("Identity")
@export var stats_id: StringName = &""
@export var archetype_name: String = ""

@export_group("Longitudinal speed")
@export var max_speed_forward: float = 32.0
@export var max_speed_reverse: float = 12.0
@export var overspeed_decay_rate: float = 18.0
@export var min_coast_stop_speed: float = 0.25

@export_group("Acceleration and braking")
@export var base_acceleration: float = 18.0
@export var acceleration_curve: Curve
@export var coasting_friction: float = 7.5
@export var braking_deceleration: float = 34.0
@export var reverse_acceleration: float = 11.0

@export_group("Steering")
@export var max_steer_angle_deg: float = 75.0
@export var steer_speed_curve: Curve
@export var steer_input_rise_rate: float = 10.0
@export var steer_input_fall_rate: float = 14.0
@export var air_steer_factor: float = 0.25

@export_group("Grip and traction")
@export var lateral_grip_grounded: float = 14.0
@export var lateral_grip_drifting: float = 6.5
@export var lateral_grip_airborne: float = 0.5
@export_range(0.0, 1.0) var offroad_speed_retention: float = 0.65

@export_group("Collision and gravity")
@export var collision_sphere_radius: float = 0.65
@export var weight_mass: float = 100.0
@export var gravity_grounded: float = 20.0
@export var gravity_airborne: float = 34.0
@export var max_fall_speed: float = 55.0
@export var ground_snap_distance: float = 0.45
@export_range(0.0, 89.0) var max_driveable_slope_deg: float = 50.0

@export_group("Hop and drift entry")
@export var hop_upward_velocity: float = 7.8
@export var hop_duration_ticks: int = 14
@export_range(0.0, 1.0) var min_drift_entry_speed_ratio: float = 0.45
@export var drift_base_slip_angle_deg: float = 24.0

@export_group("Drift control")
@export var drift_inward_steer_bonus_deg: float = 32.0
@export var drift_outward_countersteer_deg: float = 20.0
@export var drift_yaw_responsiveness: float = 9.0
@export_range(0.0, 1.0) var drift_speed_floor_ratio: float = 0.85

@export_group("Mini-turbo charge")
@export var mt_charge_base_per_tick: float = 1.0
@export var mt_charge_tight_steer_multiplier: float = 2.2
@export var mt_level_1_threshold: float = 60.0
@export var mt_level_2_threshold: float = 140.0
@export var mt_level_3_threshold: float = 240.0

@export_group("Mini-turbo and boost")
@export var mt_1_duration_ticks: int = 45
@export var mt_1_speed_bonus: float = 8.0
@export var mt_2_duration_ticks: int = 80
@export var mt_2_speed_bonus: float = 11.5
@export var mt_3_duration_ticks: int = 125
@export var mt_3_speed_bonus: float = 15.0
@export var boost_instant_acceleration: float = 65.0


func _init() -> void:
	_ensure_default_curves()


func is_valid() -> bool:
	_ensure_default_curves()
	return (
		not stats_id.is_empty()
		and not archetype_name.strip_edges().is_empty()
		and max_speed_forward > 0.0
		and max_speed_reverse > 0.0
		and base_acceleration > 0.0
		and collision_sphere_radius > 0.0
		and weight_mass > 0.0
		and hop_duration_ticks > 0
		and mt_level_1_threshold > 0.0
		and mt_level_2_threshold > mt_level_1_threshold
		and mt_level_3_threshold > mt_level_2_threshold
		and mt_1_duration_ticks > 0
		and mt_2_duration_ticks > 0
		and mt_3_duration_ticks > 0
	)


func _ensure_default_curves() -> void:
	if acceleration_curve == null:
		acceleration_curve = _make_curve([
			Vector2(0.0, 1.0),
			Vector2(0.65, 0.82),
			Vector2(1.0, 0.55),
		])
	if steer_speed_curve == null:
		steer_speed_curve = _make_curve([
			Vector2(0.0, 1.0),
			Vector2(0.35, 0.95),
			Vector2(1.0, 0.5),
		])


func _make_curve(points: Array[Vector2]) -> Curve:
	var curve: Curve = Curve.new()
	curve.bake_resolution = 64
	for point: Vector2 in points:
		curve.add_point(point)
	return curve
