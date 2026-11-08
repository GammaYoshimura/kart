class_name SimulationWorld
extends Node3D

var simulation_clock: SimulationClock = SimulationClock.new()
var states_by_slot: Dictionary = {}
var last_inputs_by_slot: Dictionary = {}

func register_state(slot: int, state: SerializableState) -> void:
	states_by_slot[slot] = state

func unregister_slot(slot: int) -> void:
	states_by_slot.erase(slot)
	last_inputs_by_slot.erase(slot)

func step_tick(inputs_by_slot: Dictionary) -> void:
	last_inputs_by_slot = inputs_by_slot.duplicate(true)
	simulation_clock.advance_tick()
	for slot_variant: Variant in inputs_by_slot:
		var command: Variant = inputs_by_slot[slot_variant]
		if command is InputCommandFrame:
			command.tick = simulation_clock.current_tick

func capture_world_snapshot() -> WorldSimSnapshot:
	return WorldSimSnapshot.new(
		simulation_clock.current_tick,
		_encode_state_dictionary(states_by_slot),
		_encode_state_dictionary(last_inputs_by_slot)
	)

func restore_world_snapshot(snapshot: WorldSimSnapshot) -> void:
	if snapshot == null:
		push_error("Cannot restore a null world snapshot")
		return
	simulation_clock.set_tick(snapshot.tick)
	states_by_slot = _decode_state_dictionary(snapshot.state_payloads)
	last_inputs_by_slot = _decode_state_dictionary(snapshot.input_payloads)

func _encode_state_dictionary(source: Dictionary) -> Dictionary:
	var encoded: Dictionary = {}
	for key: Variant in source:
		var value: Variant = source[key]
		if value is SerializableState:
			var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
			value.write_to_buffer(buffer)
			var script: Script = value.get_script() as Script
			if script == null or script.resource_path.is_empty():
				push_error("Snapshot state must use a script saved in the project")
				continue
			encoded[key] = {"kind": "serializable", "script": script.resource_path, "bytes": buffer.data_array}
		else:
			encoded[key] = {"kind": "value", "value": value}
	return encoded

func _decode_state_dictionary(encoded: Dictionary) -> Dictionary:
	var decoded: Dictionary = {}
	for key: Variant in encoded:
		var entry: Dictionary = encoded[key]
		if entry.get("kind", "value") == "serializable":
			var script: Script = load(str(entry.get("script", ""))) as Script
			if script == null:
				push_error("Snapshot references an unavailable state script")
				continue
			var state: Variant = script.new()
			if not state is SerializableState:
				push_error("Snapshot script does not extend SerializableState")
				continue
			var buffer: StreamPeerBuffer = StreamPeerBuffer.new()
			buffer.data_array = entry.get("bytes", PackedByteArray())
			state.read_from_buffer(buffer)
			decoded[key] = state
		else:
			decoded[key] = entry.get("value")
	return decoded
