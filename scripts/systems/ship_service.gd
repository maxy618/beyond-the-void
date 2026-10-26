class_name ShipService
extends RefCounted

## Loadout validation and derived ship stats. Fuel is part of the persistent state.

const DEFAULT_HULL := "ship.hull.salt_skiff"
const DEFAULT_MODULES := ["ship.module.scan_array", "ship.module.ion_fins"]
const OWNED_MODULES := [
	"ship.module.scan_array", "ship.module.ion_fins", "ship.module.cargo_pods", "ship.module.heat_sink",
]
const JUMP_FUEL_COST := 8.0

var session = null
var hull_id: String = DEFAULT_HULL
var equipped: Array = []
var owned: Array = []
var fuel: float = 80.0

func setup(game_session) -> void:
	session = game_session

func reset() -> void:
	hull_id = DEFAULT_HULL
	equipped = DEFAULT_MODULES.duplicate()
	owned = OWNED_MODULES.duplicate()
	var hull = get_hull()
	fuel = float(hull.get("fuel_capacity", 80))
	sync_inventory_capacity()

func get_hull() -> Dictionary:
	return session.registry.get_hull(hull_id)

func get_module(module_id: String) -> Dictionary:
	return session.registry.get_ship_module(module_id)

func module_mass() -> float:
	var mass := 0.0
	for module_id in equipped:
		mass += float(get_module(str(module_id)).get("mass_kg", 0.0))
	return mass

func power_draw() -> float:
	var draw := 0.0
	for module_id in equipped:
		draw += float(get_module(str(module_id)).get("power_draw", 0.0))
	return draw

func slot_usage() -> Dictionary:
	var usage: Dictionary = {}
	for module_id in equipped:
		var slot := str(get_module(str(module_id)).get("slot", "utility"))
		usage[slot] = int(usage.get(slot, 0)) + 1
	return usage

func stats() -> Dictionary:
	var hull := get_hull()
	var out: Dictionary = (hull.get("stats", {}) as Dictionary).duplicate()
	for module_id in equipped:
		for effect_key in get_module(str(module_id)).get("effects", {}).keys():
			out[effect_key] = float(out.get(effect_key, 0.0)) + float(get_module(str(module_id)).get("effects", {})[effect_key])
	out["mass_kg"] = float(hull.get("hull_mass_kg", 0.0)) + module_mass()
	out["module_mass_kg"] = module_mass()
	out["mass_limit_kg"] = float(hull.get("mass_limit_kg", 0.0))
	out["power_draw"] = power_draw()
	out["power_budget"] = float(hull.get("power_budget", 0.0))
	out["fuel"] = fuel
	out["fuel_capacity"] = float(hull.get("fuel_capacity", 0.0))
	out["slots"] = hull.get("slots", {})
	out["slot_usage"] = slot_usage()
	return out

func can_equip(module_id: String) -> Dictionary:
	var module := get_module(module_id)
	if module.is_empty():
		return {"ok": false, "code": "module_missing"}
	if not module_id in owned:
		return {"ok": false, "code": "not_owned"}
	if module_id in equipped:
		return {"ok": false, "code": "already_equipped"}
	var hull := get_hull()
	var slot := str(module.get("slot", "utility"))
	var slots: Dictionary = hull.get("slots", {})
	if int(slot_usage().get(slot, 0)) >= int(slots.get(slot, 0)):
		return {"ok": false, "code": "slots_full"}
	var compatible := false
	for tag in module.get("compatibility_tags", []):
		if str(tag) in hull.get("compatibility_tags", []):
			compatible = true
			break
	if not compatible:
		return {"ok": false, "code": "incompatible"}
	var new_mass: float = float(hull.get("hull_mass_kg", 0.0)) + module_mass() + float(module.get("mass_kg", 0.0))
	if new_mass > float(hull.get("mass_limit_kg", 0.0)):
		return {"ok": false, "code": "mass_limit"}
	if power_draw() + float(module.get("power_draw", 0.0)) > float(hull.get("power_budget", 0.0)):
		return {"ok": false, "code": "power_limit"}
	return {"ok": true, "code": "ok"}

func equip(module_id: String) -> Dictionary:
	var check := can_equip(module_id)
	if not bool(check.get("ok", false)):
		return check
	equipped.append(module_id)
	sync_inventory_capacity()
	return {"ok": true, "code": "module_equipped", "module_id": module_id, "stats": stats()}

func unequip(module_id: String) -> Dictionary:
	if not module_id in equipped:
		return {"ok": false, "code": "not_equipped"}
	var candidate: Array = equipped.duplicate()
	candidate.erase(module_id)
	var old_mass := module_mass()
	var new_mass := old_mass - float(get_module(module_id).get("mass_kg", 0.0))
	var hull := get_hull()
	if float(hull.get("hull_mass_kg", 0.0)) + new_mass > float(hull.get("mass_limit_kg", 0.0)):
		return {"ok": false, "code": "mass_limit"}
	var cargo_after := float(stats().get("cargo_mass", 0.0)) - float(get_module(module_id).get("effects", {}).get("cargo_mass", 0.0))
	if session.inventory.total_mass() > cargo_after:
		return {"ok": false, "code": "capacity"}
	equipped = candidate
	sync_inventory_capacity()
	return {"ok": true, "code": "module_unequipped", "module_id": module_id, "stats": stats()}

func sync_inventory_capacity() -> void:
	if session != null and session.inventory != null:
		session.inventory.capacity_kg = float(stats().get("cargo_mass", 80.0))

func travel_check(target_system_id: String) -> Dictionary:
	var current = session.registry.get_system(session.system_id)
	if current.is_empty():
		return {"ok": false, "code": "invalid_target"}
	if not target_system_id in current.get("links", []):
		return {"ok": false, "code": "not_adjacent"}
	if target_system_id == session.system_id:
		return {"ok": false, "code": "invalid_target"}
	if fuel < JUMP_FUEL_COST:
		return {"ok": false, "code": "no_fuel"}
	var jump_range := int(stats().get("jump_range", 1))
	if jump_range < 1:
		return {"ok": false, "code": "jump_range"}
	return {"ok": true, "code": "ok", "fuel_cost": JUMP_FUEL_COST}

func consume_jump() -> void:
	fuel = maxf(0.0, fuel - JUMP_FUEL_COST)

func to_state() -> Dictionary:
	return {"hull_id": hull_id, "equipped": equipped.duplicate(), "owned": owned.duplicate(), "fuel": fuel}

func from_state(state: Dictionary) -> void:
	var saved_hull := str(state.get("hull_id", DEFAULT_HULL))
	hull_id = saved_hull if not session.registry.get_hull(saved_hull).is_empty() else DEFAULT_HULL
	owned = []
	for module_id in state.get("owned", OWNED_MODULES):
		if not session.registry.get_ship_module(str(module_id)).is_empty():
			owned.append(str(module_id))
	equipped = []
	for module_id in state.get("equipped", DEFAULT_MODULES):
		if str(module_id) in owned and not str(module_id) in equipped:
			equipped.append(str(module_id))
	fuel = clampf(float(state.get("fuel", get_hull().get("fuel_capacity", 80))), 0.0, float(get_hull().get("fuel_capacity", 80)))
	sync_inventory_capacity()
