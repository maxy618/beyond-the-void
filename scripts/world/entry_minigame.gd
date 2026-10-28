class_name BtvEntryMinigame
extends Control

## Playable atmospheric entry: drag to steer the falling pod through debris.
## Short, skippable, and it hands the resulting hull condition to the field screen.

signal finished(hull: float)

const DURATION := 10.0
const POD_Y := 0.64

var loc: Localization
var quality := "balanced"
var reduced_motion := false

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _hull := 100.0
var _pod_x := 0.5
var _target_x := 0.5
var _shake := 0.0
var _done := false
var _closing := false
var _spawn_timer := 0.0
var _status: Label
var _altitude: Label
var _hull_bar: ProgressBar
var _hint: Label
var _skip: Button
var _pod: Node2D
var _debris_root: Node2D
var _debris: Array = []
var _sparks: Array = []
var _rock_texture: Texture2D

func setup(p_loc: Localization, p_seed: int, p_quality: String, p_reduced: bool) -> void:
	loc = p_loc
	quality = p_quality
	reduced_motion = p_reduced
	_rng.seed = p_seed ^ 0x5EED

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	_rock_texture = BtvPixelSprites.prop_texture("rock")
	_build_pod()
	_build_hud()
	queue_redraw()

func _build_pod() -> void:
	_pod = Node2D.new()
	_pod.z_index = 6
	add_child(_pod)
	var plate := Sprite2D.new()
	plate.texture = BtvPixelSprites.prop_texture("plate")
	plate.scale = Vector2(2.6, 2.6)
	plate.position = Vector2(-20, 0)
	plate.rotation = -0.18
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pod.add_child(plate)
	var plate_b := Sprite2D.new()
	plate_b.texture = BtvPixelSprites.prop_texture("plate")
	plate_b.scale = Vector2(2.2, 2.2)
	plate_b.position = Vector2(18, 4)
	plate_b.rotation = 0.22
	plate_b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pod.add_child(plate_b)
	var engine := Sprite2D.new()
	engine.texture = BtvPixelSprites.prop_texture("engine")
	engine.scale = Vector2(1.8, 1.8)
	engine.position = Vector2(0, 24)
	engine.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pod.add_child(engine)
	_debris_root = Node2D.new()
	_debris_root.z_index = 4
	add_child(_debris_root)

func _build_hud() -> void:
	var title := BtvTheme.label("ATMOSPHERIC ENTRY  //  VELA", 14, BtvTheme.ACCENT)
	title.position = Vector2(28, 26)
	add_child(title)
	_status = BtvTheme.label("DESCENT", 11, BtvTheme.TEXT_DIM)
	_status.position = Vector2(28, 50)
	add_child(_status)
	_hull_bar = ProgressBar.new()
	_hull_bar.position = Vector2(28, 76)
	_hull_bar.size = Vector2(size.x - 56, 12)
	_hull_bar.max_value = 100.0
	_hull_bar.value = _hull
	_hull_bar.show_percentage = false
	_hull_bar.add_theme_stylebox_override("background", BtvTheme.flat(BtvTheme.BG_DEEP, 0, BtvTheme.LINE, 1))
	_hull_bar.add_theme_stylebox_override("fill", BtvTheme.flat(BtvTheme.ACCENT, 0))
	add_child(_hull_bar)
	_altitude = BtvTheme.label("ALT 12.0 KM", 11, BtvTheme.TEXT_FAINT)
	_altitude.position = Vector2(28, 96)
	add_child(_altitude)
	_hint = BtvTheme.label("DRAG TO STEER  //  BRACE FOR IMPACT", 12, BtvTheme.TEXT_DIM)
	_hint.position = Vector2(28, size.y - 52)
	add_child(_hint)
	_skip = BtvTheme.button("SKIP", 44)
	_skip.position = Vector2(size.x - 124, 24)
	_skip.size = Vector2(96, 44)
	_skip.pressed.connect(_finish_early)
	add_child(_skip)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_set_target(event.position.x)
	elif event is InputEventScreenTouch and event.pressed:
		_set_target(event.position.x)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_set_target(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_target(event.position.x)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_target_x = clampf(_target_x - 0.12, 0.06, 0.94)
	elif event.is_action_pressed("ui_right"):
		_target_x = clampf(_target_x + 0.12, 0.06, 0.94)

func _set_target(x: float) -> void:
	if _done:
		return
	_target_x = clampf(x / maxf(1.0, size.x), 0.06, 0.94)

func _process(delta: float) -> void:
	if _done:
		return
	_time += delta
	_pod_x = lerpf(_pod_x, _target_x, 1.0 - exp(-7.0 * delta))
	_pod.position = Vector2(size.x * _pod_x, size.y * POD_Y + sin(_time * 2.2) * 3.0)
	_pod.rotation = clampf((_target_x - _pod_x) * 0.55, -0.2, 0.2)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _rng.randf_range(0.42, 0.72)
		_spawn_debris()
	_update_debris(delta)
	_update_sparks(delta)
	_shake = maxf(0.0, _shake - delta * 2.4)
	var progress := clampf(_time / DURATION, 0.0, 1.0)
	_hull_bar.value = _hull
	_altitude.text = "ALT %0.1f KM" % lerpf(12.0, 0.2, progress)
	queue_redraw()

	if _time >= DURATION:
		_land()

func _spawn_debris() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _rock_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var scale_value := _rng.randf_range(0.9, 2.1)
	sprite.scale = Vector2.ONE * scale_value
	sprite.position = Vector2(_rng.randf_range(0.04, 0.96) * size.x, size.y * 0.04)
	_debris_root.add_child(sprite)
	_debris.append({
		"node": sprite,
		"x": sprite.position.x,
		"y": sprite.position.y,
		"vy": _rng.randf_range(150.0, 280.0) + progress_speed(),
		"drift": _rng.randf_range(-30.0, 30.0),
		"r": 10.0 * scale_value,
	})

func progress_speed() -> float:
	return clampf(_time / DURATION, 0.0, 1.0) * 130.0

func _update_debris(delta: float) -> void:
	var pod_center := size.y * POD_Y
	var keep: Array[Dictionary] = []
	for piece in _debris:
		piece["y"] = float(piece["y"]) + float(piece["vy"]) * delta
		piece["x"] = float(piece["x"]) + float(piece["drift"]) * delta
		var node: Sprite2D = piece["node"]
		if not is_instance_valid(node):
			continue
		node.position = Vector2(float(piece["x"]), float(piece["y"]))
		node.rotation += delta * 1.4
		var hit := absf(float(piece["x"]) - size.x * _pod_x) < 26.0 + float(piece["r"]) * 0.45 \
			and absf(float(piece["y"]) - pod_center) < 26.0
		if hit and not _done:
			_hull = maxf(8.0, _hull - 14.0)
			_shake = 1.0
			_burst(Vector2(float(piece["x"]), float(piece["y"])))
			node.queue_free()
			continue
		if float(piece["y"]) > size.y + 60.0 or float(piece["x"]) < -80.0 or float(piece["x"]) > size.x + 80.0:
			node.queue_free()
			continue
		keep.append(piece)
	_debris = keep

func _burst(at: Vector2) -> void:
	for i in 7:
		_sparks.append({
			"pos": at,
			"vel": Vector2.from_angle(TAU * float(i) / 7.0) * _rng.randf_range(40.0, 130.0),
			"life": 0.5,
		})

func _update_sparks(delta: float) -> void:
	for spark in _sparks:
		spark["pos"] = Vector2(spark["pos"]) + Vector2(spark["vel"]) * delta
		spark["vel"] = Vector2(spark["vel"]) * 0.94
		spark["life"] = float(spark["life"]) - delta
	_sparks = _sparks.filter(func(spark: Dictionary) -> bool: return float(spark["life"]) > 0.0)

func _land() -> void:
	if _closing:
		return
	_done = true
	_closing = true
	_status.text = "TOUCHDOWN"
	_hint.text = "HULL %d%%  //  WELCOME TO VELA" % int(_hull)
	_skip.visible = false
	_pod.rotation = 0.0
	_pod.position.y = size.y * POD_Y + 8.0
	await get_tree().create_timer(0.9).timeout
	finished.emit(_hull)

func _finish_early() -> void:
	if _closing:
		return
	_done = true
	_closing = true
	finished.emit(maxf(_hull, 55.0))

func _draw() -> void:
	if size.x < 2.0 or _pod == null:
		return
	var horizon := size.y * 0.82
	for i in range(22):
		var t := float(i) / 21.0
		draw_rect(Rect2(0, size.y * t, size.x, size.y / 21.0 + 1),
			Color("#0b1220").lerp(Color("#6d4636"), pow(t, 1.7)))
	var glow := 0.0 if reduced_motion else 0.06 + 0.04 * sin(_time * 2.0)
	draw_rect(Rect2(0, horizon - 40, size.x, 80), Color(0.95, 0.58, 0.3, glow))
	for i in range(9):
		var x := fposmod(float(i) * 97.0 + _time * 22.0, size.x)
		draw_line(Vector2(x, 0), Vector2(x - 12, horizon), Color(0.7, 0.82, 0.86, 0.06), 1.0)
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), Color("#0a0e12"))
	for i in range(13):
		var x := float(i) * size.x / 12.0
		var h := 10.0 + fmod(float(i) * 37.0, 34.0)
		draw_rect(Rect2(x, horizon - h, size.x / 12.0 + 1, h), Color("#131a20"))
	draw_line(Vector2(0, horizon), Vector2(size.x, horizon), Color(0.55, 0.82, 0.8, 0.25), 1.0)
	var flame := 10.0 + sin(_time * 26.0) * 4.0
	var base := _pod.position + Vector2(0, 26)
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-7, 0), base + Vector2(7, 0), base + Vector2(0, flame + 12.0),
	]), Color(1.0, 0.62, 0.28, 0.75))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-3, 0), base + Vector2(3, 0), base + Vector2(0, flame),
	]), Color(0.68, 0.9, 1.0, 0.8))
	for spark in _sparks:
		var alpha := clampf(float(spark["life"]) / 0.5, 0.0, 1.0)
		draw_circle(spark["pos"], 2.0, Color(1.0, 0.72, 0.38, alpha))
	if _shake > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.35, 0.25, _shake * 0.08))
