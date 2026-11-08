class_name ScriptedInputSource
extends KartInputSource

var frames: Array[InputCommandFrame] = []
var loop_sequence: bool = false
var _next_frame_index: int = 0


func sample_input_for_tick(tick: int) -> InputCommandFrame:
	if frames.is_empty():
		return InputCommandFrame.new(tick)
	if _next_frame_index >= frames.size():
		if not loop_sequence:
			return InputCommandFrame.new(tick)
		_next_frame_index = 0
	var source_frame: InputCommandFrame = frames[_next_frame_index]
	_next_frame_index += 1
	return InputCommandFrame.new(
		tick,
		source_frame.steer_axis,
		source_frame.throttle_axis,
		source_frame.brake_axis,
		source_frame.buttons_bitmask
	)
