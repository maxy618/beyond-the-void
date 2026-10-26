extends Control

## Title screen, settings persistence and the single live field session.

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SEED := 424242

var registry: ContentRegistry
var settings: Dictionary = {}
var session: GameSession
var game_screen: BtvGameScreen
var menu_root: Control
var menu_backdrop: BtvBackdrop
var menu_status: Label
var seed_input: LineEdit
var _rebuild_pending := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_settings()
	theme = BtvTheme.make_theme(float(settings.get("text_scale", 1.0)))
	registry = ContentRegistry.new()
	if not registry.load_all("res://content"):
		_show_boot_error()
		return
	_show_menu()

func _load_settings() -> void:
	settings = {
		"quality": "balanced",
		"reduced_motion": false,
		"left_handed": false,
		"text_scale": 1.0,
		"touch_sensitivity": 1.0,
		"last_seed": DEFAULT_SEED,
	}
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key in settings.keys():
		settings[key] = config.get_value("settings", str(key), settings[key])

func _save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings.keys():
		config.set_value("settings", str(key), settings[key])
	config.save(SETTINGS_PATH)

func _show_boot_error() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	panel.add_child(column)
	column.add_child(BtvTheme.header("Content pack failed to load", 24))
	for error in registry.errors:
		column.add_child(BtvTheme.wrapped(str(error), 14, BtvTheme.DANGER))
	add_child(panel)

func _show_menu() -> void:
	_rebuild_pending = false
	if game_screen != null:
		game_screen.queue_free()
		game_screen = null
	for child in get_children():
		child.queue_free()
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_root)
	menu_backdrop = BtvBackdrop.new()
	menu_backdrop.set_visuals(int(settings.get("last_seed", DEFAULT_SEED)), str(settings.get("quality", "balanced")), bool(settings.get("reduced_motion", false)))
	menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(menu_backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	menu_root.add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(480, 0)
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	var title := BtvTheme.header(registry.loc.t("ui.title"), 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := BtvTheme.label(registry.loc.t("ui.subtitle"), 15, BtvTheme.TEXT_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	column.add_child(BtvTheme.spacer(10))
	var new_hint := BtvTheme.wrapped(registry.loc.t("ui.new_game_hint"), 13, BtvTheme.TEXT_DIM)
	new_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(new_hint)
	var seed_label := BtvTheme.label(registry.loc.t("ui.seed_label"), 12, BtvTheme.TEXT_FAINT)
	column.add_child(seed_label)
	seed_input = LineEdit.new()
	seed_input.text = str(int(settings.get("last_seed", DEFAULT_SEED)))
	seed_input.custom_minimum_size = Vector2(0, 48)
	column.add_child(seed_input)
	var new_button := BtvTheme.button(registry.loc.t("ui.new_journey"), 54)
	new_button.pressed.connect(_on_new_game)
	column.add_child(new_button)
	var continue_button := BtvTheme.button(registry.loc.t("ui.continue"), 54)
	continue_button.disabled = not _save_exists()
	continue_button.pressed.connect(_on_continue)
	column.add_child(continue_button)
	var continue_hint := BtvTheme.label(
		registry.loc.t("ui.save_found") if _save_exists() else registry.loc.t("ui.no_save"),
		11, BtvTheme.TEXT_FAINT)
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(continue_hint)
	var settings_button := BtvTheme.button(registry.loc.t("ui.settings"), 50)
	settings_button.pressed.connect(_open_menu_settings)
	column.add_child(settings_button)
	var quit_button := BtvTheme.button(registry.loc.t("ui.quit"), 48)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit_button)
	column.add_child(BtvTheme.spacer(6))
	var hint := BtvTheme.label(registry.loc.t("ui.menu_hint"), 11, BtvTheme.TEXT_FAINT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	menu_status = BtvTheme.label("", 12, BtvTheme.DANGER)
	menu_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(menu_status)
	var version := BtvTheme.label(registry.loc.t("ui.version"), 10, BtvTheme.TEXT_FAINT)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(version)

func _save_exists() -> bool:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(GameSession.DEFAULT_SAVE_PATH + str(suffix)):
			return true
	return false

func _on_new_game() -> void:
	var seed := DEFAULT_SEED
	if seed_input != null and seed_input.text.strip_edges().is_valid_int():
		seed = int(seed_input.text.strip_edges())
	settings["last_seed"] = seed
	_save_settings()
	var game := GameSession.new(registry)
	game.new_game(seed)
	game.settings = settings.duplicate()
	_start_game(game)

func _on_continue() -> void:
	var game := GameSession.new(registry)
	game.settings = settings.duplicate()
	var result := game.load_save()
	if not bool(result.get("ok", false)):
		if menu_status != null:
			menu_status.text = registry.loc.t("ui.load_failed") + "\n" + str(result.get("error", result.get("code", "")))
		return
	settings = game.settings.duplicate()
	_save_settings()
	_start_game(game)

func _start_game(game: GameSession) -> void:
	session = game
	settings = session.settings.duplicate()
	_save_settings()
	theme = BtvTheme.make_theme(float(settings.get("text_scale", 1.0)))
	for child in get_children():
		child.queue_free()
	menu_root = null
	menu_backdrop = null
	game_screen = BtvGameScreen.new()
	game_screen.setup(session)
	game_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_screen.exit_to_menu.connect(_on_exit_to_menu)
	game_screen.settings_changed.connect(_on_game_settings_changed)
	add_child(game_screen)

func _on_exit_to_menu() -> void:
	if session != null:
		session.save()
		settings = session.settings.duplicate()
		_save_settings()
	session = null
	_show_menu()

func _on_game_settings_changed() -> void:
	if session == null:
		return
	settings = session.settings.duplicate()
	_save_settings()
	theme = BtvTheme.make_theme(float(settings.get("text_scale", 1.0)))
	if not _rebuild_pending:
		_rebuild_pending = true
		call_deferred("_rebuild_game_screen")

func _rebuild_game_screen() -> void:
	_rebuild_pending = false
	if session == null or game_screen == null:
		return
	var old := game_screen
	game_screen = BtvGameScreen.new()
	game_screen.setup(session)
	game_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_screen.exit_to_menu.connect(_on_exit_to_menu)
	game_screen.settings_changed.connect(_on_game_settings_changed)
	add_child(game_screen)
	old.queue_free()

func _open_menu_settings() -> void:
	var sheet := BtvSettingsSheet.new()
	sheet.setup_settings(registry.loc, settings.duplicate(), _on_menu_setting_changed, _on_menu_settings_applied)
	add_child(sheet)

func _on_menu_setting_changed(key: String, value) -> void:
	settings[key] = value
	_save_settings()
	if menu_backdrop != null:
		menu_backdrop.set_visuals(int(settings.get("last_seed", DEFAULT_SEED)), str(settings.get("quality", "balanced")), bool(settings.get("reduced_motion", false)))
	theme = BtvTheme.make_theme(float(settings.get("text_scale", 1.0)))

func _on_menu_settings_applied(values: Dictionary) -> void:
	for key in values.keys():
		settings[key] = values[key]
	_save_settings()
	theme = BtvTheme.make_theme(float(settings.get("text_scale", 1.0)))
	call_deferred("_show_menu")
