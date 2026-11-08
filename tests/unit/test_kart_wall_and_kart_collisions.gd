extends "res://tests/test_case.gd"


func test_heavy_and_light_kart_separation_is_mass_weighted_and_planar() -> void:
	var heavy_stats: KartStatsResource = (load("res://resources/karts/stats_heavyweight.tres") as KartStatsResource).duplicate(true)
	var light_stats: KartStatsResource = (load("res://resources/karts/stats_featherweight.tres") as KartStatsResource).duplicate(true)
	var heavy: KartSimState = KartSimState.new()
	var light: KartSimState = KartSimState.new()
	heavy.linear_velocity = Vector3(5.0, 0.0, 0.0)
	light.position = Vector3(1.0, 0.0, 0.0)
	var heavy_start: Vector3 = heavy.position
	var light_start: Vector3 = light.position
	assert_true(KartCollisionResolver.resolve_pair(heavy, heavy_stats, light, light_stats))
	var heavy_shift: float = heavy.position.distance_to(heavy_start)
	var light_shift: float = light.position.distance_to(light_start)
	assert_true(light_shift > heavy_shift, "lighter kart gets more positional separation")
	assert_true(light.linear_velocity.x > heavy.linear_velocity.x, "heavy kart transfers more horizontal momentum")
	assert_almost_eq(heavy.linear_velocity.y, 0.0)
	assert_almost_eq(light.linear_velocity.y, 0.0)
	assert_true(heavy.position.distance_to(light.position) >= heavy_stats.collision_sphere_radius + light_stats.collision_sphere_radius)

