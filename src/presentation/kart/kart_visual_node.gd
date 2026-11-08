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
var _wheel_raycasts: Array[RayCast3D] = []
var _wheel_nodes: Array[Node3D] = []
var _wheel_rest_heights: Array[float] = []
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
	_wheel_nodes = [_front_left_wheel, _front_right_wheel, _rear_left_wheel, _rear_right_wheel]
	_wheel_rest_heights = [-0.4, -0.4, -0.4, -0.4]
	_wheel_raycasts = [
		get_node_or_null("ChassisPivot/WheelRayFL") as RayCast3D,
		get_node_or_null("ChassisPivot/WheelRayFR") as RayCast3D,
		get_node_or_null("ChassisPivot/WheelRayRL") as RayCast3D,
		get_node_or_null("ChassisPivot/WheelRayRR") as RayCast3D,
	]
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
	_apply_wheel_suspension()


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


func _apply_wheel_suspension() -> void:
	for wheel_index: int in range(_wheel_nodes.size()):
		var wheel_ray: RayCast3D = _wheel_raycasts[wheel_index]
		var wheel: Node3D = _wheel_nodes[wheel_index]
		var rest_height: float = _wheel_rest_heights[wheel_index]
		wheel_ray.force_raycast_update()
		if wheel_ray.is_colliding():
			var ground_point: Vector3 = _chassis_pivot.to_local(wheel_ray.get_collision_point())
			wheel.position.y = clampf(ground_point.y + 0.21, rest_height - 0.1, rest_height + 0.1)
		else:
			wheel.position.y = rest_height
