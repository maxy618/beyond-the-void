class_name BtvTheme
extends RefCounted

## Shared palette and control styling. Everything is code-drawn to avoid asset licensing.

const BG := Color("#070b12")
const BG_DEEP := Color("#04060a")
const PANEL := Color(0.047, 0.078, 0.118, 0.94)
const PANEL_SOFT := Color(0.075, 0.118, 0.165, 0.9)
const PANEL_LIGHT := Color(0.11, 0.17, 0.22, 0.94)
const TEXT := Color("#e7f0ed")
const TEXT_DIM := Color("#91a5aa")
const TEXT_FAINT := Color("#5f7479")
const ACCENT := Color("#7fe0c2")
const ACCENT_DARK := Color("#1d5b53")
const AMBER := Color("#eab676")
const BLUE := Color("#8fb6ff")
const PURPLE := Color("#b7a1ff")
const DANGER := Color("#e58b7a")
const LINE := Color(0.55, 0.75, 0.73, 0.22)

static func make_theme(text_scale: float = 1.0) -> Theme:
	var scale := clampf(text_scale, 0.85, 1.5)
	var theme := Theme.new()
	theme.default_font_size = int(round(16.0 * scale))
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.35))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", BG)
	theme.set_color("font_disabled_color", "Button", TEXT_FAINT)
	theme.set_font_size("font_size", "Button", int(round(17.0 * scale)))
	theme.set_stylebox("normal", "Button", button_box(PANEL_LIGHT, LINE, 1))
	theme.set_stylebox("hover", "Button", button_box(Color("#1b3540"), ACCENT, 2))
	theme.set_stylebox("pressed", "Button", button_box(ACCENT, ACCENT, 2))
	theme.set_stylebox("disabled", "Button", button_box(Color(0.05, 0.08, 0.1, 0.85), Color(0.2, 0.28, 0.3, 0.35), 1))
	theme.set_stylebox("focus", "Button", button_box(Color(0, 0, 0, 0), ACCENT, 1))
	theme.set_constant("outline_size", "Button", 0)
	theme.set_stylebox("panel", "PanelContainer", flat(PANEL, 6, LINE, 1))
	theme.set_stylebox("panel", "Panel", flat(PANEL, 6, LINE, 1))
	theme.set_stylebox("normal", "LineEdit", flat(BG_DEEP, 3, LINE, 1))
	theme.set_stylebox("focus", "LineEdit", flat(BG_DEEP, 3, ACCENT, 1))
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("caret_color", "LineEdit", ACCENT)
	theme.set_stylebox("normal", "OptionButton", flat(PANEL_LIGHT, 3, LINE, 1))
	theme.set_stylebox("hover", "OptionButton", flat(Color("#243b45"), 3, ACCENT, 1))
	theme.set_stylebox("pressed", "OptionButton", flat(PANEL_SOFT, 3, ACCENT, 1))
	theme.set_color("font_color", "OptionButton", TEXT)
	theme.set_stylebox("panel", "PopupMenu", flat(PANEL, 10, LINE, 1))
	theme.set_color("font_color", "PopupMenu", TEXT)
	theme.set_color("font_hover_color", "PopupMenu", BG)
	theme.set_stylebox("hover", "PopupMenu", flat(ACCENT, 6, ACCENT, 0))
	theme.set_stylebox("separator", "HSeparator", flat(LINE, 0))
	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)
	theme.set_constant("margin_left", "MarginContainer", 0)
	theme.set_stylebox("scroll", "VScrollBar", flat(Color(0, 0, 0, 0), 4))
	theme.set_stylebox("grabber", "VScrollBar", flat(LINE, 4))
	theme.set_stylebox("grabber_highlight", "VScrollBar", flat(ACCENT, 4))
	theme.set_stylebox("grabber_pressed", "VScrollBar", flat(ACCENT, 4))
	return theme

static func flat(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func button_box(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := flat(bg, 3, border, border_width)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	return style

static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

static func wrapped(text: String, size: int = 15, color: Color = TEXT_DIM) -> Label:
	var node := label(text, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

static func spacer(height: float = 8.0, expand: bool = false) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	if expand:
		node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node

static func button(text: String, min_height: float = 50.0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(0, min_height)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.focus_mode = Control.FOCUS_ALL
	return node

static func header(text: String, size: int = 24) -> Label:
	var node := label(text, size, TEXT)
	node.add_theme_color_override("font_color", TEXT)
	return node

static func color(value, fallback: Color = ACCENT) -> Color:
	if value is Color:
		return value
	var text := str(value).strip_edges()
	if text.is_empty():
		return fallback
	return Color.from_string(text, fallback)

static func dim(value: float = 0.5) -> Color:
	return Color(0, 0, 0, clampf(value, 0.0, 1.0))

static func set_full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
