class_name WorldGen
extends RefCounted

## Seeded generation. Static worlds are never saved: seeds + generator version rebuild them.

const GENERATOR_VERSION := 1
const WORLD_SIZE := 2400.0
const FRONTIER_SYLLABLES_A := ["cal", "mir", "oth", "vel", "sarn", "ith", "lo", "kes", "nur", "ash"]
const FRONTIER_SYLLABLES_B := ["dun", "rae", "tide", "hold", "reach", "wake", "gard", "fall", "mere", "spire"]

static func stream_seed(world_seed: int, label: String) -> int:
	var value: int = 2166136261
	var bytes: PackedByteArray = (label + "|" + str(world_seed)).to_utf8_buffer()
	for byte in bytes:
		value = ((value ^ int(byte)) * 16777619) & 0x7fffffff
	return value

static func rng_for(world_seed: int, label: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = stream_seed(world_seed, label)
	return rng

static func starfield(world_seed: int, label: String, count: int = 140) -> Array:
	var rng := rng_for(world_seed, "starfield:" + label)
	var stars: Array = []
	for i in range(count):
		stars.append({
			"x": rng.randf_range(0.0, 1.0),
			"y": rng.randf_range(0.0, 1.0),
			"size": rng.randf_range(0.6, 2.8),
			"phase": rng.randf_range(0.0, TAU),
			"bright": rng.randf_range(0.25, 1.0),
		})
	return stars

static func system_visual(world_seed: int, system_id: String, registry) -> Dictionary:
	var system = registry.get_system(system_id)
	var rng := rng_for(world_seed, "system:" + system_id)
	var orbits: Dictionary = {}
	for planet_id in system.get("planet_ids", []):
		var planet = registry.get_planet(str(planet_id))
		orbits[str(planet_id)] = {
			"angle": rng.randf_range(0.0, TAU),
			"radius": float(planet.get("orbit_radius", 300)),
			"size": float(planet.get("radius_px", 40)),
		}
	return {
		"system_id": system_id,
		"star_color": str(system.get("star_color", "#e8b06a")),
		"star_radius": float(system.get("star_radius", 100)),
		"orbits": orbits,
		"stars": starfield(world_seed, system_id, 150),
		"nebula": [rng.randf_range(0.1, 0.9), rng.randf_range(0.1, 0.6), rng.randf_range(0.1, 0.5)],
	}

static func generate_frontier(world_seed: int, registry) -> Array:
	var rng := rng_for(world_seed, "frontier")
	var used: Dictionary = {}
	var systems: Array = []
	for i in range(6):
		var name := ""
		for attempt in range(20):
			name = FRONTIER_SYLLABLES_A[rng.randi_range(0, FRONTIER_SYLLABLES_A.size() - 1)] + FRONTIER_SYLLABLES_B[rng.randi_range(0, FRONTIER_SYLLABLES_B.size() - 1)]
			if not used.has(name):
				break
		used[name] = true
		var system_id := "system.frontier.%02d" % i
		var links: Array = []
		if i > 0:
			links.append("system.frontier.%02d" % (i - 1))
		if i < 5:
			links.append("system.frontier.%02d" % (i + 1))
		if i == 0:
			links.append("system.ashfall_gate")
		var planets: Array = []
		var planet_count := rng.randi_range(2, 4)
		for p in range(planet_count):
			planets.append({
				"id": "%s.planet.%d" % [system_id, p],
				"kind": ["rocky", "ice", "ocean", "gas"][rng.randi_range(0, 3)],
				"orbit_radius": 260.0 + p * 190.0 + rng.randf_range(-25.0, 25.0),
				"radius": rng.randf_range(24.0, 74.0),
				"color": Color.from_hsv(rng.randf(), rng.randf_range(0.25, 0.6), rng.randf_range(0.45, 0.85)).to_html(false),
				"landable": rng.randf() < 0.35,
			})
		systems.append({
			"system_id": system_id,
			"name": name.capitalize() + " Reach",
			"links": links,
			"planets": planets,
			"danger": ["low", "moderate", "high"][rng.randi_range(0, 2)],
		})
	return systems

static func surface_layout(planet: Dictionary, registry, world_seed: int) -> Dictionary:
	var planet_id := str(planet.get("content_id", ""))
	var anchors: Array = planet.get("anchors", [])
	var anchor_by_kind: Dictionary = {}
	var anchor_points: Array = []
	for anchor in anchors:
		anchor_by_kind[str(anchor.get("kind", ""))] = anchor
		anchor_points.append(Vector2(float(anchor.get("x", 0)), float(anchor.get("y", 0))))
	var build_slots: Array = []
	var build_anchor = anchor_by_kind.get("build_site", {})
	if not build_anchor.is_empty():
		for row in range(int(build_anchor.get("rows", 2))):
			for col in range(int(build_anchor.get("cols", 2))):
				build_slots.append({
					"col": col,
					"row": row,
					"x": float(build_anchor.get("x", 1200)) + col * 150.0,
					"y": float(build_anchor.get("y", 1800)) + row * 150.0,
				})
	var rng := rng_for(world_seed, "surface:" + planet_id)
	var nodes: Array = []
	var sequence := 0
	var species_pool: Array = planet.get("species_pool", [])
	for species_id in species_pool:
		var species = registry.get_species(str(species_id))
		var kind := str(species.get("kind", ""))
		var copies := 2 if kind == "flora" else 1
		for copy_index in range(copies):
			var point := _scatter_point(rng, anchor_points, nodes)
			nodes.append({
				"node_id": "%s.%s.%02d" % [planet_id, kind, sequence],
				"kind": kind,
				"species_id": str(species_id),
				"x": point.x,
				"y": point.y,
				"item_id": str(species.get("harvest", {}).get("item_id", "")),
				"amount": int(species.get("harvest", {}).get("amount", 1)),
			})
			sequence += 1
	var decor: Array = []
	for i in range(46):
		decor.append({
			"x": rng.randf_range(160.0, WORLD_SIZE - 160.0),
			"y": rng.randf_range(160.0, WORLD_SIZE - 160.0),
			"scale": rng.randf_range(0.4, 2.0),
			"kind": ["rock", "crystal", "tuft", "pool"][rng.randi_range(0, 3)],
			"phase": rng.randf_range(0.0, TAU),
		})
	var ship = anchor_by_kind.get("ship", {})
	var start := Vector2(float(ship.get("x", 1200)), float(ship.get("y", 1850)) - 70.0)
	return {
		"planet_id": planet_id,
		"world_size": WORLD_SIZE,
		"nodes": nodes,
		"decor": decor,
		"build_slots": build_slots,
		"start_pos": [start.x, start.y],
		"ship_pos": [float(ship.get("x", 1200)), float(ship.get("y", 1900))],
	}

static func _scatter_point(rng: RandomNumberGenerator, anchor_points: Array, nodes: Array) -> Vector2:
	for attempt in range(80):
		var candidate := Vector2(rng.randf_range(260.0, WORLD_SIZE - 260.0), rng.randf_range(300.0, WORLD_SIZE - 300.0))
		var clear := true
		for point in anchor_points:
			if candidate.distance_to(point) < 190.0:
				clear = false
				break
		if clear:
			for node in nodes:
				if candidate.distance_to(Vector2(float(node.get("x", 0)), float(node.get("y", 0)))) < 105.0:
					clear = false
					break
		if clear:
			return candidate
	return Vector2(rng.randf_range(260.0, WORLD_SIZE - 260.0), rng.randf_range(300.0, WORLD_SIZE - 300.0))

static func generation_signature(world_seed: int, registry) -> String:
	var snapshot: Dictionary = {
		"frontier": generate_frontier(world_seed, registry),
		"systems": {},
	}
	for system_id in registry.systems.keys():
		snapshot["systems"][str(system_id)] = system_visual(world_seed, str(system_id), registry)
	for planet_id in registry.planets.keys():
		var planet = registry.get_planet(str(planet_id))
		if bool(planet.get("landable", false)):
			snapshot["surface_" + str(planet_id)] = surface_layout(planet, registry, world_seed)
	return JSON.stringify(snapshot)
