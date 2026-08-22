class_name UISettings
extends RefCounted

var _root: Control
var _fx: UIFx
var _panel: ColorRect
var _sound_button: Button
var _language_button: Button
var _reset_button: Button
var _reset_hint: Label
var _reset_armed: bool = false
var _on_refresh: Callable

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_panel = root.get_node("%SettingsPanel")
	_sound_button = root.get_node("%SoundButton")
	_language_button = root.get_node("%LanguageButton")
	_reset_button = root.get_node("%ResetButton")
	_reset_hint = root.get_node("%ResetHint")
	root.get_node("%SettingsButton").pressed.connect(_open)
	root.get_node("%SettingsCloseButton").pressed.connect(_close)
	_sound_button.pressed.connect(_on_sound)
	_language_button.pressed.connect(_on_language)
	_reset_button.pressed.connect(_on_reset)
	GameState.language_changed.connect(_apply_language)
	GameState.loaded.connect(_apply_language)
	YandexSDK.language_loaded.connect(_apply_language)
	_apply_language()

func _apply_language() -> void:
	_root.get_node("%SettingsTitle").text = "Настройки" if Loc.ru() else "Settings"
	_root.get_node("%SettingsCloseButton").text = "Закрыть" if Loc.ru() else "Close"
	_root.get_node("%SettingsButton").tooltip_text = "Настройки" if Loc.ru() else "Settings"
	_sound_button.text = ("Звук: вкл" if GameState.sound_on else "Звук: выкл") if Loc.ru() else ("Sound: on" if GameState.sound_on else "Sound: off")
	_language_button.text = "Язык: Русский" if Loc.ru() else "Language: English"
	_reset_button.text = "Сброс прогресса" if Loc.ru() else "Reset progress"
	_reset_hint.text = ""
	_reset_armed = false

func _open() -> void:
	_reset_armed = false
	_reset_hint.text = ""
	_reset_button.text = "Сброс прогресса" if Loc.ru() else "Reset progress"
	_panel.visible = true

func _close() -> void:
	_panel.visible = false

func _on_sound() -> void:
	GameState.set_sound(not GameState.sound_on)
	AudioManager.set_muted(not GameState.sound_on)
	_sound_button.text = ("Звук: вкл" if GameState.sound_on else "Звук: выкл") if Loc.ru() else ("Sound: on" if GameState.sound_on else "Sound: off")

func _on_language() -> void:
	var next := "en" if Loc.ru() else "ru"
	GameState.set_language(next)

func _on_reset() -> void:
	var ru := Loc.ru()
	if not _reset_armed:
		_reset_armed = true
		_reset_hint.text = ("Точно? Нажми ещё раз для сброса." if ru else "Are you sure? Tap again to reset.")
		_reset_button.text = "СБРОСИТЬ?" if ru else "RESET?"
		return
	GameState.reset()
	YandexSDK.clear_save()
	YandexSDK.save_all()
	_reset_armed = false
	_reset_hint.text = ("Прогресс сброшен." if ru else "Progress reset.")
	_reset_button.text = "Сброс прогресса" if ru else "Reset progress"
	_fx.show_toast(("Прогресс сброшен!" if ru else "Progress reset!"))
	if _on_refresh.is_valid():
		_on_refresh.call()