extends SceneTree

## Deterministic generation stress: 500 seeds, failed seeds retained with reasons.

const SEED_BASE := 100000
const SEED_COUNT := 500

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var registry := ContentRegistry.new()
	if not registry.load_all("res://content"):
		print("GENERATION_ABORTED content load failed: ", registry.errors)
		quit(2)
		return
	var planet: Dictionary = registry.get_planet("planet.vela")
	var started := Time.get_ticks_msec()
	var failed_seeds: Array = []
	var node_total := 0
	var slowest_ms := 0
	var slowest_seed := -1
	for i in range(SEED_COUNT):
		var seed := SEED_BASE + i
		var seed_started := Time.get_ticks_msec()
		var errors: Array = []
		var layout: Dictionary = WorldGen.surface_layout(planet, registry, seed)
		var nodes: Array = layout.get("nodes", [])
		if nodes.size() < 12:
			errors.append("fewer than 12 ecology nodes (%d)" % nodes.size())
		if layout.get("build_slots", []).size() != 4:
			errors.append("expected 4 build pads")
		var seen_nodes: Dictionary = {}
		for raw in nodes:
			var node: Dictionary = raw
			var node_id := str(node.get("node_id", ""))
			if node_id.is_empty() or seen_nodes.has(node_id):
				errors.append("duplicate or empty node id " + node_id)
			seen_nodes[node_id] = true
			var x := float(node.get("x", -1.0))
			var y := float(node.get("y", -1.0))
			if x < 0.0 or y < 0.0 or x > WorldGen.WORLD_SIZE or y > WorldGen.WORLD_SIZE:
				errors.append("node out of bounds " + node_id)
			var species_id := str(node.get("species_id", ""))
			if registry.get_species(species_id).is_empty():
				errors.append("unknown species " + species_id)
			var item_id := str(node.get("item_id", ""))
			if not item_id.is_empty() and registry.get_item(item_id).is_empty():
				errors.append("unknown harvest item " + item_id)
		node_total += nodes.size()
		var frontier: Array = WorldGen.generate_frontier(seed, registry)
		if frontier.size() != 6:
			errors.append("frontier system count %d" % frontier.size())
		var seen_systems: Dictionary = {}
		for raw_system in frontier:
			var system: Dictionary = raw_system
			var system_id := str(system.get("system_id", ""))
			if system_id.is_empty() or seen_systems.has(system_id):
				errors.append("duplicate or empty frontier system " + system_id)
			seen_systems[system_id] = true
			if system.get("planets", []).is_empty():
				errors.append("frontier system has no planets " + system_id)
		var elapsed := Time.get_ticks_msec() - seed_started
		if elapsed > slowest_ms:
			slowest_ms = elapsed
			slowest_seed = seed
		if not errors.is_empty():
			failed_seeds.append({"seed": seed, "errors": errors})
	var duration := Time.get_ticks_msec() - started
	var report := {
		"schema_version": 1,
		"generated_at_unix": int(Time.get_unix_time_from_system()),
		"engine_version": str(Engine.get_version_info().get("string", "")),
		"generator_version": WorldGen.GENERATOR_VERSION,
		"seed_base": SEED_BASE,
		"seed_count": SEED_COUNT,
		"planet_id": "planet.vela",
		"duration_ms": duration,
		"average_ms": float(duration) / float(SEED_COUNT),
		"slowest_seed": slowest_seed,
		"slowest_seed_ms": slowest_ms,
		"seeds_passed": SEED_COUNT - failed_seeds.size(),
		"seeds_failed": failed_seeds.size(),
		"nodes_generated": node_total,
		"failed_seeds": failed_seeds,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/reports"))
	var file := FileAccess.open("res://build/reports/generation_stress.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("GENERATION_STRESS seeds=%d failed=%d nodes=%d duration_ms=%d" % [SEED_COUNT, failed_seeds.size(), node_total, duration])
	for failure in failed_seeds.slice(0, 10):
		print("FAILED_SEED ", failure)
	quit(0 if failed_seeds.is_empty() else 1)
