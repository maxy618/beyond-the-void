class_name BtvInventorySheet
extends BtvPanelBase

## Read-only pack ledger; moving items is done by crafting, trade and missions.

func setup_inventory(p_session: GameSession, p_loc: Localization) -> void:
	setup(p_session, p_loc, "ui.inventory")

func _fill() -> void:
	add_section(loc.t("ui.inventory_mass", {
		"mass": "%.1f" % session.inventory.total_mass(),
		"capacity": "%.0f" % session.inventory.capacity_kg,
	}))
	add_note(loc.t("ui.credits_value", {"credits": session.credits}))
	body.add_child(BtvTheme.spacer(4))
	var ids: Array = session.inventory.items.keys()
	ids.sort_custom(func(a, b) -> bool:
		return _name(str(a)).nocasecmp_to(_name(str(b))) < 0
	)
	var shown := 0
	for raw_id in ids:
		var item_id := str(raw_id)
		var count: int = session.inventory.count(item_id)
		if count <= 0:
			continue
		shown += 1
		var item: Dictionary = session.registry.get_item(item_id)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL_SOFT, 12, BtvTheme.LINE, 1))
		body.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(8, 0)
		swatch.color = BtvTheme.color(item.get("icon_color", "#7fe0c2"))
		swatch.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(swatch)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		text.add_child(BtvTheme.label(_name(item_id), 16, BtvTheme.TEXT))
		text.add_child(BtvTheme.wrapped("%s · %s" % [
			loc.t("ui.item_stack", {"count": count, "item": _name(item_id)}),
			loc.t("ui.mass_short") + " %.2f" % (float(item.get("mass_kg", 0.0)) * count),
		], 12, BtvTheme.TEXT_DIM))
		var value := BtvTheme.label("%d cr" % int(item.get("base_value", 0)), 13, BtvTheme.AMBER)
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value.custom_minimum_size = Vector2(64, 0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value)
	if shown == 0:
		add_empty(loc.t("ui.inventory_empty"))

func _name(item_id: String) -> String:
	var item: Dictionary = session.registry.get_item(item_id)
	return loc.t(str(item.get("display_key", "")))
