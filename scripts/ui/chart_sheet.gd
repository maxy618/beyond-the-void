class_name BtvChartSheet
extends BtvPanelBase

## System chart: landing clearance in the current system and linked jump routes.

func setup_chart(p_session: GameSession, p_loc: Localization) -> void:
	setup(p_session, p_loc, "ui.system_map")

func _fill() -> void:
	var system: Dictionary = session.registry.get_system(session.system_id)
	add_section(loc.t(str(system.get("display_key", ""))))
	add_note(loc.t("ui.ship_in_orbit"))
	if session.mode == "planet":
		add_note(loc.t("ui.returned_to_orbit"))
		return
	body.add_child(BtvTheme.spacer(4))
	add_section(loc.t("ui.planets"))
	for raw_planet_id in system.get("planet_ids", []):
		var planet: Dictionary = session.registry.get_planet(str(raw_planet_id))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL_SOFT, 12, BtvTheme.LINE, 1))
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 5)
		card.add_child(column)
		var top := HBoxContainer.new()
		column.add_child(top)
		var planet_name := BtvTheme.label(loc.t(str(planet.get("display_key", ""))), 16, BtvTheme.TEXT)
		planet_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(planet_name)
		top.add_child(BtvTheme.label(loc.t("ui.landable") if bool(planet.get("landable", false)) else loc.t("ui.not_landable"), 11, BtvTheme.ACCENT if bool(planet.get("landable", false)) else BtvTheme.TEXT_FAINT))
		column.add_child(BtvTheme.wrapped(loc.t(str(planet.get("description_key", ""))), 12, BtvTheme.TEXT_DIM))
		if bool(planet.get("landable", false)):
			var land := BtvTheme.button(loc.t("ui.land"), 48)
			land.pressed.connect(_land.bind(str(planet.get("content_id", ""))))
			column.add_child(land)
	body.add_child(BtvTheme.spacer(4))
	add_section(loc.t("ui.destination"))
	for raw_link in system.get("links", []):
		var link_id := str(raw_link)
		var link: Dictionary = session.registry.get_system(link_id)
		var button := BtvTheme.button("%s · %s" % [
			loc.t("ui.jump_to", {"system": loc.t(str(link.get("display_key", "")))}),
			loc.t("ui.fuel_cost", {"fuel": "%.0f" % ShipService.JUMP_FUEL_COST}),
		], 48)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = session.ship.fuel < ShipService.JUMP_FUEL_COST
		button.pressed.connect(_jump.bind(link_id))
		body.add_child(button)
	if system.get("links", []).is_empty():
		add_note(loc.t("ui.travel_unavailable"))

func _land(planet_id: String) -> void:
	if bool(session.land_on(planet_id).get("ok", false)):
		close()

func _jump(system_id: String) -> void:
	if bool(session.travel_to(system_id).get("ok", false)):
		close()
