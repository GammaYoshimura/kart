extends Control

const WINDOWS_DRAW_CALL_BUDGET: int = 1000
const ANDROID_DRAW_CALL_BUDGET: int = 250

@onready var _label: Label = $Label

func _ready() -> void:
	visible = false
	var connection_error: int = PerfMonitor.metrics_updated.connect(_on_metrics_updated)
	if connection_error != OK:
		push_error("Failed to connect the performance overlay to PerfMonitor.")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_perf_overlay"):
		visible = not visible

func _on_metrics_updated(metrics: Dictionary) -> void:
	var draw_budget: int = ANDROID_DRAW_CALL_BUDGET if OS.has_feature("android") else WINDOWS_DRAW_CALL_BUDGET
	var fps: float = float(metrics.get("fps", 0.0))
	var draw_calls: int = int(metrics.get("draw_calls", 0))
	var frame_ms: float = float(metrics.get("process_seconds", 0.0)) * 1000.0
	_label.text = "FPS: %.0f\nFrame: %.2f ms\nDraw calls: %d / %d\nPrimitives: %d\nRAM: %s\nVRAM: %s" % [
		fps, frame_ms, draw_calls, draw_budget,
		int(metrics.get("primitives", 0)),
		String.humanize_size(int(metrics.get("memory_bytes", 0))),
		String.humanize_size(int(metrics.get("video_memory_bytes", 0)))
	]
	if fps < 30.0 or draw_calls > draw_budget:
		_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.25))
	elif fps < 58.0 or draw_calls > int(float(draw_budget) * 0.8):
		_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))
	else:
		_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.48))

