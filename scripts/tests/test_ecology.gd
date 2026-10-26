extends BtvTestSuite

const FLORA := "species.flora.saltreed"
const FAUNA := "species.fauna.mist_manta"

func _first_node(session: GameSession, kind: String) -> Dictionary:
	for node in session.surface_layout().get("nodes", []):
		if str(node.get("kind", "")) == kind:
			return node
	return {}

func test_observe_requires_planet_and_mode() -> void:
	var session := new_session()
	var result := session.observe_species(FLORA)
	check(not result.get("ok", false), "cannot observe from space")
	session.land_on("planet.vela")
	session.set_tool_mode("mode.sample")
	var wrong := session.observe_species(FLORA)
	check(not wrong.get("ok", false), "observation needs scan mode")
	equal(str(wrong.get("code", "")), "wrong_mode", "wrong-mode code")
	session.set_tool_mode("mode.scan")
	var ok := session.observe_species(FLORA)
	check(ok.get("ok", false), "scan observation works")
	equal(str(ok.get("code", "")), "observed", "observation code")
	check(bool(ok.get("first", false)), "first observation flagged")
	equal(int(session.observations.get(FLORA, {}).get("harmed", 0)), 0, "observation harms nothing")

func test_observe_twice_counts_without_harm() -> void:
	var session := new_player()
	session.observe_species(FLORA)
	var second := session.observe_species(FLORA)
	check(second.get("ok", false), "repeat observation allowed")
	check(not bool(second.get("first", false)), "repeat is not first")
	equal(int(session.observations[FLORA].get("count", 0)), 2, "observation count accumulates")
	equal(int(session.observations[FLORA].get("harmed", 0)), 0, "no harm from observation")

func test_gather_requires_sample_mode_and_node() -> void:
	var session := new_player()
	var node := _first_node(session, "flora")
	check(not node.is_empty(), "layout has flora node")
	var wrong := session.gather_species(str(node.get("species_id", "")), str(node.get("node_id", "")))
	check(not wrong.get("ok", false), "gather needs sample mode")
	equal(str(wrong.get("code", "")), "wrong_mode", "gather wrong-mode code")
	session.set_tool_mode("mode.sample")
	var ok := session.gather_species(str(node.get("species_id", "")), str(node.get("node_id", "")))
	check(ok.get("ok", false), "sample gather works: " + str(ok))
	check(session.inventory.count(str(ok.get("item_id", ""))) >= 1, "harvest item added")
	var again := session.gather_species(str(node.get("species_id", "")), str(node.get("node_id", "")))
	check(not again.get("ok", false), "same node cannot be stripped twice immediately")
	equal(str(again.get("code", "")), "regrowing", "node cooldown code")

func test_gather_reduces_local_population_and_recovers() -> void:
	var session := new_player()
	var node := _first_node(session, "flora")
	var species_id := str(node.get("species_id", ""))
	session.set_tool_mode("mode.sample")
	var before := session.ecology.population("planet.vela", species_id)
	check(session.gather_species(species_id, str(node.get("node_id", ""))).get("ok", false), "gather")
	equal(session.ecology.population("planet.vela", species_id), before - 1, "population cost applied")
	session.advance_time(120.0)
	check(session.ecology.population("planet.vela", species_id) >= before - 1, "population begins recovering")
	check(session.ecology.population("planet.vela", species_id) <= session.ecology.target_population(species_id), "population bounded by target")

func test_absent_species_rejected() -> void:
	var session := new_player()
	var planet: Dictionary = session.get_planet()
	var absent := ""
	for species_id in registry.species.keys():
		if not str(species_id) in planet.get("species_pool", []):
			absent = str(species_id)
			break
	check(not absent.is_empty(), "found a species absent from Vela")
	var result := session.observe_species(absent)
	check(not result.get("ok", false), "cannot observe a species that is not present")
	equal(str(result.get("code", "")), "no_target", "absent species code")
	session.set_tool_mode("mode.sample")
	var gather := session.gather_species(absent, "node.absent")
	check(not gather.get("ok", false), "cannot gather absent flora")

func test_calm_is_nonlethal() -> void:
	var session := new_player()
	session.set_tool_mode("mode.dampen")
	var before := session.ecology.population("planet.vela", FAUNA)
	var result := session.calm_species(FAUNA)
	check(result.get("ok", false), "calm succeeds")
	check(bool(result.get("first", false)), "first calm flagged")
	equal(session.ecology.population("planet.vela", FAUNA), before, "calming does not reduce population")
	equal(int(session.observations.get(FAUNA, {}).get("harmed", 0)), 0, "no harm recorded from calming")

func test_fauna_cannot_be_gathered() -> void:
	var session := new_player()
	session.set_tool_mode("mode.sample")
	var result := session.gather_species(FAUNA, "node.fauna.test")
	check(not result.get("ok", false), "fauna is not a harvest plant")
	equal(str(result.get("code", "")), "invalid_target", "fauna gather code")

func test_gather_capacity_failure_keeps_population() -> void:
	var session := new_player()
	var node := _first_node(session, "flora")
	var species_id := str(node.get("species_id", ""))
	session.set_tool_mode("mode.sample")
	session.inventory.capacity_kg = session.inventory.total_mass()
	var before := session.ecology.population("planet.vela", species_id)
	var result := session.gather_species(species_id, str(node.get("node_id", "")))
	check(not result.get("ok", false), "full pack blocks gathering")
	equal(session.ecology.population("planet.vela", species_id), before, "failed gather does not consume population")
