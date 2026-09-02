class_name UIAchievements
extends RefCounted

const THEME := preload("res://scripts/ui_theme.gd")

var _root: Control
var _fx: UIFx
var _panel: ColorRect
var _list: VBoxContainer
var _ach_button: Button

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_panel = root.get_node("%AchievementsPanel")
	_list = root.get_node("%AchList")
	_ach_button = root.get_node("%AchievementsButton")
	_ach_button.pressed.connect(_on_button_pressed)
	root.get_node("%AchCloseButton").pressed.connect(_close)
	GameState.achievement_unlocked.connect(_on_unlocked)
	GameState.achievements_changed.connect(_on_changed)
	GameState.language_changed.connect(_on_lang)
	GameState.loaded.connect(_on_lang)
	YandexSDK.language_loaded.connect(_on_lang)
	_on_lang()

func _on_button_pressed() -> void:
	if GameState.is_web():
		return
	_build()
	_panel.visible = not _panel.visible

func _close() -> void:
	_panel.visible = false

func _on_changed() -> void:
	if _panel.visible:
		_build()

func _on_unlocked(id: String) -> void:
	AudioManager.play_ach()
	_fx.show_toast(GameState.ach_localized(id))
	if _panel.visible:
		_build()

func _on_lang() -> void:
	_root.get_node("%AchTitle").text = "Ачивки" if Loc.ru() else "Achievements"
	_root.get_node("%AchCloseButton").text = "Закрыть" if Loc.ru() else "Close"
	if _panel.visible:
		_build()

func _build() -> void:
	for c in _list.get_children():
		c.queue_free()
	var header := Label.new()
	if Loc.ru():
		header.text = "Цели ×%.0f и награды ×%.0f за перерождение" % [GameState.ACH_TARGET_GROWTH, GameState.ACH_REWARD_GROWTH]
	else:
		header.text = "Targets ×%.0f and rewards ×%.0f per rebirth" % [GameState.ACH_TARGET_GROWTH, GameState.ACH_REWARD_GROWTH]
	header.add_theme_color_override("font_color", Color("#a9a5b8"))
	header.add_theme_font_size_override("font_size", 14)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(header)
	for a in GameState.ACHIEVEMENTS:
		var id: String = a.id
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", THEME.rounded_rect(Color("#14141d"), Color("#2a2438"), 1, 10))
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		row.add_child(hb)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var title := Label.new()
		title.text = GameState.ach_localized(id)
		title.add_theme_color_override("font_color", Color("#f5f0e0"))
		title.add_theme_font_size_override("font_size", 17)
		vb.add_child(title)
		var prog := Label.new()
		prog.add_theme_font_size_override("font_size", 14)
		vb.add_child(prog)
		var claimed := GameState.is_claimed(id)
		var achieved := GameState.is_achieved(id)
		if claimed:
			prog.text = "✓"
			prog.add_theme_color_override("font_color", Color("#3ddc84"))
		elif achieved:
			prog.text = "%s / %s" % [GameState.format_num(GameState.ach_progress(id)), GameState.format_num(GameState.ach_target(id))]
			prog.add_theme_color_override("font_color", Color("#3ddc84"))
		else:
			prog.text = "%s / %s" % [GameState.format_num(GameState.ach_progress(id)), GameState.format_num(GameState.ach_target(id))]
			prog.add_theme_color_override("font_color", Color("#a9a5b8"))
		var claim := Button.new()
		claim.custom_minimum_size = Vector2(130, 0)
		claim.text = ("Забрать +%s" % GameState.format_num(GameState.ach_reward(id))) if Loc.ru() else ("Claim +%s" % GameState.format_num(GameState.ach_reward(id)))
		THEME.apply_button(claim, Color("#1a1a28"), THEME.ACCENT)
		claim.disabled = not (achieved and not claimed)
		claim.pressed.connect(_claim.bind(id, row))
		hb.add_child(claim)
		_list.add_child(row)

func _claim(id: String, _row: Control) -> void:
	if GameState.is_web():
		return
	if GameState.claim_achievement(id):
		AudioManager.play_ach()