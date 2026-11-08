extends Node

var launch_options: Dictionary = {}
var platform_service: PlatformService
var launch_mode: StringName = &"client"

func _ready() -> void:
	launch_options = CliArgsParser.parse(OS.get_cmdline_user_args())
	if bool(launch_options["server"]) or OS.has_feature("dedicated_server"):
		platform_service = HeadlessServerService.new()
		launch_mode = &"server"
	elif OS.has_feature("android"):
		platform_service = AndroidPlatformService.new()
	else:
		platform_service = DesktopPlatformService.new()
	if bool(launch_options["run_tests"]):
		launch_mode = &"tests"
