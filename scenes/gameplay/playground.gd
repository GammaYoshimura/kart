extends Node3D

@onready var _kart: KartSimBody = $Kart
@onready var _speed_label: Label = $HUD/Speed


func _process(_delta: float) -> void:
	var speed_kmh: int = roundi(absf(_kart.state.forward_speed) * 3.6)
	_speed_label.text = "VELOCIDAD  %03d km/h" % speed_kmh
