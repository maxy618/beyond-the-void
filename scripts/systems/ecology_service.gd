class_name EcologyService
extends RefCounted

## Local populations, non-lethal observation, sustainable gathering and recovery.

const GATHER_COOLDOWN_SECONDS := 60.0

var session = null
var populations: Dictionary = {}
var recovery_progress: Dictionary = {}

func setup(game_session) -> void:
	session = game_session

func reset() -> void:
	populations.clear()
	recovery_progress.clear()

func ensure_planet(planet_id: String) -> void:
	if planet_id.is_empty() or populations.has(planet_id):
		return
	var planet = session.registry.get_planet(planet_id)
	var pops: Dictionary = {}
	var progress: Dictionary = {}
	for species_id in planet.get("species_pool", []):
		var species = session.registry.get_species(str(species_id))
		var population: Dictionary = species.get("population", {})
		pops[str(species_id)] = int(population.get("initial", 4))
		progress[str(species_id)] = 0.0
	populations[planet_id] = pops
	recovery_progress[planet_id] = progress

func population(planet_id: String, species_id: String) -> int:
	ensure_planet(planet_id)
	return int((populations.get(planet_id, {}) as Dictionary).get(species_id, 0))

func target_population(species_id: String) -> int:
	var species = session.registry.get_species(species_id)
	return int(species.get("population", {}).get("target", 4))

func observe(species_id: String) -> Dictionary:
	var species = session.registry.get_species(species_id)
	if species.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if session.mode != "planet" or session.planet_id.is_empty():
		return {"ok": false, "code": "not_landable"}
	if not _species_present(species_id):
		return {"ok": false, "code": "no_target"}
	var requirement: Dictionary = species.get("observation", {})
	var required_mode := str(requirement.get("requires_tool_mode", ""))
	if not required_mode.is_empty() and session.tool_mode != required_mode:
		return {"ok": false, "code": "wrong_mode", "required_mode": required_mode}
	ensure_planet(session.planet_id)
	var population := population(session.planet_id, species_id)
	if population <= 0:
		return {"ok": false, "code": "no_target"}
	var existing: Dictionary = session.observations.get(species_id, {})
	var first := existing.is_empty()
	existing["count"] = int(existing.get("count", 0)) + 1
	existing["first_seen"] = float(existing.get("first_seen", session.game_time))
	existing["harmed"] = int(existing.get("harmed", 0))
	session.observations[species_id] = existing
	session.quests.handle_event("observe_species", {"id": species_id})
	session.notify("observation")
	return {
		"ok": true, "code": "observed", "species_id": species_id, "first": first,
		"population": population, "field_note_key": str(species.get("field_note_key", "")),
		"species": species,
	}

func gather(species_id: String, node_id: String) -> Dictionary:
	var species = session.registry.get_species(species_id)
	if species.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if session.mode != "planet":
		return {"ok": false, "code": "not_landable"}
	if not _species_present(species_id):
		return {"ok": false, "code": "no_target"}
	if str(species.get("kind", "")) != "flora":
		return {"ok": false, "code": "invalid_target"}
	if session.tool_mode != "mode.sample":
		return {"ok": false, "code": "wrong_mode", "required_mode": "mode.sample"}
	if not session.is_node_ready(node_id):
		return {"ok": false, "code": "regrowing", "seconds": session.node_cooldown_remaining(node_id)}
	if not _node_matches(species_id, node_id):
		return {"ok": false, "code": "no_target"}
	var harvest: Dictionary = species.get("harvest", {})
	var item_id := str(harvest.get("item_id", ""))
	var amount := int(harvest.get("amount", 1))
	if item_id.is_empty() or amount <= 0:
		return {"ok": false, "code": "item_missing"}
	ensure_planet(session.planet_id)
	if population(session.planet_id, species_id) <= 0:
		return {"ok": false, "code": "no_target"}
	var add_check: Dictionary = session.inventory.can_add(item_id, amount)
	if not bool(add_check.get("ok", false)):
		return add_check
	var population_cost := maxi(1, int(harvest.get("population_cost", 1)))
	session.inventory.add(item_id, amount)
	var pops: Dictionary = populations[session.planet_id]
	pops[species_id] = maxi(0, int(pops.get(species_id, 0)) - population_cost)
	session.node_cooldowns[node_id] = session.game_time + GATHER_COOLDOWN_SECONDS
	session.quests.on_inventory_changed()
	session.notify("gather")
	return {
		"ok": true, "code": "gathered", "species_id": species_id, "item_id": item_id,
		"count": amount, "population": int(pops[species_id]),
	}

func calm(species_id: String) -> Dictionary:
	var species = session.registry.get_species(species_id)
	if species.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if session.mode != "planet":
		return {"ok": false, "code": "not_landable"}
	if not _species_present(species_id):
		return {"ok": false, "code": "no_target"}
	if str(species.get("kind", "")) != "fauna":
		return {"ok": false, "code": "invalid_target"}
	if session.tool_mode != "mode.dampen":
		return {"ok": false, "code": "wrong_mode", "required_mode": "mode.dampen"}
	var flag := "calm." + species_id
	var first := not bool(session.facts.get(flag, false))
	session.facts[flag] = true
	session.notify("calm")
	return {"ok": true, "code": "calmed", "species_id": species_id, "first": first}

func tick(seconds: float) -> void:
	if seconds <= 0.0:
		return
	for planet_id in populations.keys():
		var pops: Dictionary = populations[planet_id]
		var progress: Dictionary = recovery_progress.get(planet_id, {})
		for species_id in pops.keys():
			var target := target_population(str(species_id))
			if int(pops[species_id]) >= target:
				progress[species_id] = 0.0
				continue
			var species = session.registry.get_species(str(species_id))
			var recovery := maxf(1.0, float(species.get("population", {}).get("recovery_seconds", 60.0)))
			progress[species_id] = float(progress.get(species_id, 0.0)) + seconds
			while float(progress[species_id]) >= recovery and int(pops[species_id]) < target:
				progress[species_id] = float(progress[species_id]) - recovery
				pops[species_id] = int(pops[species_id]) + 1
		recovery_progress[planet_id] = progress

func to_state() -> Dictionary:
	return {"populations": populations.duplicate(true), "recovery_progress": recovery_progress.duplicate(true)}

func _species_present(species_id: String) -> bool:
	var planet = session.registry.get_planet(session.planet_id)
	return species_id in planet.get("species_pool", [])

func _node_matches(species_id: String, node_id: String) -> bool:
	for node in session.surface_layout().get("nodes", []):
		if str(node.get("node_id", "")) == node_id:
			return str(node.get("species_id", "")) == species_id
	return false

func from_state(state: Dictionary) -> void:
	populations = (state.get("populations", {}) as Dictionary).duplicate(true)
	recovery_progress = (state.get("recovery_progress", {}) as Dictionary).duplicate(true)
