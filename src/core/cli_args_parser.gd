class_name CliArgsParser
extends RefCounted

static func parse(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {
		"server": false,
		"port": 7777,
		"max_players": 12,
		"track": "",
		"bot_count": 0,
		"run_tests": false,
	}
	for argument: String in args:
		if argument == "--server":
			parsed["server"] = true
		elif argument == "--run-tests":
			parsed["run_tests"] = true
		elif argument.begins_with("--port="):
			parsed["port"] = _read_int_option(argument, "--port=", 7777, 1, 65535)
		elif argument.begins_with("--max-players="):
			parsed["max_players"] = _read_int_option(argument, "--max-players=", 12, 1, 64)
		elif argument.begins_with("--bot-count="):
			parsed["bot_count"] = _read_int_option(argument, "--bot-count=", 0, 0, 64)
		elif argument.begins_with("--track="):
			parsed["track"] = argument.trim_prefix("--track=").strip_edges()
	return parsed

static func _read_int_option(argument: String, prefix: String, fallback: int, minimum: int, maximum: int) -> int:
	var value: int = argument.trim_prefix(prefix).to_int()
	return clampi(value, minimum, maximum) if value > 0 or minimum == 0 else fallback
