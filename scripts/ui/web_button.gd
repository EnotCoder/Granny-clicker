class_name UIWebButton
extends RefCounted

var _root: Control
var _fx: UIFx
var _button: TextureButton
var _label: Label

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_button = root.get_node("%WebButton")
	_label = root.get_node("%WebLabel")
	_button.pressed.connect(_on_pressed)
	GameState.web_started.connect(_on_started)
	GameState.web_ended.connect(_on_ended)
	GameState.language_changed.connect(update_button)
	GameState.loaded.connect(update_button)
	YandexSDK.language_loaded.connect(update_button)
	update_button()

func _on_pressed() -> void:
	GameState.start_web()
	if GameState.is_web():
		AudioManager.play_prestige()

func _on_started() -> void:
	update_button()
	_fx.punch(_button)

func _on_ended() -> void:
	update_button()

func update_button() -> void:
	if _button == null:
		return
	var ru := Loc.ru()
	var text: String
	if GameState.is_web():
		_button.disabled = true
		text = ("Паутина: %dс" if ru else "Web: %ds") % int(ceil(GameState.web_time))
	elif GameState.can_start_web():
		_button.disabled = false
		text = "Паутина ×2" if ru else "Web ×2"
	else:
		_button.disabled = true
		text = ("Кулдаун: %dс" if ru else "Cooldown: %ds") % int(ceil(GameState.web_cd_left()))
	if _label and text != _label.text:
		_label.text = text

func tick(_delta: float) -> void:
	update_button()
