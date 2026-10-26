class_name SaveService
extends RefCounted

## Versioned JSON saves. Primary -> complete temp -> backup fallback; content refs validated before apply.

const CURRENT_SCHEMA := 2

static func save_session(session: GameSession, path: String = GameSession.DEFAULT_SAVE_PATH) -> Dictionary:
	if path.is_empty():
		return {"ok": false, "code": "save_failed", "error": "empty path"}
	var primary_abs := _abs(path)
	var tmp_path := path + ".tmp"
	var tmp_abs := _abs(tmp_path)
	var backup_path := path + ".bak"
	var backup_abs := _abs(backup_path)
	var dir_error := DirAccess.make_dir_recursive_absolute(primary_abs.get_base_dir())
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return {"ok": false, "code": "save_failed", "error": "cannot create save directory (%d)" % dir_error}
	var data := session.to_save_dict()
	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(tmp_abs, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "code": "save_failed", "error": "cannot open temp save"}
	file.store_string(text)
	file.flush()
	file.close()
	var check := _parse_file(tmp_abs)
	if not bool(check.get("ok", false)):
		DirAccess.remove_absolute(tmp_abs)
		return {"ok": false, "code": "save_failed", "error": "temporary save failed validation: " + str(check.get("error", ""))}
	var backup_written := false
	if FileAccess.file_exists(primary_abs):
		var copy_error := DirAccess.copy_absolute(primary_abs, backup_abs)
		if copy_error != OK:
			DirAccess.remove_absolute(tmp_abs)
			return {"ok": false, "code": "save_failed", "error": "cannot refresh backup (%d)" % copy_error}
		backup_written = true
	if FileAccess.file_exists(primary_abs):
		var remove_error := DirAccess.remove_absolute(primary_abs)
		if remove_error != OK:
			DirAccess.remove_absolute(tmp_abs)
			return {"ok": false, "code": "save_failed", "error": "cannot replace primary (%d)" % remove_error}
	var rename_error := DirAccess.rename_absolute(tmp_abs, primary_abs)
	if rename_error != OK:
		return {"ok": false, "code": "save_failed", "error": "cannot finalize save (%d); temp retained" % rename_error, "path": path, "temp_path": tmp_path}
	return {
		"ok": true, "code": "saved", "path": path, "backup_path": backup_path,
		"backup_written": backup_written, "bytes": text.length(),
	}

static func load_into(session: GameSession, path: String = GameSession.DEFAULT_SAVE_PATH) -> Dictionary:
	var candidates := [
		{"path": path, "source": "primary"},
		{"path": path + ".tmp", "source": "temp"},
		{"path": path + ".bak", "source": "backup"},
	]
	var primary_corrupt := false
	var migration_result: Dictionary = {}
	var refs_result: Dictionary = {}
	var source_path := ""
	var source := ""
	var failure: Dictionary = {}
	for candidate in candidates:
		var candidate_path := str(candidate.get("path", ""))
		if not FileAccess.file_exists(_abs(candidate_path)):
			continue
		var read := _parse_file(_abs(candidate_path))
		if not bool(read.get("ok", false)):
			if str(candidate.get("source", "")) == "primary":
				primary_corrupt = true
			failure = {
				"ok": false, "code": "load_failed",
				"error": str(read.get("error", "unreadable save")),
				"source": str(candidate.get("source", "")), "source_path": candidate_path,
			}
			continue
		var candidate_data: Dictionary = read.get("data", {})
		var candidate_migration := migrate(candidate_data, session.registry)
		if not bool(candidate_migration.get("ok", false)):
			if str(candidate.get("source", "")) == "primary":
				primary_corrupt = true
			failure = candidate_migration.duplicate(true)
			failure["source"] = str(candidate.get("source", ""))
			failure["source_path"] = candidate_path
			continue
		var migrated_data: Dictionary = candidate_migration.get("data", {})
		var candidate_refs := validate_content_refs(session.registry, migrated_data)
		if not bool(candidate_refs.get("ok", false)):
			if str(candidate.get("source", "")) == "primary":
				primary_corrupt = true
			failure = {
				"ok": false, "code": "missing_content",
				"error": "save references content that is not installed",
				"errors": candidate_refs.get("errors", []),
				"source": str(candidate.get("source", "")), "source_path": candidate_path,
			}
			continue
		migration_result = candidate_migration
		refs_result = candidate_refs
		source_path = candidate_path
		source = str(candidate.get("source", ""))
		break
	if source.is_empty():
		if failure.is_empty():
			failure = {"ok": false, "code": "load_failed", "error": "no readable save or backup at " + path}
		failure["primary_corrupt"] = primary_corrupt
		return failure
	var migration := migration_result
	var refs := refs_result
	var data: Dictionary = migration.get("data", {})
	data["_save_path"] = source_path
	session.apply_save_data(data)
	return {
		"ok": true, "code": "loaded", "path": path, "source": source,
		"source_path": source_path, "used_backup": source != "primary",
		"primary_corrupt": primary_corrupt,
		"from_schema": migration.get("from_schema", CURRENT_SCHEMA),
		"migrations": migration.get("migrations", []),
		"warnings": refs.get("warnings", []),
	}

static func migrate(data: Dictionary, registry: ContentRegistry) -> Dictionary:
	if not data.has("save_schema") and not data.has("version"):
		return {"ok": false, "code": "load_failed", "error": "save has no schema marker"}
	var from_schema := int(data.get("save_schema", data.get("version", 1)))
	if from_schema > CURRENT_SCHEMA:
		return {"ok": false, "code": "save_too_new", "error": "save schema %d is newer than supported schema %d" % [from_schema, CURRENT_SCHEMA]}
	if from_schema < 1:
		return {"ok": false, "code": "load_failed", "error": "invalid save schema"}
	var working: Dictionary = data.duplicate(true)
	var migrations: Array = []
	var schema := from_schema
	while schema < CURRENT_SCHEMA:
		if schema == 1:
			working = _migrate_v1_to_v2(working, registry)
			migrations.append({"from": 1, "to": 2, "reason": "legacy_prototype"})
			schema = 2
		else:
			return {"ok": false, "code": "load_failed", "error": "no migration path from schema %d" % schema}
	working["save_schema"] = CURRENT_SCHEMA
	return {"ok": true, "code": "migrated", "data": working, "from_schema": from_schema, "migrations": migrations}

static func validate_content_refs(registry: ContentRegistry, data: Dictionary) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var saved_content = data.get("content", {})
	if typeof(saved_content) == TYPE_DICTIONARY:
		var saved_pack := str(saved_content.get("pack_id", ""))
		if not saved_pack.is_empty() and saved_pack != registry.pack_id:
			errors.append("missing_pack:" + saved_pack)
	var location: Dictionary = data.get("location", {})
	var system_id := str(location.get("system_id", ""))
	if registry.get_system(system_id).is_empty():
		errors.append("missing_system:" + system_id)
	var planet_id := str(location.get("planet_id", ""))
	if not planet_id.is_empty():
		var planet = registry.get_planet(planet_id)
		if planet.is_empty():
			errors.append("missing_planet:" + planet_id)
		elif str(planet.get("system_id", "")) != system_id:
			errors.append("planet_system_mismatch:" + planet_id)
	for item_id in (data.get("inventory", {}) as Dictionary).keys():
		if registry.get_item(str(item_id)).is_empty():
			errors.append("missing_item:" + str(item_id))
	for item_id in (data.get("inventory", {}) as Dictionary).keys():
		if int(data["inventory"][item_id]) < 0:
			errors.append("negative_inventory:" + str(item_id))
	var ship_data: Dictionary = data.get("ship", {})
	var hull_id := str(ship_data.get("hull_id", ""))
	if not hull_id.is_empty() and registry.get_hull(hull_id).is_empty():
		errors.append("missing_hull:" + hull_id)
	for module_id in ship_data.get("equipped", []):
		if registry.get_ship_module(str(module_id)).is_empty():
			errors.append("missing_ship_module:" + str(module_id))
	for module_id in ship_data.get("owned", []):
		if registry.get_ship_module(str(module_id)).is_empty():
			errors.append("missing_ship_module:" + str(module_id))
	for building in data.get("buildings", []):
		var definition_id := str(building.get("definition_id", ""))
		if registry.get_building(definition_id).is_empty():
			errors.append("missing_building:" + definition_id)
	var quest_state: Dictionary = data.get("quests", {})
	for quest_id in (quest_state.get("active", {}) as Dictionary).keys():
		if registry.get_quest(str(quest_id)).is_empty():
			errors.append("missing_quest:" + str(quest_id))
	for quest_id in quest_state.get("completed", []):
		if registry.get_quest(str(quest_id)).is_empty():
			errors.append("missing_quest:" + str(quest_id))
	for receipt_key in (quest_state.get("receipts", {}) as Dictionary).keys():
		var receipt = quest_state["receipts"][receipt_key]
		var quest_id := str(receipt.get("quest_id", "")) if typeof(receipt) == TYPE_DICTIONARY else ""
		if not quest_id.is_empty() and registry.get_quest(quest_id).is_empty():
			errors.append("missing_quest:" + quest_id)
	for species_id in (data.get("observations", {}) as Dictionary).keys():
		if registry.get_species(str(species_id)).is_empty():
			errors.append("missing_species:" + str(species_id))
	for market_id in (data.get("markets", {}) as Dictionary).keys():
		if registry.get_market(str(market_id)).is_empty():
			errors.append("missing_market:" + str(market_id))
	var ecology_state: Dictionary = data.get("ecology", {})
	for planet_key in (ecology_state.get("populations", {}) as Dictionary).keys():
		for species_id in (ecology_state["populations"][planet_key] as Dictionary).keys():
			if registry.get_species(str(species_id)).is_empty():
				errors.append("missing_species:" + str(species_id))
	var tool_mode := str(data.get("tool_mode", "mode.scan"))
	if registry.get_mode(tool_mode).is_empty():
		errors.append("missing_tool_mode:" + tool_mode)
	if registry.get_mode("mode.scan").is_empty():
		errors.append("missing_tool_mode:mode.scan")
	var generator_version := int(data.get("generator_version", 0))
	if generator_version > 0 and generator_version != WorldGen.GENERATOR_VERSION:
		warnings.append("generator_version_changed:%d->%d" % [generator_version, WorldGen.GENERATOR_VERSION])
	var saved_version := str((data.get("content", {}) as Dictionary).get("content_version", ""))
	if not saved_version.is_empty() and saved_version != registry.content_version:
		warnings.append("content_version_changed:" + saved_version + "->" + registry.content_version)
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}

static func _migrate_v1_to_v2(data: Dictionary, registry: ContentRegistry) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var system_id := "system.ashfall_gate"
	var planet_id := ""
	var mode := "space"
	var location = data.get("location", "")
	if typeof(location) == TYPE_STRING:
		var loc_text := str(location)
		if loc_text.begins_with("planet."):
			planet_id = loc_text
			var planet = registry.get_planet(planet_id)
			system_id = str(planet.get("system_id", system_id))
			mode = "planet"
		elif loc_text.begins_with("system."):
			system_id = loc_text
	elif typeof(location) == TYPE_DICTIONARY:
		system_id = str(location.get("system_id", system_id))
		planet_id = str(location.get("planet_id", ""))
		mode = str(location.get("mode", "planet" if not planet_id.is_empty() else "space"))
	var player_pos = data.get("player_pos", [0.0, 0.0])
	out["save_schema"] = 2
	out["world_seed"] = int(data.get("world_seed", data.get("seed", GameSession.START_WORLD_SEED)))
	out["location"] = {"system_id": system_id, "planet_id": planet_id, "mode": mode, "player_pos": player_pos}
	out["game_time"] = float(data.get("game_time", 0.0))
	out["credits"] = int(data.get("credits", 0))
	out["facts"] = data.get("facts", {})
	out["observations"] = data.get("observations", {})
	out["inventory"] = data.get("inventory", {})
	out["buildings"] = data.get("buildings", [])
	out["node_cooldowns"] = data.get("node_cooldowns", {})
	out["tool_mode"] = str(data.get("tool_mode", "mode.scan"))
	out["markets"] = data.get("markets", {})
	out["journal"] = data.get("journal", [])
	out["event_log"] = data.get("event_log", [])
	out["ecology"] = data.get("ecology", {})
	out["settings"] = data.get("settings", {
		"quality": "balanced", "reduced_motion": false, "left_handed": false,
		"text_scale": 1.0, "touch_sensitivity": 1.0,
	})
	var quests_src = data.get("quests", {})
	if typeof(quests_src) == TYPE_ARRAY:
		var active: Dictionary = {}
		for quest_id in quests_src:
			active[str(quest_id)] = {"completed_steps": [], "seen": {}, "counts": {}, "started_at": 0.0}
		out["quests"] = {"active": active, "completed": data.get("completed_quests", []), "receipts": {}, "pending_rewards": {}}
	elif typeof(quests_src) == TYPE_DICTIONARY:
		quests_src["pending_rewards"] = quests_src.get("pending_rewards", {})
		out["quests"] = quests_src
	else:
		out["quests"] = {"active": {}, "completed": [], "receipts": {}, "pending_rewards": {}}
	var ship_src: Dictionary = data.get("ship", {})
	out["ship"] = {
		"hull_id": str(ship_src.get("hull_id", ship_src.get("hull", ShipService.DEFAULT_HULL))),
		"equipped": ship_src.get("equipped", ship_src.get("modules", ShipService.DEFAULT_MODULES)),
		"owned": ship_src.get("owned", ShipService.OWNED_MODULES),
		"fuel": float(ship_src.get("fuel", 80.0)),
	}
	out["migration_history"] = [{"from": 1, "to": 2, "reason": "legacy_prototype"}]
	return out

static func _parse_file(path: String) -> Dictionary:
	var abs_path := _abs(path)
	if not FileAccess.file_exists(abs_path):
		return {"ok": false, "error": "missing file"}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(abs_path)) != OK:
		return {"ok": false, "error": "JSON parse error line %d: %s" % [json.get_error_line(), json.get_error_message()]}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "save root must be an object"}
	return {"ok": true, "data": json.data}

static func _abs(path: String) -> String:
	if path.is_absolute_path():
		return path
	return ProjectSettings.globalize_path(path)
