extends RefCounted
## Фабрика стилей для тёмно-золотого интерфейса.

const GOLD := Color("#ffd447")
const GOLD_DARK := Color("#8a5a00")
const DARK := Color("#0e0e16")
const DARK_LIGHT := Color("#191927")
const PANEL_BG := Color("#12121c")
const ACCENT := Color("#ffb700")
const GREEN := Color("#3ddc84")
const RED := Color("#ff6b6b")
const TEXT_MAIN := Color("#f5f0e0")
const TEXT_DIM := Color("#a9a5b8")
const COLOR_CLICK := Color("#3b82f6")
const COLOR_PASSIVE := Color("#22c55e")

static func rounded_rect(bg: Color, border: Color = Color(0, 0, 0, 0), border_w: int = 0, radius: int = 14, shadow: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 3)
	return sb

static func gradient_rect(colors: PackedColorArray, radius: int = 14, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = colors[0]
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	return sb

static func button_style(normal_bg: Color, accent: Color) -> Dictionary:
	var dark := normal_bg.darkened(0.25)
	var normal := rounded_rect(dark, accent.darkened(0.45), 2, 12, true)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0

	var hover := rounded_rect(dark.lightened(0.12), accent.darkened(0.3), 2, 12, true)
	hover.content_margin_left = 16.0
	hover.content_margin_right = 16.0
	hover.content_margin_top = 10.0
	hover.content_margin_bottom = 10.0

	var pressed := rounded_rect(dark.darkened(0.15), accent.darkened(0.45), 2, 12)
	pressed.content_margin_left = 16.0
	pressed.content_margin_right = 16.0
	pressed.content_margin_top = 10.0
	pressed.content_margin_bottom = 10.0

	var disabled := rounded_rect(Color("#12121a"), Color("#2c2c3e"), 2, 12)
	disabled.content_margin_left = 16.0
	disabled.content_margin_right = 16.0
	disabled.content_margin_top = 10.0
	disabled.content_margin_bottom = 10.0

	return {
		"normal": normal,
		"hover": hover,
		"pressed": pressed,
		"disabled": disabled,
	}

static func apply_button(btn: Button, bg: Color, accent: Color) -> void:
	var s := button_style(bg, accent)
	btn.add_theme_stylebox_override("normal", s.normal)
	btn.add_theme_stylebox_override("hover", s.hover)
	btn.add_theme_stylebox_override("pressed", s.pressed)
	btn.add_theme_stylebox_override("disabled", s.disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", TEXT_MAIN)
	btn.add_theme_color_override("font_disabled_color", Color("#6a6780"))
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_constant_override("outline_size", 0)
