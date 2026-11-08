extends Node

signal metrics_updated(metrics: Dictionary)

const SAMPLE_INTERVAL_SECONDS: float = 0.5
const METRIC_NAMES: PackedStringArray = [
	"fps", "process_seconds", "physics_seconds", "draw_calls", "primitives", "memory_bytes", "video_memory_bytes"
]

var latest_metrics: Dictionary = {}
var _sample_elapsed: float = 0.0

func _process(delta: float) -> void:
	_sample_elapsed += delta
	if _sample_elapsed < SAMPLE_INTERVAL_SECONDS:
		return
	_sample_elapsed = fmod(_sample_elapsed, SAMPLE_INTERVAL_SECONDS)
	_sample_metrics()

func snapshot() -> Dictionary:
	return latest_metrics.duplicate(true)

func _sample_metrics() -> void:
	latest_metrics = {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_seconds": Performance.get_monitor(Performance.TIME_PROCESS),
		"physics_seconds": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
	}
	metrics_updated.emit(snapshot())
