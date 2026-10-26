class_name ContentValidator
extends RefCounted

## Static validation for the external content pack. This does not mutate content.

var errors: Array[String] = []
var warnings: Array[String] = []

const OBJECTIVE_TYPES := [
	"enter_location", "observe_species", "collect_item", "deliver_item", "craft_recipe",
	"repair_object", "trade_quantity", "build_module", "reach_system", "collect_evidence",
	"speak_to_npc", "interact_object", "wait_for_event", "set_world_fact",
]
const CONDITION_TYPES := ["flag", "not_flag", "has_item", "quest_active", "quest_completed", "observed_species"]
const EFFECT_TYPES := ["set_flag", "start_quest", "add_journal", "add_item", "add_credits"]
const CORE_UI_KEYS := [
	"ui.title", "ui.new_journey", "ui.continue", "ui.settings", "ui.inventory", "ui.craft",
	"ui.codex", "ui.build", "ui.journal", "ui.market", "ui.talk", "ui.observe", "ui.gather",
	"ui.calm", "ui.save", "ui.land", "ui.return_to_ship", "ui.ship_loadout", "ui.close",
]

var registry = null
var _ids: Dictionary = {}
var _anchor_ids: Dictionary = {}
var _flags_used: Dictionary = {}

func validate(content) -> bool:
	errors.clear()
	warnings.clear()
	registry = content
	_ids.clear()
	_anchor_ids.clear()
	for bucket_name in ["items", "recipes", "species", "hulls", "ship_modules", "markets", "quests", "dialogues", "buildings", "planets", "systems", "settlements", "ecologies", "multitool_modes"]:
		for content_id in registry.records_of(bucket_name).keys():
			if _ids.has(content_id):
				_err("duplicate content ID: " + str(content_id))
			_ids[content_id] = bucket_name
	for planet_id in registry.planets.keys():
		for anchor in registry.get_planet(planet_id).get("anchors", []):
			_anchor_ids[str(anchor.get("id", ""))] = true
	_validate_manifest()
	_validate_items()
	_validate_recipes()
	_validate_species()
	_validate_ecologies()
	_validate_world()
	_validate_economy()
	_validate_ships()
	_validate_buildings()
	_validate_modes()
	_validate_quests()
	_validate_dialogues()
	_validate_ui_keys()
	return errors.is_empty()

func _validate_manifest() -> void:
	for file in registry.manifest_files:
		var path: String = str(file.get("path", ""))
		if str(registry._file_versions.get(path, "")).is_empty():
			_err("content file has no content_version: " + path)
		var declared: Array = file.get("added_ids", [])
		if declared.is_empty():
			_err("content file declares no added_ids: " + path)
		var seen: Dictionary = {}
		for content_id in declared:
			var id := str(content_id)
			if seen.has(id):
				_err("manifest duplicate ID %s in %s" % [id, path])
			seen[id] = true
			if not _ids.has(id):
				_err("manifest ID not loaded: " + id)
	if registry.planets.is_empty() or registry.quests.is_empty() or registry.dialogues.is_empty():
		_err("content pack must include planets, quests and dialogues")

func _validate_items() -> void:
	var item_names: Dictionary = {}
	for content_id in registry.items.keys():
		item_names[str(content_id)] = true
	for content_id in registry.items.keys():
		var item = registry.get_item(content_id)
		_require_fields(item, ["display_key", "description_key", "category", "stack_limit", "mass_kg", "base_value", "tags", "source_methods"], content_id)
		_check_key(str(item.get("display_key", "")), content_id)
		_check_key(str(item.get("description_key", "")), content_id)
		if int(item.get("stack_limit", 0)) <= 0:
			_err("%s has non-positive stack_limit" % content_id)
		if float(item.get("mass_kg", 0.0)) < 0.0:
			_err("%s has negative mass_kg" % content_id)
		if int(item.get("base_value", -1)) < 0:
			_err("%s has negative base_value" % content_id)
		var recipes = item.get("processing_recipes", [])
		if typeof(recipes) != TYPE_ARRAY:
			_err("%s processing_recipes must be an array" % content_id)
			continue
		for recipe_id in recipes:
			if not registry.recipes.has(str(recipe_id)):
				_err("%s references missing recipe %s" % [content_id, recipe_id])

func _validate_recipes() -> void:
	for content_id in registry.recipes.keys():
		var recipe = registry.get_recipe(content_id)
		_require_fields(recipe, ["display_key", "description_key", "station", "duration_seconds", "inputs", "outputs"], content_id)
		_check_key(str(recipe.get("display_key", "")), content_id)
		_check_key(str(recipe.get("description_key", "")), content_id)
		if float(recipe.get("duration_seconds", 0.0)) <= 0.0:
			_err("%s has non-positive duration" % content_id)
		var inputs = recipe.get("inputs", [])
		var outputs = recipe.get("outputs", [])
		if typeof(inputs) != TYPE_ARRAY or inputs.is_empty():
			_err("%s needs at least one input" % content_id)
		else:
			for line in inputs:
				_check_item_stack(line, str(content_id) + " input")
		if typeof(outputs) != TYPE_ARRAY or outputs.is_empty():
			_err("%s needs at least one output" % content_id)
		else:
			for line in outputs:
				_check_item_stack(line, str(content_id) + " output")
		var unlock = recipe.get("unlock", {})
		if typeof(unlock) == TYPE_DICTIONARY:
			for species_id in unlock.get("observations", []):
				if not registry.species.has(str(species_id)):
					_err("%s unlock references missing species %s" % [content_id, species_id])

func _validate_species() -> void:
	var flora := 0
	var fauna := 0
	for content_id in registry.species.keys():
		var species = registry.get_species(content_id)
		if str(species.get("kind", "")) == "flora":
			flora += 1
		elif str(species.get("kind", "")) == "fauna":
			fauna += 1
		else:
			_err("%s has invalid kind" % content_id)
		_require_fields(species, ["display_key", "field_note_key", "observation_hint_key", "classification", "body_plan", "palette", "biome_tags", "role", "activity", "behavior", "size_m", "population", "observation", "ecology", "ethical_rules"], content_id)
		_check_key(str(species.get("display_key", "")), content_id)
		_check_key(str(species.get("field_note_key", "")), content_id)
		_check_key(str(species.get("observation_hint_key", "")), content_id)
		var palette = species.get("palette", [])
		if typeof(palette) != TYPE_ARRAY or palette.size() < 3:
			_err("%s needs at least 3 palette colours" % content_id)
		var population = species.get("population", {})
		if typeof(population) != TYPE_DICTIONARY or int(population.get("target", 0)) <= 0:
			_err("%s needs population.target > 0" % content_id)
		if int(population.get("initial", 0)) > int(population.get("target", 0)):
			_err("%s initial population exceeds target" % content_id)
		var observation = species.get("observation", {})
		if typeof(observation) != TYPE_DICTIONARY or str(observation.get("requires_tool_mode", "")).is_empty():
			_err("%s needs observation.requires_tool_mode" % content_id)
		elif not registry.multitool_modes.has(str(observation.get("requires_tool_mode", ""))):
			_err("%s requires missing tool mode %s" % [content_id, observation.get("requires_tool_mode")])
		var ecology = species.get("ecology", {})
		if typeof(ecology) == TYPE_DICTIONARY:
			_check_key(str(ecology.get("note_key", "")), content_id)
		if str(species.get("kind", "")) == "flora":
			var harvest = species.get("harvest", {})
			if typeof(harvest) != TYPE_DICTIONARY:
				_err("%s flora needs harvest" % content_id)
			elif not registry.items.has(str(harvest.get("item_id", ""))):
				_err("%s harvests missing item %s" % [content_id, harvest.get("item_id")])
			elif int(harvest.get("amount", 0)) <= 0:
				_err("%s harvest amount must be positive" % content_id)
	if flora < 12:
		_err("content pack needs at least 12 flora records (found %d)" % flora)
	if fauna < 12:
		_err("content pack needs at least 12 fauna records (found %d)" % fauna)

func _validate_ecologies() -> void:
	for content_id in registry.ecologies.keys():
		var ecology = registry.get_ecology(content_id)
		_require_fields(ecology, ["display_key", "summary_key", "planet_id", "species"], content_id)
		_check_key(str(ecology.get("display_key", "")), content_id)
		_check_key(str(ecology.get("summary_key", "")), content_id)
		if not registry.planets.has(str(ecology.get("planet_id", ""))):
			_err("%s references missing planet" % content_id)
		var seen: Dictionary = {}
		for species_id in ecology.get("species", []):
			if seen.has(str(species_id)):
				_err("%s lists species twice: %s" % [content_id, species_id])
			seen[str(species_id)] = true
			if not registry.species.has(str(species_id)):
				_err("%s references missing species %s" % [content_id, species_id])

func _validate_world() -> void:
	for content_id in registry.systems.keys():
		var system = registry.get_system(content_id)
		_require_fields(system, ["display_key", "star_color", "star_radius", "planet_ids", "links", "description_key"], content_id)
		_check_key(str(system.get("display_key", "")), content_id)
		_check_key(str(system.get("description_key", "")), content_id)
		for planet_id in system.get("planet_ids", []):
			if not registry.planets.has(str(planet_id)):
				_err("%s references missing planet %s" % [content_id, planet_id])
		for link in system.get("links", []):
			if not registry.systems.has(str(link)):
				_err("%s links to missing system %s" % [content_id, link])
	for content_id in registry.planets.keys():
		var planet = registry.get_planet(content_id)
		_require_fields(planet, ["display_key", "description_key", "system_id", "kind", "landable", "biome_tags", "palette", "species_pool", "anchors"], content_id)
		_check_key(str(planet.get("display_key", "")), content_id)
		_check_key(str(planet.get("description_key", "")), content_id)
		if not registry.systems.has(str(planet.get("system_id", ""))):
			_err("%s references missing system" % content_id)
		var palette = planet.get("palette", [])
		if typeof(palette) != TYPE_ARRAY or palette.size() < 4:
			_err("%s needs at least 4 palette colours" % content_id)
		for species_id in planet.get("species_pool", []):
			if not registry.species.has(str(species_id)):
				_err("%s species_pool references missing species %s" % [content_id, species_id])
		if str(planet.get("ecology_id", "")) != "" and not registry.ecologies.has(str(planet.get("ecology_id", ""))):
			_err("%s references missing ecology" % content_id)
		for anchor in planet.get("anchors", []):
			if typeof(anchor) != TYPE_DICTIONARY:
				_err("%s anchor must be an object" % content_id)
				continue
			if str(anchor.get("kind", "")).is_empty() or not anchor.has("x") or not anchor.has("y"):
				_err("%s anchor needs kind, x, y" % content_id)
			if str(anchor.get("kind", "")) == "market" and not registry.markets.has(str(anchor.get("id", ""))):
				_err("%s anchor references missing market" % content_id)
			if str(anchor.get("kind", "")) == "npc" and not registry.dialogues.has(str(anchor.get("id", ""))):
				_err("%s anchor references missing dialogue" % content_id)
	for content_id in registry.settlements.keys():
		var settlement = registry.get_settlement(content_id)
		_require_fields(settlement, ["display_key", "planet_id", "population", "description_key", "services"], content_id)
		_check_key(str(settlement.get("display_key", "")), content_id)
		_check_key(str(settlement.get("description_key", "")), content_id)
		if not registry.planets.has(str(settlement.get("planet_id", ""))):
			_err("%s references missing planet" % content_id)

func _validate_economy() -> void:
	for content_id in registry.markets.keys():
		var market = registry.get_market(content_id)
		_require_fields(market, ["display_key", "market_type", "settlement_id", "currency", "stock_model", "initial_stock", "trade_rules"], content_id)
		_check_key(str(market.get("display_key", "")), content_id)
		_check_key(str(market.get("player_facing_explanation_key", "")), content_id)
		if not registry.settlements.has(str(market.get("settlement_id", ""))):
			_err("%s references missing settlement" % content_id)
		var model = market.get("stock_model", {})
		if typeof(model) != TYPE_DICTIONARY or str(model.get("type", "")) != "finite_supply_demand":
			_err("%s must use finite_supply_demand" % content_id)
		var floor_factor := float(model.get("price_floor_factor", 1.0))
		var ceiling_factor := float(model.get("price_ceiling_factor", 1.0))
		if floor_factor <= 0.0 or ceiling_factor < floor_factor:
			_err("%s has invalid price factors" % content_id)
		var seen: Dictionary = {}
		for stock in market.get("initial_stock", []):
			if typeof(stock) != TYPE_DICTIONARY:
				_err("%s stock line must be an object" % content_id)
				continue
			var item_id := str(stock.get("item_id", ""))
			if not registry.items.has(item_id):
				_err("%s stocks missing item %s" % [content_id, item_id])
			if seen.has(item_id):
				_err("%s stocks item twice: %s" % [content_id, item_id])
			seen[item_id] = true
			if int(stock.get("quantity", -1)) < 0 or int(stock.get("target_stock", 0)) <= 0:
				_err("%s stock quantity/target invalid for %s" % [content_id, item_id])
		var rules = market.get("trade_rules", {})
		if typeof(rules) != TYPE_DICTIONARY or not bool(rules.get("atomic", false)):
			_err("%s market trades must be atomic" % content_id)

func _validate_ships() -> void:
	if registry.hulls.is_empty():
		_err("at least one hull is required")
	for content_id in registry.hulls.keys():
		var hull = registry.get_hull(content_id)
		_require_fields(hull, ["display_key", "description_key", "class", "hull_mass_kg", "stats", "slots", "power_budget", "mass_limit_kg", "fuel_capacity", "compatibility_tags"], content_id)
		_check_key(str(hull.get("display_key", "")), content_id)
		_check_key(str(hull.get("description_key", "")), content_id)
		_check_key(str(hull.get("lore_key", "")), content_id)
		var stats = hull.get("stats", {})
		if typeof(stats) != TYPE_DICTIONARY or int(stats.get("jump_range", 0)) <= 0:
			_err("%s needs positive jump_range" % content_id)
	for content_id in registry.ship_modules.keys():
		var module = registry.get_ship_module(content_id)
		_require_fields(module, ["display_key", "description_key", "slot", "mass_kg", "power_draw", "effects"], content_id)
		_check_key(str(module.get("display_key", "")), content_id)
		_check_key(str(module.get("description_key", "")), content_id)
		if float(module.get("mass_kg", 0.0)) <= 0.0:
			_err("%s mass must be positive" % content_id)

func _validate_buildings() -> void:
	for content_id in registry.buildings.keys():
		var building = registry.get_building(content_id)
		_require_fields(building, ["display_key", "description_key", "cost", "power_production", "power_draw", "effect"], content_id)
		_check_key(str(building.get("display_key", "")), content_id)
		_check_key(str(building.get("description_key", "")), content_id)
		var cost = building.get("cost", {})
		if typeof(cost) == TYPE_DICTIONARY:
			if int(cost.get("credits", -1)) < 0:
				_err("%s cost.credits invalid" % content_id)
			for line in cost.get("items", []):
				_check_item_stack(line, str(content_id) + " cost")
		if int(building.get("power_production", 0)) < 0 or int(building.get("power_draw", 0)) < 0:
			_err("%s power values cannot be negative" % content_id)
		var production = building.get("production", null)
		if production != null:
			if typeof(production) != TYPE_DICTIONARY:
				_err("%s production must be an object or null" % content_id)
			else:
				if float(production.get("cycle_seconds", 0.0)) <= 0.0:
					_err("%s production cycle must be positive" % content_id)
				_check_item_stack(production.get("input", {}), str(content_id) + " production input")
				_check_item_stack(production.get("output", {}), str(content_id) + " production output")

func _validate_modes() -> void:
	for content_id in registry.multitool_modes.keys():
		var mode = registry.get_mode(content_id)
		_require_fields(mode, ["display_key", "description_key", "action", "range_m", "energy_draw"], content_id)
		_check_key(str(mode.get("display_key", "")), content_id)
		_check_key(str(mode.get("description_key", "")), content_id)
		_check_key(str(mode.get("ethical_note_key", "")), content_id)

func _validate_quests() -> void:
	for content_id in registry.quests.keys():
		var quest = registry.get_quest(content_id)
		_require_fields(quest, ["title_key", "summary_key", "steps", "rewards", "failure_policy"], content_id)
		_check_key(str(quest.get("title_key", "")), content_id)
		_check_key(str(quest.get("summary_key", "")), content_id)
		var steps = quest.get("steps", [])
		if typeof(steps) != TYPE_ARRAY or steps.is_empty():
			_err("%s needs steps" % content_id)
			continue
		var seen: Dictionary = {}
		for step in steps:
			if typeof(step) != TYPE_DICTIONARY:
				_err("%s step must be an object" % content_id)
				continue
			var step_id := str(step.get("id", ""))
			if step_id.is_empty() or seen.has(step_id):
				_err("%s has missing or duplicate step id" % content_id)
			seen[step_id] = true
			_check_key(str(step.get("title_key", "")), content_id)
			_check_key(str(step.get("journal_key", "")), content_id)
			var objective = step.get("objective", {})
			if typeof(objective) != TYPE_DICTIONARY:
				_err("%s step %s has invalid objective" % [content_id, step_id])
				continue
			var otype := str(objective.get("type", ""))
			if not OBJECTIVE_TYPES.has(otype):
				_err("%s step %s uses unknown objective %s" % [content_id, step_id, otype])
			_check_objective(otype, objective, str(content_id) + "/" + step_id)
		var rewards = quest.get("rewards", {})
		if typeof(rewards) == TYPE_DICTIONARY:
			for line in rewards.get("items", []):
				_check_item_stack(line, str(content_id) + " reward")
			if str(rewards.get("idempotency_key", "")).is_empty():
				_err("%s rewards need an idempotency_key" % content_id)
			_check_key(str(rewards.get("journal_key", "")), content_id)
		for journal_key in quest.get("journal_entries", []):
			_check_key(str(journal_key), content_id)
		for cond in quest.get("start_conditions", []):
			_check_condition(cond, content_id)

func _check_objective(otype: String, objective: Dictionary, label: String) -> void:
	var target := str(objective.get("id", ""))
	match otype:
		"enter_location":
			if not _is_location(target):
				_err("%s references unknown location %s" % [label, target])
		"observe_species":
			if not objective.has("count") or int(objective.get("count", 0)) <= 0:
				_err("%s needs positive count" % label)
			if target != "" and not registry.species.has(target):
				_err("%s references missing species %s" % [label, target])
		"collect_item", "deliver_item", "trade_quantity":
			if not registry.items.has(target):
				_err("%s references missing item %s" % [label, target])
			if int(objective.get("count", 0)) <= 0:
				_err("%s needs positive count" % label)
		"craft_recipe":
			if not registry.recipes.has(target):
				_err("%s references missing recipe %s" % [label, target])
		"build_module":
			if not registry.buildings.has(target):
				_err("%s references missing building %s" % [label, target])
		"reach_system":
			if not registry.systems.has(target):
				_err("%s references missing system %s" % [label, target])
		"speak_to_npc":
			if not registry.dialogues.has(target):
				_err("%s references missing dialogue %s" % [label, target])
		"interact_object", "repair_object":
			if not _anchor_ids.has(target):
				_err("%s references unknown object %s" % [label, target])
		"set_world_fact":
			if str(objective.get("id", "")).is_empty():
				_err("%s needs a fact id" % label)

func _validate_dialogues() -> void:
	for content_id in registry.dialogues.keys():
		var dialogue = registry.get_dialogue(content_id)
		_require_fields(dialogue, ["speaker_key", "entry_node", "nodes"], content_id)
		_check_key(str(dialogue.get("speaker_key", "")), content_id)
		var nodes = dialogue.get("nodes", {})
		if typeof(nodes) != TYPE_DICTIONARY or nodes.is_empty():
			_err("%s has no dialogue nodes" % content_id)
			continue
		var entry := str(dialogue.get("entry_node", ""))
		if not nodes.has(entry):
			_err("%s entry node missing: %s" % [content_id, entry])
		var visit: Dictionary = {}
		for node_id in nodes.keys():
			var node = nodes[node_id]
			if typeof(node) != TYPE_DICTIONARY:
				_err("%s node %s must be an object" % [content_id, node_id])
				continue
			_check_key(str(node.get("text_key", "")), content_id)
			var choice_ids: Dictionary = {}
			var choices = node.get("choices", [])
			if typeof(choices) != TYPE_ARRAY:
				_err("%s node %s choices must be an array" % [content_id, node_id])
				continue
			for choice in choices:
				if typeof(choice) != TYPE_DICTIONARY:
					_err("%s node %s choice must be an object" % [content_id, node_id])
					continue
				var choice_id := str(choice.get("id", ""))
				if choice_id.is_empty() or choice_ids.has(choice_id):
					_err("%s node %s has missing or duplicate choice id" % [content_id, node_id])
				choice_ids[choice_id] = true
				_check_key(str(choice.get("text_key", "")), content_id)
				var next = choice.get("next", null)
				if next != null:
					var next_id := str(next)
					if not nodes.has(next_id):
						_err("%s node %s points to missing node %s" % [content_id, node_id, next_id])
					else:
						visit[next_id] = true
				for cond in choice.get("conditions", []):
					_check_condition(cond, content_id)
				for effect in choice.get("effects", []):
					_check_effect(effect, content_id)
		var queue: Array[String] = []
		if nodes.has(entry):
			queue.append(entry)
			visit[entry] = true
		while not queue.is_empty():
			var current: String = queue.pop_front()
			for choice in (nodes.get(current, {}).get("choices", [])):
				var nxt = choice.get("next", null)
				if nxt != null and nodes.has(str(nxt)) and not visit.has(str(nxt)):
					visit[str(nxt)] = true
					queue.append(str(nxt))
		for node_id in nodes.keys():
			if not visit.has(str(node_id)) and str(node_id) != entry:
				_err("%s has unreachable node %s" % [content_id, node_id])
		var cycles := _find_cycle(nodes, entry)
		if cycles:
			warnings.append("%s contains a dialogue loop through %s (allowed for navigation)" % [content_id, cycles])

func _check_condition(cond, label: String) -> void:
	if typeof(cond) != TYPE_DICTIONARY:
		_err("%s condition must be an object" % label)
		return
	var ctype := str(cond.get("type", ""))
	if not CONDITION_TYPES.has(ctype):
		_err("%s uses unknown condition %s" % [label, ctype])
		return
	var cid := str(cond.get("id", ""))
	match ctype:
		"has_item":
			if not registry.items.has(cid):
				_err("%s condition references missing item %s" % [label, cid])
		"quest_active", "quest_completed":
			if not registry.quests.has(cid):
				_err("%s condition references missing quest %s" % [label, cid])
		"observed_species":
			if not registry.species.has(cid):
				_err("%s condition references missing species %s" % [label, cid])
		_:
			if cid.is_empty():
				_err("%s condition needs an id" % label)

func _check_effect(effect, label: String) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		_err("%s effect must be an object" % label)
		return
	var etype := str(effect.get("type", ""))
	if not EFFECT_TYPES.has(etype):
		_err("%s uses unknown effect %s" % [label, etype])
		return
	if etype == "start_quest" and not registry.quests.has(str(effect.get("id", ""))):
		_err("%s starts missing quest %s" % [label, effect.get("id")])
	if etype == "add_item" and not registry.items.has(str(effect.get("id", ""))):
		_err("%s adds missing item %s" % [label, effect.get("id")])
	if etype == "add_journal":
		_check_key(str(effect.get("key", "")), label)

func _validate_ui_keys() -> void:
	if registry.loc == null:
		return
	for key in CORE_UI_KEYS:
		if not registry.loc.has(key):
			_err("localization missing core UI key: " + key)

func _check_item_stack(line, label: String) -> void:
	if typeof(line) != TYPE_DICTIONARY:
		_err("%s stack must be an object" % label)
		return
	if not registry.items.has(str(line.get("item_id", ""))):
		_err("%s references missing item %s" % [label, line.get("item_id")])
	if int(line.get("count", line.get("quantity", 0))) <= 0:
		_err("%s needs positive count" % label)

func _is_location(location_id: String) -> bool:
	if location_id.ends_with(".surface"):
		return registry.planets.has(location_id.trim_suffix(".surface"))
	return registry.planets.has(location_id) or registry.systems.has(location_id)

func _find_cycle(nodes: Dictionary, start: String) -> String:
	var state: Dictionary = {}
	var stack: Array[String] = []
	var found := _cycle_dfs(nodes, start, state, stack)
	return " -> ".join(found) if not found.is_empty() else ""

func _cycle_dfs(nodes: Dictionary, node_id: String, state: Dictionary, stack: Array[String]) -> Array[String]:
	state[node_id] = 1
	stack.append(node_id)
	var node = nodes.get(node_id, {})
	for choice in node.get("choices", []):
		var nxt = choice.get("next", null)
		if nxt == null:
			continue
		var next_id := str(nxt)
		if not nodes.has(next_id):
			continue
		if state.get(next_id, 0) == 1:
			return stack.duplicate()
		if state.get(next_id, 0) == 0:
			var found := _cycle_dfs(nodes, next_id, state, stack)
			if not found.is_empty():
				return found
	stack.pop_back()
	state[node_id] = 2
	return []

func _require_fields(record: Dictionary, fields: Array, label: String) -> void:
	for field in fields:
		if not record.has(field):
			_err("%s missing required field %s" % [label, field])

func _check_key(key: String, label: String) -> void:
	if key.is_empty():
		_err("%s references an empty localization key" % label)
	elif registry.loc != null and not registry.loc.has(key):
		_err("%s references missing localization key %s" % [label, key])

func _err(message: String) -> void:
	errors.append(message)
