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
	_build_ramp_sector()
	_build_surface_sector()


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


func _build_ramp_sector() -> void:
	_add_ramp(Vector3(178.0, 0.25, 105.0), 15.0, false, "Ramp_15")
	_add_ramp(Vector3(192.0, 0.25, 68.0), 30.0, false, "Ramp_30")
	_add_ramp(Vector3(206.0, 0.25, 30.0), 45.0, false, "Ramp_45")
	_add_ramp(Vector3(222.0, 0.25, -12.0), 18.0, true, "TrickRamp_01")
	_add_ramp(Vector3(238.0, 0.25, -48.0), 30.0, true, "TrickRamp_02")
	_add_ramp(Vector3(254.0, 0.25, -84.0), 42.0, true, "TrickRamp_03")
	var bank: StaticBody3D = StaticBody3D.new()
	bank.name = "BankedCurve_25"
	bank.position = Vector3(180.0, 0.8, -40.0)
	bank.rotation.z = deg_to_rad(25.0)
	bank.collision_layer = 1
	_add_box_surface(bank, Vector3(12.0, 0.45, 24.0))
	add_child(bank)
	_add_sector_label("RAMPS 15° / 30° / 45°   •   BANK 25°   •   TRICK BOOST", Vector3(210.0, 7.0, -115.0))


func _add_ramp(ramp_position: Vector3, slope_degrees: float, is_trick_ramp: bool, ramp_name: String) -> void:
	var ramp: StaticBody3D = StaticBody3D.new()
	ramp.name = ramp_name
	ramp.position = ramp_position
	ramp.rotation.x = deg_to_rad(slope_degrees)
	ramp.collision_layer = 1
	ramp.set_meta("is_trick_ramp", is_trick_ramp)
	_add_box_surface(ramp, Vector3(8.0, 0.5, 14.0))
	add_child(ramp)


func _add_box_surface(parent: StaticBody3D, box_size: Vector3) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = box_size
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _gate_material
	parent.add_child(mesh_instance)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box_size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	parent.add_child(collision)


func _build_surface_sector() -> void:
	var surfaces: Array[Dictionary] = [
		{"name": "Asphalt", "id": 1, "x": -28.0, "speed": 1.0, "accel": 1.0, "grip": 1.0, "color": Color(0.18, 0.22, 0.27)},
		{"name": "Dirt", "id": 2, "x": -42.0, "speed": 0.85, "accel": 0.78, "grip": 0.82, "color": Color(0.42, 0.25, 0.12)},
		{"name": "Sand", "id": 3, "x": -56.0, "speed": 0.68, "accel": 0.62, "grip": 0.7, "color": Color(0.82, 0.65, 0.3)},
		{"name": "Grass", "id": 4, "x": -70.0, "speed": 0.55, "accel": 0.52, "grip": 0.55, "color": Color(0.16, 0.48, 0.2)},
		{"name": "Ice", "id": 5, "x": -84.0, "speed": 0.9, "accel": 0.9, "grip": 0.22, "color": Color(0.35, 0.78, 0.95)},
	]
	for surface: Dictionary in surfaces:
		var body: StaticBody3D = StaticBody3D.new()
		body.name = "Surface_%s" % str(surface["name"])
		body.position = Vector3(float(surface["x"]), -0.15, 50.0)
		body.collision_layer = 1
		body.set_meta("surface_id", int(surface["id"]))
		body.set_meta("surface_speed_mult", float(surface["speed"]))
		body.set_meta("surface_acceleration_mult", float(surface["accel"]))
		body.set_meta("surface_grip_mult", float(surface["grip"]))
		body.set_meta("cancels_drift_without_boost", str(surface["name"]) == "Grass")
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(surface["color"])
		material.roughness = 0.88
		var size: Vector3 = Vector3(12.0, 0.3, 120.0)
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = size
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.material_override = material
		body.add_child(mesh_instance)
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	_add_sector_label("SURFACES: ASPHALT / DIRT / SAND / GRASS / ICE", Vector3(-56.0, 5.0, -18.0))
	_add_boost_pad(Vector3(-56.0, 0.0, -92.0))
	_add_boost_pad(Vector3(-56.0, 0.0, -104.0))


func _add_boost_pad(pad_position: Vector3) -> void:
	var pad: Area3D = Area3D.new()
	pad.name = "BoostPad"
	pad.position = pad_position
	pad.set_script(load("res://src/simulation/track/boost_pad_zone.gd"))
	var pad_mesh: BoxMesh = BoxMesh.new()
	pad_mesh.size = Vector3(7.0, 0.12, 2.4)
	var pad_material: StandardMaterial3D = StandardMaterial3D.new()
	pad_material.albedo_color = Color(0.1, 1.0, 0.45, 1.0)
	pad_material.emission_enabled = true
	pad_material.emission = Color(0.04, 0.8, 0.22, 1.0)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = pad_mesh
	mesh_instance.material_override = pad_material
	pad.add_child(mesh_instance)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(7.0, 0.4, 2.4)
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	pad.add_child(collision)
	add_child(pad)
