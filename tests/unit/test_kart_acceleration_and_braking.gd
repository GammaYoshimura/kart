extends "res://tests/test_case.gd"


func test_forward_speed_braking_and_reverse_limits() -> void:
	var body: KartSimBody = _make_body()
	var throttle: InputCommandFrame = InputCommandFrame.new(0, 0, 1000, 0, 0)
	for tick: int in range(600):
		body._update_longitudinal_velocity(throttle, 1.0 / 60.0)
	assert_almost_eq(body.state.forward_speed, body.stats.max_speed_forward, 0.001, "reaches top speed")
	var brake: InputCommandFrame = InputCommandFrame.new(0, 0, 0, 1000, 0)
	for tick: int in range(150):
		body._update_longitudinal_velocity(brake, 1.0 / 60.0)
	assert_true(body.state.forward_speed <= 0.0, "brakes through zero and enters reverse")
	assert_almost_eq(body.state.forward_speed, -body.stats.max_speed_reverse, 0.001, "reverse speed cap")
	body.free()


func _make_body() -> KartSimBody:
	var body: KartSimBody = KartSimBody.new()
	body.stats = load("res://resources/karts/stats_balanced.tres") as KartStatsResource
	return body
