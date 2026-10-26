class_name BtvBuildSheet
extends BtvPanelBase

## Landing-base pads. Placement, power and production are all server-side (domain) decisions.

func setup_build(p_session: GameSession, p_loc: Localization) -> void:
	setup(p_session, p_loc, "ui.build_title")

func _fill() -> void:
	if session.mode != "planet":
		add_empty(loc.t("ui.not_landable"))
		return
	var totals: Dictionary = session.build.totals()
	add_section(loc.t("ui.power_total", {
		"produced": int(totals.get("power_production", 0)),
		"draw": int(totals.get("power_draw", 0)),
	}))
	add_note(loc.t("ui.credits_value", {"credits": session.credits}) + " · " + (
		loc.t("ui.powered") if bool(totals.get("powered", false)) else loc.t("ui.unpowered")))
	if not session.buildings.is_empty():
		add_section(loc.t("ui.modules"))
		for raw_building in session.buildings:
			var building: Dictionary = raw_building
			var definition: Dictionary = session.registry.get_building(str(building.get("definition_id", "")))
			var status := loc.t("ui.powered") if bool(building.get("powered", false)) else loc.t("ui.unpowered")
			var line := BtvTheme.wrapped("%s · %s · %s" % [
				loc.t(str(definition.get("display_key", ""))), status,
				loc.t("ui.build_slot", {"slot": "%d-%d" % [int(building.get("col", 0)) + 1, int(building.get("row", 0)) + 1]}),
			], 13, BtvTheme.TEXT_DIM)
			body.add_child(line)
	body.add_child(BtvTheme.spacer(4))
	add_section(loc.t("ui.build"))
	for building_id in session.registry.buildings.keys():
		var definition: Dictionary = session.registry.get_building(str(building_id))
		var cost: Dictionary = definition.get("cost", {})
		var cost_parts: Array[String] = []
		cost_parts.append("%d cr" % int(cost.get("credits", 0)))
		for raw_item in cost.get("items", []):
			var item: Dictionary = raw_item
			cost_parts.append("%s x%d" % [_item_name(str(item.get("item_id", ""))), int(item.get("count", 1))])
		var free_slot := _first_free_slot()
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL_SOFT, 12, BtvTheme.LINE, 1))
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		card.add_child(column)
		column.add_child(BtvTheme.label(loc.t(str(definition.get("display_key", ""))), 16, BtvTheme.TEXT))
		column.add_child(BtvTheme.wrapped(loc.t(str(definition.get("description_key", ""))), 13, BtvTheme.TEXT_DIM))
		column.add_child(BtvTheme.wrapped("%s: %s" % [loc.t("ui.build_cost"), ", ".join(cost_parts)], 12, BtvTheme.AMBER))
		var power := int(definition.get("power_production", 0))
		var draw := int(definition.get("power_draw", 0))
		var power_parts: Array[String] = []
		if power > 0:
			power_parts.append("+%d" % power)
		if draw > 0:
			power_parts.append("-%d" % draw)
		if not power_parts.is_empty():
			column.add_child(BtvTheme.wrapped("%s: %s" % [loc.t("ui.build_power"), " / ".join(power_parts)], 12, BtvTheme.TEXT_DIM))
		var production = definition.get("production", null)
		if production != null:
			column.add_child(BtvTheme.wrapped("%s: %s -> %s · %s" % [
				loc.t("ui.build_produce"),
				_item_name(str(production.get("input", {}).get("item_id", ""))),
				_item_name(str(production.get("output", {}).get("item_id", ""))),
				loc.t("ui.duration", {"seconds": int(production.get("cycle_seconds", 0))}),
			], 12, BtvTheme.TEXT_DIM))
		var action := BtvTheme.button(loc.t("ui.build_action"), 48)
		action.disabled = free_slot.is_empty()
		if not free_slot.is_empty():
			action.pressed.connect(_build.bind(str(building_id), free_slot))
		column.add_child(action)
	if session.registry.buildings.is_empty():
		add_empty(loc.t("ui.no_build_slot"))
	if _first_free_slot().is_empty():
		add_note(loc.t("ui.no_build_slot"))

func _first_free_slot() -> Dictionary:
	for raw_slot in session.surface_layout().get("build_slots", []):
		var slot: Dictionary = raw_slot
		if not session.build.slot_taken(int(slot.get("col", -1)), int(slot.get("row", -1))):
			return slot
	return {}

func _build(building_id: String, slot: Dictionary) -> void:
	var result := session.build_module(building_id, int(slot.get("col", 0)), int(slot.get("row", 0)))
	if bool(result.get("ok", false)):
		refresh()

func _item_name(item_id: String) -> String:
	var item: Dictionary = session.registry.get_item(item_id)
	return loc.t(str(item.get("display_key", "")))
