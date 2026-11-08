extends "res://tests/test_case.gd"


func test_hop_drift_charge_levels_and_release_boost() -> void:
	var body: KartSimBody = KartSimBody.new()
	body.stats = load("res://resources/karts/stats_balanced.tres") as KartStatsResource
	body.state.is_grounded = true
	body.state.forward_speed = body.stats.max_speed_forward * 0.8
	var held_command: InputCommandFrame = InputCommandFrame.new(1, 500, 0, 0, InputCommandFrame.BIT_DRIFT_HOP)
	body.state.update_drift_hop_buffer(held_command)
	body._update_hop_and_drift_state(held_command)
	assert_eq(body.state.drift_state, 1, "hop starts from the buffered command")
	body.state.hop_ticks_left = 1
	body._update_hop_and_drift_state(InputCommandFrame.new(2, 500, 0, 0, InputCommandFrame.BIT_DRIFT_HOP))
	assert_eq(body.state.drift_state, 2, "hop enters drift at sufficient speed")
	body.state.mt_charge = body.stats.mt_level_1_threshold
	body._update_mini_turbo_level()
	assert_eq(body.state.mt_level, 1)
	body.state.mt_charge = body.stats.mt_level_2_threshold
	body._update_mini_turbo_level()
	assert_eq(body.state.mt_level, 2)
	body.state.mt_charge = body.stats.mt_level_3_threshold
	body._update_mini_turbo_level()
	assert_eq(body.state.mt_level, 3)
	body._release_drift()
	assert_eq(body.state.boost_ticks_left, body.stats.mt_3_duration_ticks)
	assert_almost_eq(body.state.forward_speed, body.stats.max_speed_forward + body.stats.mt_3_speed_bonus * 0.8)
	assert_eq(body.state.drift_state, 0)
	body.free()

