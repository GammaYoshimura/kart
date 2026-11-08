class_name HeadlessServerService
extends PlatformService

func platform_id() -> StringName:
	return &"dedicated_server"

func is_application_active() -> bool:
	return true
