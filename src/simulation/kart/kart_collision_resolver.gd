class_name KartCollisionResolver
extends RefCounted

const DEFAULT_BOOST_RAM_MULTIPLIER: float = 1.4
const DEFAULT_RESTITUTION: float = 0.1


static func resolve_all(states_by_slot: Dictionary, stats_by_slot: Dictionary) -> void:
	var slots: Array[int] = []
	for slot_variant: Variant in states_by_slot:
		var slot: int = int(slot_variant)
		if states_by_slot[slot_variant] is KartSimState and stats_by_slot.has(slot):
			slots.append(slot)
	slots.sort()
	for first_index: int in range(slots.size()):
		for second_index: int in range(first_index + 1, slots.size()):
			var first_slot: int = slots[first_index]
			var second_slot: int = slots[second_index]
			resolve_pair(
				states_by_slot[first_slot] as KartSimState,
				stats_by_slot[first_slot] as KartStatsResource,
				states_by_slot[second_slot] as KartSimState,
				stats_by_slot[second_slot] as KartStatsResource
			)


static func resolve_pair(
	first: KartSimState,
	first_stats: KartStatsResource,
	second: KartSimState,
	second_stats: KartStatsResource
) -> bool:
	var separation: Vector3 = second.position - first.position
	separation.y = 0.0
	var distance: float = separation.length()
	var minimum_distance: float = first_stats.collision_sphere_radius + second_stats.collision_sphere_radius
	if distance >= minimum_distance:
		return false
	var normal: Vector3 = separation / distance if distance > 0.0001 else Vector3.RIGHT
	var inverse_mass_a: float = 1.0 / maxf(first_stats.weight_mass, 0.01)
	var inverse_mass_b: float = 1.0 / maxf(second_stats.weight_mass, 0.01)
	var inverse_mass_sum: float = inverse_mass_a + inverse_mass_b
	var penetration: float = minimum_distance - distance
	first.position -= normal * penetration * inverse_mass_a / inverse_mass_sum
	second.position += normal * penetration * inverse_mass_b / inverse_mass_sum
	var relative_velocity: Vector3 = second.linear_velocity - first.linear_velocity
	relative_velocity.y = 0.0
	var closing_speed: float = relative_velocity.dot(normal)
	if closing_speed < 0.0:
		var ram_multiplier: float = DEFAULT_BOOST_RAM_MULTIPLIER if first.boost_ticks_left > 0 or second.boost_ticks_left > 0 else 1.0
		var impulse_magnitude: float = -(1.0 + DEFAULT_RESTITUTION) * closing_speed / inverse_mass_sum * ram_multiplier
		var impulse: Vector3 = normal * impulse_magnitude
		first.linear_velocity -= impulse * inverse_mass_a
		second.linear_velocity += impulse * inverse_mass_b
	_sync_horizontal_speeds(first)
	_sync_horizontal_speeds(second)
	return true


static func _sync_horizontal_speeds(state: KartSimState) -> void:
	var horizontal_velocity: Vector3 = Vector3(state.linear_velocity.x, 0.0, state.linear_velocity.z)
	state.forward_speed = horizontal_velocity.dot(state.forward_dir)
	state.lateral_speed = horizontal_velocity.dot(state.right_dir)
