extends "res://tests/test_case.gd"

func test_seed_and_restored_state_are_deterministic() -> void:
	var first: SeededRNG = SeededRNG.new(91234)
	var second: SeededRNG = SeededRNG.new(91234)
	for index: int in range(12):
		assert_eq(first.next_int(), second.next_int(), "matching seeds at draw %d" % index)
	var saved_state: Dictionary = first.get_state()
	var expected_next: int = first.next_int()
	first.set_state(saved_state)
	assert_eq(first.next_int(), expected_next)

func test_pick_weighted_ignores_nonpositive_weights() -> void:
	var rng: SeededRNG = SeededRNG.new(7)
	for index: int in range(100):
		var choice: int = rng.pick_weighted(PackedFloat32Array([-1.0, 0.0, 2.0]))
		assert_eq(choice, 2)
	assert_eq(rng.pick_weighted(PackedFloat32Array([0.0, -4.0])), -1)
