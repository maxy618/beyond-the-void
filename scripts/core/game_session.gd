class_name GameSession
extends RefCounted

## Persistent player session and the single place that coordinates domain services.

signal changed(reason: String)
signal journal_added(entry: Dictionary)
signal toast_requested(code: String, args: Dictionary)

const GAME_VERSION := "0.1.0"
const SAVE_SCHEMA := 2
const START_WORLD_SEED := 424242
const DEFAULT_SAVE_PATH := "user://saves/slot_1.json"

var registry: ContentRegistry = null
var loc: Localization = null
var inventory: Inventory = null
var quests: QuestEngine = null
var dialogue: DialogueEngine = null
var ecology: EcologyService = null
var build: BuildService = null
var ship: ShipService = null

var world_seed: int = START_WORLD_SEED
var system_id: String = "system.ashfall_gate"
var planet_id: String = ""
var mode: String = "space"
var player_pos: Vector2 = Vector2.ZERO
var credits: int = 0
var facts: Dictionary = {}
var observations: Dictionary = {}
var market_states: Dictionary = {}
var buildings: Array = []
var node_cooldowns: Dictionary = {}
var tool_mode: String = "mode.scan"
var game_time: float = 0.0
var journal: Array = []
var settings: Dictionary = {}
var event_log: Array = []
var migration_history: Array = []
var save_path: String = DEFAULT_SAVE_PATH
var last_notice: String = ""
var surface_cache: Dictionary = {}

func _init(content_registry: ContentRegistry, localization: Localization = null) -> void:
	registry = content_registry
	loc = localization if localization != null else registry.loc
	if loc == null:
		loc = Localization.new()
	inventory = Inventory.new()
	inventory.setup(registry)
	quests = QuestEngine.new()
	quests.setup(self)
	dialogue = DialogueEngine.new()
	dialogue.setup(self)
	ecology = EcologyService.new()
	ecology.setup(self)
	build = BuildService.new()
	build.setup(self)
	ship = ShipService.new()
	ship.setup(self)
	settings = default_settings()

func default_settings() -> Dictionary:
	return {
		"quality": "balanced",
		"reduced_motion": false,
		"left_handed": false,
		"text_scale": 1.0,
		"touch_sensitivity": 1.0,
	}

func new_game(world_seed_value: int = START_WORLD_SEED) -> void:
	world_seed = world_seed_value
	system_id = "system.ashfall_gate"
	planet_id = ""
	mode = "space"
	player_pos = Vector2.ZERO
	credits = 120
	facts.clear()
	facts["flag.game_started"] = true
	observations.clear()
	buildings.clear()
	node_cooldowns.clear()
	game_time = 0.0
	journal.clear()
	event_log.clear()
	migration_history.clear()
	surface_cache.clear()
	tool_mode = "mode.scan"
	save_path = DEFAULT_SAVE_PATH
	dialogue.reset()
	ecology.reset()
	build.reset()
	quests.reset()
	inventory.from_dict({})
	ship.reset()
	_init_markets()
	inventory.add_many([
		{"item_id": "item.alloy_plate", "count": 2},
		{"item_id": "item.saltglass_shard", "count": 2},
		{"item_id": "item.crystal_fiber", "count": 1},
		{"item_id": "item.ration_pack", "count": 2},
		{"item_id": "item.purified_water", "count": 2},
		{"item_id": "item.repair_kit", "count": 1},
		{"item_id": "item.mira_photo", "count": 1},
	])
	add_journal("journal.intro")
	quests.start_auto_quests()
	record_event("new_game", {"world_seed": world_seed})
	notify("new_game")

func _init_markets() -> void:
	market_states.clear()
	for market_id in registry.markets.keys():
		var state := MarketState.new()
		state.setup(registry.get_market(str(market_id)))
		market_states[str(market_id)] = state

func get_market(market_id: String) -> MarketState:
	return market_states.get(market_id, null)

func get_planet() -> Dictionary:
	return registry.get_planet(planet_id)

func get_system() -> Dictionary:
	return registry.get_system(system_id)

func location_id() -> String:
	if mode == "planet" and not planet_id.is_empty():
		return planet_id + ".surface"
	return system_id

func surface_layout() -> Dictionary:
	if planet_id.is_empty():
		return {}
	if surface_cache.get("planet_id", "") != planet_id:
		surface_cache = WorldGen.surface_layout(registry.get_planet(planet_id), registry, world_seed)
	return surface_cache

func land_on(target_planet_id: String) -> Dictionary:
	var planet = registry.get_planet(target_planet_id)
	if planet.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if not bool(planet.get("landable", false)):
		return {"ok": false, "code": "not_landable"}
	if str(planet.get("system_id", "")) != system_id:
		return {"ok": false, "code": "not_adjacent"}
	mode = "planet"
	planet_id = target_planet_id
	surface_cache.clear()
	var layout := surface_layout()
	var start = layout.get("start_pos", [1150.0, 1930.0])
	player_pos = Vector2(float(start[0]), float(start[1]))
	ecology.ensure_planet(planet_id)
	facts["visited." + planet_id] = true
	add_journal("journal.landing")
	quests.handle_event("enter_location", {"id": location_id()})
	record_event("landing", {"planet_id": planet_id})
	notify("landing")
	return {"ok": true, "code": "landed", "planet_id": planet_id, "layout": layout}

func return_to_space() -> Dictionary:
	if mode != "planet":
		return {"ok": false, "code": "invalid_target"}
	facts["visited." + planet_id] = true
	mode = "space"
	planet_id = ""
	player_pos = Vector2.ZERO
	surface_cache.clear()
	notify("launch")
	return {"ok": true, "code": "launched"}

func travel_to(target_system_id: String) -> Dictionary:
	if mode != "space":
		return {"ok": false, "code": "not_in_space"}
	var check := ship.travel_check(target_system_id)
	if not bool(check.get("ok", false)):
		return check
	ship.consume_jump()
	system_id = target_system_id
	planet_id = ""
	facts["visited." + target_system_id] = true
	quests.handle_event("reach_system", {"id": target_system_id})
	record_event("travel", {"system_id": target_system_id, "fuel": ship.fuel})
	notify("travel")
	return {"ok": true, "code": "ok", "system_id": target_system_id, "fuel": ship.fuel}

func set_tool_mode(mode_id: String) -> Dictionary:
	if registry.get_mode(mode_id).is_empty():
		return {"ok": false, "code": "invalid_target"}
	tool_mode = mode_id
	notify("tool_mode")
	return {"ok": true, "code": "mode_changed", "mode_id": mode_id}

func observe_species(species_id: String) -> Dictionary:
	var result := ecology.observe(species_id)
	if bool(result.get("ok", false)):
		record_event("observation", {"species_id": species_id, "first": result.get("first", false)})
		if bool(result.get("first", false)):
			toast_requested.emit("observed", {"species": loc.t(str(result.get("species", {}).get("display_key", "")))})
	return result

func gather_species(species_id: String, node_id: String) -> Dictionary:
	var result := ecology.gather(species_id, node_id)
	if bool(result.get("ok", false)):
		record_event("gather", {"species_id": species_id, "item_id": result.get("item_id", ""), "count": result.get("count", 0)})
		toast_requested.emit("gathered", {"count": result.get("count", 0), "item": loc.t(str(registry.get_item(str(result.get("item_id", ""))).get("display_key", "")))})
	return result

func calm_species(species_id: String) -> Dictionary:
	return ecology.calm(species_id)

func is_node_ready(node_id: String) -> bool:
	return game_time >= float(node_cooldowns.get(node_id, 0.0))

func node_cooldown_remaining(node_id: String) -> float:
	return maxf(0.0, float(node_cooldowns.get(node_id, 0.0)) - game_time)

func craft_recipe(recipe_id: String) -> Dictionary:
	var recipe = registry.get_recipe(recipe_id)
	var result := CraftingService.craft(recipe, inventory, observations)
	if bool(result.get("ok", false)):
		game_time += float(recipe.get("duration_seconds", 0.0))
		quests.handle_event("craft_recipe", {"id": recipe_id})
		quests.on_inventory_changed()
		record_event("craft", {"recipe_id": recipe_id})
		toast_requested.emit("crafted", {"item": loc.t(str(recipe.get("display_key", "")))})
		notify("craft")
	return result

func can_craft(recipe_id: String) -> Dictionary:
	return CraftingService.can_craft(registry.get_recipe(recipe_id), inventory, observations)

func buy(market_id: String, item_id: String, quantity: int = 1) -> Dictionary:
	var market := get_market(market_id)
	if market == null:
		return {"ok": false, "code": "invalid_target"}
	var result: Dictionary = market.commit_buy(item_id, quantity, inventory, credits, registry)
	if bool(result.get("ok", false)):
		credits = int(result.get("credits_after", credits))
		quests.handle_event("trade_quantity", {"id": item_id, "quantity": quantity})
		quests.on_inventory_changed()
		record_event("trade_buy", result.duplicate(true))
		notify("trade")
	return result

func sell(market_id: String, item_id: String, quantity: int = 1) -> Dictionary:
	var market := get_market(market_id)
	if market == null:
		return {"ok": false, "code": "invalid_target"}
	var result: Dictionary = market.commit_sell(item_id, quantity, inventory, credits, registry)
	if bool(result.get("ok", false)):
		credits = int(result.get("credits_after", credits))
		quests.handle_event("trade_quantity", {"id": item_id, "quantity": quantity})
		record_event("trade_sell", result.duplicate(true))
		notify("trade")
	return result

func build_module(definition_id: String, col: int, row: int) -> Dictionary:
	var result := build.build(definition_id, col, row)
	if bool(result.get("ok", false)):
		record_event("build", {"definition_id": definition_id, "col": col, "row": row})
	return result

func interact_object(object_id: String, action: String) -> Dictionary:
	if object_id == "object.relay_console" and action == "restore_power":
		if bool(facts.get("flag.relay_repaired", false)):
			return {"ok": true, "code": "already_done"}
		if not bool(facts.get("flag.lens_calibrated", false)):
			return {"ok": false, "code": "need_calibration"}
		if inventory.count("item.signal_lens") < 1:
			return {"ok": false, "code": "need_lens"}
		inventory.remove("item.signal_lens", 1)
		facts["flag.lens_calibrated"] = false
		facts["flag.relay_repaired"] = true
		add_journal("journal.relay.repaired")
		quests.handle_event("interact_object", {"id": object_id, "action": action})
		record_event("interact", {"object_id": object_id, "action": action})
		toast_requested.emit("repaired", {})
		notify("interact")
		return {"ok": true, "code": "repaired"}
	quests.handle_event("interact_object", {"id": object_id, "action": action})
	notify("interact")
	return {"ok": true, "code": "interacted"}

func talk_to(dialogue_id: String) -> Dictionary:
	var result := dialogue.start(dialogue_id)
	if bool(result.get("ok", false)):
		add_journal("journal.talk." + dialogue_id.trim_prefix("dialogue."))
		notify("dialogue")
	return result

func equip_module(module_id: String) -> Dictionary:
	var result := ship.equip(module_id)
	if bool(result.get("ok", false)):
		record_event("ship_equip", {"module_id": module_id})
		notify("ship")
	return result

func unequip_module(module_id: String) -> Dictionary:
	var result := ship.unequip(module_id)
	if bool(result.get("ok", false)):
		record_event("ship_unequip", {"module_id": module_id})
		notify("ship")
	return result

func advance_time(seconds: float) -> void:
	if seconds <= 0.0:
		return
	game_time += seconds
	ecology.tick(seconds)
	build.tick(seconds)
	for market in market_states.values():
		market.tick(seconds)

func add_journal(key: String) -> void:
	if key.is_empty():
		return
	for entry in journal:
		if str(entry.get("key", "")) == key:
			return
	var entry := {"key": key, "at": game_time}
	journal.append(entry)
	journal_added.emit(entry)

func record_event(event_type: String, data: Dictionary = {}) -> void:
	event_log.append({"type": event_type, "at": game_time, "data": data.duplicate(true)})
	while event_log.size() > 200:
		event_log.pop_front()

func notify(reason: String) -> void:
	last_notice = reason
	changed.emit(reason)

func set_setting(key: String, value) -> void:
	settings[key] = value
	notify("settings")

func to_save_dict() -> Dictionary:
	var markets: Dictionary = {}
	for market_id in market_states.keys():
		markets[str(market_id)] = (market_states[market_id] as MarketState).to_state()
	return {
		"save_schema": SAVE_SCHEMA,
		"game_version": GAME_VERSION,
		"generator_version": WorldGen.GENERATOR_VERSION,
		"content": registry.pack_versions(),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"world_seed": world_seed,
		"location": {
			"system_id": system_id,
			"planet_id": planet_id,
			"mode": mode,
			"player_pos": [player_pos.x, player_pos.y],
		},
		"game_time": game_time,
		"credits": credits,
		"facts": facts.duplicate(true),
		"observations": observations.duplicate(true),
		"inventory": inventory.to_dict(),
		"inventory_capacity_kg": inventory.capacity_kg,
		"markets": markets,
		"quests": quests.to_state(),
		"buildings": buildings.duplicate(true),
		"node_cooldowns": node_cooldowns.duplicate(true),
		"tool_mode": tool_mode,
		"journal": journal.duplicate(true),
		"settings": settings.duplicate(true),
		"ship": ship.to_state(),
		"ecology": ecology.to_state(),
		"migration_history": migration_history.duplicate(true),
		"event_log": event_log.duplicate(true),
	}

func apply_save_data(data: Dictionary) -> void:
	var location: Dictionary = data.get("location", {})
	world_seed = int(data.get("world_seed", START_WORLD_SEED))
	system_id = str(location.get("system_id", "system.ashfall_gate"))
	planet_id = str(location.get("planet_id", ""))
	mode = str(location.get("mode", "space"))
	var pos: Array = location.get("player_pos", [0.0, 0.0])
	player_pos = Vector2(float(pos[0]), float(pos[1])) if pos.size() >= 2 else Vector2.ZERO
	game_time = float(data.get("game_time", 0.0))
	credits = int(data.get("credits", 0))
	facts = (data.get("facts", {}) as Dictionary).duplicate(true)
	observations = (data.get("observations", {}) as Dictionary).duplicate(true)
	quests.from_state(data.get("quests", {}))
	buildings = (data.get("buildings", []) as Array).duplicate(true)
	node_cooldowns = (data.get("node_cooldowns", {}) as Dictionary).duplicate(true)
	tool_mode = str(data.get("tool_mode", "mode.scan"))
	journal = (data.get("journal", []) as Array).duplicate(true)
	settings = default_settings()
	for key in (data.get("settings", {}) as Dictionary).keys():
		settings[key] = data["settings"][key]
	migration_history = (data.get("migration_history", []) as Array).duplicate(true)
	event_log = (data.get("event_log", []) as Array).duplicate(true)
	ship.from_state(data.get("ship", {}))
	inventory.from_dict((data.get("inventory", {}) as Dictionary).duplicate())
	inventory.capacity_kg = float(data.get("inventory_capacity_kg", ship.stats().get("cargo_mass", 80.0)))
	ecology.from_state(data.get("ecology", {}))
	_init_markets()
	for market_id in (data.get("markets", {}) as Dictionary).keys():
		var state := get_market(str(market_id))
		if state != null:
			state.from_state(data["markets"][market_id])
	surface_cache.clear()
	if mode == "planet":
		ecology.ensure_planet(planet_id)
	dialogue.reset()
	build.last_production.clear()
	save_path = str(data.get("_save_path", save_path))
	notify("loaded")

func save(path: String = "") -> Dictionary:
	var target := path if not path.is_empty() else save_path
	var result := SaveService.save_session(self, target)
	if bool(result.get("ok", false)):
		save_path = target
	return result

func load_save(path: String = "") -> Dictionary:
	var target := path if not path.is_empty() else save_path
	return SaveService.load_into(self, target)

func setting_text_size(base: int) -> int:
	return maxi(12, int(round(base * float(settings.get("text_scale", 1.0)))))

func quality_particles(base: int) -> int:
	var factor: float = float({"low": 0.35, "balanced": 0.7, "high": 1.0, "ultra": 1.35}.get(str(settings.get("quality", "balanced")), 0.7))
	return maxi(4, int(base * float(factor)))
