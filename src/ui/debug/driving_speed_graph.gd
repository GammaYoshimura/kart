extends Control

var _samples: Array[float] = []


func set_samples(samples: Array[float]) -> void:
	_samples = samples.duplicate()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.06, 0.08, 0.9), true)
	if _samples.size() < 2:
		return
	var maximum_speed: float = maxf(_samples.max(), 1.0)
	var previous_point: Vector2 = _sample_position(0, maximum_speed)
	for sample_index: int in range(1, _samples.size()):
		var current_point: Vector2 = _sample_position(sample_index, maximum_speed)
		draw_line(previous_point, current_point, Color(0.15, 0.92, 1.0), 2.0, true)
		previous_point = current_point


func _sample_position(index: int, maximum_speed: float) -> Vector2:
	var horizontal_fraction: float = float(index) / float(maxi(_samples.size() - 1, 1))
	var vertical_fraction: float = clampf(_samples[index] / maximum_speed, 0.0, 1.0)
	return Vector2(horizontal_fraction * size.x, (1.0 - vertical_fraction) * size.y)
