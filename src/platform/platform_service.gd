class_name PlatformService
extends RefCounted

func platform_id() -> StringName:
	return &"base"

func sample_action(_action: StringName) -> float:
	return 0.0

func set_fullscreen(_enabled: bool) -> void:
	pass

func vibrate(_duration_ms: int, _amplitude: float = 1.0) -> void:
	pass

func is_application_active() -> bool:
	return true

func save_profile(_profile_id: String, _data: PackedByteArray) -> bool:
	return false

func load_profile(_profile_id: String) -> PackedByteArray:
	return PackedByteArray()

func connect_to_server(_address: String, _port: int) -> Error:
	return ERR_UNAVAILABLE
