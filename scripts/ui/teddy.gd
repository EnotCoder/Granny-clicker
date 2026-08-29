class_name UITeddy
extends RefCounted

const TEDDY_TEX := preload("res://assets/teddy.png")

var _root: Control
var _fx: UIFx
var _button: TextureButton
var _panel: ColorRect
var _even_btn: Button
var _odd_btn: Button
var _active: bool = true

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_button = root.get_node("%TeddyButton")
	_panel = root.get_node("%TeddyPanel")
	_even_btn = _panel.get_node("TeddyCenter/TeddyBox/EvenButton")
	_odd_btn = _panel.get_node("TeddyCenter/TeddyBox/OddButton")
	_button.texture_normal = TEDDY_TEX
	_button.texture_pressed = TEDDY_TEX
	_button.texture_hover = TEDDY_TEX
	_button.pressed.connect(_open)
	_even_btn.pressed.connect(_play.bind(true))
	_odd_btn.pressed.connect(_play.bind(false))
	_panel.get_node("TeddyCenter/TeddyBox/TeddyCloseButton").pressed.connect(_close)
	GameState.active_changed.connect(_on_active_changed)

func _on_active_changed(active: bool) -> void:
	_active = active

func _open() -> void:
	if not _active:
		return
	_panel.visible = true

func _close() -> void:
	_panel.visible = false

func _play(player_even: bool) -> void:
	if not _panel.visible:
		return
	var roll := randi_range(1, 100)
	var is_even := roll % 2 == 0
	var player_won := player_even == is_even
	_panel.visible = false
	if player_won:
		var gain := GameState.coins * 0.5
		GameState.add_coins(gain)
		_fx.spawn_float_at(gain, _button.global_position + _button.size * 0.5)
		_fx.show_toast((("Тедди проиграл! Ты получаешь ×1.5") if Loc.ru() else ("Teddy lost! You get ×1.5")))
		AudioManager.play_ach()
	else:
		var lost := GameState.coins * 0.5
		GameState.coins = maxf(0.0, GameState.coins - lost)
		GameState.coins_changed.emit()
		_fx.show_toast((("Тедди забрал 50%! Царап!") if Loc.ru() else ("Teddy took 50%! Scratch!")))
		AudioManager.play_click()
		_fx.red_flash(0.35, 0.5)
		_fx.shake(10.0, 0.4)
		_fx.blood_burst(_button.global_position + _button.size * 0.5, 16)
	YandexSDK.save_all()
