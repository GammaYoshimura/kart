extends "res://tests/test_case.gd"

const TICK_COUNT: int = 1000
const TICK_DELTA: float = 1.0 / 60.0


func test_identical_commands_produce_identical_1000_tick_trajectory() -> void:
	var first: KartSimBody = _make_body()
	var second: KartSimBody = _make_body()
	for tick: int in range(TICK_COUNT):
		var steer: int = 450 if tick % 180 < 90 else -450
		var throttle: int = 1000 if tick % 300 < 230 else 0
		var brake: int = 1000 if tick % 300 >= 230 else 0
		var command: InputCommandFrame = InputCommandFrame.new(tick, steer, throttle, brake, 0)
		_simulate_drive_tick(first, command)
		_simulate_drive_tick(second, command)
	assert_vec3_approx(first.state.position, second.state.position, 0.0, "1000 tick position")
	assert_almost_eq(first.state.heading_yaw, second.state.heading_yaw, 0.0, "1000 tick heading")
	assert_almost_eq(first.state.forward_speed, second.state.forward_speed, 0.0, "1000 tick speed")
	first.free()
	second.free()


func _simulate_drive_tick(body: KartSimBody, command: InputCommandFrame) -> void:
	body._update_steering_and_heading(command, TICK_DELTA)
	body._update_longitudinal_velocity(command, TICK_DELTA)
	body._update_lateral_velocity(TICK_DELTA)
	body._apply_gravity_and_slopes(TICK_DELTA)
	var velocity: Vector3 = body.state.forward_dir * body.state.forward_speed + body.state.right_dir * body.state.lateral_speed
	body.state.linear_velocity = velocity
	body.state.position += velocity * TICK_DELTA


func _make_body() -> KartSimBody:
	var body: KartSimBody = KartSimBody.new()
	body.stats = load("res://resources/karts/stats_balanced.tres") as KartStatsResource
	body.state.is_grounded = true
	return body
