extends CanvasLayer

@export var target_path: NodePath = NodePath("../Kart")

@onready var _panel: Control = $Panel
@onready var _speed_label: Label = $Panel/Margin/VBox/Speed
@onready var _drift_label: Label = $Panel/Margin/VBox/Drift
@onready var _input_label: Label = $Panel/Margin/VBox/Input
@onready var _buttons_label: Label = $Panel/Margin/VBox/Buttons
@onready var _graph: Control = $Panel/Margin/VBox/SpeedGraph

var _target: KartSimBody
var _speed_history: Array[float] = []
var _sample_accumulator: float = 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path) as KartSimBody
	_panel.visible = false
	if _target == null:
		push_error("DrivingDebugOverlay requires a KartSimBody target.")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_driving_debug"):
		_panel.visible = not _panel.visible
	if _target == null:
		return
	var state: KartSimState = _target.state
	var speed_ms: float = absf(state.forward_speed)
	_speed_label.text = "SPEED  %.2f m/s   %.0f km/h" % [speed_ms, speed_ms * 3.6]
	var drift_names: Array[String] = ["NONE", "HOPPING", "DRIFTING"]
	var drift_name: String = drift_names[clampi(state.drift_state, 0, drift_names.size() - 1)]
	var slip_angle_deg: float = rad_to_deg(atan2(state.lateral_speed, maxf(absf(state.forward_speed), 0.01)))
	_drift_label.text = "SLIP  %.1f°   %s   MT %d (%.0f)   BOOST %d ticks" % [
		slip_angle_deg, drift_name, state.mt_level, state.mt_charge, state.boost_ticks_left
	]
	var command: InputCommandFrame = _target.last_command_frame
	_input_label.text = "STEER %+0.2f   THROTTLE %.2f   BRAKE %.2f" % [
		command.get_steer_float(), command.get_throttle_float(), command.get_brake_float()
	]
	_buttons_label.text = "HOP %s  ITEM %s  LOOK %s  RESPAWN %s" % [
		_on_off(command.is_button_pressed(InputCommandFrame.BIT_DRIFT_HOP)),
		_on_off(command.is_button_pressed(InputCommandFrame.BIT_USE_ITEM)),
		_on_off(command.is_button_pressed(InputCommandFrame.BIT_LOOK_BACK)),
		_on_off(command.is_button_pressed(InputCommandFrame.BIT_RESPAWN_REQUEST))
	]
	_sample_accumulator += delta
	if _sample_accumulator >= 1.0 / 60.0:
		_sample_accumulator = fposmod(_sample_accumulator, 1.0 / 60.0)
		_speed_history.append(speed_ms)
		if _speed_history.size() > 300:
			_speed_history.remove_at(0)
		_graph.call("set_samples", _speed_history)


func _on_off(value: bool) -> String:
	return "ON" if value else "--"
