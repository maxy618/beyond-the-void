extends BtvTestSuite

const SAVE := "user://saves/test_roundtrip.json"

func _clean() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = SAVE + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _write_raw(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _read_raw(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _complete_main_receipt(session: GameSession) -> void:
	session.quests.completed.append("quest.main.prologue.signal")
	session.quests.receipts["reward.quest.main.prologue.signal.v1"] = {"quest_id": "quest.main.prologue.signal", "claimed_at": 5.0}
	session.facts["flag.prologue_beacon_lit"] = true

func test_full_state_roundtrip() -> void:
	_clean()
	var session := new_player()
	session.observe_species("species.flora.saltreed")
	session.set_tool_mode("mode.sample")
	var node := {}
	for candidate in session.surface_layout().get("nodes", []):
		if str(candidate.get("species_id", "")) == "species.flora.saltreed":
			node = candidate
			break
	check(not node.is_empty(), "roundtrip test needs a saltreed node")
	session.gather_species("species.flora.saltreed", str(node.get("node_id", "")))
	session.set_tool_mode("mode.scan")
	session.build_module("build.power_cell", 0, 0)
	session.equip_module("ship.module.cargo_pods")
	session.credits = 77
	session.set_setting("quality", "high")
	var saved := session.save(SAVE)
	check(saved.get("ok", false), "save succeeds: " + str(saved))
	check(FileAccess.file_exists(SAVE), "primary save exists")
	check(FileAccess.file_exists(SAVE + ".tmp") == false, "temp save removed after rename")
	var loaded := new_session()
	var result := loaded.load_save(SAVE)
	check(result.get("ok", false), "load succeeds: " + str(result))
	equal(result.get("source", ""), "primary", "load source primary")
	equal(loaded.world_seed, session.world_seed, "seed restored")
	equal(loaded.system_id, session.system_id, "system restored")
	equal(loaded.planet_id, session.planet_id, "planet restored")
	equal(loaded.mode, session.mode, "mode restored")
	equal(loaded.player_pos, session.player_pos, "player position restored")
	equal(loaded.credits, 77, "credits restored")
	equal(loaded.inventory.to_dict(), session.inventory.to_dict(), "inventory restored")
	equal(loaded.buildings.size(), 1, "building restored")
	equal(loaded.ship.equipped, session.ship.equipped, "loadout restored")
	equal(loaded.observations.keys(), session.observations.keys(), "observations restored")
	equal(int(loaded.ecology.population("planet.vela", "species.flora.saltreed")), int(session.ecology.population("planet.vela", "species.flora.saltreed")), "ecology restored")
	equal(str(loaded.settings.get("quality", "")), "high", "settings restored")
	_clean()

func test_backup_survives_corrupt_primary() -> void:
	_clean()
	var first := new_session()
	first.credits = 111
	check(first.save(SAVE).get("ok", false), "first save")
	var second := new_session()
	second.credits = 999
	check(second.save(SAVE).get("ok", false), "second save creates backup")
	check(FileAccess.file_exists(SAVE + ".bak"), "backup exists")
	_write_raw(SAVE, {"not": "a save"})
	var loaded := new_session()
	var result := loaded.load_save(SAVE)
	check(result.get("ok", false), "corrupt primary recovers from backup: " + str(result))
	equal(result.get("source", ""), "backup", "backup source reported")
	check(bool(result.get("primary_corrupt", false)), "corruption reported")
	equal(loaded.credits, 111, "backup contents restored")
	_clean()

func test_temp_save_recovers_interrupted_write() -> void:
	_clean()
	var session := new_session()
	session.credits = 222
	check(session.save(SAVE).get("ok", false), "seed save")
	var data := _read_raw(SAVE)
	data["credits"] = 333
	_write_raw(SAVE + ".tmp", data)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var loaded := new_session()
	var result := loaded.load_save(SAVE)
	check(result.get("ok", false), "interrupted write recovers from temp: " + str(result))
	equal(result.get("source", ""), "temp", "temp source reported")
	equal(loaded.credits, 333, "temp contents restored")
	_clean()

func test_v1_migration() -> void:
	_clean()
	var legacy := {
		"version": 1,
		"seed": 777,
		"location": "planet.vela",
		"credits": 42,
		"inventory": {"item.crystal_fiber": 3},
		"quests": ["quest.main.prologue.signal"],
		"ship": {"hull": "ship.hull.salt_skiff", "modules": ["ship.module.scan_array"]},
		"completed_quests": [],
	}
	_write_raw(SAVE, legacy)
	var loaded := new_session()
	var result := loaded.load_save(SAVE)
	check(result.get("ok", false), "v1 save loads: " + str(result))
	equal(int(result.get("from_schema", 0)), 1, "reported source schema")
	equal(loaded.world_seed, 777, "legacy seed migrated")
	equal(loaded.system_id, "system.ashfall_gate", "planet implies system")
	equal(loaded.planet_id, "planet.vela", "legacy planet restored")
	equal(loaded.mode, "planet", "legacy mode restored")
	equal(loaded.credits, 42, "legacy credits restored")
	equal(loaded.inventory.count("item.crystal_fiber"), 3, "legacy inventory restored")
	check(loaded.migration_history.size() >= 1, "migration history retained")
	_clean()

func test_missing_content_is_rejected_without_apply() -> void:
	_clean()
	var session := new_session()
	check(session.save(SAVE).get("ok", false), "seed save")
	var data := _read_raw(SAVE)
	data["content"] = {"pack_id": "pack.not_installed", "content_version": "9.9.9"}
	_write_raw(SAVE, data)
	var loaded := new_session()
	var credits := loaded.credits
	var result := loaded.load_save(SAVE)
	check(not result.get("ok", false), "missing pack rejected")
	equal(str(result.get("code", "")), "missing_content", "missing-content code")
	equal(loaded.credits, credits, "rejected save is not applied")
	_clean()

func test_newer_schema_is_rejected() -> void:
	_clean()
	var session := new_session()
	check(session.save(SAVE).get("ok", false), "seed save")
	var data := _read_raw(SAVE)
	data["save_schema"] = 99
	_write_raw(SAVE, data)
	var loaded := new_session()
	var result := loaded.load_save(SAVE)
	check(not result.get("ok", false), "future schema rejected")
	equal(str(result.get("code", "")), "save_too_new", "future schema code")
	_clean()

func test_corrupt_all_sources_reports_failure() -> void:
	_clean()
	_write_raw(SAVE, {"bad": true})
	_write_text(SAVE + ".tmp", "{broken")
	_write_text(SAVE + ".bak", "[]")
	var session := new_session()
	var credits := session.credits
	var result := session.load_save(SAVE)
	check(not result.get("ok", false), "unreadable save fails cleanly")
	equal(str(result.get("code", "")), "load_failed", "load failure code")
	equal(session.credits, credits, "failed load leaves session intact")
	_clean()

func test_duplicate_reward_is_blocked_after_reload() -> void:
	_clean()
	var session := new_session()
	_complete_main_receipt(session)
	check(session.save(SAVE).get("ok", false), "save receipt")
	var loaded := new_session()
	check(loaded.load_save(SAVE).get("ok", false), "load receipt")
	var credits := loaded.credits
	var claim := loaded.quests.claim_rewards("quest.main.prologue.signal")
	equal(str(claim.get("code", "")), "already_claimed", "receipt persisted")
	equal(loaded.credits, credits, "no duplicate reward paid")
	_clean()

func test_save_reports_backup_on_second_write() -> void:
	_clean()
	var session := new_session()
	var first := session.save(SAVE)
	check(first.get("ok", false), "first save")
	check(not bool(first.get("backup_written", true)), "first save has no prior backup")
	var second := session.save(SAVE)
	check(second.get("ok", false), "second save")
	check(bool(second.get("backup_written", false)), "second save refreshes backup")
	check(int(second.get("bytes", 0)) > 100, "save reports bytes")
	_clean()
