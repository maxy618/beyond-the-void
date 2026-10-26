extends BtvTestSuite

const MAIN := "quest.main.prologue.signal"
const SIDE := "quest.side.kasa_garden"
const KASA := "dialogue.npc.kasa"

func _run_main_to_completion(session: GameSession) -> Dictionary:
	session.set_tool_mode("mode.scan")
	session.observe_species("species.flora.saltreed")
	session.observe_species("species.fauna.mist_manta")
	var node := {}
	for candidate in session.surface_layout().get("nodes", []):
		if str(candidate.get("species_id", "")) == "species.flora.saltreed":
			node = candidate
			break
	session.set_tool_mode("mode.sample")
	session.gather_species("species.flora.saltreed", str(node.get("node_id", "")))
	session.craft_recipe("recipe.refine.insulated_fiber")
	var lens := session.craft_recipe("recipe.craft.signal_lens")
	session.talk_to(KASA)
	var fit := session.dialogue.choose("fit_lens")
	var relay := session.interact_object("object.relay_console", "restore_power")
	return {"lens": lens, "fit": fit, "relay": relay}

func test_main_quest_is_ordered_and_rewarded_once() -> void:
	var session := new_player()
	equal(session.quests.status(MAIN), "active", "prologue auto-starts")
	var run := _run_main_to_completion(session)
	check(run.get("lens", {}).get("ok", false), "signal lens crafted")
	check(run.get("fit", {}).get("ok", false), "Kasa calibrates lens")
	check(run.get("relay", {}).get("ok", false), "relay restored")
	equal(session.quests.status(MAIN), "completed", "main quest completed")
	check(bool(session.facts.get("flag.prologue_beacon_lit", false)), "story flag set")
	equal(session.credits, 205, "reward credits granted exactly once")
	check(session.quests.receipts.has("reward.quest.main.prologue.signal.v1"), "receipt stored")
	var credits := session.credits
	var again := session.quests.claim_rewards(MAIN)
	equal(str(again.get("code", "")), "already_claimed", "duplicate claim rejected")
	equal(session.credits, credits, "duplicate claim pays nothing")

func test_ordered_steps_do_not_skip() -> void:
	var session := new_player()
	session.set_tool_mode("mode.scan")
	session.observe_species("species.flora.saltreed")
	session.observe_species("species.fauna.mist_manta")
	check(session.quests.active[MAIN]["completed_steps"].has("witness"), "witness step completed")
	check(not session.quests.active[MAIN]["completed_steps"].has("salvage"), "later salvage step not skipped")
	check(not session.quests.active[MAIN]["completed_steps"].has("craft_lens"), "later craft step not skipped")

func test_side_quest_dialogue_starts_and_completes() -> void:
	var session := new_player()
	var blocked := session.quests.start_quest(SIDE)
	equal(str(blocked.get("code", "")), "locked", "side quest requires dialogue flag")
	var started := session.talk_to(KASA)
	check(started.get("ok", false), "dialogue starts")
	var choice := session.dialogue.choose("ask_garden")
	check(choice.get("ok", false), "garden choice accepted")
	check(bool(session.facts.get("flag.kasa_garden_asked", false)), "garden flag set")
	equal(session.quests.status(SIDE), "active", "side quest active before observations")
	session.set_tool_mode("mode.scan")
	for species_id in ["species.flora.saltreed", "species.fauna.mist_manta", "species.flora.glassbell"]:
		check(session.observe_species(species_id).get("ok", false), "observe " + species_id)
	equal(session.quests.status(SIDE), "completed", "side quest completed after three observations")
	equal(session.credits, 160, "side reward credits")
	equal(session.inventory.count("item.fiber_weave"), 1, "side reward item")
	var credits := session.credits
	session.talk_to(KASA)
	session.dialogue.choose("ask_garden")
	equal(session.credits, credits, "restarting side dialogue pays no duplicate reward")

func test_dialogue_rechecks_conditions_at_commit() -> void:
	var session := new_player()
	session.inventory.add("item.signal_lens", 1)
	session.talk_to(KASA)
	var visible := session.dialogue.visible_choices()
	var has_fit := false
	for choice in visible:
		if str(choice.get("id", "")) == "fit_lens":
			has_fit = true
	check(has_fit, "fit_lens visible while holding lens")
	session.inventory.remove("item.signal_lens", 1)
	var locked := session.dialogue.choose("fit_lens")
	equal(str(locked.get("code", "")), "choice_locked", "condition removed at commit rejects choice")
	check(not bool(session.facts.get("flag.lens_calibrated", false)), "locked choice applies no effects")
	session.inventory.add("item.signal_lens", 1)
	var accepted := session.dialogue.choose("fit_lens")
	check(accepted.get("ok", false), "choice accepted after condition restored")
	check(bool(session.facts.get("flag.lens_calibrated", false)), "choice effect applied")

func test_receipt_survives_save_roundtrip() -> void:
	var session := new_player()
	_run_main_to_completion(session)
	var state := session.quests.to_state()
	var other := new_session()
	other.quests.from_state(state)
	equal(other.quests.status(MAIN), "completed", "completed quest restored")
	var claimed := other.quests.claim_rewards(MAIN)
	equal(str(claimed.get("code", "")), "already_claimed", "receipt blocks duplicate after restore")
	equal(other.credits, 120, "restored session did not receive unpaid reward")

func test_unknown_quest_and_dialogue_are_safe() -> void:
	var session := new_session()
	check(not session.quests.start_quest("quest.none").get("ok", false), "unknown quest rejected")
	check(not session.talk_to("dialogue.none").get("ok", false), "unknown dialogue rejected")
	check(not session.dialogue.choose("ask_signal").get("ok", false), "choice while inactive rejected")
