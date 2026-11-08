class_name SimulationClock
extends RefCounted

const TICK_RATE: int = 60
const FIXED_DELTA: float = 1.0 / float(TICK_RATE)

var current_tick: int = 0

func advance_tick() -> int:
	current_tick += 1
	return current_tick

func reset() -> void:
	current_tick = 0

func set_tick(t: int) -> void:
	current_tick = maxi(t, 0)

func ticks_to_ms(tick: int, sub_tick_fraction: float = 0.0) -> int:
	return roundi((float(tick) + clampf(sub_tick_fraction, 0.0, 1.0)) * 1000.0 / float(TICK_RATE))
