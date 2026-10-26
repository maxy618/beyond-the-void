extends BtvTestSuite

func test_inventory_add_remove_and_mass() -> void:
	var inv := Inventory.new()
	inv.setup(registry)
	check(inv.add("item.crystal_fiber", 2).get("ok", false), "add fiber")
	equal(inv.count("item.crystal_fiber"), 2, "fiber count")
	near(inv.total_mass(), 0.4, 0.001, "fiber mass")
	check(not inv.add("item.unknown", 1).get("ok", false), "unknown item rejected")
	equal(inv.count("item.crystal_fiber"), 2, "failed add does not mutate")
	check(inv.remove("item.crystal_fiber", 1), "remove one")
	equal(inv.count("item.crystal_fiber"), 1, "remaining fiber")
	check(not inv.remove("item.crystal_fiber", 2), "cannot remove more than held")
	equal(inv.count("item.crystal_fiber"), 1, "failed remove does not mutate")

func test_inventory_capacity_is_enforced() -> void:
	var inv := Inventory.new()
	inv.setup(registry)
	inv.capacity_kg = 0.25
	check(not inv.add("item.crystal_fiber", 2).get("ok", false), "two fiber exceed tiny capacity")
	equal(inv.count("item.crystal_fiber"), 0, "capacity failure leaves inventory empty")
	check(inv.add("item.crystal_fiber", 1).get("ok", false), "one fiber fits")
	check(not inv.add("item.alloy_plate", 1).get("ok", false), "heavy plate rejected")

func test_add_many_is_atomic() -> void:
	var inv := Inventory.new()
	inv.setup(registry)
	inv.capacity_kg = 1.0
	var result := inv.add_many([
		{"item_id": "item.alloy_plate", "count": 1},
		{"item_id": "item.alloy_plate", "count": 1},
	])
	check(not result.get("ok", false), "second heavy plate cannot fit")
	equal(inv.count("item.alloy_plate"), 0, "bulk add rolled back")

func test_stack_limit_is_enforced() -> void:
	var inv := Inventory.new()
	inv.setup(registry)
	inv.capacity_kg = 1000.0
	var item: Dictionary = registry.get_item("item.signal_lens")
	var limit := int(item.get("stack_limit", 99))
	check(inv.add("item.signal_lens", limit).get("ok", false), "fill stack")
	check(not inv.add("item.signal_lens", 1).get("ok", false), "stack limit rejects overflow")
	equal(inv.count("item.signal_lens"), limit, "stack count unchanged")

func test_craft_consumes_inputs_and_adds_output() -> void:
	var session := new_session()
	session.inventory.add("item.crystal_fiber", 2)
	var before := session.inventory.count("item.crystal_fiber")
	var result := session.craft_recipe("recipe.refine.insulated_fiber")
	check(result.get("ok", false), "craft insulated fiber: " + str(result))
	equal(session.inventory.count("item.crystal_fiber"), before - 2, "fiber consumed")
	equal(session.inventory.count("item.insulated_fiber"), 1, "output present")

func test_failed_craft_rolls_back() -> void:
	var session := new_session()
	session.inventory.add("item.crystal_fiber", 2)
	session.inventory.capacity_kg = 0.1
	var before := session.inventory.to_dict()
	var result := session.craft_recipe("recipe.refine.insulated_fiber")
	check(not result.get("ok", false), "craft rejected when output cannot fit")
	equal(session.inventory.to_dict(), before, "failed craft leaves inventory byte-for-byte unchanged")

func test_missing_inputs_do_not_mutate() -> void:
	var session := new_session()
	var before := session.inventory.to_dict()
	var result := session.craft_recipe("recipe.craft.signal_lens")
	check(not result.get("ok", false), "craft rejected without inputs")
	equal(session.inventory.to_dict(), before, "missing-input craft leaves inventory unchanged")

func test_observation_gated_recipe() -> void:
	var session := new_session()
	session.inventory.add("item.mist_sample", 1)
	session.inventory.add("item.saltglass_shard", 1)
	var locked := session.craft_recipe("recipe.refine.conductive_gel")
	check(not locked.get("ok", false), "gel recipe locked before observation")
	equal(str(locked.get("code", "")), "locked", "locked code")
	session.observations["species.fauna.mist_manta"] = {"count": 1, "harmed": 0, "first_seen_at": 0.0}
	var unlocked := session.craft_recipe("recipe.refine.conductive_gel")
	check(unlocked.get("ok", false), "gel recipe unlocked by observation: " + str(unlocked))
	equal(session.inventory.count("item.conductive_gel"), 1, "gel output")

func test_duplicate_inventory_is_independent() -> void:
	var inv := Inventory.new()
	inv.setup(registry)
	inv.add("item.crystal_fiber", 2)
	var copy := inv.duplicate_inventory()
	check(copy.remove("item.crystal_fiber", 1), "copy removal")
	equal(inv.count("item.crystal_fiber"), 2, "original unaffected")
