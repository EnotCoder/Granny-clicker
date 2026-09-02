class_name UIFrenzy
extends RefCounted

const T_GRANNY := preload("res://assets/granny_button/granny.png")
const T_GRANNY_PRESSED := preload("res://assets/granny_button/granny_pressed.png")
const T_GRANDPA := preload("res://assets/grandpa_button/grandpa.png")
const T_GRANDPA_PRESSED := preload("res://assets/grandpa_button/grandpa_pressed.png")

var _root: Control
var _fx: UIFx
var _meme_button: TextureButton
var _frenzy_button: Button
var _angela: UIAngela

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_meme_button = root.get_node("%MemeButton")
	_frenzy_button = root.get_node("%FrenzyButton")
	_frenzy_button.pressed.connect(_on_pressed)
	GameState.frenzy_started.connect(_on_started)
	GameState.frenzy_ended.connect(_on_ended)
	GameState.language_changed.connect(update_button)
	GameState.loaded.connect(update_button)
	YandexSDK.language_loaded.connect(update_button)
	update_button()

func _on_pressed() -> void:
	if GameState.is_web():
		return
	GameState.start_frenzy()
	if GameState.is_frenzy():
		AudioManager.play_prestige()

func _on_started() -> void:
	_apply_character(true)
	update_button()
	if _angela:
		_angela.hide()
	_fx.show_toast(("ДЕДЪ В ЯРОСТИ! +150% к клику!" if Loc.ru() else "GRANDPA RAGE! +150% click power!"))
	_fx.punch(_meme_button)

func _on_ended() -> void:
	_apply_character(false)
	update_button()
	_fx.show_toast(("Дедушка смолчал..." if Loc.ru() else "Grandpa calmed down..."))

func _apply_character(frenzy: bool) -> void:
	if _meme_button == null:
		return
	if frenzy:
		_meme_button.texture_normal = T_GRANDPA
		_meme_button.texture_pressed = T_GRANDPA_PRESSED
	else:
		_meme_button.texture_normal = T_GRANNY
		_meme_button.texture_pressed = T_GRANNY_PRESSED

func update_button() -> void:
	if _frenzy_button == null:
		return
	var ru := Loc.ru()
	var label: String
	if GameState.is_web():
		_frenzy_button.disabled = true
		label = ("Паутина!" if ru else "In web!")
	elif GameState.is_frenzy():
		_frenzy_button.disabled = true
		label = ("Бешеный дедушка: %dс" if ru else "Grandpa Rage: %ds") % int(ceil(GameState.frenzy_time))
	elif GameState.can_start_frenzy():
		_frenzy_button.disabled = false
		label = "Бешеный дедушка" if ru else "Grandpa Rage"
	else:
		_frenzy_button.disabled = true
		label = ("Кулдаун: %dс" if ru else "Cooldown: %ds") % int(ceil(GameState.frenzy_cd_left()))
	if label != _frenzy_button.text:
		_frenzy_button.text = label

func tick(_delta: float) -> void:
	update_button()