class_name BtvSurfaceWorld
extends Node2D

## Deterministic Vela surface: authored pixel ground, props, species nodes and anchors.
## Stage 1 uses a fixed 10x5 chunk region; Stage 3 turns this into a wrapping chunk stream.

const CHUNK := 512
const CHUNKS_X := 10
const CHUNKS_Y := 5
const WORLD_W := CHUNK * CHUNKS_X
const WORLD_H := CHUNK * CHUNKS_Y
const ANCHOR_OFFSET := Vector2(1280, 200)
const WATER_RECT := Rect2(3050, 1850, 560, 380)

var session: GameSession
var planet: Dictionary
var planet_id := ""
var spawn_point := Vector2(2430, 2080)
var nodes: Array[Dictionary] = []
var anchors: Array[Dictionary] = []
var props: Array[Dictionary] = []

var _seed := 0
var _noise := FastNoiseLite.new()
var _blockers: StaticBody2D
var _prop_root: Node2D
var _node_root: Node2D
var _anchor_root: Node2D
var _sway: Array[Dictionary] = []
var _time := 0.0

func setup(p_session: GameSession) -> void:
	session = p_session
	planet_id = session.planet_id
	planet = session.get_planet()
	_seed = WorldGen.stream_seed(session.world_seed, "surface2:" + planet_id)
	_noise.seed = _seed
	_noise.frequency = 0.0016
	_noise.fractal_octaves = 3
	y_sort_enabled = true
	_prop_root = _layer(-8)
	_node_root = _layer(0)
	_anchor_root = _layer(1)
	_blockers = StaticBody2D.new()
	_blockers.name = "Blockers"
	add_child(_blockers)
	_build_anchors()
	_build_ground()
	_build_water()
	_build_props()
	_build_nodes()
	_publish_layout()

func _layer(z: int) -> Node2D:
	var node := Node2D.new()
	node.y_sort_enabled = true
	node.z_index = z
	add_child(node)
	return node

func world_rect() -> Rect2:
	return Rect2(0, 0, WORLD_W, WORLD_H)

func spawn() -> Vector2:
	return spawn_point

func biome_at(world_pos: Vector2) -> String:
	if WATER_RECT.grow(40.0).has_point(world_pos):
		return "shore"
	var value := _noise.get_noise_2d(world_pos.x, world_pos.y)
	if value > 0.24:
		return "crystal"
	return "mist"

func _build_ground() -> void:
	for cy in range(CHUNKS_Y):
		for cx in range(CHUNKS_X):
			var origin := Vector2(cx * CHUNK, cy * CHUNK)
			var biome := biome_at(origin + Vector2(CHUNK * 0.5, CHUNK * 0.5))
			var sprite := Sprite2D.new()
			sprite.texture = BtvPixelSprites.ground_texture(biome, (cx * 7 + cy * 3) % 4)
			sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, CHUNK, CHUNK)
			sprite.centered = false
			sprite.position = origin
			sprite.z_index = -20
			sprite.modulate = _biome_tint(biome)
			add_child(sprite)

func _biome_tint(biome: String) -> Color:
	match biome:
		"crystal":
			return Color(0.92, 1.0, 1.06)
		"shore":
			return Color(1.06, 1.0, 0.92)
		_:
			return Color(0.88, 1.02, 0.98)

func _build_water() -> void:
	for vari in range(2):
		var water := Sprite2D.new()
		water.texture = BtvPixelSprites.water_texture(vari)
		water.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		water.region_enabled = true
		water.region_rect = Rect2(0, 0, WATER_RECT.size.x, WATER_RECT.size.y)
		water.centered = false
		water.position = WATER_RECT.position
		water.z_index = -9 if vari == 0 else -8
		water.modulate = Color(1, 1, 1, 0.92) if vari == 0 else Color(0.7, 0.95, 1.0, 0.35)
		add_child(water)
	_add_blocker(WATER_RECT.get_center(), WATER_RECT.size * 0.5, "water")

func _build_props() -> void:
	for cy in range(CHUNKS_Y):
		for cx in range(CHUNKS_X):
			var rng := WorldGen.rng_for(_seed, "chunk:%d:%d" % [cx, cy])
			var origin := Vector2(cx * CHUNK, cy * CHUNK)
			var biome := biome_at(origin + Vector2(CHUNK * 0.5, CHUNK * 0.5))
			var count := rng.randi_range(2, 4)
			for i in range(count):
				var pos := origin + Vector2(rng.randf_range(48.0, CHUNK - 48.0), rng.randf_range(48.0, CHUNK - 48.0))
				if _blocked_spot(pos):
					continue
				var kind := _prop_kind(biome, rng)
				_add_prop(kind, pos, rng)

func _prop_kind(biome: String, rng: RandomNumberGenerator) -> String:
	match biome:
		"crystal":
			return ["crystal", "crystal", "rock", "fern"][rng.randi_range(0, 3)]
		"shore":
			return ["rock", "kelp", "bell", "moss"][rng.randi_range(0, 3)]
		_:
			return ["fern", "kelp", "bell", "moss", "rock", "crystal"][rng.randi_range(0, 5)]

func _add_prop(kind: String, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = BtvPixelSprites.prop_texture(kind)
	sprite.position = pos
	sprite.scale = Vector2.ONE * rng.randf_range(1.4, 2.2)
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = Color(1, 1, 1, 0.96)
	_prop_root.add_child(sprite)
	var shadow := Sprite2D.new()
	shadow.texture = BtvPixelSprites.shadow_texture(18, 7)
	shadow.position = pos + Vector2(0, 2)
	shadow.scale = Vector2.ONE * sprite.scale.x * 0.8
	shadow.z_index = -1
	_prop_root.add_child(shadow)
	var entry := {"kind": kind, "pos": pos, "sprite": sprite}
	props.append(entry)
	match kind:
		"rock":
			_add_blocker(pos, Vector2(18, 12) * sprite.scale.x, "rock")
		"boulder":
			_add_blocker(pos, Vector2(26, 16) * sprite.scale.x, "rock")
		"crystal":
			_add_blocker(pos, Vector2(9, 9) * sprite.scale.x, "crystal")
	if kind == "kelp" or kind == "fern" or kind == "bell" or kind == "moss":
		_sway.append({"sprite": sprite, "phase": rng.randf_range(0.0, TAU), "amount": rng.randf_range(0.02, 0.06)})

func _add_blocker(pos: Vector2, half_size: Vector2, kind: String) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = half_size * 2.0
	shape.shape = rect
	shape.position = pos
	shape.set_meta("kind", kind)
	_blockers.add_child(shape)

func _blocked_spot(pos: Vector2) -> bool:
	if WATER_RECT.grow(70.0).has_point(pos):
		return true
	for anchor in anchors:
		if pos.distance_to(Vector2(anchor.get("pos", Vector2.ZERO))) < 150.0:
			return true
	return false

func _build_anchors() -> void:
	for raw in planet.get("anchors", []):
		var anchor: Dictionary = raw
		var pos := Vector2(float(anchor.get("x", 0)), float(anchor.get("y", 0))) + ANCHOR_OFFSET
		var entry := {
			"kind": str(anchor.get("kind", "")),
			"id": str(anchor.get("id", "")),
			"pos": pos,
			"raw": anchor,
		}
		anchors.append(entry)
		_build_anchor_visual(entry)
	var ship = _find_anchor("ship")
	if not ship.is_empty():
		spawn_point = Vector2(ship.pos) + Vector2(0, 150)

func _find_anchor(kind: String) -> Dictionary:
	for anchor in anchors:
		if str(anchor.get("kind", "")) == kind:
			return anchor
	return {}

func _build_anchor_visual(anchor: Dictionary) -> void:
	match str(anchor.get("kind", "")):
		"ship":
			_add_ship(anchor.pos, true)
		"npc":
			var npc := Sprite2D.new()
			npc.texture = BtvPixelSprites.player_texture("down", "idle", 0)
			npc.position = anchor.pos
			npc.offset = Vector2(0, -34)
			npc.scale = Vector2.ONE * 2.4
			npc.modulate = Color(1.0, 0.82, 0.62)
			npc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_anchor_root.add_child(npc)
			_add_shadow(anchor.pos)
			_add_blocker(anchor.pos, Vector2(14, 8), "npc")
		"market":
			_add_composed(BtvPixelSprites.prop_texture("canopy"), anchor.pos + Vector2(0, -64), 3.0)
			_add_composed(BtvPixelSprites.prop_texture("counter"), anchor.pos, 3.0)
			_add_shadow(anchor.pos, 1.6)
			_add_blocker(anchor.pos, Vector2(34, 14), "market")
		"relay":
			_add_composed(BtvPixelSprites.prop_texture("mast"), anchor.pos + Vector2(0, -58), 2.6)
			_add_composed(BtvPixelSprites.prop_texture("dish"), anchor.pos + Vector2(0, -126), 3.0)
			_add_shadow(anchor.pos, 1.2)
			_add_blocker(anchor.pos, Vector2(10, 10), "relay")
		"build_site":
			for row in range(2):
				for col in range(2):
					var pad := Sprite2D.new()
					pad.texture = BtvPixelSprites.prop_texture("plate")
					pad.position = anchor.pos + Vector2(col * 44 - 22, row * 44 - 22)
					pad.scale = Vector2.ONE * 3.2
					pad.modulate = Color(0.65, 0.85, 0.85, 0.55)
					_anchor_root.add_child(pad)
		"workbench":
			_add_composed(BtvPixelSprites.prop_texture("workbench"), anchor.pos, 3.0)
			_add_shadow(anchor.pos, 1.4)
			_add_blocker(anchor.pos, Vector2(54, 12), "workbench")

func _add_ship(pos: Vector2, wrecked: bool) -> void:
	var root := Node2D.new()
	root.position = pos
	root.y_sort_enabled = true
	var angles := [-0.18, 0.12, -0.05] if wrecked else [0.0, 0.0, 0.0]
	var offsets := [Vector2(-34, -26), Vector2(6, -18), Vector2(30, -40)] if wrecked else [Vector2(-30, -26), Vector2(4, -26), Vector2(34, -26)]
	for i in range(3):
		var plate := Sprite2D.new()
		plate.texture = BtvPixelSprites.prop_texture("plate")
		plate.position = offsets[i]
		plate.rotation = angles[i]
		plate.scale = Vector2.ONE * 4.6
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(plate)
	var engine := Sprite2D.new()
	engine.texture = BtvPixelSprites.prop_texture("engine")
	engine.position = Vector2(-78, -34)
	engine.scale = Vector2.ONE * 3.6
	engine.modulate = Color(1, 1, 1, 0.35 if wrecked else 1.0)
	root.add_child(engine)
	_anchor_root.add_child(root)
	_add_shadow(pos + Vector2(0, -6), 3.4)
	_add_blocker(pos, Vector2(64, 22), "ship")

func _add_composed(texture: Texture2D, pos: Vector2, scale_value: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2.ONE * scale_value
	sprite.offset = Vector2(0, -texture.get_height() * 0.5)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anchor_root.add_child(sprite)

func _add_shadow(pos: Vector2, scale_value: float = 1.0) -> void:
	var shadow := Sprite2D.new()
	shadow.texture = BtvPixelSprites.shadow_texture(22, 9)
	shadow.position = pos + Vector2(0, 2)
	shadow.scale = Vector2.ONE * scale_value
	shadow.z_index = -1
	_anchor_root.add_child(shadow)

func _build_nodes() -> void:
	var rng := WorldGen.rng_for(_seed, "species")
	var counts := {"flora": 3, "fauna": 2}
	var sequence := {"flora": 0, "fauna": 0}
	for raw_species in planet.get("species_pool", []):
		var species_id := str(raw_species)
		var species: Dictionary = session.registry.get_species(species_id)
		var kind := str(species.get("kind", "flora"))
		var copies := int(counts.get(kind, 2))
		for copy_index in range(copies):
			var near := copy_index == 0
			var pos := _find_species_point(rng, near)
			var node_id := "%s.%s.%02d" % [planet_id, kind, int(sequence.get(kind, 0))]
			sequence[kind] = int(sequence.get(kind, 0)) + 1
			var sprite := Sprite2D.new()
			sprite.texture = _species_texture(species, copy_index)
			sprite.position = pos
			var size_scale := 1.7
			if kind == "fauna":
				size_scale = 1.9
			sprite.scale = Vector2.ONE * size_scale
			sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5 * size_scale) / size_scale
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.set_meta("species_id", species_id)
			_node_root.add_child(sprite)
			_add_node_shadow(pos, kind)
			var entry := {
				"node_id": node_id, "kind": kind, "species_id": species_id,
				"pos": pos, "sprite": sprite, "species": species,
				"item_id": str(species.get("harvest", {}).get("item_id", "")),
				"amount": int(species.get("harvest", {}).get("amount", 1)),
			}
			nodes.append(entry)
			if kind == "flora":
				_sway.append({"sprite": sprite, "phase": rng.randf_range(0.0, TAU), "amount": rng.randf_range(0.015, 0.04)})
			else:
				_sway.append({"sprite": sprite, "phase": rng.randf_range(0.0, TAU), "amount": 0.0, "bob": true})

func _species_texture(species: Dictionary, variant: int) -> Texture2D:
	if str(species.get("kind", "")) == "fauna":
		var plan := str(species.get("body_plan", ""))
		if plan == "manta":
			return BtvPixelSprites.prop_texture("manta")
		if plan == "grazer":
			return BtvPixelSprites.prop_texture("grazer")
		return BtvPixelSprites.prop_texture("drone")
	var body := str(species.get("body_plan", ""))
	match body:
		"bell":
			return BtvPixelSprites.prop_texture("bell")
		"mat":
			return BtvPixelSprites.prop_texture("moss")
		"reed", "kelp", "frond":
			return BtvPixelSprites.prop_texture("kelp")
		_:
			return BtvPixelSprites.prop_texture("fern" if variant % 2 == 0 else "moss")

func _add_node_shadow(pos: Vector2, kind: String) -> void:
	var shadow := Sprite2D.new()
	shadow.texture = BtvPixelSprites.shadow_texture(20, 8)
	shadow.position = pos + Vector2(0, 2)
	shadow.scale = Vector2.ONE * (1.4 if kind == "flora" else 1.8)
	shadow.z_index = -1
	_node_root.add_child(shadow)

func _find_species_point(rng: RandomNumberGenerator, near_spawn: bool) -> Vector2:
	for attempt in range(120):
		var pos: Vector2
		if near_spawn:
			var angle := rng.randf_range(0.0, TAU)
			pos = spawn_point + Vector2(cos(angle), sin(angle)) * rng.randf_range(220.0, 420.0)
		else:
			pos = Vector2(rng.randf_range(300.0, WORLD_W - 300.0), rng.randf_range(260.0, WORLD_H - 260.0))
		if pos.x < 80 or pos.y < 80 or pos.x > WORLD_W - 80 or pos.y > WORLD_H - 80:
			continue
		if WATER_RECT.grow(90.0).has_point(pos):
			continue
		var clear := true
		for anchor in anchors:
			if pos.distance_to(Vector2(anchor.get("pos", Vector2.ZERO))) < 180.0:
				clear = false
				break
		for existing in nodes:
			if pos.distance_to(Vector2(existing.get("pos", Vector2.ZERO))) < 90.0:
				clear = false
				break
		if clear:
			return pos
	return spawn_point + Vector2(rng.randf_range(-300.0, 300.0), rng.randf_range(-260.0, 260.0))

func _publish_layout() -> void:
	session.surface_cache = {
		"planet_id": planet_id,
		"world_size": WORLD_W,
		"nodes": nodes,
		"anchors": anchors,
		"start_pos": [spawn_point.x, spawn_point.y],
	}

func node_at(node_id: String) -> Dictionary:
	for entry in nodes:
		if str(entry.get("node_id", "")) == node_id:
			return entry
	return {}

func nearest_node(pos: Vector2, max_distance: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := max_distance
	for entry in nodes:
		var distance := pos.distance_to(Vector2(entry.get("pos", Vector2.ZERO)))
		if distance < best_distance:
			best = entry
			best_distance = distance
	return best

func nearest_anchor(pos: Vector2, max_distance: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := max_distance
	for entry in anchors:
		if str(entry.get("kind", "")) == "build_site":
			continue
		var distance := pos.distance_to(Vector2(entry.get("pos", Vector2.ZERO)))
		if distance < best_distance:
			best = entry
			best_distance = distance
	return best

func set_node_depleted(node_id: String, depleted: bool) -> void:
	var entry := node_at(node_id)
	var sprite: Sprite2D = entry.get("sprite", null)
	if sprite == null:
		return
	sprite.modulate = Color(0.45, 0.5, 0.5, 0.55) if depleted else Color(1, 1, 1, 1)

func _process(delta: float) -> void:
	_time += delta
	for item in _sway:
		var sprite: Sprite2D = item.get("sprite", null)
		if sprite == null or not is_instance_valid(sprite):
			continue
		var phase := float(item.get("phase", 0.0))
		var amount := float(item.get("amount", 0.0))
		if bool(item.get("bob", false)):
			sprite.position.y += sin(_time * 1.3 + phase) * 0.04
		elif amount > 0.0:
			sprite.rotation = sin(_time * 1.1 + phase) * amount
