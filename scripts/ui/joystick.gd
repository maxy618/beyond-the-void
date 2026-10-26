class_name BtvJoystick
extends Control

## Fixed thumb stick with a generous touch zone. The visual handle follows the finger.

signal moved(vector: Vector2)

var radius: float = 56.0
var handle_radius: float = 25.0
var value: Vector2 = Vector2.ZERO
var active: bool = false
var _touch_index: int = -1

func _ready() -> void:
	custom_minimum_size = Vector2(152, 152)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

func reset() -> void:
	active = false
	value = Vector2.ZERO
	_touch_index = -1
	moved.emit(Vector2.ZERO)
	queue_redraw()

func _center() -> Vector2:
	return size * 0.5

func _draw() -> void:
	var center := _center()
	draw_circle(center, radius + 10.0, Color(0.02, 0.04, 0.05, 0.45))
	draw_circle(center, radius, Color(0.08, 0.14, 0.16, 0.55))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.55, 0.9, 0.82, 0.25), 1.5)
	for i in range(4):
		var angle := TAU * float(i) / 4.0
		draw_line(center + Vector2(cos(angle), sin(angle)) * (radius * 0.68), center + Vector2(cos(angle), sin(angle)) * (radius * 0.9), Color(0.55, 0.9, 0.82, 0.16), 1.0)
	var handle := center + value * radius
	draw_circle(handle, handle_radius, Color(0.5, 0.88, 0.8, 0.22))
	draw_circle(handle, handle_radius * 0.72, Color(0.56, 0.9, 0.82, 0.46))
	draw_circle(handle, handle_radius * 0.28, BtvTheme.ACCENT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active:
			active = true
			_touch_index = event.index
			_update_from_screen(event.position)
		elif not event.pressed and active and event.index == _touch_index:
			active = false
			_touch_index = -1
			value = Vector2.ZERO
			moved.emit(Vector2.ZERO)
			queue_redraw()
		accept_event()
	elif event is InputEventScreenDrag and active and event.index == _touch_index:
		_update_from_screen(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active = true
			_update_from_screen(event.position)
		else:
			active = false
			value = Vector2.ZERO
			moved.emit(Vector2.ZERO)
			queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and active:
		_update_from_screen(event.position)
		accept_event()

func _update_from_screen(position: Vector2) -> void:
	var offset := position - _center()
	var limit := radius
	var length := offset.length()
	value = offset / limit if length <= limit else offset.normalized()
	moved.emit(value)
	queue_redraw()
