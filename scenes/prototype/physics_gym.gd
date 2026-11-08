extends Node3D

const GATE_SPACING_METERS: int = 50
const STRAIGHT_LENGTH_METERS: int = 300
const TRACK_HALF_WIDTH: float = 9.0

@onready var _kart: KartSimBody = $Kart
@onready var _readout: Label = $HUD/Readout
var _gate_material: StandardMaterial3D


func _ready() -> void:
	_gate_material = StandardMaterial3D.new()
	_gate_material.albedo_color = Color(0.12, 0.84, 1.0, 1.0)
	_gate_material.emission_enabled = true
	_gate_material.emission = Color(0.04, 0.3, 0.55, 1.0)
	_gate_material.emission_energy_multiplier = 1.4
	_build_distance_gates()


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
