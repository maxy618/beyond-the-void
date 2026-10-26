extends BtvTestSuite

const SAVE := "user://saves/e2e_vertical_slice.json"

func category() -> String:
	return "integration"

func _clean() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + suffix))

func _flora_nodes(session: GameSession, species_id: String) -> Array:
	var out: Array = []
	for node in session.surface_layout().get("nodes", []):
		if str(node.get("species_id", "")) == species_id:
			out.append(node)
	return out

func test_vertical_slice_end_to_end() -> void:
	_clean()
	var session := new_session(424242)
	equal(session.quests.status("quest.main.prologue.signal"), "active", "fresh save starts prologue")

	var landing := session.land_on("planet.vela")
	check(landing.get("ok", false), "land on Vela: " + str(landing))
	equal(session.quests.active["quest.main.prologue.signal"]["completed_steps"], ["surface"], "landing completes surface step")

	session.set_tool_mode("mode.scan")
	check(session.observe_species("species.flora.saltreed").get("ok", false), "observe flora")
	check(session.observe_species("species.fauna.mist_manta").get("ok", false), "observe fauna")
	var after_witness: Array = session.quests.active["quest.main.prologue.signal"]["completed_steps"]
	check(after_witness.has("witness"), "two observations complete witness step")

	var saltreed_nodes := _flora_nodes(session, "species.flora.saltreed")
	check(saltreed_nodes.size() >= 2, "two saltreed stands for sustainable sampling")
	session.set_tool_mode("mode.sample")
	var gather_one := session.gather_species("species.flora.saltreed", str(saltreed_nodes[0].get("node_id", "")))
	check(gather_one.get("ok", false), "gather fiber: " + str(gather_one))
	check(session.quests.active["quest.main.prologue.signal"]["completed_steps"].has("salvage"), "salvage step completes from held fiber")

	check(session.craft_recipe("recipe.refine.insulated_fiber").get("ok", false), "refine insulated fiber")
	check(session.craft_recipe("recipe.craft.signal_lens").get("ok", false), "craft signal lens")

	var market := session.get_market("market.vela.coast")
	var salt_before := market.stock_of("item.saltglass_shard")
	var credits_before_buy := session.credits
	var buy := session.buy("market.vela.coast", "item.saltglass_shard", 2)
	check(buy.get("ok", false), "buy saltglass: " + str(buy))
	equal(market.stock_of("item.saltglass_shard"), salt_before - 2, "market stock fell")
	equal(session.credits, credits_before_buy - int(buy.get("total", 0)), "credits paid")
	var water_before := market.stock_of("item.purified_water")
	var sell := session.sell("market.vela.coast", "item.purified_water", 1)
	check(sell.get("ok", false), "sell field water: " + str(sell))
	equal(market.stock_of("item.purified_water"), water_before + 1, "market stock rose")
	check(session.credits >= 0 and market.stock_of("item.purified_water") >= 0, "no negative credits or stock")

	session.talk_to("dialogue.npc.kasa")
	var fit := session.dialogue.choose("fit_lens")
	check(fit.get("ok", false), "Kasa calibrates lens: " + str(fit))
	var relay := session.interact_object("object.relay_console", "restore_power")
	check(relay.get("ok", false), "relay restored: " + str(relay))
	equal(session.quests.status("quest.main.prologue.signal"), "completed", "prologue completed")
	check(bool(session.facts.get("flag.prologue_beacon_lit", false)), "beacon flag set")

	var credits_before_build := session.credits
	var cell := session.build_module("build.power_cell", 0, 0)
	check(cell.get("ok", false), "power cell built: " + str(cell))
	var gather_two := session.gather_species("species.flora.saltreed", str(saltreed_nodes[1].get("node_id", "")))
	check(gather_two.get("ok", false), "second sustainable sample: " + str(gather_two))
	var smelter := session.build_module("build.smelter", 0, 1)
	check(smelter.get("ok", false), "smelter built: " + str(smelter))
	check(bool(session.build.totals().get("powered", false)), "base power grid powered")
	check(session.credits < credits_before_build, "construction consumed credits")

	var alloy_before := session.inventory.count("item.alloy_plate")
	session.advance_time(20.0)
	equal(session.inventory.count("item.alloy_plate"), alloy_before + 1, "powered smelter produced alloy")
	var alloy_stock_before := market.stock_of("item.alloy_plate")
	var credits_before_sell := session.credits
	var sell_alloy := session.sell("market.vela.coast", "item.alloy_plate", 1)
	check(sell_alloy.get("ok", false), "sell produced alloy: " + str(sell_alloy))
	equal(market.stock_of("item.alloy_plate"), alloy_stock_before + 1, "sold alloy enters finite stock")
	equal(session.credits, credits_before_sell + int(sell_alloy.get("total", 0)), "sale credits paid")

	var equip := session.equip_module("ship.module.cargo_pods")
	check(equip.get("ok", false), "ship component changed: " + str(equip))
	equal(session.inventory.capacity_kg, 125.0, "component effect applied")

	var population := session.ecology.population("planet.vela", "species.flora.saltreed")
	var saved := session.save(SAVE)
	check(saved.get("ok", false), "save vertical slice: " + str(saved))

	var restored := new_session()
	var load := restored.load_save(SAVE)
	check(load.get("ok", false), "restore vertical slice: " + str(load))
	equal(restored.mode, "planet", "restored on planet")
	equal(restored.planet_id, "planet.vela", "restored planet")
	equal(restored.player_pos, session.player_pos, "restored position")
	equal(restored.credits, session.credits, "restored credits")
	equal(restored.inventory.to_dict(), session.inventory.to_dict(), "restored inventory")
	equal(restored.quests.status("quest.main.prologue.signal"), "completed", "restored quest completion")
	check(bool(restored.facts.get("flag.prologue_beacon_lit", false)), "restored story flag")
	check("ship.module.cargo_pods" in restored.ship.equipped, "restored ship component")
	equal(restored.inventory.capacity_kg, 125.0, "restored cargo capacity")
	equal(restored.buildings.size(), 2, "restored buildings")
	check(bool(restored.build.totals().get("powered", false)), "restored base remains powered")
	equal(restored.ecology.population("planet.vela", "species.flora.saltreed"), population, "restored ecology population")
	equal(restored.get_market("market.vela.coast").stock_of("item.saltglass_shard"), market.stock_of("item.saltglass_shard"), "restored market stock")
	equal(restored.get_market("market.vela.coast").stock_of("item.alloy_plate"), market.stock_of("item.alloy_plate"), "restored traded stock")
	check(restored.observations.has("species.flora.saltreed") and restored.observations.has("species.fauna.mist_manta"), "restored field observations")
	check(restored.journal.size() >= session.journal.size(), "restored journal history")

	var credits := restored.credits
	var duplicate := restored.quests.claim_rewards("quest.main.prologue.signal")
	equal(str(duplicate.get("code", "")), "already_claimed", "restored receipt blocks duplicate reward")
	equal(restored.credits, credits, "duplicate reward pays nothing")
	_clean()
