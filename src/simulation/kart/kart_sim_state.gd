class_name KartSimState
extends SerializableState

const DRIFT_HOP_BUFFER_TICKS: int = 6

var position: Vector3 = Vector3.ZERO
var linear_velocity: Vector3 = Vector3.ZERO
var heading_yaw: float = 0.0
var forward_dir: Vector3 = Vector3.FORWARD
var right_dir: Vector3 = Vector3.RIGHT
var up_normal: Vector3 = Vector3.UP
var forward_speed: float = 0.0
var lateral_speed: float = 0.0
var vertical_speed: float = 0.0
var smoothed_steer_input: float = 0.0
var is_grounded: bool = false
var airborne_ticks: int = 0
var just_landed_this_tick: bool = false
var landing_impact_speed: float = 0.0
var current_surface_id: int = 0
var ground_normal: Vector3 = Vector3.UP
var drift_state: int = 0
var drift_dir: int = 0
var hop_ticks_left: int = 0
var mt_charge: float = 0.0
var mt_level: int = 0
var boost_ticks_left: int = 0
var boost_speed_bonus: float = 0.0
var trick_boost_armed: bool = false
var wall_contact_cooldown: int = 0
var kart_bump_cooldown: int = 0
var last_wall_normal: Vector3 = Vector3.ZERO
var drift_hop_buffer_tick: int = -1
var last_drift_hop_pressed: bool = false


func update_drift_hop_buffer(command: InputCommandFrame) -> void:
	var pressed: bool = command.is_button_pressed(InputCommandFrame.BIT_DRIFT_HOP)
	if pressed and not last_drift_hop_pressed:
		drift_hop_buffer_tick = command.tick
	last_drift_hop_pressed = pressed
	if drift_hop_buffer_tick >= 0 and command.tick - drift_hop_buffer_tick > DRIFT_HOP_BUFFER_TICKS:
		drift_hop_buffer_tick = -1


func consume_drift_hop_buffer(current_tick: int, grounded: bool) -> bool:
	if not grounded or drift_hop_buffer_tick < 0:
		return false
	var age: int = current_tick - drift_hop_buffer_tick
	if age < 0 or age > DRIFT_HOP_BUFFER_TICKS:
		drift_hop_buffer_tick = -1
		return false
	drift_hop_buffer_tick = -1
	return true


func write_to_buffer(buf: StreamPeerBuffer) -> void:
	buf.big_endian = false
	buf.put_vector3(position)
	buf.put_vector3(linear_velocity)
	buf.put_float(heading_yaw)
	buf.put_vector3(forward_dir)
	buf.put_vector3(right_dir)
	buf.put_vector3(up_normal)
	buf.put_float(forward_speed)
	buf.put_float(lateral_speed)
	buf.put_float(vertical_speed)
	buf.put_float(smoothed_steer_input)
	buf.put_u8(1 if is_grounded else 0)
	buf.put_32(airborne_ticks)
	buf.put_u8(1 if just_landed_this_tick else 0)
	buf.put_float(landing_impact_speed)
	buf.put_32(current_surface_id)
	buf.put_vector3(ground_normal)
	buf.put_8(drift_state)
	buf.put_8(drift_dir)
	buf.put_32(hop_ticks_left)
	buf.put_float(mt_charge)
	buf.put_8(mt_level)
	buf.put_32(boost_ticks_left)
	buf.put_float(boost_speed_bonus)
	buf.put_u8(1 if trick_boost_armed else 0)
	buf.put_32(wall_contact_cooldown)
	buf.put_32(kart_bump_cooldown)
	buf.put_vector3(last_wall_normal)
	buf.put_32(drift_hop_buffer_tick)
	buf.put_u8(1 if last_drift_hop_pressed else 0)


func read_from_buffer(buf: StreamPeerBuffer) -> void:
	buf.big_endian = false
	position = buf.get_vector3()
	linear_velocity = buf.get_vector3()
	heading_yaw = buf.get_float()
	forward_dir = buf.get_vector3()
	right_dir = buf.get_vector3()
	up_normal = buf.get_vector3()
	forward_speed = buf.get_float()
	lateral_speed = buf.get_float()
	vertical_speed = buf.get_float()
	smoothed_steer_input = buf.get_float()
	is_grounded = buf.get_u8() != 0
	airborne_ticks = buf.get_32()
	just_landed_this_tick = buf.get_u8() != 0
	landing_impact_speed = buf.get_float()
	current_surface_id = buf.get_32()
	ground_normal = buf.get_vector3()
	drift_state = buf.get_8()
	drift_dir = buf.get_8()
	hop_ticks_left = buf.get_32()
	mt_charge = buf.get_float()
	mt_level = buf.get_8()
	boost_ticks_left = buf.get_32()
	boost_speed_bonus = buf.get_float()
	trick_boost_armed = buf.get_u8() != 0
	wall_contact_cooldown = buf.get_32()
	kart_bump_cooldown = buf.get_32()
	last_wall_normal = buf.get_vector3()
	drift_hop_buffer_tick = buf.get_32()
	last_drift_hop_pressed = buf.get_u8() != 0


func copy_from(other: KartSimState) -> void:
	position = other.position
	linear_velocity = other.linear_velocity
	heading_yaw = other.heading_yaw
	forward_dir = other.forward_dir
	right_dir = other.right_dir
	up_normal = other.up_normal
	forward_speed = other.forward_speed
	lateral_speed = other.lateral_speed
	vertical_speed = other.vertical_speed
	smoothed_steer_input = other.smoothed_steer_input
	is_grounded = other.is_grounded
	airborne_ticks = other.airborne_ticks
	just_landed_this_tick = other.just_landed_this_tick
	landing_impact_speed = other.landing_impact_speed
	current_surface_id = other.current_surface_id
	ground_normal = other.ground_normal
	drift_state = other.drift_state
	drift_dir = other.drift_dir
	hop_ticks_left = other.hop_ticks_left
	mt_charge = other.mt_charge
	mt_level = other.mt_level
	boost_ticks_left = other.boost_ticks_left
	boost_speed_bonus = other.boost_speed_bonus
	trick_boost_armed = other.trick_boost_armed
	wall_contact_cooldown = other.wall_contact_cooldown
	kart_bump_cooldown = other.kart_bump_cooldown
	last_wall_normal = other.last_wall_normal
	drift_hop_buffer_tick = other.drift_hop_buffer_tick
	last_drift_hop_pressed = other.last_drift_hop_pressed
