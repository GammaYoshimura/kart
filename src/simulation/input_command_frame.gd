class_name InputCommandFrame
extends SerializableState

const BIT_DRIFT_HOP: int = 1 << 0
const BIT_USE_ITEM: int = 1 << 1
const BIT_LOOK_BACK: int = 1 << 2
const BIT_AIM_BACKWARD: int = 1 << 3
const BIT_RESPAWN_REQUEST: int = 1 << 4

var tick: int = 0
var steer_axis: int = 0
var throttle_axis: int = 0
var brake_axis: int = 0
var buttons_bitmask: int = 0

func _init(p_tick: int = 0, p_steer: int = 0, p_throttle: int = 0, p_brake: int = 0, p_buttons: int = 0) -> void:
	tick = p_tick
	steer_axis = clampi(p_steer, -1000, 1000)
	throttle_axis = clampi(p_throttle, 0, 1000)
	brake_axis = clampi(p_brake, 0, 1000)
	buttons_bitmask = p_buttons & 0xffff

func get_steer_float() -> float:
	return float(steer_axis) / 1000.0

func get_throttle_float() -> float:
	return float(throttle_axis) / 1000.0

func get_brake_float() -> float:
	return float(brake_axis) / 1000.0

func is_button_pressed(bit: int) -> bool:
	return (buttons_bitmask & bit) != 0

func set_button(bit: int, pressed: bool) -> void:
	if pressed:
		buttons_bitmask = (buttons_bitmask | bit) & 0xffff
	else:
		buttons_bitmask = buttons_bitmask & ~bit

func write_to_buffer(buf: StreamPeerBuffer) -> void:
	buf.big_endian = false
	buf.put_u32(tick & 0xffffffff)
	buf.put_16(steer_axis)
	# The 10-byte wire frame stores throttle and brake as two 8-bit normalized axes.
	var throttle_byte: int = roundi(float(throttle_axis) * 255.0 / 1000.0)
	var brake_byte: int = roundi(float(brake_axis) * 255.0 / 1000.0)
	buf.put_u16((throttle_byte & 0xff) | ((brake_byte & 0xff) << 8))
	buf.put_u16(buttons_bitmask)

func read_from_buffer(buf: StreamPeerBuffer) -> void:
	buf.big_endian = false
	tick = buf.get_u32()
	steer_axis = clampi(buf.get_16(), -1000, 1000)
	var packed_axes: int = buf.get_u16()
	throttle_axis = roundi(float(packed_axes & 0xff) * 1000.0 / 255.0)
	brake_axis = roundi(float((packed_axes >> 8) & 0xff) * 1000.0 / 255.0)
	buttons_bitmask = buf.get_u16()
