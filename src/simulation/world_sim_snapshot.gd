class_name WorldSimSnapshot
extends RefCounted

var tick: int = 0
var state_payloads: Dictionary = {}
var input_payloads: Dictionary = {}

func _init(p_tick: int = 0, p_states: Dictionary = {}, p_inputs: Dictionary = {}) -> void:
	tick = p_tick
	state_payloads = p_states.duplicate(true)
	input_payloads = p_inputs.duplicate(true)
