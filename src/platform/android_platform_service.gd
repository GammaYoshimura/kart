class_name AndroidPlatformService
extends PlatformService

func platform_id() -> StringName:
	return &"android"

func sample_action(action: StringName) -> float:
	return Input.get_action_strength(action)

func vibrate(duration_ms: int, amplitude: float = 1.0) -> void:
	if ClassDB.class_exists("Vibrator"):
		var vibrator: Object = ClassDB.instantiate("Vibrator")
		if vibrator != null and vibrator.has_method("vibrate"):
			vibrator.call("vibrate", duration_ms, clampf(amplitude, 0.0, 1.0))
