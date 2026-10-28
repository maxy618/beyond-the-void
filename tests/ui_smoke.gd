extends SceneTree

## Windowed portrait smoke: boots the real scene, drives the surface screen,
## exercises movement, panels, pause/save and captures screenshots.
## Run without --headless so Godot renders the actual interface.

const OUT := "res://build/reports/screenshots"
const REPORT := "res://build/reports/ui_smoke.json"
const UI_SAVE := "user://saves/slot_1.json"

var app: Control
var screen: BtvGameScreen
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

func _physics(count: int) -> void:
	for index in count:
		await physics_frame

func _close_panel() -> void:
	if screen._panel != null:
		screen._panel.close()
	await _frames(2)

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
	_check(app.menu_root != null and app.menu_root.get_child_count() >= 2, "title menu built")
	var menu_fields: Array = app.menu_root.find_children("*", "LineEdit", true, false)
	_check(menu_fields.is_empty(), "title menu has no seed field")
	await _shot("01_title_720x1280")

	app._on_new_game()
	await _frames(4)
	_check(app._entry != null, "entry mini-game starts on new game")
	if app._entry != null:
		await _shot("02_entry")
		app._entry._finish_early()
		await _frames(4)
	screen = app.game_screen as BtvGameScreen
	_check(screen != null, "game screen starts")
	if screen == null:
		_finish()
		return
	_check(screen.session.mode == "planet", "new game begins on a planet surface")
	_check(screen.session.planet_id == "planet.vela", "new game lands on Vela")
	_check(screen.world != null and screen.world.visible, "world view present")
	_check(screen.player != null, "player present")
	_check(screen.director != null and screen.director.camera != null, "camera director owns a camera")
	_check(screen._viewport.size.x <= 360 and screen._viewport.size.y > 0, "world renders in a low-resolution viewport")
	await _shot("02_surface")

	_check(screen.combat != null, "combat director present")
	_check(screen.combat.hostiles.size() == 3, "three hostiles spawned")
	_check(screen._fire_button != null and screen._fire_button.visible, "fire button present")
	var bolts_before := screen.combat.bolts.size()
	screen._on_fire_down()
	await _frames(2)
	screen._on_fire_up()
	_check(screen.combat.bolts.size() > bolts_before, "fire spawns a player bolt")
	_check(screen.player.combat, "player enters combat pose after firing")
	await _shot("02b_combat")

	screen._on_player_died()
	_check(screen._dying and not screen.player.visible, "death hides the player for reboot")
	await _physics(130)
	_check(not screen._dying and screen.player.visible, "player reboots after the delay")
	_check(is_equal_approx(screen.player.health, screen.player.max_health), "reboot restores hull")
	_check(is_equal_approx(screen.player.shield, screen.player.max_shield), "reboot restores shield")

	var start_x := screen.player.position.x
	screen._on_move_stick(Vector2.RIGHT)
	await _physics(30)
	screen._on_move_stick(Vector2.ZERO)
	_check(screen.player.position.x > start_x + 8.0, "move stick moves the player right")
	_check(screen.player.facing == "right", "player faces movement when aim is neutral")

	var stamina_before := screen.player.stamina
	screen._on_sprint_toggled(true)
	screen._on_move_stick(Vector2.RIGHT)
	await _physics(30)
	screen._on_move_stick(Vector2.ZERO)
	screen._on_sprint_toggled(false)
	_check(screen.player.stamina < stamina_before, "sprint drains stamina")
	await _physics(30)

	var energy_before := screen.player.energy
	screen._on_jet_toggled(true)
	await _physics(25)
	screen._on_jet_toggled(false)
	_check(screen.player.altitude > 0.0, "jetpack lifts the player")
	_check(screen.player.energy < energy_before, "jetpack drains energy")
	await _physics(90)

	screen._open_inventory()
	await _frames(2)
	_check(screen._panel is BtvInventorySheet, "inventory panel opens")
	await _shot("03_inventory")
	await _close_panel()

	screen._open_craft()
	await _frames(2)
	_check(screen._panel is BtvCraftSheet, "craft panel opens")
	await _close_panel()

	screen._open_journal()
	await _frames(2)
	_check(screen._panel is BtvJournalSheet, "journal panel opens")
	await _shot("04_journal")
	await _close_panel()

	screen._open_settings()
	await _frames(2)
	_check(screen._panel is BtvSettingsSheet, "settings panel opens")
	await _shot("05_settings")
	await _close_panel()

	screen._toggle_pause()
	await _frames(2)
	_check(screen._pause_layer != null and screen._pause_layer.visible, "pause overlay opens")
	screen._save_game()
	await _frames(2)
	_check(FileAccess.file_exists(UI_SAVE), "pause save writes a field record")
	await _shot("06_pause")
	screen._toggle_pause()
	await _frames(1)
	_check(not screen._pause_layer.visible, "pause overlay closes")

	await _resolution_checks()
	_finish()

func _resolution_checks() -> void:
	for size in [Vector2i(360, 640), Vector2i(1080, 2400)]:
		root.size = size
		DisplayServer.window_set_size(size)
		await _frames(4)
		var label := "%dx%d" % [size.x, size.y]
		print("LAYOUT %s window=%s root=%s visible=%s content=%s screen=%s vp=%s vpc=%s" % [
			label, DisplayServer.window_get_size(), root.size, root.get_visible_rect().size,
			root.content_scale_size, screen.size, screen._viewport.size, screen._viewport_container.size])
		print("LAYOUT2 %s vpc_global=%s vp_texture=%s vp_visible=%s camera_vp=%s world_rect=%s" % [
			label, screen._viewport_container.get_global_rect(),
			screen._viewport.get_texture().get_size(), screen._viewport.get_visible_rect().size,
			screen.director._viewport_size, screen._world_root.get_viewport_rect().size])
		var view_rect := Rect2(Vector2.ZERO, screen.size)
		_check(view_rect.has_point(screen._move_stick.get_global_rect().get_center()), "move stick on screen at " + label)
		_check(view_rect.has_point(screen._aim_stick.get_global_rect().get_center()), "aim stick on screen at " + label)
		_check(screen._viewport.size.x >= 160, "world viewport stays usable at " + label)
		await _shot("07_surface_" + label)

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
