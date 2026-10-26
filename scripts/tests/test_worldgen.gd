extends BtvTestSuite

func test_surface_layout_is_deterministic() -> void:
	var planet: Dictionary = registry.get_planet("planet.vela")
	var a := WorldGen.surface_layout(planet, registry, 424242)
	var b := WorldGen.surface_layout(planet, registry, 424242)
	equal(JSON.stringify(a), JSON.stringify(b), "same seed produces identical layout")
	var c := WorldGen.surface_layout(planet, registry, 424243)
	check(JSON.stringify(a) != JSON.stringify(c), "different seed changes layout")

func test_surface_layout_contains_valid_nodes() -> void:
	var planet: Dictionary = registry.get_planet("planet.vela")
	var layout := WorldGen.surface_layout(planet, registry, 424242)
	equal(int(layout.get("world_size", 0)), int(WorldGen.WORLD_SIZE), "world size")
	equal(layout.get("build_slots", []).size(), 4, "2x2 build pads")
	equal(layout.get("decor", []).size(), 46, "decor count stable")
	var nodes: Array = layout.get("nodes", [])
	check(nodes.size() >= 18, "at least three nodes per species")
	var seen: Dictionary = {}
	for node in nodes:
		var node_id := str(node.get("node_id", ""))
		check(not node_id.is_empty(), "node id present")
		check(not seen.has(node_id), "node id unique")
		seen[node_id] = true
		var species_id := str(node.get("species_id", ""))
		var species: Dictionary = registry.get_species(species_id)
		check(not species.is_empty(), "node species resolves")
		check(str(node.get("kind", "")) == str(species.get("kind", "")), "node kind matches species")
		var x := float(node.get("x", -1))
		var y := float(node.get("y", -1))
		check(x >= 0.0 and x <= WorldGen.WORLD_SIZE, "node x in bounds")
		check(y >= 0.0 and y <= WorldGen.WORLD_SIZE, "node y in bounds")
		if str(species.get("kind", "")) == "flora":
			check(not registry.get_item(str(node.get("item_id", ""))).is_empty(), "flora harvest item resolves")

func test_nodes_avoid_anchors() -> void:
	var planet: Dictionary = registry.get_planet("planet.vela")
	var layout := WorldGen.surface_layout(planet, registry, 424242)
	for node in layout.get("nodes", []):
		var point := Vector2(float(node.get("x", 0)), float(node.get("y", 0)))
		for anchor in planet.get("anchors", []):
			var anchor_point := Vector2(float(anchor.get("x", 0)), float(anchor.get("y", 0)))
			check(point.distance_to(anchor_point) >= 100.0, "node clears anchor " + str(anchor.get("kind", "")))

func test_start_and_ship_positions_match_anchors() -> void:
	var planet: Dictionary = registry.get_planet("planet.vela")
	var layout := WorldGen.surface_layout(planet, registry, 424242)
	var start: Array = layout.get("start_pos", [])
	var ship: Array = layout.get("ship_pos", [])
	check(start.size() == 2, "start position")
	check(ship.size() == 2, "ship position")
	near(float(ship[0]), 1150.0, 0.001, "ship anchor x")
	near(float(ship[1]), 2000.0, 0.001, "ship anchor y")
	check(Vector2(float(start[0]), float(start[1])).distance_to(Vector2(1150, 2000)) < 100.0, "player starts beside ship")

func test_system_visual_and_starfield_are_stable() -> void:
	var a := WorldGen.system_visual(424242, "system.ashfall_gate", registry)
	var b := WorldGen.system_visual(424242, "system.ashfall_gate", registry)
	equal(JSON.stringify(a), JSON.stringify(b), "system visual deterministic")
	equal(a.get("orbits", {}).size(), 4, "all system planets have orbits")
	equal(a.get("stars", []).size(), 150, "starfield count")

func test_frontier_is_seeded_and_linked() -> void:
	var a := WorldGen.generate_frontier(424242, registry)
	var b := WorldGen.generate_frontier(424242, registry)
	var c := WorldGen.generate_frontier(424243, registry)
	equal(a.size(), 6, "six frontier systems")
	equal(JSON.stringify(a), JSON.stringify(b), "frontier deterministic")
	check(JSON.stringify(a) != JSON.stringify(c), "frontier seed changes names and planets")
	var seen: Dictionary = {}
	for system in a:
		var id := str(system.get("system_id", ""))
		check(not seen.has(id), "frontier id unique")
		seen[id] = true
		check(not system.get("planets", []).is_empty(), "frontier system has planets")
	var first_links: Array = a[0].get("links", [])
	check(first_links.has("system.ashfall_gate"), "frontier connects to authored space")

func test_500_seed_stress() -> void:
	var planet: Dictionary = registry.get_planet("planet.vela")
	var count := 0
	for i in range(500):
		var layout := WorldGen.surface_layout(planet, registry, 100000 + i)
		if layout.get("nodes", []).size() < 12:
			check(false, "seed %d produced too few nodes" % i)
			continue
		if layout.get("build_slots", []).size() != 4:
			check(false, "seed %d lost build pads" % i)
			continue
		count += 1
	equal(count, 500, "500 seeds generated complete layouts")
