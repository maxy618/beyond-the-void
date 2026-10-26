class_name BtvShipSheet
extends BtvPanelBase

## Read the derived stats, then swap any owned module through the validated loadout path.

func setup_ship(p_session: GameSession, p_loc: Localization) -> void:
	setup(p_session, p_loc, "ui.ship_title")

func _fill() -> void:
	var hull: Dictionary = session.ship.get_hull()
	var stats: Dictionary = session.ship.stats()
	add_section(loc.t(str(hull.get("display_key", ""))))
	add_note(loc.t(str(hull.get("description_key", ""))))
	add_note("%s · %s" % [loc.t("ui.hull"), _value(stats, "hull")] + "   " +
		"%s · %s" % [loc.t("ui.maneuver"), _value(stats, "maneuver")])
	add_note("%s · %s   " % [loc.t("ui.cargo"), loc.t("ui.mass_value", {
		"mass": "%.0f" % session.inventory.total_mass(),
		"capacity": "%.0f" % session.inventory.capacity_kg,
	})] + "%s · %s" % [loc.t("ui.jump_range"), _value(stats, "jump")])
	add_note("%s · %s   " % [loc.t("ui.fuel"), "%.0f / %.0f" % [session.ship.fuel, float(stats.get("fuel_capacity", 0.0))]] +
		"%s · %.0f / %.0f" % [loc.t("ui.power"), float(stats.get("power_draw", 0.0)), float(stats.get("power_budget", 0.0))])
	var slots: Dictionary = stats.get("slots", {})
	var usage: Dictionary = stats.get("slot_usage", {})
	var slot_parts: Array[String] = []
	for slot_name in slots.keys():
		slot_parts.append("%s %d/%d" % [str(slot_name), int(usage.get(slot_name, 0)), int(slots[slot_name])])
	if not slot_parts.is_empty():
		add_note("%s · %s" % [loc.t("ui.slots"), ", ".join(slot_parts)])
	body.add_child(BtvTheme.spacer(4))
	add_section(loc.t("ui.equipped"))
	for raw_id in session.ship.equipped:
		var module_id := str(raw_id)
		var module: Dictionary = session.ship.get_module(module_id)
		_module_row(module_id, module, false)
	add_section(loc.t("ui.owned"))
	var any_owned := false
	for raw_id in session.ship.owned:
		var module_id := str(raw_id)
		if module_id in session.ship.equipped:
			continue
		any_owned = true
		var module: Dictionary = session.ship.get_module(module_id)
		_module_row(module_id, module, true)
	if not any_owned:
		add_note(loc.t("ui.no_spare_modules"))

func _module_row(module_id: String, module: Dictionary, can_add: bool) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL_SOFT, 12, BtvTheme.LINE, 1))
	body.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	card.add_child(column)
	var name_label := BtvTheme.label(loc.t(str(module.get("display_key", ""))), 15, BtvTheme.TEXT)
	column.add_child(name_label)
	column.add_child(BtvTheme.wrapped(loc.t("ui.module_mass", {
		"mass": "%.0f" % float(module.get("mass_kg", 0.0)),
		"power": float(module.get("power_draw", 0.0)),
	}), 12, BtvTheme.TEXT_DIM))
	var effect_parts: Array[String] = []
	for effect_key in module.get("effects", {}).keys():
		var effect_value := float((module.get("effects", {}) as Dictionary).get(effect_key, 0.0))
		effect_parts.append("%s %s" % [str(effect_key), str(effect_value)])
	if not effect_parts.is_empty():
		column.add_child(BtvTheme.wrapped("%s: %s" % [loc.t("ui.effect"), ", ".join(effect_parts)], 12, BtvTheme.ACCENT))
	var action := BtvTheme.button(loc.t("ui.equip") if can_add else loc.t("ui.unequip"), 46)
	if can_add:
		var check: Dictionary = session.ship.can_equip(module_id)
		action.disabled = not bool(check.get("ok", false))
		action.pressed.connect(_equip.bind(module_id))
	else:
		action.pressed.connect(_unequip.bind(module_id))
	column.add_child(action)

func _equip(module_id: String) -> void:
	var result := session.equip_module(module_id)
	if bool(result.get("ok", false)):
		refresh()

func _unequip(module_id: String) -> void:
	var result := session.unequip_module(module_id)
	if bool(result.get("ok", false)):
		refresh()

func _value(stats: Dictionary, key: String) -> String:
	return "%.2f" % float(stats.get(key, 0.0))
