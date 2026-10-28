class_name BtvGameScreen
extends Control

## Field screen: pixel world in a low-resolution SubViewport, native-resolution HUD.
## The domain session owns state; this screen presents it and routes player intent.

signal exit_to_menu
signal settings_changed

const VIEW_SIZE := Vector2(360, 640)
const TARGET_INTERVAL := 0.12
const AUTOSAVE_INTERVAL := 45.0

var session: GameSession
var loc: Localization
var input_state := InputState.new()
var world: BtvSurfaceWorld
var player: BtvPlayer
var director: BtvCameraDirector
var combat: BtvCombatDirector

var _viewport: SubViewport
var _viewport_container: SubViewportContainer
var _world_root: Node2D
var _ui: Control
var _move_stick: BtvTouchStick
var _aim_stick: BtvTouchStick
var _status: Label
var _objective: Label
var _hint: Label
var _stamina: ProgressBar
var _energy: ProgressBar
var _health: ProgressBar
var _shield: ProgressBar
var _stamina_caption: Label
var _energy_caption: Label
var _health_caption: Label
var _shield_caption: Label
var _pack_button: Button
var _log_button: Button
var _use_button: Button
var _interact_button: Button
var _fire_button: Button
var _sprint_button: Button
var _jet_button: Button
var _tool_button: Button
var _menu_button: Button
var _beam: Line2D
var _reticle: Sprite2D
var _panel: BtvPanelBase
var _pause_layer: Control
var _target: Dictionary = {}
var _anchor: Dictionary = {}
var _target_timer := 0.0
var _hud_timer := 0.0
var _beam_timer := 0.0
var _hint_timer := 0.0
var _aim_vector := Vector2.RIGHT
var _stick_move := Vector2.ZERO
var _sprint_toggle := false
var _jet_toggle := false
var _dying := false
var _respawn_timer := 0.0
var _fire_held := false
var _ambience_timer := 0.0
var _ambient := ""
var _discovery_timer := 0.0
var _mining_audio := false
var _autosave_timer := AUTOSAVE_INTERVAL

func setup(p_session: GameSession) -> void:
	session = p_session
	loc = session.loc
	if session.planet_id.is_empty() or session.mode != "planet":
		session.land_on("planet.vela")
	_build_world()
	_build_ui()
	session.changed.connect(_on_session_changed)
	session.toast_requested.connect(_on_toast)
	_bind_audio(_ui)
	_update_hud()
	_start_explore_music.call_deferred()

func _start_explore_music() -> void:
	var audio := _audio()
	if audio != null:
		audio.music.force_state("EXPLORE_CALM")

func _build_world() -> void:
	_viewport_container = SubViewportContainer.new()
	_viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_container.stretch = true
	_viewport_container.stretch_shrink = 2
	_viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_viewport_container)

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(VIEW_SIZE)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_viewport.handle_input_locally = false
	_viewport_container.add_child(_viewport)

	_world_root = Node2D.new()
	_viewport.add_child(_world_root)

	world = BtvSurfaceWorld.new()
	_world_root.add_child(world)
	world.setup(session)

	player = BtvPlayer.new()
	player.position = world.spawn()
	player.setup(world.world_rect())
	_world_root.add_child(player)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	player.footstep.connect(_on_footstep)
	player.landed.connect(_on_landed)

	director = BtvCameraDirector.new()
	_world_root.add_child(director)
	director.setup(player, world.world_rect())
	director.set_viewport_size(VIEW_SIZE)
	director.shake_scale = float(session.settings.get("screen_shake", 1.0))
	director.reduced_motion = bool(session.settings.get("reduced_motion", false))

	combat = BtvCombatDirector.new()
	_world_root.add_child(combat)
	combat.setup(player, world, session.world_seed)
	combat.aggro_changed.connect(_on_combat_aggro)

	_beam = Line2D.new()
	_beam.width = 2.0
	_beam.default_color = BtvTheme.ACCENT
	_beam.z_index = 40
	_beam.visible = false
	_world_root.add_child(_beam)

	_reticle = Sprite2D.new()
	_reticle.texture = BtvPixelSprites.prop_texture("reticle")
	_reticle.scale = Vector2(1.6, 1.6)
	_reticle.z_index = 45
	_reticle.visible = false
	_world_root.add_child(_reticle)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(_ui)

	var top := PanelContainer.new()
	top.position = Vector2(14, 12)
	top.size = Vector2(692, 158)
	top.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL, 8, BtvTheme.LINE, 1))
	_ui.add_child(top)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 3)
	top.add_child(top_box)
	_status = BtvTheme.label("", 17, BtvTheme.TEXT)
	top_box.add_child(_status)
	_objective = BtvTheme.label("", 13, BtvTheme.TEXT_DIM)
	top_box.add_child(_objective)
	var bar_caps := HBoxContainer.new()
	bar_caps.add_theme_constant_override("separation", 8)
	_stamina_caption = BtvTheme.label("STAMINA", 10, BtvTheme.TEXT_FAINT)
	_stamina_caption.custom_minimum_size.x = 190
	_energy_caption = BtvTheme.label("ENERGY", 10, BtvTheme.TEXT_FAINT)
	_energy_caption.custom_minimum_size.x = 190
	bar_caps.add_child(_stamina_caption)
	bar_caps.add_child(_energy_caption)
	top_box.add_child(bar_caps)
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 8)
	top_box.add_child(bars)
	_stamina = _bar(BtvTheme.ACCENT)
	_energy = _bar(BtvTheme.AMBER)
	bars.add_child(_stamina)
	bars.add_child(_energy)
	var defense_caps := HBoxContainer.new()
	defense_caps.add_theme_constant_override("separation", 8)
	_health_caption = BtvTheme.label("HULL", 10, BtvTheme.TEXT_FAINT)
	_health_caption.custom_minimum_size.x = 190
	_shield_caption = BtvTheme.label("SHIELD", 10, BtvTheme.TEXT_FAINT)
	_shield_caption.custom_minimum_size.x = 190
	defense_caps.add_child(_health_caption)
	defense_caps.add_child(_shield_caption)
	top_box.add_child(defense_caps)
	var defense := HBoxContainer.new()
	defense.add_theme_constant_override("separation", 8)
	top_box.add_child(defense)
	_health = _bar(BtvTheme.DANGER)
	_shield = _bar(BtvTheme.BLUE)
	defense.add_child(_health)
	defense.add_child(_shield)

	_hint = BtvTheme.wrapped("", 14, BtvTheme.TEXT_DIM)
	_hint.position = Vector2(27, 1010)
	_hint.size = Vector2(666, 60)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui.add_child(_hint)

	_move_stick = _make_stick("MOVE", BtvTheme.ACCENT)
	_move_stick.position = Vector2(18, 1082)
	_ui.add_child(_move_stick)
	_move_stick.changed.connect(_on_move_stick)

	_aim_stick = _make_stick("AIM", BtvTheme.AMBER)
	_aim_stick.position = Vector2(526, 1082)
	_ui.add_child(_aim_stick)
	_aim_stick.changed.connect(_on_aim_stick)

	_use_button = BtvTheme.button("USE", 92)
	_use_button.position = Vector2(536, 900)
	_use_button.size = Vector2(136, 92)
	_ui.add_child(_use_button)
	_use_button.button_down.connect(_on_use_down)
	_use_button.button_up.connect(_on_use_up)

	_interact_button = BtvTheme.button("INTERACT", 92)
	_interact_button.position = Vector2(376, 900)
	_interact_button.size = Vector2(148, 92)
	_ui.add_child(_interact_button)
	_interact_button.pressed.connect(_on_interact)

	_fire_button = BtvTheme.button("FIRE", 92)
	_fire_button.position = Vector2(376, 794)
	_fire_button.size = Vector2(148, 92)
	_ui.add_child(_fire_button)
	_fire_button.button_down.connect(_on_fire_down)
	_fire_button.button_up.connect(_on_fire_up)

	_sprint_button = BtvTheme.button("SPRINT", 58)
	_sprint_button.position = Vector2(608, 828)
	_sprint_button.size = Vector2(96, 58)
	_sprint_button.toggle_mode = true
	_ui.add_child(_sprint_button)
	_sprint_button.toggled.connect(_on_sprint_toggled)

	_jet_button = BtvTheme.button("JET", 58)
	_jet_button.position = Vector2(608, 762)
	_jet_button.size = Vector2(96, 58)
	_jet_button.toggle_mode = true
	_ui.add_child(_jet_button)
	_jet_button.toggled.connect(_on_jet_toggled)

	_tool_button = BtvTheme.button("SCAN", 54)
	_tool_button.position = Vector2(14, 762)
	_tool_button.size = Vector2(112, 54)
	_ui.add_child(_tool_button)
	_tool_button.pressed.connect(_cycle_tool)

	_menu_button = BtvTheme.button("MENU", 54)
	_menu_button.position = Vector2(14, 828)
	_menu_button.size = Vector2(112, 54)
	_ui.add_child(_menu_button)
	_menu_button.pressed.connect(_toggle_pause)

	_pack_button = BtvTheme.button("PACK", 40)
	_pack_button.position = Vector2(516, 178)
	_pack_button.size = Vector2(88, 46)
	_ui.add_child(_pack_button)
	_pack_button.pressed.connect(_open_inventory)

	_log_button = BtvTheme.button("LOG", 40)
	_log_button.position = Vector2(612, 178)
	_log_button.size = Vector2(88, 46)
	_ui.add_child(_log_button)
	_log_button.pressed.connect(_open_journal)

	# Gameplay keys (Space/Enter) must never activate a focused HUD button.
	for button in [_use_button, _interact_button, _fire_button, _sprint_button, _jet_button, _tool_button, _menu_button, _pack_button, _log_button]:
		button.focus_mode = Control.FOCUS_NONE

	_build_pause()
	_layout_controls()
	resized.connect(_layout_controls)
	_apply_control_prefs()

func _layout_controls() -> void:
	# Logical canvas is at least 1280 tall; taller phones use the extra height.
	var h := maxf(size.y, 1280.0)
	var low := h - 198.0
	var action := h - 380.0
	var aux := h - 452.0
	var upper := h - 518.0
	var fire_y := h - 486.0
	_hint.position = Vector2(27, h - 270.0)
	var mirror := bool(session.settings.get("left_handed", false))
	if not mirror:
		_move_stick.position = Vector2(18, low)
		_aim_stick.position = Vector2(526, low)
		_use_button.position = Vector2(536, action)
		_interact_button.position = Vector2(376, action)
		_fire_button.position = Vector2(376, fire_y)
		_sprint_button.position = Vector2(608, aux)
		_jet_button.position = Vector2(608, upper)
		_tool_button.position = Vector2(14, upper)
		_menu_button.position = Vector2(14, aux)
		_pack_button.position = Vector2(516, 178)
		_log_button.position = Vector2(612, 178)
	else:
		_move_stick.position = Vector2(526, low)
		_aim_stick.position = Vector2(18, low)
		_use_button.position = Vector2(48, action)
		_interact_button.position = Vector2(196, action)
		_fire_button.position = Vector2(196, fire_y)
		_sprint_button.position = Vector2(16, aux)
		_jet_button.position = Vector2(16, upper)
		_tool_button.position = Vector2(594, upper)
		_menu_button.position = Vector2(594, aux)
		_pack_button.position = Vector2(14, 178)
		_log_button.position = Vector2(110, 178)

func _apply_control_prefs() -> void:
	var hold_sprint := bool(session.settings.get("hold_sprint", true))
	var hold_jet := bool(session.settings.get("hold_jetpack", true))
	_sprint_button.toggle_mode = not hold_sprint
	_jet_button.toggle_mode = not hold_jet
	if hold_sprint:
		if not _sprint_button.button_down.is_connected(_on_sprint_down):
			_sprint_button.button_down.connect(_on_sprint_down)
			_sprint_button.button_up.connect(_on_sprint_up)
	else:
		_sprint_toggle = false
		_sprint_button.text = "SPRINT"
	if hold_jet:
		if not _jet_button.button_down.is_connected(_on_jet_down):
			_jet_button.button_down.connect(_on_jet_down)
			_jet_button.button_up.connect(_on_jet_up)
	else:
		_jet_toggle = false
		_jet_button.text = "JET"

func _bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(190, 14)
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = 100.0
	bar.add_theme_stylebox_override("background", BtvTheme.flat(BtvTheme.BG_DEEP, 3, BtvTheme.LINE, 1))
	bar.add_theme_stylebox_override("fill", BtvTheme.flat(color, 3))
	return bar

func _make_stick(caption: String, accent: Color) -> BtvTouchStick:
	var stick := BtvTouchStick.new()
	stick.caption = caption
	stick.accent = accent
	stick.custom_minimum_size = Vector2(176, 176)
	stick.size = Vector2(176, 176)
	return stick

func _build_pause() -> void:
	_pause_layer = Control.new()
	_pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.visible = false
	_ui.add_child(_pause_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.03, 0.82)
	_pause_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(80, 430)
	panel.size = Vector2(560, 420)
	panel.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL, 10, BtvTheme.LINE, 1))
	_pause_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(BtvTheme.label("PAUSED", 28, BtvTheme.ACCENT))
	box.add_child(BtvTheme.spacer(8))
	for item in [
		["RESUME", _toggle_pause],
		["SETTINGS", _open_settings],
		["MAIN MENU", _leave_to_menu],
	]:
		var button := BtvTheme.button(str(item[0]), 58)
		button.pressed.connect(item[1])
		box.add_child(button)
	box.add_child(BtvTheme.spacer(6))
	box.add_child(BtvTheme.label("AUTOSAVE ACTIVE", 11, BtvTheme.TEXT_FAINT))

func _process(delta: float) -> void:
	if player == null:
		return
	_tick_resolution()
	_tick_autosave(delta)
	if _dying:
		_tick_respawn(delta)
		return
	if _pause_layer.visible or is_instance_valid(_panel):
		return
	var keys := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	player.input_dir = keys.normalized() if keys.length() > 0.01 else _stick_move
	if not _aim_stick.active and not DisplayServer.is_touchscreen_available():
		var mouse := get_viewport().get_mouse_position()
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _pointer_on_ui() and mouse.length() > 4.0:
			_aim_direction((mouse - size * 0.5).normalized())
		else:
			player.set_aim(Vector2.ZERO, false)
	player.sprint_requested = Input.is_key_pressed(KEY_SHIFT) or _sprint_toggle
	player.jet_requested = Input.is_key_pressed(KEY_SPACE) or _jet_toggle
	var firing := Input.is_key_pressed(KEY_F) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or _fire_held
	if firing and (_fire_held or not _pointer_on_ui()):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not _aim_stick.active:
			var mouse_now := get_viewport().get_mouse_position()
			if mouse_now.length() > 4.0:
				_aim_direction((mouse_now - size * 0.5).normalized())
		_fire()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _pointer_on_ui():
		player.mining = true
		_beam_timer = maxf(_beam_timer, 0.12)
	else:
		player.mining = false
	if player.mining != _mining_audio:
		_mining_audio = player.mining
		var audio := _audio()
		if audio != null:
			if _mining_audio:
				audio.start_loop("mining.loop", 0.25)
			else:
				audio.stop_loop("mining.loop", 0.15)
	if _beam_timer > 0.0:
		_beam_timer -= delta
		if _beam_timer <= 0.0:
			_beam.visible = false
			_reticle.visible = _target.size() > 0 or _anchor.size() > 0
	_target_timer -= delta
	if _target_timer <= 0.0:
		_target_timer = TARGET_INTERVAL
		_update_target()
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.25
		_update_hud()
	_hint_timer = maxf(0.0, _hint_timer - delta)
	if _hint_timer <= 0.0 and _hint.text != "":
		_hint.text = ""
	player.footstep_material = _material_for(world.biome_at(player.position))
	_update_ambience(delta)
	if _discovery_timer > 0.0:
		_discovery_timer -= delta
		if _discovery_timer <= 0.0:
			var audio := _audio()
			if audio != null:
				audio.music.force_state("EXPLORE_CALM")

func _material_for(biome: String) -> String:
	match biome:
		"shore":
			return "water"
		"crystal":
			return "stone"
		"mist":
			return "grass"
	return "stone"

func _update_ambience(delta: float) -> void:
	_ambience_timer -= delta
	if _ambience_timer > 0.0:
		return
	_ambience_timer = 1.5
	var want := "amb.wind"
	match world.biome_at(player.position):
		"shore":
			want = "amb.water"
		"crystal":
			want = "amb.crystal"
		"mist":
			want = "amb.spore"
	if want == _ambient:
		return
	var audio := _audio()
	if audio == null:
		return
	if _ambient != "":
		audio.stop_loop(_ambient, 1.4)
	_ambient = want
	audio.start_loop(want, 1.8)

func _tick_resolution() -> void:
	if _viewport == null:
		return
	var shrink := maxi(1, int(floor(size.x / VIEW_SIZE.x)))
	if _viewport_container.stretch_shrink != shrink:
		_viewport_container.stretch_shrink = shrink
	if _viewport.size != Vector2i(size / float(shrink)):
		_viewport.size = Vector2i(size / float(shrink))
	# The SubViewportContainer can resize the viewport before this check, so always
	# push the actual size to the camera instead of only when we changed it ourselves.
	director.set_viewport_size(Vector2(_viewport.size))

func _pointer_on_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered is Button or hovered is BtvTouchStick

func _on_move_stick(vector: Vector2) -> void:
	_stick_move = vector

func _on_aim_stick(vector: Vector2) -> void:
	if vector.length() > 0.12:
		_aim_direction(vector)
	else:
		player.set_aim(Vector2.ZERO, false)

func _aim_direction(vector: Vector2) -> void:
	_aim_vector = vector.normalized()
	player.set_aim(_aim_vector, true)

func _on_sprint_toggled(pressed: bool) -> void:
	_sprint_toggle = pressed
	_sprint_button.text = "SPRINT+" if pressed else "SPRINT"

func _on_sprint_down() -> void:
	if bool(session.settings.get("hold_sprint", true)):
		_sprint_toggle = true
		_sprint_button.text = "SPRINT+"

func _on_sprint_up() -> void:
	if bool(session.settings.get("hold_sprint", true)):
		_sprint_toggle = false
		_sprint_button.text = "SPRINT"

func _on_jet_toggled(pressed: bool) -> void:
	_jet_toggle = pressed
	_jet_button.text = "JET+" if pressed else "JET"

func _on_jet_down() -> void:
	if bool(session.settings.get("hold_jetpack", true)):
		_jet_toggle = true
		_jet_button.text = "JET+"

func _on_jet_up() -> void:
	if bool(session.settings.get("hold_jetpack", true)):
		_jet_toggle = false
		_jet_button.text = "JET"

func _cycle_tool() -> void:
	var modes := ["mode.scan", "mode.sample", "mode.dampen"]
	var index := modes.find(session.tool_mode)
	session.set_tool_mode(modes[(index + 1) % modes.size()])
	_tool_button.text = str(session.tool_mode).get_slice(".", 1).to_upper()
	_sfx("tool.switch")

func _on_use_down() -> void:
	_primary_action()
	player.mining = true
	_beam_timer = 0.2

func _on_use_up() -> void:
	player.mining = false

func _on_interact() -> void:
	_update_target()
	if _anchor.is_empty():
		_show_hint("Nothing to interact with in range.")
		return
	_interact_anchor()

func _primary_action() -> void:
	_update_target()
	if not _anchor.is_empty():
		_interact_anchor()
		return
	if _target.is_empty():
		_show_hint("No target. Aim or move closer.")
		return
	var node := _target
	var species: Dictionary = node.get("species", {})
	var species_id := str(node.get("species_id", ""))
	var kind := str(species.get("kind", ""))
	var mode := str(session.tool_mode)
	_beam.points = PackedVector2Array([player.muzzle(), node.get("pos", player.position)])
	_beam.visible = true
	_beam.default_color = BtvTheme.ACCENT if mode == "mode.scan" else (BtvTheme.AMBER if mode == "mode.sample" else BtvTheme.PURPLE)
	director.add_trauma(0.08)
	if mode == "mode.scan":
		if session.observe_species(species_id):
			_sfx("scan.success")
			_show_hint("Scan logged: " + loc.t(str(species.get("display_key", species_id))))
			var audio := _audio()
			if audio != null:
				audio.music.set_state("DISCOVERY")
			_discovery_timer = 7.0
		else:
			_sfx("scan.fail")
			_show_hint("Scan needs a closer, unobstructed subject.")
	elif mode == "mode.sample":
		if kind != "flora":
			_sfx("scan.fail")
			_show_hint("The sampler only takes flora. Switch tool.")
		elif session.gather_species(species_id, str(node.get("id", ""))):
			world.set_node_depleted(str(node.get("id", "")), true)
			_sfx("gather")
			_show_hint("Collected " + str(species.get("harvest", {}).get("item_id", "sample")))
		else:
			_sfx("depleted")
			_show_hint("This specimen is depleted or out of range.")
	elif mode == "mode.dampen":
		if kind != "fauna":
			_sfx("scan.fail")
			_show_hint("Dampener is for fauna. Switch tool.")
		elif session.calm_species(species_id):
			_sfx("scan.success")
			_show_hint("Subject calmed.")
		else:
			_sfx("scan.fail")
			_show_hint("Out of range or already calm.")

func _interact_anchor() -> void:
	var kind := str(_anchor.get("kind", ""))
	var anchor_id := str(_anchor.get("id", ""))
	_sfx("ui.open")
	match kind:
		"npc":
			session.talk_to(anchor_id)
			_open_dialogue()
		"market":
			_open_market(anchor_id)
		"relay":
			session.interact_object(anchor_id, "restore_power")
		"ship":
			_show_hint("Hull is wrecked. Repair it first.")
		"workbench":
			_open_craft()
		"build_site":
			_open_build()
		_:
			_show_hint("Nothing to do here yet.")

func _update_target() -> void:
	if world == null:
		return
	var node := world.nearest_node(player.position, 280.0)
	var anchor := world.nearest_anchor(player.position, 260.0)
	_target = node
	_anchor = anchor
	var focus := Vector2.ZERO
	var has_focus := false
	if not node.is_empty():
		focus = node.get("pos", Vector2.ZERO)
		has_focus = true
	if not anchor.is_empty():
		var anchor_pos: Vector2 = anchor.get("pos", Vector2.ZERO)
		if not has_focus or player.position.distance_to(anchor_pos) < player.position.distance_to(focus):
			_anchor = anchor
			_target = {}
			focus = anchor_pos
	_reticle.visible = has_focus or not _anchor.is_empty()
	if _reticle.visible:
		_reticle.position = focus
	_update_action_label()

func _update_action_label() -> void:
	if not _anchor.is_empty():
		var kind := str(_anchor.get("kind", ""))
		var verb := "INTERACT"
		if kind == "npc":
			verb = "TALK"
		elif kind == "market":
			verb = "TRADE"
		elif kind == "relay":
			verb = "REPAIR"
		elif kind == "ship":
			verb = "INSPECT"
		elif kind == "workbench":
			verb = "CRAFT"
		_interact_button.text = verb
		_interact_button.disabled = false
		return
	_interact_button.text = "INTERACT"
	_interact_button.disabled = _target.is_empty()
	if _target.is_empty():
		_use_button.text = "USE"
		return
	var species: Dictionary = _target.get("species", {})
	var name := loc.t(str(species.get("display_key", "target")))
	match str(session.tool_mode):
		"mode.scan":
			_use_button.text = "SCAN\n" + name
		"mode.sample":
			_use_button.text = "GATHER\n" + name
		"mode.dampen":
			_use_button.text = "CALM\n" + name

func _update_hud() -> void:
	if session == null or player == null:
		return
	var planet_name := loc.t("planet.vela.name")
	var longitude := fposmod(player.position.x, BtvSurfaceWorld.WORLD_W) / BtvSurfaceWorld.WORLD_W * 360.0
	_status.text = "%s   %03d°   CR %d" % [planet_name, int(longitude), session.credits]
	_objective.text = loc.t("quest.main.prologue.signal.step.surface") + "  ·  " + world.biome_at(player.position).to_upper()
	_stamina.value = player.stamina
	_energy.value = player.energy
	_health.value = player.health
	_shield.value = player.shield
	_health_caption.text = "HULL %d/%d" % [int(player.health), int(player.max_health)]
	_shield_caption.text = "SHIELD %d/%d" % [int(player.shield), int(player.max_shield)]
	_stamina_caption.add_theme_color_override("font_color", BtvTheme.AMBER if player.stamina < 25.0 else BtvTheme.TEXT_FAINT)
	_energy_caption.add_theme_color_override("font_color", BtvTheme.AMBER if player.energy < 25.0 else BtvTheme.TEXT_FAINT)
	_health_caption.add_theme_color_override("font_color", BtvTheme.DANGER if player.health < 30.0 else BtvTheme.TEXT_FAINT)
	_shield_caption.add_theme_color_override("font_color", BtvTheme.BLUE if player.shield > 0.0 else BtvTheme.TEXT_FAINT)
	_tool_button.text = str(session.tool_mode).get_slice(".", 1).to_upper()
	_sprint_button.button_pressed = _sprint_toggle
	_jet_button.button_pressed = _jet_toggle

func _audio() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/AudioManager")

func _sfx(id: String, volume_db: float = 0.0) -> void:
	var audio := _audio()
	if audio != null:
		audio.play(id, volume_db)

func _on_footstep(id: String) -> void:
	var audio := _audio()
	if audio == null:
		return
	if not audio.play_at(id, player.position + Vector2(0, -6), world):
		audio.play(id)

func _on_landed() -> void:
	_sfx("land", -2.0)
	director.add_trauma(0.12)

func _bind_audio(node: Node) -> void:
	for child in node.find_children("*", "BaseButton", true, false):
		if not child.pressed.is_connected(_sfx_click):
			child.pressed.connect(_sfx_click)

func _sfx_click() -> void:
	_sfx("ui.click")

func _show_hint(text: String) -> void:
	_hint.text = text
	_hint_timer = 2.4

func _on_session_changed(_reason: String) -> void:
	_update_hud()

func _on_toast(code: String, _args: Dictionary) -> void:
	_show_hint(loc.t(code))

func _on_player_damaged(_amount: int) -> void:
	director.add_trauma(0.45)
	_sfx("hit", -4.0)

func _on_player_died() -> void:
	if _dying:
		return
	_dying = true
	_respawn_timer = 1.8
	player.mining = false
	player.input_dir = Vector2.ZERO
	player.visible = false
	if combat != null:
		combat.set_paused(true)
		combat.clear_bolts()
	director.add_trauma(0.8)
	_sfx("death")
	_show_hint("SUIT OFFLINE - emergency reboot. No save data lost.")

func _tick_respawn(delta: float) -> void:
	_respawn_timer -= delta
	if _respawn_timer > 0.0:
		return
	_dying = false
	player.visible = true
	player.revive(world.spawn())
	if combat != null:
		combat.set_paused(false)
	_show_hint("Suit rebooted. No save data lost.")

func _on_fire_down() -> void:
	_fire_held = true
	_fire()

func _on_fire_up() -> void:
	_fire_held = false

func _fire() -> void:
	if _dying or _pause_layer.visible or is_instance_valid(_panel) or player == null or not player.alive:
		return
	if player.try_fire():
		if combat != null:
			combat.fire_player(player.muzzle(), player.aim_dir)
		_sfx("shot.laser", -6.0)
		director.add_trauma(0.06)

func _on_combat_aggro(active: bool) -> void:
	if _dying or _pause_layer.visible:
		return
	var audio := _audio()
	if audio == null:
		return
	if active:
		audio.music.set_state("COMBAT")
	elif _discovery_timer <= 0.0:
		audio.music.set_state("EXPLORE_CALM")

func _toggle_pause() -> void:
	if is_instance_valid(_panel):
		_panel.close()
		return
	_pause_layer.visible = not _pause_layer.visible
	_release_inputs()
	if combat != null:
		combat.set_paused(_pause_layer.visible)
	var audio := _audio()
	if audio != null:
		if _pause_layer.visible:
			audio.music.set_state("PAUSE")
			audio.duck("SFX", -8.0, 0.6)
		else:
			audio.music.force_state("EXPLORE_CALM")

func _release_inputs() -> void:
	_stick_move = Vector2.ZERO
	_move_stick.reset()
	_aim_stick.reset()
	_sprint_toggle = false
	_jet_toggle = false
	_fire_held = false
	player.input_dir = Vector2.ZERO
	player.mining = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if is_instance_valid(_panel):
		return
	match event.keycode:
		KEY_ESCAPE:
			_handle_back()
		KEY_E:
			_on_interact()
		KEY_Q:
			_cycle_tool()
		KEY_F:
			_fire()
		KEY_SPACE:
			_jet_toggle = not _jet_toggle
			_jet_button.button_pressed = _jet_toggle
		KEY_TAB:
			_toggle_pause()
		KEY_M:
			_open_chart()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_inputs()
		_autosave_now()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autosave_now()

func _handle_back() -> void:
	if is_instance_valid(_panel):
		_panel.close()
	elif _pause_layer.visible:
		_pause_layer.visible = false
	else:
		_toggle_pause()

func _leave_to_menu() -> void:
	session.save()
	exit_to_menu.emit()

func _save_game() -> void:
	if session.save():
		_show_hint("Progress saved.")

func _tick_autosave(delta: float) -> void:
	_autosave_timer -= delta
	if _autosave_timer > 0.0:
		return
	if _dying or _pause_layer.visible or is_instance_valid(_panel):
		_autosave_timer = 5.0
		return
	_autosave_timer = AUTOSAVE_INTERVAL
	session.save()

func _autosave_now() -> void:
	if session == null or _dying:
		return
	session.save()

func _open_panel(sheet: BtvPanelBase) -> void:
	if is_instance_valid(_panel):
		_panel.close()
	_panel = sheet
	_ui.add_child(sheet)
	_bind_audio(sheet)
	_panel.closed.connect(func() -> void: _panel = null)
	_release_inputs()
	_sfx("ui.open")

func _open_inventory() -> void:
	var sheet := BtvInventorySheet.new()
	sheet.setup_inventory(session, loc)
	_open_panel(sheet)

func _open_craft() -> void:
	var sheet := BtvCraftSheet.new()
	sheet.setup_craft(session, loc)
	_open_panel(sheet)

func _open_journal() -> void:
	var sheet := BtvJournalSheet.new()
	sheet.setup_journal(session, loc)
	_open_panel(sheet)

func _open_chart() -> void:
	var sheet := BtvChartSheet.new()
	sheet.setup_chart(session, loc)
	_open_panel(sheet)

func _open_build() -> void:
	var sheet := BtvBuildSheet.new()
	sheet.setup_build(session, loc)
	_open_panel(sheet)

func _open_ship() -> void:
	var sheet := BtvShipSheet.new()
	sheet.setup_ship(session, loc)
	_open_panel(sheet)

func _open_dialogue() -> void:
	var sheet := BtvDialogueSheet.new()
	sheet.setup_dialogue(session, loc)
	_open_panel(sheet)

func _open_market(market_id: String) -> void:
	var sheet := BtvMarketSheet.new()
	sheet.setup_market(session, loc, market_id)
	_open_panel(sheet)

func _open_settings() -> void:
	var sheet := BtvSettingsSheet.new()
	sheet.setup_settings(loc, session.settings.duplicate(), _on_setting_changed, _on_settings_applied)
	_open_panel(sheet)

func _on_setting_changed(key: String, value: Variant) -> void:
	session.set_setting(key, value)
	var audio := _audio()
	if audio != null:
		audio.apply_settings(session.settings)
	if director != null:
		director.shake_scale = float(session.settings.get("screen_shake", 1.0))
		director.reduced_motion = bool(session.settings.get("reduced_motion", false))
	if key == "left_handed":
		_layout_controls()
	elif key == "hold_sprint" or key == "hold_jetpack":
		_apply_control_prefs()

func _on_settings_applied() -> void:
	settings_changed.emit()
