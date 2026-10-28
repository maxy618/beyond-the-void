class_name BtvCombatDirector
extends Node2D

## Stage 1 combat: deterministic hostile pickets, player bolts and hostile bolts.
## Visuals stay in this node; damage routes through BtvPlayer.take_damage().

signal aggro_changed(active: bool)
signal hostile_killed(kind: String)

const AGGRO_RADIUS := 340.0
const DRONE_KEEP_MIN := 140.0
const DRONE_KEEP_MAX := 240.0
const DRONE_SPEED := 34.0
const STALKER_SPEED := 62.0
const PLAYER_BOLT_SPEED := 430.0
const HOSTILE_BOLT_SPEED := 230.0
const PLAYER_BOLT_DAMAGE := 18.0
const HOSTILE_BOLT_DAMAGE := 7.0
const PLAYER_BOLT_RADIUS := 15.0
const HOSTILE_BOLT_RADIUS := 13.0

var player: BtvPlayer
var world: BtvSurfaceWorld
var hostiles: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var paused := false

var _time := 0.0
var _aggro := false

func setup(p_player: BtvPlayer, p_world: BtvSurfaceWorld, p_seed: int) -> void:
	player = p_player
	world = p_world
	for entry in plan_hostiles(p_seed, player.position, world.world_rect()):
		_spawn_hostile(str(entry.get("kind", "drone")), Vector2(entry.get("pos", player.position)))

func plan_hostiles(seed_value: int, spawn: Vector2, bounds: Rect2) -> Array[Dictionary]:
	return plan_hostiles_static(seed_value, spawn, bounds)

static func plan_hostiles_static(seed_value: int, spawn: Vector2, bounds: Rect2) -> Array[Dictionary]:
	var rng := WorldGen.rng_for(seed_value, "combat")
	var kinds := ["drone", "drone", "stalker"]
	var out: Array[Dictionary] = []
	for index in range(kinds.size()):
		var pos := spawn
		for _attempt in range(24):
			var angle := rng.randf_range(0.0, TAU)
			var radius := rng.randf_range(220.0, 320.0)
			pos = spawn + Vector2(cos(angle), sin(angle)) * radius
			pos.x = clampf(pos.x, bounds.position.x + 60.0, bounds.end.x - 60.0)
			pos.y = clampf(pos.y, bounds.position.y + 60.0, bounds.end.y - 60.0)
			if not BtvSurfaceWorld.WATER_RECT.grow(40.0).has_point(pos):
				break
		out.append({"kind": kinds[index], "pos": pos})
	return out

func _spawn_hostile(kind: String, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = BtvPixelSprites.prop_texture("drone")
	sprite.scale = Vector2.ONE * (2.2 if kind == "drone" else 2.6)
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 4
	add_child(sprite)
	var shadow := Sprite2D.new()
	shadow.texture = BtvPixelSprites.shadow_texture(16, 6)
	shadow.position = pos + Vector2(0, 2)
	shadow.scale = Vector2.ONE * 1.6
	shadow.z_index = 3
	add_child(shadow)
	var tint := Color(1.0, 1.0, 1.0) if kind == "drone" else Color(1.0, 0.58, 0.48)
	hostiles.append({
		"kind": kind,
		"pos": pos,
		"home": pos,
		"health": 42.0 if kind == "drone" else 58.0,
		"max_health": 42.0 if kind == "drone" else 58.0,
		"shoot_timer": 1.2 if kind == "drone" else 0.0,
		"contact_timer": 0.0,
		"flash": 0.0,
		"sprite": sprite,
		"shadow": shadow,
		"tint": tint,
		"phase": 0.0,
		"alive": true,
	})

func _process(delta: float) -> void:
	if player == null or world == null or not is_instance_valid(player):
		return
	if paused or not player.alive:
		return
	_time += delta
	_update_hostiles(delta)
	_update_bolts(delta)
	_update_aggro()

func _update_hostiles(delta: float) -> void:
	for index in range(hostiles.size() - 1, -1, -1):
		var h: Dictionary = hostiles[index]
		if not bool(h.get("alive", false)):
			continue
		var pos: Vector2 = h.get("pos", Vector2.ZERO)
		var to_player := player.hit_center() - pos
		var distance := to_player.length()
		var direction := to_player / maxf(distance, 0.001)
		var move := Vector2.ZERO
		if str(h.get("kind", "drone")) == "drone":
			if distance > DRONE_KEEP_MAX:
				move = direction
			elif distance < DRONE_KEEP_MIN:
				move = -direction
			else:
				move = direction.orthogonal() * sin(_time * 0.9 + float(h.get("phase", 0.0)))
			var shoot := float(h.get("shoot_timer", 0.0)) - delta
			if shoot <= 0.0 and distance < 320.0:
				shoot = 1.7
				_spawn_bolt(pos + Vector2(0, -12), direction, HOSTILE_BOLT_SPEED, HOSTILE_BOLT_DAMAGE, true)
			h["shoot_timer"] = shoot
		else:
			if distance > 26.0:
				move = direction
			var contact := float(h.get("contact_timer", 0.0)) - delta
			if distance < 30.0 and contact <= 0.0:
				contact = 1.0
				player.take_damage(9.0)
				_sfx("hit", -6.0)
			h["contact_timer"] = contact
		pos += move * (DRONE_SPEED if str(h.get("kind", "drone")) == "drone" else STALKER_SPEED) * delta
		var bounds := world.world_rect().grow(-40.0)
		pos.x = clampf(pos.x, bounds.position.x, bounds.end.x)
		pos.y = clampf(pos.y, bounds.position.y, bounds.end.y)
		h["pos"] = pos
		var flash := maxf(0.0, float(h.get("flash", 0.0)) - delta)
		h["flash"] = flash
		var sprite: Sprite2D = h.get("sprite", null)
		var shadow: Sprite2D = h.get("shadow", null)
		if sprite != null:
			var bob := sin(_time * 2.0 + float(h.get("phase", 0.0))) * 2.0
			sprite.position = pos + (Vector2(0, -10 + bob) if str(h.get("kind", "")) == "drone" else Vector2.ZERO)
			var base_tint: Color = h.get("tint", Color.WHITE)
			sprite.modulate = Color(1.0, 0.55, 0.5) if flash > 0.0 else base_tint
		if shadow != null:
			shadow.position = pos + Vector2(0, 2)
		h["phase"] = float(h.get("phase", 0.0)) + delta

func _update_bolts(delta: float) -> void:
	for index in range(bolts.size() - 1, -1, -1):
		var bolt: Dictionary = bolts[index]
		var velocity: Vector2 = bolt.get("velocity", Vector2.ZERO)
		var pos: Vector2 = bolt.get("pos", Vector2.ZERO) + velocity * delta
		bolt["pos"] = pos
		bolt["life"] = float(bolt.get("life", 0.0)) - delta
		var line: Line2D = bolt.get("line", null)
		if line != null:
			line.points = PackedVector2Array([pos - velocity.normalized() * 6.0, pos])
		var remove := float(bolt.get("life", 0.0)) <= 0.0
		if not remove and not world.world_rect().grow(40.0).has_point(pos):
			remove = true
		if not remove and bool(bolt.get("hostile", false)):
			if pos.distance_to(player.hit_center()) < HOSTILE_BOLT_RADIUS:
				player.take_damage(float(bolt.get("damage", HOSTILE_BOLT_DAMAGE)))
				remove = true
		elif not remove:
			for hostile_index in range(hostiles.size() - 1, -1, -1):
				var h: Dictionary = hostiles[hostile_index]
				if not bool(h.get("alive", false)):
					continue
				if pos.distance_to(Vector2(h.get("pos", Vector2.ZERO)) + Vector2(0, -10)) < PLAYER_BOLT_RADIUS:
					_damage_hostile(hostile_index, float(bolt.get("damage", PLAYER_BOLT_DAMAGE)))
					remove = true
					break
		if remove:
			_remove_bolt(index)

func _damage_hostile(index: int, amount: float) -> void:
	var h: Dictionary = hostiles[index]
	h["health"] = float(h.get("health", 0.0)) - amount
	h["flash"] = 0.13
	if float(h.get("health", 0.0)) > 0.0:
		return
	h["alive"] = false
	var sprite: Sprite2D = h.get("sprite", null)
	var shadow: Sprite2D = h.get("shadow", null)
	if sprite != null:
		sprite.queue_free()
	if shadow != null:
		shadow.queue_free()
	var kind := str(h.get("kind", "hostile"))
	hostiles.remove_at(index)
	_sfx("explosion", -4.0)
	hostile_killed.emit(kind)

func _spawn_bolt(from: Vector2, direction: Vector2, speed: float, damage: float, hostile: bool) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(1.0, 0.42, 0.32) if hostile else Color(0.45, 0.94, 1.0)
	line.z_index = 8
	line.points = PackedVector2Array([from, from + direction * 6.0])
	add_child(line)
	bolts.append({
		"pos": from,
		"velocity": direction.normalized() * speed,
		"damage": damage,
		"hostile": hostile,
		"life": 2.4 if hostile else 1.1,
		"line": line,
	})

func _remove_bolt(index: int) -> void:
	var bolt: Dictionary = bolts[index]
	var line: Line2D = bolt.get("line", null)
	if line != null:
		line.queue_free()
	bolts.remove_at(index)

func fire_player(from: Vector2, direction: Vector2) -> void:
	if paused or player == null or not player.alive:
		return
	_spawn_bolt(from, direction, PLAYER_BOLT_SPEED, PLAYER_BOLT_DAMAGE, false)

func clear_bolts() -> void:
	for bolt in bolts:
		var line: Line2D = bolt.get("line", null)
		if line != null:
			line.queue_free()
	bolts.clear()

func set_paused(value: bool) -> void:
	paused = value

func _update_aggro() -> void:
	var active := false
	for h in hostiles:
		if bool(h.get("alive", false)) and Vector2(h.get("pos", Vector2.ZERO)).distance_to(player.position) < AGGRO_RADIUS:
			active = true
			break
	if active != _aggro:
		_aggro = active
		aggro_changed.emit(active)

func _sfx(id: String, volume_db: float = 0.0) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play(id, volume_db)
