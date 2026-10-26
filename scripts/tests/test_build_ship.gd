extends BtvTestSuite

func test_build_requires_planet_and_valid_slot() -> void:
	var session := new_session()
	equal(str(session.build_module("build.power_cell", 0, 0).get("code", "")), "not_landable", "cannot build in space")
	session.land_on("planet.vela")
	equal(str(session.build_module("build.power_cell", 2, 0).get("code", "")), "invalid_slot", "slot bounds enforced")
	equal(str(session.build_module("build.unknown", 0, 0).get("code", "")), "invalid_target", "unknown module rejected")

func test_build_consumes_costs_and_powers_base() -> void:
	var session := new_player()
	var credits := session.credits
	var result := session.build_module("build.power_cell", 0, 0)
	check(result.get("ok", false), "power cell built: " + str(result))
	equal(session.credits, credits - 40, "credits consumed")
	equal(session.inventory.count("item.alloy_plate"), 1, "alloy consumed")
	equal(session.inventory.count("item.saltglass_shard"), 0, "saltglass consumed")
	equal(int(session.build.totals().get("power_production", 0)), 6, "power production")
	check(bool(session.build.totals().get("powered", true)), "base has power")
	equal(str(session.build_module("build.power_cell", 0, 0).get("code", "")), "occupied", "occupied slot rejected")

func test_build_failure_does_not_charge() -> void:
	var session := new_player()
	var credits := session.credits
	var inventory := session.inventory.to_dict()
	var result := session.build_module("build.habitat", 0, 0)
	check(not result.get("ok", false), "cannot build without fiber weave")
	equal(str(result.get("code", "")), "missing_inputs", "missing construction input code")
	equal(session.credits, credits, "failed build charges no credits")
	equal(session.inventory.to_dict(), inventory, "failed build consumes no items")
	equal(session.buildings.size(), 0, "failed build creates no building")

func test_powered_smelter_produces_atomically() -> void:
	var session := new_player()
	check(session.build_module("build.power_cell", 0, 0).get("ok", false), "power cell")
	check(session.build_module("build.smelter", 0, 1).get("ok", false), "smelter")
	var totals := session.build.totals()
	equal(int(totals.get("power_draw", 0)), 4, "smelter draw")
	check(bool(totals.get("powered", false)), "power grid balanced")
	session.inventory.add("item.saltglass_shard", 1)
	var before_alloy := session.inventory.count("item.alloy_plate")
	var produced := session.build.tick(20.0)
	check(produced.size() >= 1, "production event emitted")
	equal(session.inventory.count("item.alloy_plate"), before_alloy + 1, "alloy produced")
	equal(session.inventory.count("item.saltglass_shard"), 0, "input consumed")
	check(session.journal.any(func(entry): return str(entry.get("key", "")) == "journal.build.produced"), "production journal entry")

func test_production_without_input_changes_nothing() -> void:
	var session := new_player()
	session.build_module("build.power_cell", 0, 0)
	session.build_module("build.smelter", 0, 1)
	var inventory := session.inventory.to_dict()
	var produced := session.build.tick(40.0)
	equal(produced.size(), 0, "no output without input")
	equal(session.inventory.to_dict(), inventory, "stalled production consumes nothing")

func test_ship_default_loadout_and_stats() -> void:
	var session := new_session()
	var stats: Dictionary = session.ship.stats()
	equal(session.ship.hull_id, "ship.hull.salt_skiff", "starter hull")
	equal(session.ship.equipped, ["ship.module.scan_array", "ship.module.ion_fins"], "starter modules")
	near(float(stats.get("maneuver", 0.0)), 1.35, 0.001, "module stat effect applied")
	equal(float(stats.get("cargo_mass", 0.0)), 80.0, "cargo mass baseline")
	equal(session.inventory.capacity_kg, 80.0, "inventory capacity follows ship")

func test_ship_equip_changes_capacity() -> void:
	var session := new_session()
	var result := session.equip_module("ship.module.cargo_pods")
	check(result.get("ok", false), "cargo pods fit: " + str(result))
	equal(session.inventory.capacity_kg, 125.0, "cargo capacity increased")
	equal(session.inventory.count("item.alloy_plate"), 2, "equipment does not touch cargo")
	var again := session.equip_module("ship.module.cargo_pods")
	equal(str(again.get("code", "")), "already_equipped", "cannot equip twice")

func test_ship_rejects_unowned_incompatible_and_full_slots() -> void:
	var session := new_session()
	equal(str(session.equip_module("ship.module.long_jump_coil").get("code", "")), "not_owned", "unowned module rejected")
	session.equip_module("ship.module.cargo_pods")
	equal(str(session.equip_module("ship.module.heat_sink").get("code", "")), "slots_full", "utility slots enforced")
	session.ship.hull_id = "ship.hull.deep_keel"
	var incompatible := session.equip_module("ship.module.heat_sink")
	equal(str(incompatible.get("code", "")), "incompatible", "hull compatibility tags enforced")

func test_unequip_checks_cargo_capacity() -> void:
	var session := new_session()
	session.equip_module("ship.module.cargo_pods")
	session.inventory.add("item.alloy_plate", 48)
	session.inventory.add("item.saltglass_shard", 97)
	session.inventory.add("item.crystal_fiber", 98)
	check(session.inventory.total_mass() > 80.0, "load exceeds hull cargo without pods")
	var result := session.unequip_module("ship.module.cargo_pods")
	equal(str(result.get("code", "")), "capacity", "overloaded cargo blocks unequip")
	check("ship.module.cargo_pods" in session.ship.equipped, "module remains equipped after failed unequip")

func test_travel_checks_and_consumes_fuel() -> void:
	var session := new_session()
	equal(str(session.travel_to("system.threshold").get("code", "")), "ok", "adjacent jump succeeds")
	equal(session.system_id, "system.threshold", "system changed")
	near(session.ship.fuel, 72.0, 0.001, "jump fuel consumed")
	equal(str(session.travel_to("system.unknown").get("code", "")), "not_adjacent", "unknown route rejected")
	check(session.travel_to("system.ashfall_gate").get("ok", false), "jump back")
	check(session.land_on("planet.vela").get("ok", false), "land on Vela")
	equal(str(session.travel_to("system.threshold").get("code", "")), "not_in_space", "cannot jump from surface")
