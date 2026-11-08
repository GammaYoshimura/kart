class_name SeededRNG
extends RefCounted

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value

func next_int() -> int:
	return _rng.randi()

func next_range_int(min_v: int, max_v: int) -> int:
	assert(min_v <= max_v, "min_v must be <= max_v")
	return _rng.randi_range(min_v, max_v)

func next_float() -> float:
	return _rng.randf()

func next_range_float(min_v: float, max_v: float) -> float:
	assert(min_v <= max_v, "min_v must be <= max_v")
	return _rng.randf_range(min_v, max_v)

func pick_weighted(weights: PackedFloat32Array) -> int:
	var total_weight: float = 0.0
	for weight: float in weights:
		total_weight += maxf(weight, 0.0)
	if total_weight <= 0.0:
		return -1
	var target: float = _rng.randf() * total_weight
	for index: int in range(weights.size()):
		target -= maxf(weights[index], 0.0)
		if target < 0.0:
			return index
	return weights.size() - 1

func get_state() -> Dictionary:
	return {"seed": _rng.seed, "state": _rng.state}

func set_state(state: Dictionary) -> void:
	assert(state.has("seed") and state.has("state"), "RNG state requires seed and state")
	_rng.seed = int(state["seed"])
	_rng.state = int(state["state"])
