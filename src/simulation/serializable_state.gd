class_name SerializableState
extends RefCounted

func write_to_buffer(_buf: StreamPeerBuffer) -> void:
	push_error("write_to_buffer must be implemented by a subclass")

func read_from_buffer(_buf: StreamPeerBuffer) -> void:
	push_error("read_from_buffer must be implemented by a subclass")
