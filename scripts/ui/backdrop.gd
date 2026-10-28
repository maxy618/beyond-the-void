class_name BtvBackdrop
extends Control

## Menu backdrop: seeded stars, a distant accretion ring, slow dust. No textures.

var world_seed: int = 424242
var quality: String = "balanced"
var reduced_motion: bool = false
var time: float = 0.0
var stars: Array = []
var dust: Array = []
var nebula: Array = []
var pointer := Vector2.ZERO
var pointer_active := false

var _drone: Sprite2D
var _drone_pos := Vector2.ZERO
var _drone_vel := Vector2.ZERO
var _drone_ready := false
var _trail: Array[Vector2] = []
var _rings: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drone = Sprite2D.new()
	_drone.texture = BtvPixelSprites.prop_texture("drone")
	_drone.scale = Vector2(2.2, 2.2)
	_drone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_drone.z_index = 5
	add_child(_drone)
	_rebuild()

func set_pointer(position: Vector2, active: bool) -> void:
	if active and not pointer_active:
		_drone_pos = position
		_drone_vel = Vector2.ZERO
	pointer = position
	pointer_active = active

func tap(position: Vector2) -> void:
	_rings.append({"pos": position, "age": 0.0})
	if _rings.size() > 6:
		_rings.pop_front()
	set_pointer(position, true)

func set_visuals(seed_value: int, quality_value: String, reduced: bool) -> void:
	world_seed = seed_value
	quality = quality_value
	reduced_motion = reduced
	_rebuild()
	queue_redraw()

func _rebuild() -> void:
	stars = WorldGen.starfield(world_seed, "menu", int(_quality_count(170)))
	dust.clear()
	var rng := WorldGen.rng_for(world_seed, "menu_dust")
	for i in range(int(_quality_count(30))):
		dust.append({
			"x": rng.randf(), "y": rng.randf(),
			"r": rng.randf_range(0.6, 2.2), "phase": rng.randf_range(0, TAU),
			"speed": rng.randf_range(0.004, 0.018),
		})
	nebula.clear()
	for i in range(9):
		nebula.append({
			"x": rng.randf_range(0.05, 0.95),
			"y": rng.randf_range(0.02, 0.75),
			"r": rng.randf_range(0.14, 0.42),
			"tint": [BtvTheme.PURPLE, BtvTheme.ACCENT, BtvTheme.AMBER][i % 3],
		})

func _quality_count(base: int) -> int:
	match quality:
		"low": return maxi(4, int(base * 0.35))
		"high": return base
		"ultra": return int(base * 1.4)
		_: return int(base * 0.7)

func _process(delta: float) -> void:
	if not reduced_motion:
		time += delta
	_update_drone(delta)
	for ring in _rings:
		ring["age"] = float(ring["age"]) + delta
	_rings = _rings.filter(func(ring: Dictionary) -> bool: return float(ring["age"]) < 0.9)
	queue_redraw()

func _update_drone(delta: float) -> void:
	if _drone == null or not _drone_ready:
		if size.x > 2.0:
			_drone_pos = size * Vector2(0.72, 0.3)
			_drone.position = _drone_pos
			_drone_ready = true
		return
	if pointer_active:
		var target := pointer
		if reduced_motion:
			_drone_pos = target
		else:
			_drone_vel = _drone_vel.lerp((target - _drone_pos) * 7.0, 0.35)
			_drone_pos += _drone_vel * delta
	else:
		var idle := size * Vector2(0.72, 0.3) + Vector2(sin(time * 0.5) * 18.0, cos(time * 0.4) * 10.0)
		_drone_pos = _drone_pos.lerp(idle, 1.0 - exp(-2.0 * delta))
	_drone.position = _drone_pos
	_drone.rotation = clampf(_drone_vel.x * 0.001, -0.25, 0.25)
	if not reduced_motion and _drone_pos.distance_to(pointer) > 2.0:
		_trail.append(_drone_pos)
		if _trail.size() > 16:
			_trail.pop_front()

func _draw() -> void:
	var view := size
	if view.x < 2.0 or view.y < 2.0:
		return
	for i in range(20):
		var t := float(i) / 19.0
		draw_rect(Rect2(0, view.y * t, view.x, view.y / 19.0 + 1), BtvTheme.BG.lerp(Color("#111d31"), t * 0.75))
	_draw_nebula(view)
	_draw_stars(view)
	_draw_lens(view)
	_draw_trail()
	_draw_rings()
	_draw_dust(view)
	_draw_frame(view)
	_draw_hint(view)

func _draw_trail() -> void:
	for index in _trail.size():
		var alpha := float(index) / float(maxi(1, _trail.size())) * 0.22
		draw_circle(_trail[index], 1.0 + float(index) * 0.08, Color(0.5, 0.88, 0.78, alpha))

func _draw_rings() -> void:
	for ring in _rings:
		var age := float(ring["age"])
		var radius := 10.0 + age * 120.0
		var alpha := maxf(0.0, 1.0 - age / 0.9)
		draw_arc(ring["pos"], radius, 0.0, TAU, 40, Color(0.5, 0.88, 0.78, alpha * 0.55), 1.5)
		draw_arc(ring["pos"], radius * 0.62, 0.0, TAU, 28, Color(0.92, 0.72, 0.46, alpha * 0.3), 1.0)

func _draw_hint(view: Vector2) -> void:
	if pointer_active or reduced_motion:
		return
	var alpha := 0.5 + 0.3 * sin(time * 1.4)
	draw_string(ThemeDB.fallback_font, Vector2(24, view.y - 28), "DRAG TO GUIDE THE DRONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.56, 0.65, 0.66, alpha))

func _draw_nebula(view: Vector2) -> void:
	for blob in nebula:
		var center := Vector2(float(blob.x) * view.x, float(blob.y) * view.y)
		var radius := float(blob.r) * minf(view.x, view.y)
		var tint: Color = blob.tint
		for ring in range(7, 0, -1):
			var alpha := 0.012 * (1.0 - float(ring) / 8.0)
			draw_circle(center, radius * float(ring) / 7.0, Color(tint.r, tint.g, tint.b, alpha))

func _draw_stars(view: Vector2) -> void:
	var motion := 0.0 if reduced_motion else time
	for star in stars:
		var x := float(star.x) * view.x
		var y := float(star.y) * view.y
		var twinkle := 0.65 + 0.35 * sin(motion * 0.8 + float(star.phase))
		var radius := float(star.size) * (0.8 + twinkle * 0.35)
		var alpha := float(star.bright) * twinkle
		draw_circle(Vector2(x, y), radius, Color(0.85, 0.93, 1.0, alpha))
		if float(star.size) > 2.1:
			draw_circle(Vector2(x, y), radius * 2.8, Color(0.65, 0.84, 0.96, alpha * 0.08))

func _draw_lens(view: Vector2) -> void:
	var center := Vector2(view.x * 0.53, view.y * 0.33)
	var radius := minf(view.x, view.y) * 0.16
	var spin := 0.0 if reduced_motion else time * 0.06
	for ring in range(5, 0, -1):
		var r := radius * (1.05 + float(ring) * 0.13)
		var fade := 0.05 + 0.035 * float(5 - ring)
		draw_arc(center, r, spin + float(ring) * 0.8, spin + float(ring) * 0.8 + 4.4, 42, Color(0.66, 0.54, 0.95, fade), 2.0 + float(ring) * 0.7)
	draw_circle(center, radius * 1.02, Color(0.01, 0.015, 0.025, 1.0))
	draw_circle(center, radius * 1.16, Color(0.45, 0.63, 0.91, 0.05))
	draw_arc(center, radius * 1.22, 0.0, TAU, 64, Color(0.66, 0.87, 0.92, 0.22), 1.2)

func _draw_dust(view: Vector2) -> void:
	var motion := 0.0 if reduced_motion else time
	for mote in dust:
		var x := fposmod(float(mote.x) * view.x + motion * float(mote.speed) * view.x, view.x)
		var y := float(mote.y) * view.y + sin(motion * 0.15 + float(mote.phase)) * 10.0
		draw_circle(Vector2(x, y), float(mote.r), Color(0.64, 0.85, 0.81, 0.18))

func _draw_frame(view: Vector2) -> void:
	var border := 18.0
	for i in range(6):
		var alpha := 0.07 * (1.0 - float(i) / 6.0)
		draw_rect(Rect2(0, 0, view.x, border - i * 2), Color(0, 0, 0, alpha))
		draw_rect(Rect2(0, view.y - border + i * 2, view.x, border - i * 2), Color(0, 0, 0, alpha))
		draw_rect(Rect2(0, 0, border - i * 2, view.y), Color(0, 0, 0, alpha))
		draw_rect(Rect2(view.x - border + i * 2, 0, border - i * 2, view.y), Color(0, 0, 0, alpha))
