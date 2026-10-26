extends BtvTestSuite

func test_pack_loads_and_counts() -> void:
	check(registry.load_ok, "core pack should load")
	check(registry.errors.is_empty(), "core pack should have no errors: " + str(registry.errors))
	var flora := 0
	var fauna := 0
	for species_id in registry.species.keys():
		var kind := str((registry.species[species_id] as Dictionary).get("kind", ""))
		if kind == "flora":
			flora += 1
		elif kind == "fauna":
			fauna += 1
	check(flora >= 12, "at least 12 flora records")
	check(fauna >= 12, "at least 12 fauna records")
	check(int(registry.counts().get("items", 0)) >= 12, "at least 12 item records")
	check(int(registry.counts().get("recipes", 0)) >= 8, "at least 8 recipes")
	check(int(registry.counts().get("hulls", 0)) >= 4, "at least 4 hulls")
	check(int(registry.counts().get("quests", 0)) >= 2, "at least 2 quests")
	check(str(registry.pack_versions().get("pack_id", "")) == "btv.core", "pack id")

func test_core_localization_present() -> void:
	var required_ui := ["ui.title", "ui.new_journey", "ui.continue", "ui.land", "ui.inventory", "ui.craft", "ui.market", "ui.build", "ui.save", "ui.journal", "ui.no_objective", "toast.saved"]
	for key in required_ui:
		check(loc.has(key), "missing core UI string " + key)
	for item_id in registry.items.keys():
		var item: Dictionary = registry.get_item(str(item_id))
		check(loc.has(str(item.get("display_key", ""))), "item name key " + str(item.get("display_key", "")))
	for recipe_id in registry.recipes.keys():
		var recipe: Dictionary = registry.get_recipe(str(recipe_id))
		check(loc.has(str(recipe.get("display_key", ""))), "recipe name key " + str(recipe.get("display_key", "")))
	for species_id in registry.species.keys():
		var species: Dictionary = registry.get_species(str(species_id))
		check(loc.has(str(species.get("display_key", ""))), "species name key " + str(species.get("display_key", "")))
		check(loc.has(str(species.get("field_note_key", ""))), "species field note key " + str(species.get("field_note_key", "")))
	for quest_id in registry.quests.keys():
		var quest: Dictionary = registry.get_quest(str(quest_id))
		check(loc.has(str(quest.get("title_key", ""))), "quest title key " + str(quest.get("title_key", "")))
		for step in quest.get("steps", []):
			check(loc.has(str(step.get("title_key", ""))), "quest step key " + str(step.get("title_key", "")))
	for dialogue_id in registry.dialogues.keys():
		var dialogue: Dictionary = registry.get_dialogue(str(dialogue_id))
		check(loc.has(str(dialogue.get("speaker_key", ""))), "dialogue speaker key")
		for node_id in dialogue.get("nodes", {}).keys():
			var node: Dictionary = dialogue["nodes"][node_id]
			check(loc.has(str(node.get("text_key", ""))), "dialogue node key " + str(node.get("text_key", "")))
			for choice in node.get("choices", []):
				check(loc.has(str(choice.get("text_key", ""))), "dialogue choice key " + str(choice.get("text_key", "")))

func test_cross_references_resolve() -> void:
	for recipe_id in registry.recipes.keys():
		var recipe: Dictionary = registry.get_recipe(str(recipe_id))
		for slot in ["inputs", "outputs"]:
			for line in recipe.get(slot, []):
				var item_id := str(line.get("item_id", ""))
				check(not registry.get_item(item_id).is_empty(), "recipe item ref " + item_id)
	for planet_id in registry.planets.keys():
		var planet: Dictionary = registry.get_planet(str(planet_id))
		for species_id in planet.get("species_pool", []):
			check(not registry.get_species(str(species_id)).is_empty(), "planet species ref " + str(species_id))
		if str(planet.get("ecology_id", "")) != "":
			check(not registry.get_ecology(str(planet.get("ecology_id", ""))).is_empty(), "planet ecology ref")
	for ecology_id in registry.ecologies.keys():
		var ecology: Dictionary = registry.get_ecology(str(ecology_id))
		for species_id in ecology.get("species_ids", []):
			check(not registry.get_species(str(species_id)).is_empty(), "ecology species ref " + str(species_id))
	for market_id in registry.markets.keys():
		var market: Dictionary = registry.get_market(str(market_id))
		for line in market.get("initial_stock", []):
			check(not registry.get_item(str(line.get("item_id", ""))).is_empty(), "market item ref")
	for quest_id in registry.quests.keys():
		var quest: Dictionary = registry.get_quest(str(quest_id))
		for dependency in quest.get("content_dependencies", []):
			var ref := str(dependency)
			var found := not registry.get_item(ref).is_empty() or not registry.get_recipe(ref).is_empty() or not registry.get_dialogue(ref).is_empty() or not registry.get_species(ref).is_empty()
			check(found, "quest dependency resolves " + ref)
	for hull_id in registry.hulls.keys():
		var hull: Dictionary = registry.get_hull(str(hull_id))
		for module_id in hull.get("allowed_preinstalled", []):
			check(not registry.get_ship_module(str(module_id)).is_empty(), "hull module ref " + str(module_id))

func test_validator_rejects_broken_value() -> void:
	var original: Dictionary = registry.items["item.crystal_fiber"].duplicate(true)
	registry.items["item.crystal_fiber"]["base_value"] = -3
	var validator := ContentValidator.new()
	var accepted := validator.validate(registry)
	registry.items["item.crystal_fiber"] = original
	check(not accepted, "validator must reject a negative item value")
	check(not validator.errors.is_empty(), "validator records an error")

func test_validator_rejects_missing_localization() -> void:
	var original: Dictionary = registry.items["item.crystal_fiber"].duplicate(true)
	registry.items["item.crystal_fiber"]["display_key"] = "item.test.missing_name"
	var validator := ContentValidator.new()
	var accepted := validator.validate(registry)
	registry.items["item.crystal_fiber"] = original
	check(not accepted, "validator must reject a missing localization key")

func test_manifest_matches_loaded_files() -> void:
	var files: Array = registry.manifest_files
	check(files.size() >= 15, "manifest should describe all content domains")
	for entry in files:
		check(FileAccess.file_exists("res://content/" + str(entry.get("path", ""))), "manifest path exists " + str(entry.get("path", "")))
	check(registry.pack_versions().get("files", []).size() == files.size(), "save pack versions list all files")

func test_unknown_ids_are_safe() -> void:
	check(registry.get_item("item.does.not.exist").is_empty(), "unknown item returns empty")
	check(registry.get_planet("planet.does.not.exist").is_empty(), "unknown planet returns empty")
	check(not registry.has_record("items", "item.does.not.exist"), "has_record false for unknown id")
