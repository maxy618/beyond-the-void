class_name BuildService
extends RefCounted

## Base modules share a local power grid. Production is atomic against the field inventory.

var session = null
var last_production: Array = []

func setup(game_session) -> void:
	session = game_session

func reset() -> void:
	session.buildings.clear()
	last_production.clear()

func totals() -> Dictionary:
	var production := 0
	var draw := 0
	var crew := 0
	var scan_bonus := 0
	for building in session.buildings:
		var definition = session.registry.get_building(str(building.get("definition_id", "")))
		production += int(definition.get("power_production", 0))
		draw += int(definition.get("power_draw", 0))
		var effect = definition.get("effect", {})
		if str(effect.get("type", "")) == "crew_capacity":
			crew += int(effect.get("value", 0))
		elif str(effect.get("type", "")) == "scan_bonus":
			scan_bonus += int(effect.get("value", 0))
	return {
		"power_production": production,
		"power_draw": draw,
		"powered": production >= draw,
		"crew_capacity": crew,
		"scan_bonus": scan_bonus,
	}

func slot_taken(col: int, row: int) -> bool:
	for building in session.buildings:
		if int(building.get("col", -1)) == col and int(building.get("row", -1)) == row:
			return true
	return false

func can_build(definition_id: String, col: int, row: int) -> Dictionary:
	if session.mode != "planet" or session.planet_id.is_empty():
		return {"ok": false, "code": "not_landable"}
	var definition = session.registry.get_building(definition_id)
	if definition.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if col < 0 or row < 0 or col > 1 or row > 1:
		return {"ok": false, "code": "invalid_slot"}
	if slot_taken(col, row):
		return {"ok": false, "code": "occupied"}
	var cost = definition.get("cost", {})
	if session.credits < int(cost.get("credits", 0)):
		return {"ok": false, "code": "no_credits"}
	if not session.inventory.has_many(cost.get("items", [])):
		return {"ok": false, "code": "missing_inputs"}
	return {"ok": true, "code": "ok"}

func build(definition_id: String, col: int, row: int) -> Dictionary:
	var check := can_build(definition_id, col, row)
	if not bool(check.get("ok", false)):
		return check
	var definition = session.registry.get_building(definition_id)
	var cost = definition.get("cost", {})
	session.credits -= int(cost.get("credits", 0))
	session.inventory.remove_many(cost.get("items", []))
	var instance_number := 1
	for building in session.buildings:
		instance_number = maxi(instance_number, int(str(building.get("instance_id", "build.0")).trim_prefix("build.")) + 1)
	var building := {
		"instance_id": "build.%d" % instance_number,
		"definition_id": definition_id,
		"col": col,
		"row": row,
		"powered": false,
		"progress": 0.0,
		"built_at": session.game_time,
	}
	session.buildings.append(building)
	recompute_power()
	session.quests.handle_event("build_module", {"id": definition_id})
	session.add_journal("journal.build." + definition_id.trim_prefix("build."))
	session.notify("build")
	return {"ok": true, "code": "built", "building": building, "totals": totals()}

func recompute_power() -> void:
	var total := totals()
	for building in session.buildings:
		building["powered"] = bool(total.get("powered", false))
		if not building.has("progress"):
			building["progress"] = 0.0

func tick(seconds: float) -> Array:
	last_production.clear()
	if session.mode != "planet":
		return last_production
	recompute_power()
	var total := totals()
	if not bool(total.get("powered", false)):
		return last_production
	for building in session.buildings:
		var definition = session.registry.get_building(str(building.get("definition_id", "")))
		var production = definition.get("production", null)
		if production == null or not bool(building.get("powered", false)):
			continue
		var cycle := maxf(1.0, float(production.get("cycle_seconds", 20.0)))
		building["progress"] = float(building.get("progress", 0.0)) + seconds
		while float(building["progress"]) >= cycle:
			var input_line: Dictionary = production.get("input", {})
			var output_line: Dictionary = production.get("output", {})
			var copy: Inventory = session.inventory.duplicate_inventory()
			if copy.count(str(input_line.get("item_id", ""))) < int(input_line.get("count", 0)):
				building["progress"] = cycle
				break
			if not copy.remove(str(input_line.get("item_id", "")), int(input_line.get("count", 0))):
				building["progress"] = cycle
				break
			var added: Dictionary = copy.add(str(output_line.get("item_id", "")), int(output_line.get("count", 1)))
			if not bool(added.get("ok", false)):
				building["progress"] = cycle
				break
			session.inventory.items = copy.items.duplicate()
			building["progress"] = float(building["progress"]) - cycle
			var event := {
				"building_id": str(building.get("instance_id", "")),
				"item_id": str(output_line.get("item_id", "")),
				"count": int(output_line.get("count", 1)),
			}
			last_production.append(event)
			session.add_journal("journal.build.produced")
	if not last_production.is_empty():
		session.notify("production")
	return last_production
