class_name BtvSettingsSheet
extends BtvPanelBase

## Settings sheet shared by the title screen and the field pause.

var values: Dictionary = {}
var on_changed: Callable = Callable()
var on_apply: Callable = Callable()
var _building := false

func setup_settings(p_loc: Localization, p_values: Dictionary, p_changed: Callable, p_apply: Callable = Callable()) -> void:
	loc = p_loc
	values = p_values
	on_changed = p_changed
	on_apply = p_apply
	title_key = "ui.settings_title"

func _fill() -> void:
	_building = true
	add_section(loc.t("ui.quality"))
	var quality := OptionButton.new()
	quality.custom_minimum_size = Vector2(0, 48)
	for pair in [["low", "ui.quality_low"], ["balanced", "ui.quality_balanced"], ["high", "ui.quality_high"], ["ultra", "ui.quality_ultra"]]:
		quality.add_item(loc.t(str(pair[1])))
		quality.set_item_metadata(quality.item_count - 1, str(pair[0]))
	var current_quality := str(values.get("quality", "balanced"))
	for i in range(quality.item_count):
		if str(quality.get_item_metadata(i)) == current_quality:
			quality.select(i)
	quality.item_selected.connect(func(index: int) -> void:
		_apply("quality", str(quality.get_item_metadata(index)))
	)
	body.add_child(quality)

	add_section(loc.t("ui.text_scale"))
	var text_scale := _slider(float(values.get("text_scale", 1.0)), 0.85, 1.5, 0.05)
	text_scale.value_changed.connect(func(value: float) -> void: _apply("text_scale", value))
	body.add_child(text_scale)

	add_section(loc.t("ui.touch_sensitivity"))
	var touch := _slider(float(values.get("touch_sensitivity", 1.0)), 0.5, 1.5, 0.05)
	touch.value_changed.connect(func(value: float) -> void: _apply("touch_sensitivity", value))
	body.add_child(touch)

	var reduced := CheckButton.new()
	reduced.text = loc.t("ui.reduced_motion")
	reduced.button_pressed = bool(values.get("reduced_motion", false))
	reduced.custom_minimum_size = Vector2(0, 48)
	reduced.toggled.connect(func(value: bool) -> void: _apply("reduced_motion", value))
	body.add_child(reduced)

	var left := CheckButton.new()
	left.text = loc.t("ui.left_handed")
	left.button_pressed = bool(values.get("left_handed", false))
	left.custom_minimum_size = Vector2(0, 48)
	left.toggled.connect(func(value: bool) -> void: _apply("left_handed", value))
	body.add_child(left)

	add_section(loc.t("ui.audio_section"))
	for entry in [
		["vol_master", "ui.master_volume"],
		["vol_music", "ui.music_volume"],
		["vol_sfx", "ui.sfx_volume"],
		["vol_ambience", "ui.ambience_volume"],
	]:
		add_section(loc.t(str(entry[1])))
		var volume := _slider(float(values.get(str(entry[0]), 0.8)), 0.0, 1.0, 0.05)
		volume.value_changed.connect(func(value: float) -> void: _apply(str(entry[0]), value))
		body.add_child(volume)

	var music_on := CheckButton.new()
	music_on.text = loc.t("ui.music_enabled")
	music_on.button_pressed = bool(values.get("music_enabled", true))
	music_on.custom_minimum_size = Vector2(0, 48)
	music_on.toggled.connect(func(value: bool) -> void: _apply("music_enabled", value))
	body.add_child(music_on)

	add_section(loc.t("ui.controls_section"))
	var hold_sprint := CheckButton.new()
	hold_sprint.text = loc.t("ui.hold_sprint")
	hold_sprint.button_pressed = bool(values.get("hold_sprint", true))
	hold_sprint.custom_minimum_size = Vector2(0, 48)
	hold_sprint.toggled.connect(func(value: bool) -> void: _apply("hold_sprint", value))
	body.add_child(hold_sprint)

	var hold_jet := CheckButton.new()
	hold_jet.text = loc.t("ui.hold_jetpack")
	hold_jet.button_pressed = bool(values.get("hold_jetpack", true))
	hold_jet.custom_minimum_size = Vector2(0, 48)
	hold_jet.toggled.connect(func(value: bool) -> void: _apply("hold_jetpack", value))
	body.add_child(hold_jet)

	add_section(loc.t("ui.screen_shake"))
	var shake := _slider(float(values.get("screen_shake", 1.0)), 0.0, 1.0, 0.05)
	shake.value_changed.connect(func(value: float) -> void: _apply("screen_shake", value))
	body.add_child(shake)

	body.add_child(BtvTheme.spacer(8))
	var apply_button := BtvTheme.button(loc.t("ui.apply"), 52)
	apply_button.pressed.connect(func() -> void:
		if on_apply.is_valid():
			on_apply.call(values)
		close()
	)
	body.add_child(apply_button)
	_building = false

func _slider(value: float, minimum: float, maximum: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 44)
	return slider

func _apply(key: String, value) -> void:
	if _building:
		return
	values[key] = value
	if on_changed.is_valid():
		on_changed.call(key, value)
