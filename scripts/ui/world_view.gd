class_name BtvWorldView
extends Control

## Procedural presentation of the system chart and planet surface.
## All shapes are drawn here; the domain owns every state change.

signal tapped(world_pos: Vector2)
signal planet_tapped(planet_id: String)

var session: GameSession
var layout: Dictionary = {}
var selected_planet_id: String = ""
var target: Dictionary = {}
var time: float = 0.0
var reduced_motion: bool = false
var quality: String = "balanced"
var last_facing: Vector2 = Vector2.DOWN

var _visual_system: String = ""
var _visual: Dictionary = {}
var _terrain_planet: String = ""
var _terrain: Array = []
var _pulse_phase: float = 0.0

const SCALE_MIN := 0.46
const SCALE_MAX := 0.78

func setup(p_session: GameSession) -> void:
	session = p_session
	reduced_motion = bool(session.settings.get("reduced_motion", false))
	quality = str(session.settings.get("quality", "balanced"))
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_refresh_layout()
	if session.mode == "space":
		_refresh_visual()

func set_visual_settings(reduced: bool, quality_value: String) -> void:
	reduced_motion = reduced
	quality = quality_value
	queue_redraw()

func refresh() -> void:
	_refresh_layout()
	if session != null and session.mode == "space":
		_refresh_visual()
	queue_redraw()

func set_target(value: Dictionary) -> void:
	target = value
	queue_redraw()

func _refresh_layout() -> void:
	if session == null:
		return
	layout = session.surface_layout() if session.mode == "planet" else {}
	if session.mode == "planet" and _terrain_planet != session.planet_id:
		_terrain_planet = session.planet_id
		_build_terrain()

func _refresh_visual() -> void:
	_visual_system = session.system_id
	_visual = WorldGen.system_visual(session.world_seed, session.system_id, session.registry)

func _process(delta: float) -> void:
	if session == null:
		return
	if not reduced_motion:
		time += delta
		_pulse_phase = fmod(_pulse_phase + delta, 3.0)
	if session.mode == "space" and _visual_system != session.system_id:
		_refresh_visual()
	queue_redraw()

func _draw() -> void:
	if session == null or size.x < 2.0 or size.y < 2.0:
		return
	if session.mode == "space":
		_draw_space()
	else:
		_draw_planet()

# ---------------------------------------------------------------------------
# Planet surface

func _draw_planet() -> void:
	var planet := session.get_planet()
	var palette := _palette(planet)
	var sky: Color = palette[0] if palette.size() > 0 else Color("#132326")
	var ground: Color = palette[1] if palette.size() > 1 else Color("#223a34")
	var accent: Color = palette[3] if palette.size() > 3 else BtvTheme.ACCENT
	for i in range(18):
		var t := float(i) / 17.0
		draw_rect(Rect2(0, size.y * t, size.x, size.y / 17.0 + 1), sky.lerp(ground, t * 0.9))
	_draw_sky_motes(sky, accent)
	var scale := _surface_scale()
	var camera := _camera(scale)
	var origin := size * 0.5 - camera * scale
	draw_set_transform(origin, 0.0, Vector2(scale, scale))
	_draw_ground(planet, palette)
	_draw_decor()
	_draw_build_pads()
	_draw_landmarks(planet)
	_draw_nodes()
	_draw_player()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_surface_frame(accent)
	_draw_target_label(scale, origin)

func _surface_scale() -> float:
	if size.y <= 0.0:
		return 0.6
	return clampf(minf(size.x / 1280.0, size.y / 1560.0), SCALE_MIN, SCALE_MAX)

func _camera(scale: float) -> Vector2:
	var visible := size / scale
	var cam := session.player_pos
	if visible.x < WorldGen.WORLD_SIZE:
		cam.x = clampf(cam.x, visible.x * 0.5 - 120.0, WorldGen.WORLD_SIZE - visible.x * 0.5 + 120.0)
	else:
		cam.x = WorldGen.WORLD_SIZE * 0.5
	if visible.y < WorldGen.WORLD_SIZE:
		cam.y = clampf(cam.y, visible.y * 0.5 - 160.0, WorldGen.WORLD_SIZE - visible.y * 0.5 + 120.0)
	else:
		cam.y = WorldGen.WORLD_SIZE * 0.5
	return cam

func _draw_sky_motes(sky: Color, accent: Color) -> void:
	var rng := WorldGen.rng_for(session.world_seed, "sky:" + session.planet_id)
	for i in range(int(_density(44))):
		var x := rng.randf() * size.x
		var y := rng.randf() * size.y * 0.72
		var twinkle := 0.25 + 0.25 * sin(time * 0.9 + float(i))
		draw_circle(Vector2(x, y), rng.randf_range(0.6, 2.0), Color(accent.r, accent.g, accent.b, twinkle * 0.45))
	for i in range(7):
		var y := size.y * (0.08 + float(i) * 0.055)
		draw_line(Vector2(0, y), Vector2(size.x, y + sin(float(i)) * 8.0), Color(sky.r, sky.g, sky.b, 0.08), 1.0)

func _build_terrain() -> void:
	_terrain.clear()
	var rng := WorldGen.rng_for(session.world_seed, "terrain:" + session.planet_id)
	for i in range(int(_density(110))):
		_terrain.append({
			"x": rng.randf_range(80.0, WorldGen.WORLD_SIZE - 80.0),
			"y": rng.randf_range(80.0, WorldGen.WORLD_SIZE - 80.0),
			"r": rng.randf_range(40.0, 190.0),
			"shade": rng.randi_range(0, 3),
			"water": rng.randf() < 0.26,
			"phase": rng.randf_range(0, TAU),
		})

func _draw_ground(planet: Dictionary, palette: Array) -> void:
	var base: Color = palette[2] if palette.size() > 2 else Color("#1b2d2c")
	var alt: Color = palette[4] if palette.size() > 4 else base.lightened(0.08)
	draw_rect(Rect2(0, 0, WorldGen.WORLD_SIZE, WorldGen.WORLD_SIZE), base.darkened(0.24))
	for patch in _terrain:
		var p: Dictionary = patch
		var center := Vector2(float(p.x), float(p.y))
		var radius := float(p.r)
		var shade := int(p.shade)
		var tint := alt.lerp(base, float(shade) / 5.0)
		if bool(p.water):
			tint = Color(base.r * 0.45, base.g * 0.72, base.b * 0.86, 0.9)
		draw_circle(center, radius, Color(tint.r, tint.g, tint.b, 0.22))
		if bool(p.water):
			draw_arc(center, radius * 0.7, time * 0.06 + float(p.phase), time * 0.06 + float(p.phase) + 2.4, 24, Color(0.7, 0.94, 0.94, 0.16), 2.0)
			draw_arc(center, radius * 0.45, -time * 0.05 + float(p.phase), -time * 0.05 + float(p.phase) + 2.0, 20, Color(0.7, 0.94, 0.94, 0.12), 1.2)
	# A soft path of pale mineral dust between the landing site and the relay.
	if session.planet_id == "planet.vela":
		var points := PackedVector2Array([Vector2(1160, 1990), Vector2(1240, 1760), Vector2(1460, 1560), Vector2(1640, 1240), Vector2(1760, 990)])
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(0.78, 0.88, 0.78, 0.1), 26.0, true)
			draw_line(points[i], points[i + 1], Color(0.87, 0.94, 0.84, 0.12), 4.0, true)

func _draw_decor() -> void:
	for item in layout.get("decor", []):
		var d: Dictionary = item
		var pos := Vector2(float(d.x), float(d.y))
		var scale := float(d.scale)
		var kind := str(d.kind)
		match kind:
			"rock":
				draw_circle(pos, 10.0 * scale, Color(0.12, 0.16, 0.16, 0.8))
				draw_circle(pos + Vector2(-3, -3) * scale, 5.0 * scale, Color(0.22, 0.29, 0.28, 0.8))
			"crystal":
				draw_polygon(PackedVector2Array([pos + Vector2(0, -18) * scale, pos + Vector2(8, 0) * scale, pos + Vector2(-7, 4) * scale]), PackedColorArray([Color(0.55, 0.88, 0.82, 0.5)]))
				draw_line(pos + Vector2(0, -18) * scale, pos + Vector2(-7, 4) * scale, Color(0.8, 1.0, 0.95, 0.4), 1.0)
			"tuft":
				for blade in range(3):
					var offset := Vector2(float(blade - 1) * 5.0, 0) * scale
					draw_line(pos + offset, pos + offset + Vector2(-3 + blade * 3, -18) * scale, Color(0.48, 0.67, 0.5, 0.42), 1.5)
			"pool":
				draw_circle(pos, 26.0 * scale, Color(0.2, 0.48, 0.52, 0.32))
				draw_arc(pos, 18.0 * scale, 0.3, 4.8, 18, Color(0.65, 0.95, 0.9, 0.18), 1.0)

func _draw_build_pads() -> void:
	for slot in layout.get("build_slots", []):
		var s: Dictionary = slot
		var pos := Vector2(float(s.x), float(s.y))
		var occupied := false
		for building in session.buildings:
			var b: Dictionary = building
			if int(b.get("col", -1)) == int(s.col) and int(b.get("row", -1)) == int(s.row):
				occupied = true
				_draw_building(b, pos)
		if occupied:
			continue
		var rect := Rect2(pos - Vector2(58, 48), Vector2(116, 96))
		draw_rect(rect, Color(0.25, 0.55, 0.48, 0.06))
		draw_rect(rect, Color(0.5, 0.9, 0.74, 0.32), false, 1.5)
		for corner in range(4):
			var c := rect.position + Vector2(0 if corner % 2 == 0 else rect.size.x, 0 if corner < 2 else rect.size.y)
			draw_rect(Rect2(c - Vector2(4, 1), Vector2(8, 2)), BtvTheme.ACCENT)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-32, 5), "PAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.9, 0.8, 0.5))

func _draw_building(building: Dictionary, pos: Vector2) -> void:
	var definition_id := str(building.get("definition_id", ""))
	var powered := bool(building.get("powered", false))
	var color := BtvTheme.ACCENT if powered else Color("#6b7b76")
	var rect := Rect2(pos - Vector2(50, 34), Vector2(100, 68))
	draw_rect(rect, Color(0.06, 0.1, 0.11, 0.9))
	draw_rect(rect, color, false, 2.0)
	if powered:
		draw_circle(pos, 55.0, Color(color.r, color.g, color.b, 0.05))
	match definition_id:
		"build.power_cell":
			draw_circle(pos, 18.0, Color(color.r, color.g, color.b, 0.25))
			draw_circle(pos, 7.0, color)
			draw_arc(pos, 26.0, -1.0, 4.2, 22, Color(color.r, color.g, color.b, 0.5), 2.0)
		"build.smelter":
			draw_rect(Rect2(pos - Vector2(24, 16), Vector2(48, 32)), Color(0.3, 0.18, 0.12, 0.9))
			draw_circle(pos + Vector2(0, 2), 10.0, Color(0.95, 0.46, 0.2, 0.7 if powered else 0.2))
		"build.habitat":
			draw_arc(pos + Vector2(0, 10), 30.0, PI, TAU, 24, color, 3.0)
			draw_rect(Rect2(pos - Vector2(30, 10), Vector2(60, 24)), Color(0.1, 0.18, 0.18, 0.9))
			draw_circle(pos + Vector2(-13, -8), 4.0, Color(0.95, 0.8, 0.4, 0.7 if powered else 0.15))
		"build.signal_mast":
			draw_line(pos + Vector2(0, 24), pos + Vector2(0, -30), color, 2.0)
			draw_arc(pos + Vector2(0, -18), 18.0, -1.2, 1.2, 14, color, 1.5)
			draw_arc(pos + Vector2(0, -18), 30.0, -1.0, 1.0, 16, Color(color.r, color.g, color.b, 0.5), 1.0)
		_:
			draw_rect(rect.grow(-10), color, false, 1.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-45, 56), definition_id.trim_prefix("build.").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

func _draw_landmarks(planet: Dictionary) -> void:
	for anchor in planet.get("anchors", []):
		var a: Dictionary = anchor
		var kind := str(a.kind)
		var pos := Vector2(float(a.x), float(a.y))
		match kind:
			"ship": _draw_ship(pos)
			"npc": _draw_npc(pos)
			"market": _draw_market(pos)
			"relay": _draw_relay(pos)
			"build_site": pass

func _draw_ship(pos: Vector2) -> void:
	var bobbing := 0.0 if reduced_motion else sin(time * 1.2) * 2.0
	var p := pos + Vector2(0, bobbing)
	draw_circle(p + Vector2(0, 26), 36.0, Color(0, 0, 0, 0.25))
	draw_polygon(PackedVector2Array([p + Vector2(-42, 8), p + Vector2(-18, -24), p + Vector2(28, -20), p + Vector2(44, 4), p + Vector2(12, 24), p + Vector2(-24, 20)]), PackedColorArray([Color("#94a9a4")]))
	draw_polygon(PackedVector2Array([p + Vector2(-18, -8), p + Vector2(0, -16), p + Vector2(24, -11), p + Vector2(4, -3)]), PackedColorArray([Color("#d8e5df")]))
	draw_line(p + Vector2(-30, 16), p + Vector2(30, 16), Color("#5d8d84"), 2.0)
	draw_circle(p + Vector2(30, -2), 3.0, BtvTheme.ACCENT)
	draw_string(ThemeDB.fallback_font, p + Vector2(-32, 48), "SKEIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.9, 0.85, 0.65))

func _draw_npc(pos: Vector2) -> void:
	draw_circle(pos + Vector2(0, 22), 18.0, Color(0, 0, 0, 0.28))
	draw_polygon(PackedVector2Array([pos + Vector2(-13, 20), pos + Vector2(-8, -12), pos + Vector2(0, -22), pos + Vector2(9, -11), pos + Vector2(13, 20)]), PackedColorArray([Color("#6d6a55")]))
	draw_circle(pos + Vector2(0, -20), 8.0, Color("#c9b795"))
	draw_circle(pos + Vector2(12, -2), 4.0, Color(0.95, 0.72, 0.34, 0.7))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-30, 36), "KASA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.8, 0.55, 0.8))

func _draw_market(pos: Vector2) -> void:
	draw_rect(Rect2(pos - Vector2(62, 20), Vector2(124, 56)), Color(0.1, 0.15, 0.14, 0.9))
	draw_polygon(PackedVector2Array([pos + Vector2(-70, -22), pos + Vector2(-38, -50), pos + Vector2(40, -50), pos + Vector2(70, -22)]), PackedColorArray([Color("#8a6b45")]))
	for i in range(4):
		draw_line(pos + Vector2(-60 + i * 34, -22), pos + Vector2(-60 + i * 34, 34), Color(0.38, 0.32, 0.22, 0.8), 2.0)
	for i in range(3):
		draw_rect(Rect2(pos + Vector2(-42 + i * 30, 12), Vector2(20, 14)), [Color("#668f7f"), Color("#a68458"), Color("#7b8790")][i])
	draw_string(ThemeDB.fallback_font, pos + Vector2(-48, 58), "TIDEBREAK", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.92, 0.78, 0.55, 0.7))

func _draw_relay(pos: Vector2) -> void:
	var repaired := bool(session.facts.get("flag.relay_repaired", false))
	var light := Color(0.38, 1.0, 0.72) if repaired else Color(0.38, 0.54, 0.52)
	draw_circle(pos + Vector2(0, 10), 28.0, Color(0, 0, 0, 0.3))
	draw_line(pos + Vector2(0, 30), pos + Vector2(0, -58), Color("#677a74"), 3.0)
	for i in range(3):
		draw_arc(pos + Vector2(0, -16 - i * 10), 16.0 + i * 12.0, -1.2, 1.2, 16, Color(light.r, light.g, light.b, 0.5), 1.6)
	draw_circle(pos + Vector2(0, -62), 5.0, light)
	if repaired:
		draw_circle(pos + Vector2(0, -62), 18.0, Color(light.r, light.g, light.b, 0.08))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-28, 48), "RELAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(light.r, light.g, light.b, 0.7))

func _draw_nodes() -> void:
	for raw in layout.get("nodes", []):
		var node: Dictionary = raw
		var species = session.registry.get_species(str(node.species_id))
		if species.is_empty():
			continue
		var pos := Vector2(float(node.x), float(node.y))
		var palette := _species_palette(species)
		var ready := session.is_node_ready(str(node.node_id))
		var bob := 0.0 if reduced_motion else sin(time * 1.4 + pos.x * 0.01) * 2.0
		draw_circle(pos + Vector2(0, 8), 13.0, Color(0, 0, 0, 0.28))
		if str(node.kind) == "flora":
			_draw_flora(pos + Vector2(0, bob), str(species.get("body_plan", "tuft")), palette, ready)
		else:
			_draw_fauna(pos + Vector2(0, bob), str(species.get("body_plan", "drifter")), palette)
		var observed := session.observations.has(str(node.species_id))
		if observed:
			draw_arc(pos, 22.0, -2.4, -0.7, 10, Color(0.7, 1.0, 0.9, 0.5), 1.2)
		if pos.distance_to(session.player_pos) < 190.0:
			var name := loc_name(species)
			draw_string(ThemeDB.fallback_font, pos + Vector2(-64, 42), name, HORIZONTAL_ALIGNMENT_LEFT, 128, 12, Color(0.88, 0.98, 0.94, 0.9))
		if not ready:
			draw_arc(pos, 17.0, 0.0, TAU, 22, Color(0.4, 0.5, 0.5, 0.4), 1.0)

func _draw_flora(pos: Vector2, body: String, palette: Array, ready: bool) -> void:
	var c: Color = palette[1] if palette.size() > 1 else BtvTheme.ACCENT
	var glow: Color = palette[2] if palette.size() > 2 else BtvTheme.AMBER
	var alpha := 1.0 if ready else 0.4
	if not ready:
		c = c.darkened(0.5)
		glow = glow.darkened(0.6)
	match body:
		"reed":
			for i in range(5):
				var dx := float(i - 2) * 5.0
				draw_line(pos + Vector2(dx, 8), pos + Vector2(dx * 1.5, -28 - absf(dx) * 0.5), Color(c.r, c.g, c.b, alpha), 2.0)
			draw_circle(pos + Vector2(8, -27), 3.0, Color(glow.r, glow.g, glow.b, 0.8 * alpha))
		"bell":
			draw_arc(pos + Vector2(0, -6), 14.0, PI, TAU, 18, Color(c.r, c.g, c.b, alpha), 3.0)
			draw_line(pos + Vector2(0, -20), pos + Vector2(0, 2), Color(c.r, c.g, c.b, alpha), 2.0)
			draw_circle(pos + Vector2(0, -8), 5.0, Color(glow.r, glow.g, glow.b, 0.6 * alpha))
		"mat":
			for i in range(7):
				var angle := float(i) * 0.9
				draw_circle(pos + Vector2(cos(angle), sin(angle)) * 10.0, 5.0, Color(c.r, c.g, c.b, 0.35 * alpha))
			draw_circle(pos + Vector2(3, -4), 3.0, Color(glow.r, glow.g, glow.b, 0.7 * alpha))
		"kelp":
			for i in range(4):
				var dx := float(i - 1.5) * 6.0
				var top := pos + Vector2(dx * 1.8, -30 - i * 4)
				draw_line(pos + Vector2(dx, 8), top, Color(c.r, c.g, c.b, alpha), 3.0, true)
			draw_circle(pos + Vector2(0, -34), 4.0, Color(glow.r, glow.g, glow.b, 0.6 * alpha))
		"orchid", "heather":
			draw_line(pos, pos + Vector2(0, -24), Color(c.r, c.g, c.b, alpha), 2.0)
			for i in range(5):
				var a := TAU * float(i) / 5.0
				draw_circle(pos + Vector2(0, -24) + Vector2(cos(a), sin(a)) * 8.0, 4.0, Color(glow.r, glow.g, glow.b, 0.6 * alpha))
		"cap":
			draw_line(pos + Vector2(0, 4), pos + Vector2(0, -16), Color(c.r, c.g, c.b, alpha), 3.0)
			draw_arc(pos + Vector2(0, -6), 16.0, PI, TAU, 16, Color(glow.r, glow.g, glow.b, 0.7 * alpha), 7.0)
		"thistle", "cactus":
			draw_line(pos + Vector2(0, 10), pos + Vector2(0, -24), Color(c.r, c.g, c.b, alpha), 5.0)
			draw_line(pos + Vector2(0, -10), pos + Vector2(-12, -20), Color(c.r, c.g, c.b, alpha), 3.0)
			draw_circle(pos + Vector2(0, -26), 5.0, Color(glow.r, glow.g, glow.b, 0.7 * alpha))
		"fern":
			for i in range(5):
				var tip := Vector2(float(i - 2) * 12.0, -26 + absf(float(i - 2)) * 5.0)
				draw_line(pos, pos + tip, Color(c.r, c.g, c.b, alpha), 2.0)
		"bulb":
			draw_circle(pos + Vector2(0, -4), 12.0, Color(c.r, c.g, c.b, 0.35 * alpha))
			draw_circle(pos + Vector2(0, -4), 6.0, Color(glow.r, glow.g, glow.b, 0.7 * alpha))
		_:
			draw_circle(pos + Vector2(0, -8), 12.0, Color(c.r, c.g, c.b, alpha))

func _draw_fauna(pos: Vector2, body: String, palette: Array) -> void:
	var c: Color = palette[1] if palette.size() > 1 else BtvTheme.BLUE
	var glow: Color = palette[2] if palette.size() > 2 else BtvTheme.ACCENT
	var flap := 0.0 if reduced_motion else sin(time * 2.4 + pos.y * 0.02)
	match body:
		"floating_ribbon", "jelly":
			draw_arc(pos + Vector2(0, -4), 22.0, PI, TAU, 22, Color(c.r, c.g, c.b, 0.75), 5.0)
			for i in range(4):
				draw_line(pos + Vector2(-12 + i * 8, 0), pos + Vector2(-16 + i * 10, 24 + absf(flap) * 6.0), Color(glow.r, glow.g, glow.b, 0.4), 1.5)
		"grazer":
			draw_circle(pos + Vector2(-8, 0), 13.0, Color(c.r, c.g, c.b, 0.8))
			draw_circle(pos + Vector2(10, -7), 8.0, Color(c.r, c.g, c.b, 0.9))
			for i in range(2):
				draw_line(pos + Vector2(-10 + i * 16, 8), pos + Vector2(-13 + i * 18, 20), Color(c.r, c.g, c.b, 0.7), 2.0)
			draw_circle(pos + Vector2(14, -9), 1.5, glow)
		"crawler", "crab":
			draw_circle(pos, 13.0, Color(c.r, c.g, c.b, 0.8))
			for i in range(4):
				draw_line(pos + Vector2(-10 + i * 7, 2), pos + Vector2(-16 + i * 9, 14 + (i % 2) * 4), Color(c.r, c.g, c.b, 0.6), 2.0)
			draw_circle(pos + Vector2(12, -4), 3.0, glow)
		"winged", "moth":
			var wing_span := 22.0 + absf(flap) * 12.0
			draw_polygon(PackedVector2Array([pos, pos + Vector2(-wing_span, -14), pos + Vector2(-8, 2)]), PackedColorArray([Color(c.r, c.g, c.b, 0.55)]))
			draw_polygon(PackedVector2Array([pos, pos + Vector2(wing_span, -14), pos + Vector2(8, 2)]), PackedColorArray([Color(c.r, c.g, c.b, 0.55)]))
			draw_circle(pos, 4.0, glow)
		"fox", "stilt":
			draw_circle(pos + Vector2(-2, 0), 12.0, Color(c.r, c.g, c.b, 0.8))
			draw_circle(pos + Vector2(10, -8), 7.0, Color(c.r, c.g, c.b, 0.9))
			draw_polygon(PackedVector2Array([pos + Vector2(14, -14), pos + Vector2(18, -24), pos + Vector2(20, -12)]), PackedColorArray([Color(glow.r, glow.g, glow.b, 0.8)]))
			draw_line(pos + Vector2(-10, 8), pos + Vector2(-16, 20), Color(c.r, c.g, c.b, 0.5), 2.0)
		"singer":
			draw_circle(pos, 10.0, Color(c.r, c.g, c.b, 0.8))
			draw_arc(pos + Vector2(0, -18), 9.0 + absf(flap) * 5.0, -0.6, 0.6, 10, Color(glow.r, glow.g, glow.b, 0.5), 1.5)
			draw_arc(pos + Vector2(0, -18), 16.0 + absf(flap) * 7.0, -0.5, 0.5, 12, Color(glow.r, glow.g, glow.b, 0.25), 1.0)
		"swarm":
			for i in range(7):
				var a := time * 0.9 + float(i) * 1.7
				draw_circle(pos + Vector2(cos(a) * (10.0 + i * 2.0), sin(a * 1.3) * (7.0 + i)), 2.3, Color(glow.r, glow.g, glow.b, 0.7))
		"heron":
			draw_circle(pos + Vector2(0, -8), 9.0, Color(c.r, c.g, c.b, 0.75))
			draw_line(pos + Vector2(6, 0), pos + Vector2(16, 2), Color(c.r, c.g, c.b, 0.7), 2.0)
			draw_line(pos + Vector2(-8, 8), pos + Vector2(-8, 24), Color(c.r, c.g, c.b, 0.55), 2.0)
			draw_line(pos + Vector2(6, 6), pos + Vector2(6, 24), Color(c.r, c.g, c.b, 0.55), 2.0)
		_:
			draw_circle(pos, 12.0, Color(c.r, c.g, c.b, 0.8))
			draw_circle(pos + Vector2(10, -8), 4.0, glow)

func _draw_player() -> void:
	var pos := session.player_pos
	if target.has("pos"):
		var target_pos: Vector2 = target.pos
		var radius := 30.0 + (0.0 if reduced_motion else sin(time * 2.0) * 3.0)
		draw_arc(target_pos, radius, -2.8, -1.6, 10, BtvTheme.AMBER, 2.0)
		draw_arc(target_pos, radius, 0.35, 1.55, 10, BtvTheme.AMBER, 2.0)
	draw_circle(pos + Vector2(0, 12), 17.0, Color(0, 0, 0, 0.32))
	if not reduced_motion:
		var pulse := fmod(_pulse_phase, 1.6) / 1.6
		draw_arc(pos, 20.0 + pulse * 26.0, 0.0, TAU, 30, Color(0.55, 0.95, 0.86, (1.0 - pulse) * 0.3), 1.5)
	draw_circle(pos, 11.0, Color("#d5e4df"))
	draw_circle(pos, 7.0, Color("#2e5a55"))
	var direction := last_facing if last_facing.length() > 0.1 else Vector2.DOWN
	draw_line(pos, pos + direction.normalized() * 18.0, BtvTheme.ACCENT, 3.0)
	draw_circle(pos + direction.normalized() * 18.0, 3.0, BtvTheme.ACCENT)

func _draw_surface_frame(accent: Color) -> void:
	var top := 100.0
	var bottom := size.y - 250.0
	for i in range(12):
		var alpha := 0.10 * (1.0 - float(i) / 12.0)
		draw_rect(Rect2(0, 0, size.x, top - i * 3), Color(0.01, 0.02, 0.03, alpha))
		draw_rect(Rect2(0, bottom + i * 3, size.x, size.y - bottom - i * 3), Color(0.01, 0.02, 0.03, alpha))
	draw_line(Vector2(18, size.y * 0.5), Vector2(18, size.y * 0.65), Color(accent.r, accent.g, accent.b, 0.22), 1.0)
	draw_line(Vector2(size.x - 18, size.y * 0.5), Vector2(size.x - 18, size.y * 0.65), Color(accent.r, accent.g, accent.b, 0.22), 1.0)

func _draw_target_label(scale: float, origin: Vector2) -> void:
	if not target.has("pos"):
		return
	var screen_pos := origin + (target.pos as Vector2) * scale
	var label := str(target.get("label", ""))
	if label.is_empty():
		return
	var width := 190.0
	var box := Rect2(screen_pos + Vector2(-width * 0.5, -62), Vector2(width, 26))
	draw_rect(box, Color(0.02, 0.04, 0.05, 0.78))
	draw_rect(box, Color(0.7, 0.9, 0.8, 0.35), false, 1.0)
	draw_string(ThemeDB.fallback_font, box.position + Vector2(8, 18), label, HORIZONTAL_ALIGNMENT_CENTER, width - 16, 12, BtvTheme.TEXT)

# ---------------------------------------------------------------------------
# Space

func _draw_space() -> void:
	if _visual.is_empty():
		_refresh_visual()
	var star_color := BtvTheme.color(_visual.get("star_color", "#e8b06a"))
	var nebula: Array = _visual.get("nebula", [0.2, 0.2, 0.2])
	draw_rect(Rect2(Vector2.ZERO, size), Color("#05080e"))
	_draw_space_nebula(nebula, star_color)
	var stars: Array = _visual.get("stars", [])
	for raw in stars:
		var s: Dictionary = raw
		var twinkle := 0.5 + 0.5 * sin(time * 0.5 + float(s.phase))
		draw_circle(Vector2(float(s.x) * size.x, float(s.y) * size.y), float(s.size) * 0.8, Color(0.8, 0.9, 1.0, float(s.bright) * twinkle))
	var center := Vector2(size.x * 0.5, size.y * 0.36)
	var star_radius := maxf(38.0, float(_visual.get("star_radius", 100)) * 0.42)
	for i in range(7, 0, -1):
		draw_circle(center, star_radius * (1.0 + float(i) * 0.42), Color(star_color.r, star_color.g, star_color.b, 0.018 * float(8 - i)))
	draw_circle(center, star_radius, star_color)
	draw_circle(center, star_radius * 0.68, star_color.lightened(0.35))
	var orbits: Dictionary = _visual.get("orbits", {})
	for planet_id in orbits.keys():
		var orbit: Dictionary = orbits[planet_id]
		var radius := float(orbit.radius)
		draw_arc(center, radius, 0.0, TAU, 96, Color(0.5, 0.7, 0.7, 0.1), 1.0)
		var planet = session.registry.get_planet(str(planet_id))
		var angle := float(orbit.angle) + (0.0 if reduced_motion else time * 0.012 / maxf(0.6, radius / 300.0))
		var position := center + Vector2(cos(angle), sin(angle)) * radius
		var planet_radius := maxf(12.0, float(orbit.size) * 0.65)
		draw_circle(position, planet_radius * 1.7, Color(0.5, 0.8, 0.8, 0.04))
		draw_circle(position, planet_radius, BtvTheme.color(planet.get("color", "#4d7f78")))
		draw_circle(position + Vector2(-planet_radius * 0.28, -planet_radius * 0.25), planet_radius * 0.36, Color(0.8, 0.95, 0.9, 0.18))
		draw_arc(position, planet_radius * 1.2, -1.2, 1.2, 18, Color(0.7, 0.95, 0.9, 0.2), 1.0)
		if str(planet_id) == selected_planet_id:
			draw_arc(position, planet_radius + 9.0, 0, TAU, 32, BtvTheme.AMBER, 2.0)
		var name := session.loc.t(str(planet.get("display_key", "")))
		draw_string(ThemeDB.fallback_font, position + Vector2(-70, planet_radius + 22), name, HORIZONTAL_ALIGNMENT_CENTER, 140, 12, Color(0.82, 0.92, 0.88, 0.8))
	_draw_orbit_ship(center)
	_draw_space_frame(star_color)

func _draw_space_nebula(nebula: Array, star_color: Color) -> void:
	var r := float(nebula[0]) if nebula.size() > 0 else 0.3
	var g := float(nebula[1]) if nebula.size() > 1 else 0.2
	var b := float(nebula[2]) if nebula.size() > 2 else 0.4
	for i in range(6):
		var center := Vector2(size.x * (0.18 + r * 0.7), size.y * (0.18 + g * 0.4 + float(i) * 0.09))
		var tint := Color(star_color.r * 0.2 + b * 0.4, star_color.g * 0.2 + b * 0.3, star_color.b * 0.2 + 0.5, 0.016)
		draw_circle(center, size.x * (0.3 + float(i) * 0.08), tint)

func _draw_orbit_ship(center: Vector2) -> void:
	var radius := 95.0
	var angle := -0.7 + (0.0 if reduced_motion else time * 0.03)
	var pos := center + Vector2(cos(angle), sin(angle)) * radius
	draw_line(center + Vector2(cos(angle), sin(angle)) * (radius - 30.0), pos, Color(0.4, 0.8, 0.72, 0.12), 1.0)
	draw_circle(pos, 4.0, BtvTheme.ACCENT)
	draw_line(pos, pos + Vector2(24, -8), Color(0.8, 0.95, 0.9, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(18, 22), "SKEIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.9, 0.85, 0.6))

func _draw_space_frame(star_color: Color) -> void:
	for i in range(10):
		var alpha := 0.09 * (1.0 - float(i) / 10.0)
		draw_rect(Rect2(0, 0, size.x, 100.0 - i * 4), Color(0, 0, 0, alpha))
		draw_rect(Rect2(0, size.y - 270.0 + i * 4, size.x, 270.0 - i * 4), Color(0, 0, 0, alpha))
	draw_circle(Vector2(size.x - 40, 140), 3.0, star_color)

# ---------------------------------------------------------------------------
# Input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
		accept_event()

func _handle_tap(screen_pos: Vector2) -> void:
	if session.mode == "space":
		var planet := planet_at_screen(screen_pos)
		if not planet.is_empty():
			planet_tapped.emit(str(planet.get("content_id", "")))
		return
	var world := screen_to_world(screen_pos)
	# Taps near a living thing select it; otherwise the tap is a walking order.
	var nearest := nearest_node(world, 70.0)
	if nearest.is_empty():
		tapped.emit(world)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	var scale := _surface_scale()
	var camera := _camera(scale)
	return (screen_pos - size * 0.5) / scale + camera

func world_to_screen(world_pos: Vector2) -> Vector2:
	var scale := _surface_scale()
	return (world_pos - _camera(scale)) * scale + size * 0.5

func nearest_node(point: Vector2, radius: float = 190.0) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius
	for raw in layout.get("nodes", []):
		var node: Dictionary = raw
		var distance := point.distance_to(Vector2(float(node.x), float(node.y)))
		if distance < best_distance:
			best_distance = distance
			best = node
	return best

func planet_at_screen(screen_pos: Vector2) -> Dictionary:
	if _visual.is_empty():
		return {}
	var center := Vector2(size.x * 0.5, size.y * 0.36)
	var orbits: Dictionary = _visual.get("orbits", {})
	for planet_id in orbits.keys():
		var orbit: Dictionary = orbits[planet_id]
		var radius := float(orbit.radius)
		var angle := float(orbit.angle) + (0.0 if reduced_motion else time * 0.012 / maxf(0.6, radius / 300.0))
		var position := center + Vector2(cos(angle), sin(angle)) * radius
		var planet_radius := maxf(12.0, float(orbit.size) * 0.65)
		if screen_pos.distance_to(position) <= planet_radius + 24.0:
			return session.registry.get_planet(str(planet_id))
	return {}

func _palette(planet: Dictionary) -> Array:
	var out: Array = []
	for value in planet.get("palette", []):
		out.append(BtvTheme.color(value, BtvTheme.ACCENT))
	if out.is_empty():
		out = [Color("#132326"), Color("#1c3a34"), Color("#24483e"), Color("#7fe0c2"), Color("#17332f"), Color("#eab676")]
	return out

func _species_palette(species: Dictionary) -> Array:
	var out: Array = []
	for value in species.get("palette", []):
		out.append(BtvTheme.color(value, BtvTheme.ACCENT))
	if out.is_empty():
		out = [BtvTheme.BG, BtvTheme.ACCENT, BtvTheme.AMBER]
	return out

func loc_name(species: Dictionary) -> String:
	return session.loc.t(str(species.get("display_key", "")))

func _density(base: int) -> int:
	match quality:
		"low": return maxi(4, int(base * 0.4))
		"high": return base
		"ultra": return int(base * 1.35)
		_: return int(base * 0.72)
