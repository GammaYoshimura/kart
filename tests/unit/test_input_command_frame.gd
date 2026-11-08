extends "res://tests/test_case.gd"

func test_wire_frame_is_ten_bytes_and_round_trips_limits() -> void:
	var frame: InputCommandFrame = InputCommandFrame.new(0xffffffff, -1000, 1000, 0)
	frame.set_button(InputCommandFrame.BIT_DRIFT_HOP, true)
	frame.set_button(InputCommandFrame.BIT_RESPAWN_REQUEST, true)
	var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	frame.write_to_buffer(buffer)
	assert_eq(buffer.data_array.size(), 10)
	buffer.seek(0)
	var decoded: InputCommandFrame = InputCommandFrame.new()
	decoded.read_from_buffer(buffer)
	assert_eq(decoded.tick, 0xffffffff)
	assert_eq(decoded.steer_axis, -1000)
	assert_eq(decoded.throttle_axis, 1000)
	assert_eq(decoded.brake_axis, 0)
	assert_true(decoded.is_button_pressed(InputCommandFrame.BIT_DRIFT_HOP))
	assert_true(decoded.is_button_pressed(InputCommandFrame.BIT_RESPAWN_REQUEST))
	assert_false(decoded.is_button_pressed(InputCommandFrame.BIT_USE_ITEM))

func test_axis_values_are_clamped_and_normalized() -> void:
	var frame: InputCommandFrame = InputCommandFrame.new(1, 1200, -4, 1400)
	assert_eq(frame.steer_axis, 1000)
	assert_eq(frame.throttle_axis, 0)
	assert_eq(frame.brake_axis, 1000)
	assert_almost_eq(frame.get_steer_float(), 1.0)
	assert_almost_eq(frame.get_brake_float(), 1.0)
