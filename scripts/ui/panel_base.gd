class_name BtvPanelBase
extends Control

## A bottom sheet. Subclasses fill the scroll body; the world pauses behind it.

signal closed

var session: GameSession
var loc: Localization
var title_key: String = ""
var body: VBoxContainer
var sheet: PanelContainer
var _dim: ColorRect

func setup(p_session: GameSession, p_loc: Localization, p_title_key: String) -> void:
	session = p_session
	loc = p_loc
	title_key = p_title_key

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.015, 0.025, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	sheet = PanelContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet.add_theme_stylebox_override("panel", BtvTheme.flat(BtvTheme.PANEL, 22, BtvTheme.LINE, 1))
	margin.add_child(sheet)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	sheet.add_child(outer)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 54)
	outer.add_child(header)
	var title := BtvTheme.header(loc.t(title_key), 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(54, 46)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.tooltip_text = loc.t("ui.close_panel")
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var rule := HSeparator.new()
	outer.add_child(rule)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	_fill()

func _fill() -> void:
	pass

func refresh() -> void:
	if body == null:
		return
	for child in body.get_children():
		child.queue_free()
	_fill()

func close() -> void:
	closed.emit()
	queue_free()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func add_section(text: String) -> void:
	var node := BtvTheme.label(text, 13, BtvTheme.ACCENT)
	node.add_theme_constant_override("outline_size", 0)
	body.add_child(node)

func add_note(text: String) -> Label:
	var node := BtvTheme.wrapped(text, 14, BtvTheme.TEXT_DIM)
	body.add_child(node)
	return node

func add_empty(text: String) -> void:
	var node := BtvTheme.wrapped(text, 15, BtvTheme.TEXT_FAINT)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(node)
