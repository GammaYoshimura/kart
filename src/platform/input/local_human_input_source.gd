class_name LocalHumanInputSource
extends KartInputSource

const DEFAULT_DEADZONE_INNER: float = 0.12
const DEFAULT_DEADZONE_OUTER: float = 0.95
const DEFAULT_STEERING_CURVE_EXPONENT: float = 1.35
const DIGITAL_STEER_TICKS_TO_FULL: float = 3.0
const JOY_TRIGGER_REST_VALUE: float = -1.0

var deadzone_inner: float = DEFAULT_DEADZONE_INNER
var deadzone_outer: float = DEFAULT_DEADZONE_OUTER
var steering_curve_exponent: float = DEFAULT_STEERING_CURVE_EXPONENT
var _filtered_digital_steer: float = 0.0


func sample_input_for_tick(tick: int) -> InputCommandFrame:
	var joypads: Array[int] = Input.get_connected_joypads()
	var steer_value: float = _sample_steering(joypads)
	var throttle_value: float = _sample_throttle(joypads)
	var brake_value: float = _sample_brake(joypads)
	var buttons: int = 0
	if Input.is_action_pressed("drift_hop"):
		buttons |= InputCommandFrame.BIT_DRIFT_HOP
	if Input.is_action_pressed("use_item"):
		buttons |= InputCommandFrame.BIT_USE_ITEM
	if Input.is_action_pressed("look_back"):
		buttons |= InputCommandFrame.BIT_LOOK_BACK
	if Input.is_action_pressed("aim_backward"):
		buttons |= InputCommandFrame.BIT_AIM_BACKWARD
	if Input.is_action_just_pressed("respawn_request"):
		buttons |= InputCommandFrame.BIT_RESPAWN_REQUEST
	return InputCommandFrame.new(
		tick,
		roundi(steer_value * 1000.0),
		roundi(throttle_value * 1000.0),
		roundi(brake_value * 1000.0),
		buttons
	)


func _sample_steering(joypads: Array[int]) -> float:
	var digital_direction: int = int(Input.is_action_pressed("steer_right")) - int(Input.is_action_pressed("steer_left"))
	if not joypads.is_empty():
		var analog_value: float = Input.get_joy_axis(joypads[0], JOY_AXIS_LEFT_X)
		if absf(analog_value) > deadzone_inner:
			_filtered_digital_steer = 0.0
			return _filter_analog_steer(analog_value)
	return _filter_digital_steer(digital_direction)


func _filter_analog_steer(value: float) -> float:
	var magnitude: float = absf(value)
	var safe_outer: float = maxf(deadzone_outer, deadzone_inner + 0.001)
	var normalized: float = clampf((magnitude - deadzone_inner) / (safe_outer - deadzone_inner), 0.0, 1.0)
	var curved: float = pow(normalized, maxf(steering_curve_exponent, 0.01))
	return signf(value) * curved


func _filter_digital_steer(direction: int) -> float:
	var target: float = float(clampi(direction, -1, 1))
	if target != 0.0 and signf(_filtered_digital_steer) == -target:
		_filtered_digital_steer = 0.0
	_filtered_digital_steer = move_toward(
		_filtered_digital_steer,
		target,
		1000.0 / DIGITAL_STEER_TICKS_TO_FULL / 1000.0
	)
	return _filtered_digital_steer


func _sample_throttle(joypads: Array[int]) -> float:
	var value: float = Input.get_action_strength("accelerate")
	if not joypads.is_empty():
		var trigger: float = Input.get_joy_axis(joypads[0], JOY_AXIS_TRIGGER_RIGHT)
		value = maxf(value, (trigger - JOY_TRIGGER_REST_VALUE) * 0.5)
		if Input.is_joy_button_pressed(joypads[0], JOY_BUTTON_A):
			value = 1.0
	return clampf(value, 0.0, 1.0)


func _sample_brake(joypads: Array[int]) -> float:
	var value: float = Input.get_action_strength("brake_reverse")
	if not joypads.is_empty():
		var trigger: float = Input.get_joy_axis(joypads[0], JOY_AXIS_TRIGGER_LEFT)
		value = maxf(value, (trigger - JOY_TRIGGER_REST_VALUE) * 0.5)
		if Input.is_joy_button_pressed(joypads[0], JOY_BUTTON_B):
			value = 1.0
	return clampf(value, 0.0, 1.0)
