class_name KartInputSource
extends RefCounted


func sample_input_for_tick(tick: int) -> InputCommandFrame:
	push_error("KartInputSource.sample_input_for_tick must be implemented by a subclass.")
	return InputCommandFrame.new(tick)
