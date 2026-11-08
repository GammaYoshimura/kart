extends Node3D

const GATE_SPACING_METERS: int = 50
const STRAIGHT_LENGTH_METERS: int = 300
const TRACK_HALF_WIDTH: float = 9.0

@onready var _kart: KartSimBody = $Kart
@onready var _readout: Label = $HUD/Readout
var _gate_material: StandardMaterial3D
var _drift_road_material: StandardMaterial3D


func _ready() -> void:
	_gate_material = StandardMaterial3D.new()
	_gate_material.albedo_color = Color(0.12, 0.84, 1.0, 1.0)
	_gate_material.emission_enabled = true
	_gate_material.emission = Color(0.04, 0.3, 0.55, 1.0)
	_gate_material.emission_energy_multiplier = 1.4
	_drift_road_material = StandardMaterial3D.new()
	_drift_road_material.albedo_color = Color(0.15, 0.19, 0.24, 1.0)
	_drift_road_material.roughness = 0.88
	_build_distance_gates()
	_build_drift_sector()


func _process(_delta: float) -> void:
	var distance_m: int = roundi(145.0 - _kart.global_position.z)
	var speed_kmh: int = roundi(absf(_kart.state.forward_speed) * 3.6)
	_readout.text = "RECTA 300 m   %03d / 300 m     %03d km/h" % [clampi(distance_m, 0, STRAIGHT_LENGTH_METERS), speed_kmh]


func _build_distance_gates() -> void:
	for distance_m: int in range(GATE_SPACING_METERS, STRAIGHT_LENGTH_METERS + 1, GATE_SPACING_METERS):
		var gate: Node3D = Node3D.new()
		gate.name = "DistanceGate_%03d" % distance_m
		gate.position = Vector3(0.0, 0.0, 145.0 - float(distance_m))
		add_child(gate)
		_add_gate_beam(gate, Vector3(-TRACK_HALF_WIDTH, 2.2, 0.0), Vector3(0.35, 4.4, 0.35))
		_add_gate_beam(gate, Vector3(TRACK_HALF_WIDTH, 2.2, 0.0), Vector3(0.35, 4.4, 0.35))
		_add_gate_beam(gate, Vector3(0.0, 4.25, 0.0), Vector3(TRACK_HALF_WIDTH * 2.0 + 0.35, 0.35, 0.35))
		var label: Label3D = Label3D.new()
		label.position = Vector3(0.0, 4.8, 0.0)
		label.text = "%d m" % distance_m
		label.font_size = 64
		label.modulate = Color(0.72, 0.94, 1.0)
		gate.add_child(label)


func _add_gate_beam(parent: Node3D, beam_position: Vector3, beam_size: Vector3) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = beam_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _gate_material
	mesh_instance.position = beam_position
	parent.add_child(mesh_instance)


func _build_drift_sector() -> void:
	var manual_centerline: Array[Vector3] = [
		Vector3(28.0, 0.0, 135.0), Vector3(28.0, 0.0, 115.0),
		Vector3(36.0, 0.0, 103.0), Vector3(46.0, 0.0, 90.0),
		Vector3(46.0, 0.0, 75.0), Vector3(36.0, 0.0, 63.0),
		Vector3(28.0, 0.0, 50.0), Vector3(28.0, 0.0, 30.0),
		Vector3(34.0, 0.0, 20.0), Vector3(45.0, 0.0, 15.0),
	]
	for angle_index: int in range(1, 13):
		var angle: float = PI - PI * float(angle_index) / 12.0
		manual_centerline.append(Vector3(75.0 + cos(angle) * 30.0, 0.0, 15.0 + sin(angle) * 30.0))
	manual_centerline.append(Vector3(122.0, 0.0, 15.0))
	for angle_index: int in range(1, 9):
		var angle: float = PI - PI * float(angle_index) / 8.0
		manual_centerline.append(Vector3(134.0 + cos(angle) * 12.0, 0.0, 15.0 + sin(angle) * 12.0))
	for point_index: int in range(manual_centerline.size() - 1):
		_add_drift_road_segment(manual_centerline[point_index], manual_centerline[point_index + 1], point_index)
	_add_sector_label("S-CURVES / 90° / R30 180° / R12 HAIRPIN", Vector3(82.0, 3.0, -25.0))


func _add_drift_road_segment(start: Vector3, finish: Vector3, segment_index: int) -> void:
	var planar_delta: Vector3 = finish - start
	planar_delta.y = 0.0
	var segment_length: float = planar_delta.length() + 0.8
	var road: StaticBody3D = StaticBody3D.new()
	road.name = "DriftRoad_%03d" % segment_index
	road.position = (start + finish) * 0.5 + Vector3.DOWN * 0.15
	road.rotation.y = atan2(planar_delta.x, planar_delta.z)
	road.collision_layer = 1
	var road_mesh: BoxMesh = BoxMesh.new()
	road_mesh.size = Vector3(8.0, 0.3, segment_length)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = road_mesh
	mesh_instance.material_override = _drift_road_material
	road.add_child(mesh_instance)
	var road_shape: BoxShape3D = BoxShape3D.new()
	road_shape.size = road_mesh.size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = road_shape
	road.add_child(collision)
	add_child(road)


func _add_sector_label(text_value: String, label_position: Vector3) -> void:
	var label: Label3D = Label3D.new()
	label.text = text_value
	label.position = label_position
	label.font_size = 48
	label.modulate = Color(1.0, 0.72, 0.2)
	add_child(label)
