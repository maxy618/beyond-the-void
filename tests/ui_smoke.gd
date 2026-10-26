extends SceneTree

## Windowed portrait smoke: boots the real scene, exercises UI paths and captures screenshots.
## Run without --headless: Godot renders the actual interface for visual evidence.

const OUT := "res://build/reports/screenshots"
const REPORT := "res://build/reports/ui_smoke.json"
const UI_SAVE := "user://saves/slot_1.json"

var app: Control
var failures: Array[String] = []
var steps: Array[Dictionary] = []
var screenshots: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	steps.append({"check": message, "ok": condition})
	if not condition:
		failures.append(message)
		print("FAILED " + message)

func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(name + ".png")
	if image == null or image.is_empty():
		_check(false, "empty screenshot " + name)
		return
	var error := image.save_png(path)
	_check(error == OK, "screenshot " + name)
	if error == OK:
		screenshots.append(path)
		print("SHOT " + path + " " + str(image.get_width()) + "x" + str(image.get_height()))

func _frames(count: int = 2) -> void:
	for index in count:
		await process_frame

func _close_panel(screen: BtvGameScreen) -> void:
	if screen._panel != null:
		screen._panel.close()
	await _frames(2)

func _move_to(screen: BtvGameScreen, point: Vector2, mode_id: String) -> void:
	screen.session.player_pos = point
	screen.session.set_tool_mode(mode_id)
	screen._update_target()
	screen._update_hud()

func _run() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = UI_SAVE + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size = Vector2i(720, 1280)
	DisplayServer.window_set_size(Vector2i(720, 1280))
	await _frames(3)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_check(false, "main scene loads")
		_finish()
		return
	app = packed.instantiate() as Control
	root.add_child(app)
	await _frames(4)
	_check(app.registry != null and app.registry.load_ok, "content pack loaded")
	_check(app.menu_root != null and app.seed_input != null, "title menu built")
	await _shot("01_title_720x1280")

	app.seed_input.text = "424242"
	app._on_new_game()
	await _frames(4)
	var screen := app.game_screen as BtvGameScreen
	_check(screen != null, "game screen starts")
	if screen == null:
		_finish()
		return
	_check(screen.session.mode == "space", "new game begins in space")
	_check(screen.world != null and screen.world.visible, "world view present")
	await _shot("02_space")

	screen._open_chart()
	await _frames(2)
	_check(screen._panel is BtvChartSheet, "chart panel opens in space")
	await _shot("03_chart")
	await _close_panel(screen)

	var landed := screen.session.land_on("planet.vela")
	_check(bool(landed.get("ok", false)), "land on Vela")
	screen._refresh_world()
	await _frames(3)
	_check(screen.session.mode == "planet", "planet mode after landing")
	await _shot("04_planet_tidebreak")

	screen._open_inventory()
	await _frames(2)
	_check(screen._panel is BtvInventorySheet, "inventory panel opens")
	await _shot("05_inventory")
	await _close_panel(screen)

	screen._open_craft()
	await _frames(2)
	_check(screen._panel is BtvCraftSheet, "craft panel opens")
	await _shot("06_craft")
	var craft_sheet := screen._panel as BtvCraftSheet
	var alloy_before := screen.session.inventory.count("item.alloy_plate")
	craft_sheet._craft("recipe.refine.alloy_plate")
	await _frames(2)
	_check(screen.session.inventory.count("item.alloy_plate") > alloy_before, "craft panel fabricates alloy plate")
	await _close_panel(screen)

	var layout: Dictionary = screen.session.surface_layout()
	var flora_node: Dictionary = {}
	for raw in layout.get("nodes", []):
		var node: Dictionary = raw
		if str(node.get("kind", "")) == "flora":
			flora_node = node
			break
	_check(not flora_node.is_empty(), "surface contains flora")
	if not flora_node.is_empty():
		var node_pos := Vector2(float(flora_node.x), float(flora_node.y))
		_move_to(screen, node_pos + Vector2(30, 0), "mode.scan")
		_check(str(screen._target.get("kind", "")) == "species", "scan target selected")
		var species_id := str(flora_node.get("species_id", ""))
		var before_observations := screen.session.observations.size()
		screen._action_button.pressed.emit()
		await _frames(3)
		_check(screen.session.observations.has(species_id), "UI observe records species")
		_check(screen.session.observations.size() > before_observations, "observation count advances")
		await _shot("07_observed")

		var item_id := str((screen.session.registry.get_species(species_id) as Dictionary).get("harvest", {}).get("item_id", ""))
		var before_count := screen.session.inventory.count(item_id)
		_move_to(screen, node_pos + Vector2(30, 0), "mode.sample")
		screen._action_button.pressed.emit()
		await _frames(2)
		_check(screen.session.inventory.count(item_id) > before_count, "UI gather adds harvest item")

	var anchors: Array = screen.session.get_planet().get("anchors", [])
	var market_anchor: Dictionary = {}
	var npc_anchor: Dictionary = {}
	for raw_anchor in anchors:
		var anchor: Dictionary = raw_anchor
		if str(anchor.get("kind", "")) == "market":
			market_anchor = anchor
		elif str(anchor.get("kind", "")) == "npc":
			npc_anchor = anchor
	if not market_anchor.is_empty():
		_move_to(screen, Vector2(float(market_anchor.x) + 90.0, float(market_anchor.y)), "mode.scan")
		_check(str(screen._target.get("kind", "")) == "market", "market target selected")
		screen._action_button.pressed.emit()
		await _frames(3)
		_check(screen._panel is BtvMarketSheet, "market panel opens from world target")
		await _shot("08_market")
		var market_sheet := screen._panel as BtvMarketSheet
		var credits_before := screen.session.credits
		var stock_before: int = screen.session.market_states["market.vela.coast"].stock_of("item.saltglass_shard")
		market_sheet._buy("item.saltglass_shard")
		market_sheet._buy("item.saltglass_shard")
		await _frames(2)
		_check(screen.session.credits < credits_before, "market panel buy spends credits")
		_check(screen.session.market_states["market.vela.coast"].stock_of("item.saltglass_shard") < stock_before, "market panel buy reduces stock")
		await _close_panel(screen)
	if not npc_anchor.is_empty():
		_move_to(screen, Vector2(float(npc_anchor.x) + 80.0, float(npc_anchor.y)), "mode.scan")
		_check(str(screen._target.get("kind", "")) == "npc", "npc target selected")
		screen._action_button.pressed.emit()
		await _frames(3)
		_check(screen._panel is BtvDialogueSheet, "dialogue panel opens from world target")
		await _shot("09_dialogue")
		var dialogue_sheet := screen._panel as BtvDialogueSheet
		var node_before := screen.session.dialogue.current_node_id
		dialogue_sheet._choose("ask_signal")
		await _frames(2)
		_check(screen.session.dialogue.current_node_id != node_before, "dialogue choice advances node")
		await _close_panel(screen)

	screen._open_build()
	await _frames(2)
	_check(screen._panel is BtvBuildSheet, "build panel opens")
	await _shot("10_build")
	var build_sheet := screen._panel as BtvBuildSheet
	var buildings_before := screen.session.buildings.size()
	build_sheet._build("build.power_cell", build_sheet._first_free_slot())
	await _frames(2)
	_check(screen.session.buildings.size() > buildings_before, "build panel places power cell")
	await _close_panel(screen)

	screen._open_ship()
	await _frames(2)
	_check(screen._panel is BtvShipSheet, "ship panel opens")
	await _shot("11_ship")
	var ship_sheet := screen._panel as BtvShipSheet
	var capacity_before := screen.session.inventory.capacity_kg
	ship_sheet._equip("ship.module.cargo_pods")
	await _frames(2)
	_check(screen.session.inventory.capacity_kg > capacity_before, "ship panel equips cargo pods")
	await _close_panel(screen)

	screen._open_journal()
	await _frames(2)
	_check(screen._panel is BtvJournalSheet, "journal panel opens")
	await _shot("12_journal")
	await _close_panel(screen)

	screen._open_settings()
	await _frames(2)
	_check(screen._panel is BtvSettingsSheet, "settings panel opens")
	await _shot("13_settings")
	await _close_panel(screen)

	screen._toggle_pause()
	await _frames(2)
	_check(screen._pause_layer != null and screen._pause_layer.visible, "pause overlay opens")
	screen._save_game()
	await _frames(2)
	_check(FileAccess.file_exists(UI_SAVE), "pause save writes a field record")
	await _shot("14_pause")
	screen._toggle_pause()
	await _frames(1)
	_check(not screen._pause_layer.visible, "pause overlay closes")

	_check(screen.session.journal.size() > 0, "gameplay generated journal entries")
	_check(screen.session.observations.size() > 0, "gameplay generated codex observations")
	await _responsive_shots(screen)
	_finish()

func _responsive_shots(screen: BtvGameScreen) -> void:
	root.size = Vector2i(360, 640)
	await _frames(3)
	await _shot("15_planet_360x640")
	root.size = Vector2i(1080, 2400)
	await _frames(3)
	var tall_dock := screen._dock.get_global_rect()
	var tall_stick := screen._joystick.get_global_rect()
	_check(tall_dock.size.x <= 1080.0 and tall_dock.end.x <= 1080.5, "tall 9:20 dock fits portrait width")
	_check(tall_stick.position.x >= 0.0 and tall_stick.end.x <= 1080.5, "tall 9:20 joystick remains on screen")
	await _shot("16_planet_1080x2400")

func _finish() -> void:
	var report := {
		"ok": failures.is_empty(),
		"checks": steps.size(),
		"failures": failures,
		"steps": steps,
		"screenshots": screenshots,
		"window": [720, 1280],
		"tested_resolutions": [[720, 1280], [360, 640], [1080, 2400]],
		"engine": Engine.get_version_info(),
	}
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("UI_SMOKE checks=%d failures=%d screenshots=%d" % [steps.size(), failures.size(), screenshots.size()])
	if failures.is_empty():
		quit(0)
	else:
		quit(1)
