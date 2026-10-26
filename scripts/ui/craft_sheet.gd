class_name BtvCraftSheet
extends BtvPanelBase

## Field fabricator recipes. Availability is derived from the same service that commits the craft.

func setup_craft(p_session: GameSession, p_loc: Localization) -> void:
	setup(p_session, p_loc, "ui.craft")

func _fill() -> void:
	add_note(loc.t("ui.mass_value", {
		"mass": "%.1f" % session.inventory.total_mass(),
		"capacity": "%.0f" % session.inventory.capacity_kg,
	}))
	var ids: Array = session.registry.recipes.keys()
	ids.sort_custom(func(a, b) -> bool:
		return _recipe_name(str(a)).nocasecmp_to(_recipe_name(str(b))) < 0
	)
	for raw_id in ids:
		var recipe_id := str(raw_id)
		var recipe: Dictionary = session.registry.get_recipe(recipe_id)
		var unlocked := CraftingService.is_unlocked(recipe, session.observations)
		var check: Dictionary = CraftingService.can_craft(recipe, session.inventory, session.observations)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BtvTheme.flat(
			BtvTheme.PANEL_SOFT if unlocked else BtvTheme.BG_DEEP, 12,
			BtvTheme.LINE if unlocked else BtvTheme.dim(0.08), 1))
		body.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		card.add_child(column)
		var top := HBoxContainer.new()
		column.add_child(top)
		var name_label := BtvTheme.label(_recipe_name(recipe_id), 16, BtvTheme.TEXT if unlocked else BtvTheme.TEXT_FAINT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_label)
		var time_label := BtvTheme.label(loc.t("ui.duration", {"seconds": int(recipe.get("duration_seconds", 0))}), 12, BtvTheme.TEXT_DIM)
		top.add_child(time_label)
		column.add_child(BtvTheme.wrapped(loc.t(str(recipe.get("description_key", ""))), 13, BtvTheme.TEXT_DIM))
		if not unlocked:
			var unlock: Dictionary = recipe.get("unlock", {})
			for raw_species in unlock.get("observations", []):
				var species: Dictionary = session.registry.get_species(str(raw_species))
				column.add_child(BtvTheme.wrapped(loc.t("ui.unlocked_by", {
					"species": loc.t(str(species.get("display_key", ""))),
				}), 12, BtvTheme.AMBER))
			column.add_child(BtvTheme.label(loc.t("ui.recipe_locked"), 12, BtvTheme.TEXT_FAINT))
			continue
		var input_parts: Array[String] = []
		for raw_input in recipe.get("inputs", []):
			var input: Dictionary = raw_input
			var item_id := str(input.get("item_id", ""))
			var need := int(input.get("count", 1))
			input_parts.append("%s %d/%d" % [_item_name(item_id), session.inventory.count(item_id), need])
		var output_parts: Array[String] = []
		for raw_output in recipe.get("outputs", []):
			var output: Dictionary = raw_output
			output_parts.append("%s x%d" % [_item_name(str(output.get("item_id", ""))), int(output.get("count", 1))])
		column.add_child(BtvTheme.wrapped("%s: %s" % [loc.t("ui.inputs"), ", ".join(input_parts)], 12, BtvTheme.TEXT_DIM))
		column.add_child(BtvTheme.wrapped("%s: %s" % [loc.t("ui.outputs"), ", ".join(output_parts)], 12, BtvTheme.ACCENT))
		var action := BtvTheme.button(loc.t("ui.craft_action"), 48)
		action.disabled = not bool(check.get("ok", false))
		action.pressed.connect(_craft.bind(recipe_id))
		column.add_child(action)
	if session.registry.recipes.is_empty():
		add_empty(loc.t("ui.no_recipes"))

func _craft(recipe_id: String) -> void:
	var result := session.craft_recipe(recipe_id)
	if bool(result.get("ok", false)):
		refresh()

func _recipe_name(recipe_id: String) -> String:
	var recipe: Dictionary = session.registry.get_recipe(recipe_id)
	return loc.t(str(recipe.get("display_key", "")))

func _item_name(item_id: String) -> String:
	var item: Dictionary = session.registry.get_item(item_id)
	return loc.t(str(item.get("display_key", "")))
