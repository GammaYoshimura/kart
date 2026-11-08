class_name BoostPadZone
extends Area3D

@export var boost_duration_ticks: int = 60
@export var boost_speed_bonus: float = 12.0


func _ready() -> void:
	collision_layer = 1 << 7
	collision_mask = 1 << 2
	var connection_error: int = body_entered.connect(_on_body_entered)
	if connection_error != OK:
		push_error("BoostPadZone could not connect its body_entered signal.")


func _on_body_entered(body: Node3D) -> void:
	if body is KartSimBody:
		(body as KartSimBody).apply_boost(boost_duration_ticks, boost_speed_bonus)
