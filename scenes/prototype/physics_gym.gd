extends Node3D

const GATE_SPACING_METERS: int = 50
const STRAIGHT_LENGTH_METERS: int = 300
const TRACK_HALF_WIDTH: float = 9.0

@onready var _kart: KartSimBody = $Kart
@onready var _readout: Label = $HUD/Readout
@onready var _replay_button: Button = $HUD/ReplayButton
var _gate_material: StandardMaterial3D
var _drift_road_material: StandardMaterial3D
var _recorded_commands: Array[InputCommandFrame] = []
var _scripted_source: ScriptedInputSource
var _replay_mode: int = 0


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
	_build_collision_sector()
	var replay_connection_error: int = _replay_button.pressed.connect(_on_replay_button_pressed)
	if replay_connection_error != OK:
		push_error("PhysicsGym could not connect its replay button.")


func _physics_process(_delta: float) -> void:
	if _replay_mode == 1:
		var command: InputCommandFrame = _kart.last_command_frame
		_recorded_commands.append(InputCommandFrame.new(
			command.tick, command.steer_axis, command.throttle_axis, command.brake_axis, command.buttons_bitmask
		))
	elif _replay_mode == 2 and _scripted_source != null and _scripted_source._next_frame_index >= _scripted_source.frames.size():
		_replay_mode = 0
		_kart.input_source = LocalHumanInputSource.new()
		_replay_button.text = "Grabar / reproducir inputs"
		_readout.text += "   REPLAY COMPLETE"


func _process(_delta: float) -> void:
	var distance_m: int = roundi(145.0 - _kart.global_position.z)
	var speed_kmh: int = roundi(absf(_kart.state.forward_speed) * 3.6)
	_readout.text = "RECTA 300 m   %03d / 300 m     %03d km/h" % [clampi(distance_m, 0, STRAIGHT_LENGTH_METERS), speed_kmh]
	if _replay_mode == 1:
		_readout.text += "   REC %d ticks" % _recorded_commands.size()
	elif _replay_mode == 2:
		_readout.text += "   REPLAY"


func _on_replay_button_pressed() -> void:
	if _replay_mode == 0:
		_recorded_commands.clear()
		_replay_mode = 1
		_kart.input_source = LocalHumanInputSource.new()
		_replay_button.text = "Detener y reproducir"
	elif _replay_mode == 1:
		if _recorded_commands.is_empty():
			return
		_scripted_source = ScriptedInputSource.new()
		_scripted_source.frames = _recorded_commands.duplicate(true)
		_replay_mode = 2
		_kart.global_position = Vector3(0.0, 0.72, 145.0)
		_kart.velocity = Vector3.ZERO
		_kart.state = KartSimState.new()
		_kart.state.position = _kart.global_position
		_kart.state.heading_yaw = 0.0
		_kart.simulation_tick = 0
		_kart.input_source = _scripted_source
		_replay_button.text = "Parar replay"
	else:
		_replay_mode = 0
		_kart.input_source = LocalHumanInputSource.new()
		_replay_button.text = "Grabar / reproducir inputs"


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


func _build_collision_sector() -> void:
	_add_static_test_box("CollisionArenaFloor", Vector3(-155.0, -0.15, 0.0), Vector3(90.0, 0.3, 70.0), 0.0, _drift_road_material, 1)
	_add_static_test_box("ImpactWall_15", Vector3(-178.0, 0.65, -10.0), Vector3(18.0, 1.3, 0.8), 15.0, _gate_material, 2)
	_add_static_test_box("ImpactWall_45", Vector3(-155.0, 0.65, -10.0), Vector3(18.0, 1.3, 0.8), 45.0, _gate_material, 2)
	_add_static_test_box("ImpactWall_90", Vector3(-132.0, 0.65, -10.0), Vector3(18.0, 1.3, 0.8), 90.0, _gate_material, 2)
	_add_cylinder_pillar(Vector3(-178.0, 1.0, 12.0), 1.1)
	_add_cylinder_pillar(Vector3(-155.0, 1.0, 12.0), 1.6)
	_add_cylinder_pillar(Vector3(-132.0, 1.0, 12.0), 2.1)
	_add_kart_dummy("Dummy_Light_75kg", Vector3(-174.0, 0.72, 25.0), Color(0.25, 0.85, 1.0), 75.0)
	_add_kart_dummy("Dummy_Balanced_100kg", Vector3(-155.0, 0.72, 25.0), Color(0.35, 1.0, 0.4), 100.0)
	_add_kart_dummy("Dummy_Heavy_130kg", Vector3(-136.0, 0.72, 25.0), Color(1.0, 0.42, 0.12), 130.0)
	_add_sector_label("COLLISION ARENA  /  MUROS 15° · 45° · 90°  /  MASAS 75 · 100 · 130 kg", Vector3(-155.0, 7.0, -32.0))


func _add_static_test_box(node_name: String, body_position: Vector3, box_size: Vector3, yaw_degrees: float, material: StandardMaterial3D, layer: int) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = body_position
	body.rotation.y = deg_to_rad(yaw_degrees)
	body.collision_layer = layer
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = box_size
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = box_size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _add_cylinder_pillar(pillar_position: Vector3, radius: float) -> void:
	var pillar: StaticBody3D = StaticBody3D.new()
	pillar.name = "CollisionPillar_%.1f" % radius
	pillar.position = pillar_position
	pillar.collision_layer = 2
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 2.0
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _gate_material
	pillar.add_child(mesh_instance)
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = 2.0
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	pillar.add_child(collision)
	add_child(pillar)


func _add_kart_dummy(dummy_name: String, dummy_position: Vector3, kart_color: Color, weight_mass: float) -> void:
	var dummy: StaticBody3D = StaticBody3D.new()
	dummy.name = dummy_name
	dummy.position = dummy_position
	dummy.collision_layer = 1 << 2
	dummy.set_meta("weight_mass", weight_mass)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = kart_color
	var chassis: BoxMesh = BoxMesh.new()
	chassis.size = Vector3(1.45, 0.48, 2.1)
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = chassis
	mesh_instance.material_override = material
	dummy.add_child(mesh_instance)
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 0.65
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = shape
	dummy.add_child(collision)
	var label: Label3D = Label3D.new()
	label.position = Vector3(0.0, 1.0, 0.0)
	label.text = "%s kg" % roundi(weight_mass)
	label.font_size = 48
	dummy.add_child(label)
	add_child(dummy)
