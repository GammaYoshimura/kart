class_name KartVisualNode
extends Node3D

@export var sim_body_path: NodePath = NodePath("../Kart")
@export var wheel_radius: float = 0.28

var _sim_body: KartSimBody
var _chassis_pivot: Node3D
var _front_left_wheel: Node3D
var _front_right_wheel: Node3D
var _rear_left_wheel: Node3D
var _rear_right_wheel: Node3D
var _previous_transform: Transform3D
var _current_transform: Transform3D
var _wheel_rotation: float = 0.0


func _ready() -> void:
	_sim_body = get_node_or_null(sim_body_path) as KartSimBody
	_chassis_pivot = get_node_or_null("ChassisPivot") as Node3D
	_front_left_wheel = get_node_or_null("ChassisPivot/WheelFL") as Node3D
	_front_right_wheel = get_node_or_null("ChassisPivot/WheelFR") as Node3D
	_rear_left_wheel = get_node_or_null("ChassisPivot/WheelRL") as Node3D
	_rear_right_wheel = get_node_or_null("ChassisPivot/WheelRR") as Node3D
	if _sim_body == null or _chassis_pivot == null:
		push_error("KartVisualNode requires a KartSimBody and ChassisPivot.")
		set_process(false)
		set_physics_process(false)
		return
	_current_transform = _get_sim_transform()
	_previous_transform = _current_transform
	global_transform = _current_transform


func _physics_process(delta: float) -> void:
	_previous_transform = _current_transform
	_current_transform = _get_sim_transform()
	_wheel_rotation = fposmod(_wheel_rotation + _sim_body.state.forward_speed * delta / maxf(wheel_radius, 0.01), TAU)


func _process(_delta: float) -> void:
	global_transform = _previous_transform.interpolate_with(
		_current_transform,
		Engine.get_physics_interpolation_fraction()
	)
	_apply_chassis_motion()
	_apply_wheel_motion()


func _get_sim_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, _sim_body.state.heading_yaw), _sim_body.state.position)


func _apply_chassis_motion() -> void:
	var state: KartSimState = _sim_body.state
	var drift_yaw: float = -float(state.drift_dir) * deg_to_rad(18.0) if state.drift_state == 2 else 0.0
	_chassis_pivot.rotation = Vector3(
		-deg_to_rad(4.0) if state.boost_ticks_left > 0 else 0.0,
		drift_yaw,
		-clampf(state.smoothed_steer_input * 0.12, -0.18, 0.18)
	)
	var front_steer: float = state.smoothed_steer_input * deg_to_rad(32.0)
	_front_left_wheel.rotation.y = front_steer
	_front_right_wheel.rotation.y = front_steer


func _apply_wheel_motion() -> void:
	_front_left_wheel.rotation.x = _wheel_rotation
	_front_right_wheel.rotation.x = _wheel_rotation
	_rear_left_wheel.rotation.x = _wheel_rotation
	_rear_right_wheel.rotation.x = _wheel_rotation
