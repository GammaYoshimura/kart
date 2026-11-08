extends "res://tests/test_case.gd"

func test_tick_advance_reset_and_set() -> void:
	var clock: SimulationClock = SimulationClock.new()
	assert_eq(clock.current_tick, 0)
	assert_eq(clock.advance_tick(), 1)
	clock.set_tick(120)
	assert_eq(clock.current_tick, 120)
	clock.reset()
	assert_eq(clock.current_tick, 0)

func test_tick_time_conversion() -> void:
	var clock: SimulationClock = SimulationClock.new()
	assert_eq(clock.ticks_to_ms(60), 1000)
	assert_eq(clock.ticks_to_ms(60, 0.5), 1008)
	assert_eq(clock.ticks_to_ms(-10, 0.0), -167)
