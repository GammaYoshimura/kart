class_name DrivingDebugDraw3D
extends Node3D

@export var target_path: NodePath = NodePath("../Kart")

var _target: KartSimBody
var _mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D
var _line_material: StandardMaterial3D


func _ready() -> void:
	_target = get_node_or_null(target_path) as KartSimBody
	_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "DebugVectors"
	_mesh_instance.mesh = _mesh
	_line_material = StandardMaterial3D.new()
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_material.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = _line_material
	add_child(_mesh_instance)
	visible = false
	if _target == null:
		push_error("DrivingDebugDraw3D requires a KartSimBody target.")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_driving_debug"):
		visible = not visible
	if not visible or _target == null:
		return
	_mesh.clear_surfaces()
	_mesh_instance.global_position = _target.state.position
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var state: KartSimState = _target.state
	_add_line(Vector3.ZERO, state.linear_velocity.limit_length(6.0), Color(0.2, 1.0, 0.35))
	_add_line(Vector3.ZERO, state.forward_dir * 3.0, Color(0.2, 0.55, 1.0))
	_add_line(Vector3.ZERO, state.ground_normal * 1.6, Color(1.0, 0.7, 0.15))
	_add_line(Vector3.ZERO, state.last_wall_normal * 1.2, Color(1.0, 0.2, 0.16))
	for child: Node in _target.get_children():
		if child is RayCast3D and child.name.begins_with("GroundRay_"):
			var ground_ray: RayCast3D = child as RayCast3D
			var ray_start: Vector3 = ground_ray.global_position - _target.global_position
			var ray_end_world: Vector3 = ground_ray.get_collision_point() if ground_ray.is_colliding() else ground_ray.to_global(ground_ray.target_position)
			_add_line(ray_start, ray_end_world - _target.global_position, Color(1.0, 0.9, 0.25))
	_mesh.surface_end()


func _add_line(start: Vector3, finish: Vector3, color: Color) -> void:
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(start)
	_mesh.surface_add_vertex(finish)
