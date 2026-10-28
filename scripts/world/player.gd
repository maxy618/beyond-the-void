class_name BtvPlayer
extends CharacterBody2D

## Player motion: walk, sprint with stamina, jetpack with energy and altitude, aim facing.
## The domain session owns progression; this node owns only physical/feel state.

signal landed
signal damaged(amount: float)
signal died
signal exhausted_changed(exhausted: bool)
signal footstep(material: String)
signal fired

const WALK_SPEED := 96.0
const SPRINT_MULT := 1.65
const ACCEL := 900.0
const FRICTION := 1200.0
const STAMINA_MAX := 100.0
const STAMINA_DRAIN := 24.0
const STAMINA_REGEN := 17.0
const STAMINA_RECOVER_AT := 28.0
const ENERGY_MAX := 100.0
const ENERGY_DRAIN := 26.0
const ENERGY_REGEN := 15.0
const JET_RISE := 118.0
const JET_FALL := 96.0
const ALTITUDE_MAX := 46.0
const JET_COOLDOWN := 2.4
const FIRE_COOLDOWN := 0.28
const SPRITE_SCALE := 3.0

var input_dir := Vector2.ZERO
var aim_dir := Vector2.DOWN
var aim_active := false
var sprint_requested := false
var sprint_toggle := false
var jet_requested := false
var jet_toggle := false
var stamina := STAMINA_MAX
var energy := ENERGY_MAX
var exhausted := false
var altitude := 0.0
var jetting := false
var mining := false
var combat := false
var health := 100.0
var max_health := 100.0
var shield := 50.0
var max_shield := 50.0
var alive := true
var facing := "down"
var moving := false
var sprinting := false
var world_bounds := Rect2()
var footstep_material := "grass"

var _sprite: Sprite2D
var _shadow: Sprite2D
var _walk_phase := 0.0
var _jet_cooldown := 0.0
var _energy_delay := 0.0
var _stamina_delay := 0.0
var _time := 0.0
var _hurt_flash := 0.0
var _step_timer := 0.0
var _was_jetting := false
var _fire_cooldown := 0.0
var _combat_timer := 0.0

func setup(bounds: Rect2) -> void:
	world_bounds = bounds
	collision_layer = 1
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_shadow = Sprite2D.new()
	_shadow.texture = BtvPixelSprites.shadow_texture(24, 10)
	_shadow.scale = Vector2.ONE * 1.5
	_shadow.z_index = -1
	_shadow.modulate = Color(0.1, 0.15, 0.16, 0.55)
	add_child(_shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = BtvPixelSprites.player_texture("down", "idle", 0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * SPRITE_SCALE
	# 24x30 texture: -15 px offset puts the boots exactly on the node origin.
	_sprite.offset = Vector2(0, -15)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 7.0
	capsule.height = 20.0
	shape.shape = capsule
	shape.position = Vector2(0, -10)
	add_child(shape)
	_update_visual()

func muzzle() -> Vector2:
	return position + Vector2(0, -45.0 - altitude) + aim_dir * 16.0

func center() -> Vector2:
	return position + Vector2(0, -44.0 - altitude)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	_time += delta
	_jet_cooldown = maxf(0.0, _jet_cooldown - delta)
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_combat_timer = maxf(0.0, _combat_timer - delta)
	combat = _combat_timer > 0.0
	_update_sprint(delta)
	_update_jetpack(delta)
	_move(delta)
	_update_steps(delta)
	_update_visual()

func _update_steps(delta: float) -> void:
	if not moving or altitude > 0.5:
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = 0.26 if sprinting else 0.38
		footstep.emit("sprint.step" if sprinting else "step." + footstep_material)

func _update_sprint(delta: float) -> void:
	var wants := sprint_requested or sprint_toggle
	var input_strength := input_dir.length()
	sprinting = wants and not exhausted and input_strength > 0.2 and stamina > 0.0
	if sprinting:
		stamina = maxf(0.0, stamina - STAMINA_DRAIN * delta)
		_stamina_delay = 0.9
		if stamina <= 0.0 and not exhausted:
			exhausted = true
			exhausted_changed.emit(true)
	else:
		_stamina_delay = maxf(0.0, _stamina_delay - delta)
		if _stamina_delay <= 0.0:
			stamina = minf(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
	if exhausted and stamina >= STAMINA_RECOVER_AT:
		exhausted = false
		exhausted_changed.emit(false)

func _update_jetpack(delta: float) -> void:
	var wants := jet_requested or jet_toggle
	var was_airborne := altitude > 0.5
	if wants and energy > 0.5 and _jet_cooldown <= 0.0:
		jetting = true
		altitude = minf(ALTITUDE_MAX, altitude + JET_RISE * delta)
		energy = maxf(0.0, energy - ENERGY_DRAIN * delta)
		_energy_delay = 0.8
		if energy <= 0.0:
			_jet_cooldown = JET_COOLDOWN
	else:
		jetting = false
		if altitude > 0.0:
			altitude = maxf(0.0, altitude - JET_FALL * delta)
		_energy_delay = maxf(0.0, _energy_delay - delta)
		if altitude <= 0.0 and _energy_delay <= 0.0:
			energy = minf(ENERGY_MAX, energy + ENERGY_REGEN * delta)
	if was_airborne and altitude <= 0.5 and not jetting:
		landed.emit()
	if jetting != _was_jetting:
		_was_jetting = jetting
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			if jetting:
				audio.play("jetpack.ignite")
				audio.start_loop("jetpack.loop", 0.2)
			else:
				audio.stop_loop("jetpack.loop", 0.25)

func _move(delta: float) -> void:
	var direction := input_dir.limit_length(1.0)
	moving = direction.length() > 0.08
	var target_speed := WALK_SPEED * (SPRINT_MULT if sprinting else 1.0)
	if moving:
		velocity = velocity.move_toward(direction * target_speed, ACCEL * delta)
		if not aim_active:
			_update_facing(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
	if world_bounds.size.x > 0.0:
		position.x = clampf(position.x, world_bounds.position.x + 18.0, world_bounds.end.x - 18.0)
		position.y = clampf(position.y, world_bounds.position.y + 18.0, world_bounds.end.y - 18.0)

func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x > 0.0 else "left"
	else:
		facing = "down" if direction.y >= 0.0 else "up"

func set_aim(direction: Vector2, active: bool) -> void:
	aim_active = active and direction.length() > 0.01
	if aim_active:
		aim_dir = direction.normalized()
		_update_facing(aim_dir)

func track_aim(direction: Vector2) -> void:
	if direction.length() > 0.01:
		aim_dir = direction.normalized()
		_update_facing(aim_dir)

func try_fire() -> bool:
	if not alive or _fire_cooldown > 0.0:
		return false
	_fire_cooldown = FIRE_COOLDOWN
	_combat_timer = 0.16
	combat = true
	fired.emit()
	return true

func hit_center() -> Vector2:
	return position + Vector2(0, -22.0 - altitude)

func _update_visual() -> void:
	if _sprite == null:
		return
	_hurt_flash = maxf(0.0, _hurt_flash - get_physics_process_delta_time())
	var pose := "idle"
	if jetting or altitude > 0.5:
		pose = "jetpack"
	elif combat:
		pose = "combat"
	elif mining:
		pose = "mine"
	elif moving:
		pose = "walk"
	var frame := 0
	if pose == "walk":
		_walk_phase += get_physics_process_delta_time() * (8.0 if sprinting else 5.5)
		frame = int(_walk_phase) % 4
	var texture := BtvPixelSprites.player_texture(facing, pose, frame)
	if _sprite.texture != texture:
		_sprite.texture = texture
	_sprite.flip_h = false
	_sprite.position.y = -altitude
	_shadow.position.y = 0
	_shadow.scale = Vector2.ONE * (1.5 - altitude * 0.006)
	_shadow.modulate.a = 0.55 - altitude * 0.004
	if _hurt_flash > 0.0:
		_sprite.modulate = Color(1.0, 0.55, 0.55)
	else:
		_sprite.modulate = Color.WHITE

func take_damage(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	_hurt_flash = 0.18
	var remaining := amount
	if shield > 0.0:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0.0:
		health = maxf(0.0, health - remaining)
	damaged.emit(amount)
	if health <= 0.0:
		alive = false
		velocity = Vector2.ZERO
		died.emit()

func revive(at: Vector2) -> void:
	alive = true
	position = at
	velocity = Vector2.ZERO
	health = max_health
	shield = max_shield
	stamina = STAMINA_MAX
	energy = ENERGY_MAX
	altitude = 0.0
	jetting = false
	exhausted = false
	_fire_cooldown = 0.0
	_combat_timer = 0.0
	combat = false
	if _sprite != null:
		_sprite.modulate = Color.WHITE

func status() -> Dictionary:
	return {
		"pos": [position.x, position.y],
		"altitude": altitude,
		"stamina": stamina,
		"energy": energy,
		"exhausted": exhausted,
		"sprinting": sprinting,
		"jetting": jetting,
		"health": health,
		"shield": shield,
		"facing": facing,
		"moving": moving,
		"alive": alive,
	}
