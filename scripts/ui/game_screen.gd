class_name BtvGameScreen
extends Control

## Field view: world, compact HUD, contextual action, thumb stick and bottom sheets.
## The domain session owns state; this screen only presents and routes intent.

signal exit_to_menu
signal settings_changed

const WALK_SPEED := 250.0
const TARGET_INTERVAL := 0.16

var session: GameSession
var loc: Localization
var world: BtvWorldView
var input_state := InputState.new()

var _top_hud: PanelContainer
var _location_label: Label
var _stats_label: Label
var _objective_label: Label
var _dock: PanelContainer
var _near_label: Label
var _action_button: Button
var _mode_buttons: Dictionary = {}
var _utility_buttons: Dictionary = {}
var _joystick: BtvJoystick
var _hint_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _pause_layer: Control
var _panel: BtvPanelBase
var _target: Dictionary = {}
var _target_timer := 0.0
var _hud_timer := 0.0
var _toast_timer := 0.0
var _walk_target := Vector2.ZERO
var _has_walk_target := false
var _safe_left := 12
var _safe_right := 12
var _safe_top := 10
var _safe_bottom := 12

func setup(p_session: GameSession) -> void:
	session = p_session
	loc = p_session.loc

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	world = BtvWorldView.new()
	world.setup(session)
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.tapped.connect(_on_world_tap)
	world.planet_tapped.connect(_on_planet_tapped)
	add_child(world)
	_build_hud()
	_build_dock()
	_build_joystick()
	_build_toast()
	_build_pause()
	session.changed.connect(_on_session_changed)
	session.toast_requested.connect(_on_toast)
	_apply_safe_area()
	_update_hud()
	_update_target()
	set_process(true)

func _process(delta: float) -> void:
	if session == null:
		return
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_panel != null:
			_toast_panel.visible = false
	var modal := _panel != null or (_pause_layer != null and _pause_layer.visible)
	if modal:
		return
	var move := input_state.move_vector
	var keyboard := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	if keyboard.length_squared() > 0.01:
		move = keyboard.normalized()
		_has_walk_target = false
	if move.length_squared() > 0.01:
		_has_walk_target = false
		session.player_pos += move.limit_length(1.0) * WALK_SPEED * delta
		world.last_facing = move.normalized()
	elif _has_walk_target:
		var to_target := _walk_target - session.player_pos
		if to_target.length() <= 8.0:
			_has_walk_target = false
		else:
			var step := to_target.normalized() * minf(WALK_SPEED * delta, to_target.length())
			session.player_pos += step
			world.last_facing = step.normalized()
	session.player_pos.x = clampf(session.player_pos.x, 80.0, WorldGen.WORLD_SIZE - 80.0)
	session.player_pos.y = clampf(session.player_pos.y, 80.0, WorldGen.WORLD_SIZE - 80.0)
	session.advance_time(delta)
	_target_timer += delta
	_hud_timer += delta
	if _target_timer >= TARGET_INTERVAL:
		_target_timer = 0.0
		_update_target()
	if _hud_timer >= 0.3:
		_hud_timer = 0.0
		_update_hud()

func _build_hud() -> void:
	_top_hud = PanelContainer.new()
	_top_hud.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL, 14, BtvTheme.LINE, 1))
	_top_hud.anchor_right = 1.0
	_top_hud.offset_left = 12
	_top_hud.offset_right = -12
	_top_hud.offset_top = 10
	_top_hud.offset_bottom = 108
	_top_hud.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_top_hud)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	_top_hud.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_location_label = BtvTheme.label("", 15, BtvTheme.ACCENT)
	_location_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_location_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(_location_label)
	var pause := Button.new()
	pause.text = "II"
	pause.tooltip_text = loc.t("ui.menu")
	pause.custom_minimum_size = Vector2(50, 36)
	pause.add_theme_font_size_override("font_size", 13)
	pause.pressed.connect(_toggle_pause)
	header.add_child(pause)
	_stats_label = BtvTheme.label("", 12, BtvTheme.TEXT_DIM)
	column.add_child(_stats_label)
	_objective_label = BtvTheme.label("", 12, BtvTheme.AMBER)
	_objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(_objective_label)

func _build_dock() -> void:
	_dock = PanelContainer.new()
	_dock.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL, 18, BtvTheme.LINE, 1))
	_dock.anchor_top = 1.0
	_dock.anchor_bottom = 1.0
	_dock.anchor_right = 1.0
	_dock.offset_left = 12
	_dock.offset_right = -12
	_dock.offset_top = -252
	_dock.offset_bottom = -10
	add_child(_dock)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_dock.add_child(column)
	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 8)
	column.add_child(target_row)
	_near_label = BtvTheme.label(loc.t("ui.no_target_near"), 13, BtvTheme.TEXT_DIM)
	_near_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_near_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	target_row.add_child(_near_label)
	_action_button = BtvTheme.button(loc.t("ui.interact"), 46)
	_action_button.custom_minimum_size = Vector2(154, 46)
	_action_button.disabled = true
	_action_button.pressed.connect(_on_action_pressed)
	target_row.add_child(_action_button)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	column.add_child(mode_row)
	var mode_label := BtvTheme.label(loc.t("ui.tool_modes"), 11, BtvTheme.TEXT_FAINT)
	mode_label.custom_minimum_size = Vector2(66, 0)
	mode_row.add_child(mode_label)
	for mode_id in ["mode.scan", "mode.sample", "mode.dampen"]:
		var mode: Dictionary = session.registry.get_mode(mode_id)
		var button := BtvTheme.button(loc.t(str(mode.get("display_key", mode_id))), 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_set_mode.bind(mode_id))
		mode_row.add_child(button)
		_mode_buttons[mode_id] = button
	var utility_row := HBoxContainer.new()
	utility_row.add_theme_constant_override("separation", 4)
	column.add_child(utility_row)
	_add_utility(utility_row, "pack", "ui.inventory_short", _open_inventory)
	_add_utility(utility_row, "craft", "ui.craft_short", _open_craft)
	_add_utility(utility_row, "base", "ui.base_short", _open_build)
	_add_utility(utility_row, "ship", "ui.ship_short", _open_ship)
	_add_utility(utility_row, "log", "ui.log_short", _open_journal)
	_add_utility(utility_row, "chart", "ui.chart_short", _open_chart)
	var hint := BtvTheme.label(loc.t("ui.touch_hint"), 10, BtvTheme.TEXT_FAINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	_hint_label = hint

func _add_utility(parent: HBoxContainer, key: String, text_key: String, callback: Callable) -> void:
	var button := BtvTheme.button(loc.t(text_key), 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(callback)
	parent.add_child(button)
	_utility_buttons[key] = button

func _build_joystick() -> void:
	_joystick = BtvJoystick.new()
	_joystick.anchor_top = 1.0
	_joystick.anchor_bottom = 1.0
	_joystick.offset_top = -424
	_joystick.offset_bottom = -272
	_joystick.offset_left = 16
	_joystick.offset_right = 168
	_joystick.moved.connect(_on_joystick_moved)
	add_child(_joystick)

func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL, 14, BtvTheme.ACCENT_DARK, 1))
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.offset_left = -180
	_toast_panel.offset_right = 180
	_toast_panel.offset_top = 120
	_toast_panel.offset_bottom = 170
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_panel)
	_toast_label = BtvTheme.label("", 13, BtvTheme.TEXT)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast_label)

func _build_pause() -> void:
	_pause_layer = Control.new()
	_pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.visible = false
	_pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.025, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 0)
	card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL, 22, BtvTheme.LINE, 1))
	center.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	var title := BtvTheme.header(loc.t("ui.pause_menu"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for item in [
		["ui.resume", _toggle_pause],
		["ui.save_game", _save_game],
		["ui.settings", _open_settings],
		["ui.return_to_menu", _leave_to_menu],
	]:
		var button := BtvTheme.button(loc.t(str(item[0])), 52)
		button.pressed.connect(item[1])
		column.add_child(button)
	var hint := BtvTheme.wrapped(loc.t("ui.menu_hint"), 12, BtvTheme.TEXT_FAINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

func _apply_safe_area() -> void:
	var window_size := DisplayServer.window_get_size()
	var window_pos := DisplayServer.window_get_position()
	var safe := DisplayServer.get_display_safe_area()
	var left := 12
	var top := 10
	var right := 12
	var bottom := 10
	if OS.has_feature("mobile") and safe.size.x > 0 and safe.size.y > 0 and window_size.x > 0 and window_size.y > 0:
		var viewport_size := get_viewport_rect().size
		var scale_x := viewport_size.x / float(window_size.x)
		var scale_y := viewport_size.y / float(window_size.y)
		left = maxi(12, int(round(float(maxi(0, safe.position.x - window_pos.x)) * scale_x)))
		top = maxi(10, int(round(float(maxi(0, safe.position.y - window_pos.y)) * scale_y)) + 8)
		right = maxi(12, int(round(float(maxi(0, window_pos.x + window_size.x - safe.end.x)) * scale_x)))
		bottom = maxi(10, int(round(float(maxi(0, window_pos.y + window_size.y - safe.end.y)) * scale_y)))
	_safe_left = left
	_safe_right = right
	_safe_top = top
	_safe_bottom = bottom
	_top_hud.offset_left = left
	_top_hud.offset_right = -right
	_top_hud.offset_top = top
	_top_hud.offset_bottom = top + 98
	_dock.offset_left = left
	_dock.offset_right = -right
	_dock.offset_bottom = -bottom
	_toast_panel.offset_top = top + 108
	_toast_panel.offset_bottom = top + 158
	_layout_joystick()

func _layout_joystick() -> void:
	if _joystick == null:
		return
	var left_handed := bool(session.settings.get("left_handed", false))
	_joystick.anchor_left = 0.0
	_joystick.anchor_right = 0.0
	if left_handed:
		_joystick.anchor_left = 1.0
		_joystick.anchor_right = 1.0
		_joystick.offset_left = -(_safe_right + 152)
		_joystick.offset_right = -_safe_right
	else:
		_joystick.offset_left = _safe_left
		_joystick.offset_right = _safe_left + 152
	_joystick.offset_top = -(_safe_bottom + 262 + 152)
	_joystick.offset_bottom = -(_safe_bottom + 262)

func _on_joystick_moved(vector: Vector2) -> void:
	if _panel != null or (_pause_layer != null and _pause_layer.visible):
		return
	input_state.set_move(vector)
	_has_walk_target = false

func _on_world_tap(world_pos: Vector2) -> void:
	if _panel != null or (_pause_layer != null and _pause_layer.visible):
		return
	_walk_target = world_pos
	_has_walk_target = true

func _on_planet_tapped(planet_id: String) -> void:
	world.selected_planet_id = planet_id
	_open_chart()

func _set_mode(mode_id: String) -> void:
	var result := session.set_tool_mode(mode_id)
	if bool(result.get("ok", false)):
		_update_modes()
		_update_target()

func _update_modes() -> void:
	for mode_id in _mode_buttons.keys():
		var button: Button = _mode_buttons[mode_id]
		var active := str(mode_id) == session.tool_mode
		button.add_theme_stylebox_override("normal", BtvTheme.flat(
			BtvTheme.ACCENT_DARK if active else BtvTheme.PANEL_LIGHT, 12,
			BtvTheme.ACCENT if active else BtvTheme.LINE, 1))
		button.add_theme_color_override("font_color", BtvTheme.BG_DEEP if active else BtvTheme.TEXT)

func _update_hud() -> void:
	if session == null or _location_label == null:
		return
	if session.mode == "planet":
		var planet: Dictionary = session.get_planet()
		_location_label.text = loc.t(str(planet.get("display_key", ""))) + " · " + loc.t("ui.planet")
	else:
		var system: Dictionary = session.registry.get_system(session.system_id)
		_location_label.text = loc.t(str(system.get("display_key", ""))) + " · " + loc.t("ui.orbit")
	_stats_label.text = "%s   %s   %s" % [
		loc.t("ui.credits_value", {"credits": session.credits}),
		loc.t("ui.mass_value", {
			"mass": "%.0f" % session.inventory.total_mass(),
			"capacity": "%.0f" % session.inventory.capacity_kg,
		}),
		loc.t("ui.fuel_value", {"fuel": "%.0f" % session.ship.fuel}),
	]
	_objective_label.text = loc.t("ui.objective") + ": " + session.quests.current_objective_text()
	if _hint_label != null:
		_hint_label.text = loc.t("ui.touch_hint" if session.mode == "planet" else "ui.space_hint")
	_utility_buttons["base"].disabled = session.mode != "planet"
	_utility_buttons["chart"].disabled = session.mode != "space"
	_update_modes()

func _update_target() -> void:
	if session == null:
		return
	var best: Dictionary = {}
	var player := session.player_pos
	if session.mode == "planet":
		var mode: Dictionary = session.registry.get_mode(session.tool_mode)
		var reach := float(mode.get("range_m", 12)) * 10.0
		var layout := session.surface_layout()
		for raw_node in layout.get("nodes", []):
			var node: Dictionary = raw_node
			var distance := player.distance_to(Vector2(float(node.x), float(node.y)))
			if distance > reach:
				continue
			if best.is_empty() or distance < float(best.get("distance", INF)):
				var species: Dictionary = session.registry.get_species(str(node.get("species_id", "")))
				var action := _node_action(str(node.get("kind", "")), str(node.get("species_id", "")), str(node.get("node_id", "")))
				best = {
					"kind": "species", "pos": Vector2(float(node.x), float(node.y)),
					"distance": distance, "label": loc.t(str(species.get("display_key", ""))),
					"species_id": str(node.get("species_id", "")), "node_id": str(node.get("node_id", "")),
					"action": action, "node": node, "species": species,
				}
		var anchors: Array = session.get_planet().get("anchors", [])
		for raw_anchor in anchors:
			var anchor: Dictionary = raw_anchor
			var anchor_kind := str(anchor.get("kind", ""))
			if anchor_kind == "build_site":
				continue
			var distance := player.distance_to(Vector2(float(anchor.x), float(anchor.y)))
			if distance > 190.0:
				continue
			if best.is_empty() or distance < float(best.get("distance", INF)):
				best = _anchor_target(anchor, distance)
	_target = best
	world.set_target(best)
	if best.is_empty():
		_near_label.text = loc.t("ui.no_space_target" if session.mode == "space" else "ui.no_target_near")
		_action_button.text = loc.t("ui.interact")
		_action_button.disabled = true
		return
	var distance_m := float(best.get("distance", 0.0)) / 10.0
	_near_label.text = loc.t("ui.near_target", {
		"target": str(best.get("label", "")),
		"distance": "%.0f" % distance_m,
	})
	var action: Dictionary = best.get("action", {})
	_action_button.text = loc.t(str(action.get("text_key", "ui.interact")))
	_action_button.disabled = not bool(action.get("enabled", false))

func _node_action(kind: String, species_id: String, node_id: String) -> Dictionary:
	match session.tool_mode:
		"mode.scan":
			return {"text_key": "ui.observe", "enabled": true}
		"mode.sample":
			if kind == "flora":
				var ready := session.is_node_ready(node_id)
				return {"text_key": "ui.gather" if ready else "ui.action_cooldown", "enabled": ready}
			return {"text_key": "ui.action_switch_mode", "enabled": false}
		"mode.dampen":
			if kind == "fauna":
				return {"text_key": "ui.calm", "enabled": true}
			return {"text_key": "ui.action_switch_mode", "enabled": false}
	return {"text_key": "ui.interact", "enabled": false}

func _anchor_target(anchor: Dictionary, distance: float) -> Dictionary:
	var anchor_kind := str(anchor.get("kind", ""))
	var anchor_id := str(anchor.get("id", ""))
	match anchor_kind:
		"npc":
			var dialogue: Dictionary = session.registry.get_dialogue(anchor_id)
			return {
				"kind": "npc", "id": anchor_id, "pos": Vector2(float(anchor.x), float(anchor.y)),
				"distance": distance, "label": loc.t(str(dialogue.get("speaker_key", "ui.talk"))),
				"action": {"text_key": "ui.talk", "enabled": true},
			}
		"market":
			var market: Dictionary = session.registry.get_market(anchor_id)
			return {
				"kind": "market", "id": anchor_id, "pos": Vector2(float(anchor.x), float(anchor.y)),
				"distance": distance, "label": loc.t(str(market.get("display_key", "ui.market"))),
				"action": {"text_key": "ui.trade", "enabled": true},
			}
		"relay":
			return {
				"kind": "relay", "id": anchor_id, "pos": Vector2(float(anchor.x), float(anchor.y)),
				"distance": distance, "label": loc.t("ui.relay_console"),
				"action": {"text_key": "ui.repair", "enabled": true},
			}
		"ship":
			return {
				"kind": "ship", "id": anchor_id, "pos": Vector2(float(anchor.x), float(anchor.y)),
				"distance": distance, "label": loc.t("ui.ship"),
				"action": {"text_key": "ui.board_ship", "enabled": true},
			}
		_:
			return {}

func _on_action_pressed() -> void:
	if _target.is_empty():
		return
	match str(_target.get("kind", "")):
		"species":
			var species_id := str(_target.get("species_id", ""))
			var node: Dictionary = _target.get("node", {})
			match session.tool_mode:
				"mode.scan":
					session.observe_species(species_id)
				"mode.sample":
					if str(node.get("kind", "")) != "flora":
						_show_toast(loc.t("toast.wrong_mode"))
					else:
						session.gather_species(species_id, str(node.get("node_id", "")))
				"mode.dampen":
					if str(node.get("kind", "")) != "fauna":
						_show_toast(loc.t("toast.wrong_mode"))
					else:
						session.calm_species(species_id)
			_update_target()
		"npc":
			var talk := session.talk_to(str(_target.get("id", "")))
			if bool(talk.get("ok", false)):
				_open_dialogue()
			else:
				_show_toast(_result_text(talk))
		"market":
			_open_market(str(_target.get("id", "")))
		"relay":
			var result := session.interact_object(str(_target.get("id", "")), "restore_power")
			if not bool(result.get("ok", false)):
				_show_toast(_result_text(result))
			_update_hud()
			_update_target()
		"ship":
			var launched := session.return_to_space()
			if bool(launched.get("ok", false)):
				_show_toast(loc.t("ui.returned_to_orbit"))
				_refresh_world()
			else:
				_show_toast(_result_text(launched))
		"build":
			_open_build()

func _result_text(result: Dictionary) -> String:
	var code := str(result.get("code", ""))
	var key := "toast." + code
	if loc.has(key):
		return loc.t(key)
	return loc.t("toast.no_effect")

func _open_inventory() -> void:
	var sheet := BtvInventorySheet.new()
	sheet.setup_inventory(session, loc)
	_open_panel(sheet)

func _open_craft() -> void:
	var sheet := BtvCraftSheet.new()
	sheet.setup_craft(session, loc)
	_open_panel(sheet)

func _open_market(market_id: String) -> void:
	var sheet := BtvMarketSheet.new()
	sheet.setup_market(session, loc, market_id)
	_open_panel(sheet)

func _open_build() -> void:
	var sheet := BtvBuildSheet.new()
	sheet.setup_build(session, loc)
	_open_panel(sheet)

func _open_ship() -> void:
	var sheet := BtvShipSheet.new()
	sheet.setup_ship(session, loc)
	_open_panel(sheet)

func _open_journal() -> void:
	var sheet := BtvJournalSheet.new()
	sheet.setup_journal(session, loc)
	_open_panel(sheet)

func _open_chart() -> void:
	var sheet := BtvChartSheet.new()
	sheet.setup_chart(session, loc)
	_open_panel(sheet)

func _open_dialogue() -> void:
	var sheet := BtvDialogueSheet.new()
	sheet.setup_dialogue(session, loc)
	_open_panel(sheet)

func _open_settings() -> void:
	var sheet := BtvSettingsSheet.new()
	sheet.setup_settings(loc, session.settings.duplicate(), _on_setting_changed, _on_settings_applied)
	_open_panel(sheet)

func _open_panel(sheet: BtvPanelBase) -> void:
	if _panel != null:
		_panel.closed.disconnect(_on_panel_closed)
		_panel.queue_free()
	_panel = sheet
	sheet.closed.connect(_on_panel_closed)
	add_child(sheet)
	_clear_inputs()

func _on_panel_closed() -> void:
	_panel = null
	_clear_inputs()
	_refresh_world()
	_update_hud()
	_update_target()

func _on_setting_changed(key: String, value) -> void:
	session.set_setting(key, value)
	world.set_visual_settings(
		bool(session.settings.get("reduced_motion", false)),
		str(session.settings.get("quality", "balanced"))
	)
	_layout_joystick()

func _on_settings_applied(_values: Dictionary) -> void:
	settings_changed.emit()
	_show_toast(loc.t("toast.settings_saved"))

func _save_game() -> void:
	var result := session.save()
	if bool(result.get("ok", false)):
		_show_toast(loc.t("toast.saved"))
	else:
		_show_toast(loc.t("toast.save_failed"))

func _toggle_pause() -> void:
	if _pause_layer == null:
		return
	_pause_layer.visible = not _pause_layer.visible
	if _pause_layer.visible:
		_clear_inputs()
		_pause_layer.move_to_front()
	else:
		_clear_inputs()

func _leave_to_menu() -> void:
	_clear_inputs()
	exit_to_menu.emit()

func _refresh_world() -> void:
	world.refresh()
	world.selected_planet_id = session.planet_id if session.mode == "planet" else world.selected_planet_id
	_update_hud()
	_update_target()

func _on_session_changed(reason: String) -> void:
	if reason == "landing" or reason == "launch" or reason == "travel" or reason == "loaded":
		_refresh_world()
	_update_hud()
	_update_target()

func _on_toast(code: String, args: Dictionary) -> void:
	var key := "toast." + code
	if loc.has(key):
		_show_toast(loc.t(key, args))

func _show_toast(text: String) -> void:
	if _toast_panel == null or text.is_empty():
		return
	_toast_label.text = text
	_toast_panel.visible = true
	_toast_panel.move_to_front()
	_toast_timer = 2.6

func _clear_inputs() -> void:
	input_state.clear()
	if _joystick != null:
		_joystick.reset()
	_has_walk_target = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_clear_inputs()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()

func _handle_back() -> void:
	if _panel != null:
		_panel.close()
	elif _pause_layer != null and _pause_layer.visible:
		_toggle_pause()
	else:
		_toggle_pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _panel == null:
			_toggle_pause()
			get_viewport().set_input_as_handled()
