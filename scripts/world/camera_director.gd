class_name BtvCameraDirector
extends Node2D

## Single owner of the gameplay Camera2D. Gameplay code never sets zoom directly.
## Modes, critically damped follow/zoom, aim look-ahead, bounds, trauma shake.

const MODE_ZOOM := {
	"on_foot": 0.95,
	"sprint": 0.85,
	"aim": 1.03,
	"jetpack": 0.85,
	"cinematic": 0.79,
}
const MODE_LOOKAHEAD := {
	"on_foot": 16.0,
	"sprint": 26.0,
	"aim": 30.0,
	"jetpack": 10.0,
	"cinematic": 0.0,
}

var camera: Camera2D
var player: BtvPlayer
var world_rect := Rect2()
var mode := "on_foot"
var override_mode := ""
var shake_scale := 1.0
var reduced_motion := false

var _position := Vector2.ZERO
var _velocity := Vector2.ZERO
var _zoom := 1.14
var _zoom_velocity := 0.0
var _trauma := 0.0
var _time := 0.0
var _viewport_size := Vector2(360, 640)

func setup(p_player: BtvPlayer, bounds: Rect2) -> void:
	player = p_player
	world_rect = bounds
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = false
	add_child(camera)
	_position = player.position
	camera.position = _position
	camera.zoom = Vector2.ONE * _zoom

func set_viewport_size(size: Vector2) -> void:
	_viewport_size = size

func set_override(value: String) -> void:
	override_mode = value

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func current_zoom() -> float:
	return _zoom

func _process(delta: float) -> void:
	if camera == null or player == null:
		return
	_time += delta
	_trauma = maxf(0.0, _trauma - delta * 1.6)
	var desired_mode := _resolve_mode()
	if desired_mode != mode:
		mode = desired_mode
	var look := _lookahead()
	var target := player.position + look + Vector2(0, -player.altitude * 0.5)
	var zoom_target: float = float(MODE_ZOOM.get(mode, 1.14))
	zoom_target -= player.altitude * 0.0018
	if player.health < player.max_health * 0.35:
		zoom_target += 0.05
	_position = _spring(_position, target, _velocity, 14.0, delta)
	_zoom = _spring_float(_zoom, zoom_target, _zoom_velocity, 9.0, delta)
	if world_rect.size.x > 0.0:
		var half := _viewport_size / (2.0 * _zoom)
		var min_x := world_rect.position.x + half.x
		var max_x := world_rect.end.x - half.x
		var min_y := world_rect.position.y + half.y
		var max_y := world_rect.end.y - half.y
		_position.x = min_x if min_x > max_x else clampf(_position.x, min_x, max_x)
		_position.y = min_y if min_y > max_y else clampf(_position.y, min_y, max_y)
	camera.position = Vector2(roundf(_position.x), roundf(_position.y))
	camera.zoom = Vector2.ONE * _zoom
	var shake := _trauma * _trauma * 9.0 * shake_scale
	if reduced_motion:
		shake = 0.0
	if shake > 0.05:
		camera.offset = Vector2(
			sin(_time * 47.0) * shake + sin(_time * 31.0) * shake * 0.4,
			cos(_time * 41.0) * shake * 0.7
		)
	else:
		camera.offset = Vector2.ZERO

func _resolve_mode() -> String:
	if not override_mode.is_empty():
		return override_mode
	if player.jetting or player.altitude > 4.0:
		return "jetpack"
	if player.sprinting and player.moving:
		return "sprint"
	if player.aim_active:
		return "aim"
	return "on_foot"

func _lookahead() -> Vector2:
	var amount := float(MODE_LOOKAHEAD.get(mode, 16.0))
	if mode == "sprint":
		return player.velocity.normalized() * amount
	if mode == "aim":
		return player.aim_dir * amount
	if mode == "on_foot":
		return player.aim_dir * amount * 0.4
	return Vector2.ZERO

static func _spring(current: Vector2, target: Vector2, velocity: Vector2, omega: float, delta: float) -> Vector2:
	var x := current - target
	var f := 1.0 + 2.0 * delta * omega
	var oo := omega * omega
	var hoo := delta * oo
	var hhoo := delta * hoo
	var det_inv := 1.0 / (f + hhoo)
	var det_x := f * x + delta * velocity
	var det_v := velocity + hoo * x
	velocity = det_v * det_inv
	return target + det_x * det_inv

static func _spring_float(current: float, target: float, velocity: float, omega: float, delta: float) -> float:
	var x := current - target
	var f := 1.0 + 2.0 * delta * omega
	var oo := omega * omega
	var hoo := delta * oo
	var hhoo := delta * hoo
	var det_inv := 1.0 / (f + hhoo)
	var det_x := f * x + delta * velocity
	return target + det_x * det_inv
