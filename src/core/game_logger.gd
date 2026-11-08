class_name GameLogger
extends RefCounted

const CHANNELS: PackedStringArray = ["SIM", "NET", "AI", "TRACK", "UI", "AUDIO", "BACKEND"]
const MAX_LOG_BYTES: int = 1_048_576
const LOG_PATH: String = "user://logs/session.log"

var enabled_channels: Dictionary = {}
var current_tick: int = -1
var _file: FileAccess

func _init() -> void:
	for channel: String in CHANNELS:
		enabled_channels[channel] = true
	_open_log()

func set_channel_enabled(channel: String, enabled: bool) -> void:
	if channel in CHANNELS:
		enabled_channels[channel] = enabled

func log(channel: String, message: String) -> void:
	if not CHANNELS.has(channel) or not bool(enabled_channels.get(channel, false)):
		return
	var timestamp: String = Time.get_datetime_string_from_system(true, true)
	var line: String = "%s [tick=%d] [%s] %s" % [timestamp, current_tick, channel, message]
	print(line)
	if _file != null:
		_file.store_line(line)
		_file.flush()

func close() -> void:
	if _file != null:
		_file.close()
		_file = null

func _open_log() -> void:
	var directory: String = LOG_PATH.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var existing_file: FileAccess = FileAccess.open(LOG_PATH, FileAccess.READ) if FileAccess.file_exists(LOG_PATH) else null
	var log_size: int = existing_file.get_length() if existing_file != null else 0
	if existing_file != null:
		existing_file.close()
	if log_size >= MAX_LOG_BYTES:
		var old_path: String = LOG_PATH + ".1"
		if FileAccess.file_exists(old_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(old_path))
		DirAccess.rename_absolute(ProjectSettings.globalize_path(LOG_PATH), ProjectSettings.globalize_path(old_path))
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE_READ)
	if _file != null:
		_file.seek_end()
