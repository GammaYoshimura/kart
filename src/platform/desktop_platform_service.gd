class_name DesktopPlatformService
extends PlatformService

func platform_id() -> StringName:
	return &"windows_desktop" if OS.get_name() == "Windows" else &"desktop"

func sample_action(action: StringName) -> float:
	return Input.get_action_strength(action)

func set_fullscreen(enabled: bool) -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func save_profile(profile_id: String, data: PackedByteArray) -> bool:
	var file: FileAccess = FileAccess.open("user://profiles/%s.dat" % profile_id.validate_filename(), FileAccess.WRITE)
	if file == null:
		var directory_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://profiles"))
		if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
			return false
		file = FileAccess.open("user://profiles/%s.dat" % profile_id.validate_filename(), FileAccess.WRITE)
	if file == null:
		return false
	var write_succeeded: bool = file.store_buffer(data)
	file.close()
	return write_succeeded

func load_profile(profile_id: String) -> PackedByteArray:
	var path: String = "user://profiles/%s.dat" % profile_id.validate_filename()
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	return file.get_buffer(file.get_length()) if file != null else PackedByteArray()
