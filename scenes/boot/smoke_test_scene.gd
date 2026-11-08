extends Node3D

@onready var _model: Node3D = $RotatingModel
@onready var _info: Label = $CanvasLayer/Info

var _refresh_elapsed: float = 0.0

func _process(delta: float) -> void:
	_model.rotate_y(delta * 0.7)
	_refresh_elapsed += delta
	if _refresh_elapsed >= 0.1:
		_refresh_elapsed = 0.0
		_update_readout()

func _update_readout() -> void:
	var active_inputs: PackedStringArray = PackedStringArray()
	for action: String in ["accelerate", "brake_reverse", "steer_left", "steer_right", "drift_hop", "use_item"]:
		if Input.is_action_pressed(action):
			active_inputs.append(action)
	var input_text: String = ", ".join(active_inputs) if not active_inputs.is_empty() else "ninguno"
	_info.text = "SMOKE TEST\nFPS: %d\nInput detectado: %s\nPulsa F5 para el overlay de rendimiento." % [Engine.get_frames_per_second(), input_text]

func _on_run_tests_pressed() -> void:
	var output: Array = []
	var arguments: PackedStringArray = PackedStringArray([
		"--headless",
		"--path",
		ProjectSettings.globalize_path("res://"),
		"--script",
		"res://tests/test_runner.gd",
	])
	var exit_code: int = OS.execute(OS.get_executable_path(), arguments, output, true)
	_info.text += "\nTests internos: %s (código %d)" % ["PASS" if exit_code == 0 else "FAIL", exit_code]
	if not output.is_empty():
		_info.text += "\n" + "\n".join(PackedStringArray(output))
