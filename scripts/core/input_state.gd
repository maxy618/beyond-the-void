class_name InputState
extends RefCounted

## Owns held input. The UI clears it on pause, focus loss and screen changes.

var move_vector: Vector2 = Vector2.ZERO
var joystick_active: bool = false
var action_held: bool = false

func set_move(value: Vector2) -> void:
	move_vector = value.limit_length(1.0)
	joystick_active = value.length() > 0.01

func clear() -> void:
	move_vector = Vector2.ZERO
	joystick_active = false
	action_held = false
