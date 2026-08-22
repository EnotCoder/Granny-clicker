class_name UIHud
extends RefCounted

var _root: Control
var _coins_label: Label
var _per_sec_label: Label
var _ach_button: Button
var _fullscreen_button: Button

func _init(root: Control) -> void:
	_root = root
	_coins_label = root.get_node("%CoinsLabel")
	_per_sec_label = root.get_node("%PerSecLabel")
	_ach_button = root.get_node("%AchievementsButton")
	_fullscreen_button = root.get_node("%FullscreenButton")
	GameState.coins_changed.connect(update_all)
	GameState.upgrades_changed.connect(update_all)
	GameState.achievement_unlocked.connect(_on_achievement_unlocked)
	GameState.achievements_changed.connect(_update_ach_button)
	GameState.language_changed.connect(_on_lang)
	GameState.loaded.connect(_on_lang)
	YandexSDK.fullscreen_checked.connect(_update_fullscreen_button)
	YandexSDK.language_loaded.connect(_on_lang)
	update_all()

func update_all() -> void:
	if _coins_label == null:
		return
	var shown := GameState.format_num(GameState.coins)
	if shown != _coins_label.text:
		_coins_label.text = shown
	if _per_sec_label:
		var suffix := "сек" if Loc.ru() else "s"
		_per_sec_label.text = "+%s/%s" % [GameState.format_num(GameState.get_money_per_sec()), suffix]
	_update_ach_button()

func _on_achievement_unlocked(_id: String) -> void:
	_update_ach_button()

func _update_ach_button() -> void:
	if _ach_button == null:
		return
	var n := GameState.unclaimed_count()
	_ach_button.text = ("Ачивки" if Loc.ru() else "Achievements")
	if n > 0:
		_ach_button.text += " (%d)" % n

func _update_fullscreen_button() -> void:
	if _fullscreen_button:
		_fullscreen_button.visible = YandexSDK.fullscreen_available

func _on_lang() -> void:
	_update_ach_button()