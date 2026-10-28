class_name BtvTouchStick
extends Control

## Independent touch stick. Tracks its own touch index so move and aim work together.
## The visual handle follows the finger; aim never fires by itself.

signal changed(vector: Vector2)
signal released

var radius := 78.0
var value := Vector2.ZERO
var active := false
var caption := ""
var accent := Color("#7fe0c2")

var _index := -1
var _center := Vector2(88, 88)

func _ready() -> void:
	custom_minimum_size = Vector2(176, 176)
	size = Vector2(176, 176)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_center = size * 0.5

func reset() -> void:
	active = false
	value = Vector2.ZERO
	_index = -1
	changed.emit(Vector2.ZERO)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _index == -1:
			_index = touch.index
			active = true
			_set_from_local(touch.position)
		elif not touch.pressed and touch.index == _index:
			reset()
			released.emit()
		accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _index:
			_set_from_local(drag.position)
			accept_event()

func _set_from_local(local: Vector2) -> void:
	var offset := local - _center
	value = offset.limit_length(radius) / radius
	changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var center := _center
	draw_circle(center, radius + 14.0, Color(0.02, 0.03, 0.04, 0.35))
	draw_circle(center, radius, Color(0.05, 0.09, 0.11, 0.55))
	draw_arc(center, radius, 0.0, TAU, 56, Color(accent.r, accent.g, accent.b, 0.42), 2.0)
	draw_arc(center, radius * 0.55, 0.0, TAU, 40, Color(accent.r, accent.g, accent.b, 0.16), 1.0)
	for i in range(4):
		var angle := TAU * float(i) / 4.0
		var from := center + Vector2(cos(angle), sin(angle)) * (radius * 0.72)
		var to := center + Vector2(cos(angle), sin(angle)) * (radius * 0.9)
		draw_line(from, to, Color(accent.r, accent.g, accent.b, 0.3), 1.5)
	var handle := center + value * radius
	draw_circle(handle, 30.0, Color(0.07, 0.14, 0.15, 0.92))
	draw_arc(handle, 30.0, 0.0, TAU, 36, accent, 2.0)
	draw_circle(handle, 7.0, Color(accent.r, accent.g, accent.b, 0.85))
	if not caption.is_empty():
		draw_string(ThemeDB.fallback_font, center + Vector2(-radius, radius + 24.0), caption,
			HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 13, Color(0.62, 0.78, 0.78, 0.7))
