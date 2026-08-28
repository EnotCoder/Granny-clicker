class_name UIAngela
extends RefCounted

const SZ := Vector2(330, 330)
const FLY_DURATION := 4.5
const ALPHA := 0.6
const BOB := 22.0

var _root: Control
var _fx: UIFx
var _button: TextureButton
var _settings_panel: ColorRect
var _ach_panel: ColorRect
var _prestige_panel: ColorRect
var _active: bool = true
var _time: float = 5.0
var _lifetime: float = 0.0
var _tween: Tween

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_button = root.get_node("%AngelaButton")
	_settings_panel = root.get_node("%SettingsPanel")
	_ach_panel = root.get_node("%AchievementsPanel")
	_prestige_panel = root.get_node("%PrestigePanel")
	_button.pressed.connect(_on_pressed)
	_button.z_index = 50

func process(delta: float) -> void:
	if not _active:
		return
	if _settings_panel.visible or _ach_panel.visible or _prestige_panel.visible:
		if _button.visible:
			hide()
		return
	if _button.visible:
		_lifetime -= delta
		if _lifetime <= 0.0:
			hide()
		return
	_time -= delta
	if _time <= 0.0:
		_time = randf_range(18.0, 40.0)
		if _can_spawn():
			_spawn()

func _can_spawn() -> bool:
	if GameState.is_frenzy():
		return false
	if _settings_panel.visible or _ach_panel.visible or _prestige_panel.visible:
		return false
	return true

func hide() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_button.visible = false
	_lifetime = 0.0

func set_active(active: bool) -> void:
	_active = active
	if not active:
		hide()

func _spawn() -> void:
	var vp := _root.get_viewport_rect().size
	var y := vp.y * 0.5 - SZ.y * 0.5
	var start := Vector2(-SZ.x - 40.0, y)
	var end := Vector2(vp.x + 40.0, y)
	_button.position = start
	_button.scale = Vector2(0.9, 0.9)
	_button.modulate.a = 0.0
	_button.visible = true
	_lifetime = FLY_DURATION + 0.6
	if _tween:
		_tween.kill()
	_tween = _root.create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_button, "modulate:a", ALPHA, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_button, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_button, "position:x", end.x, FLY_DURATION).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_method(func(p: float) -> void: _button.position.y = y + sin(p * PI) * BOB, 0.0, 1.0, FLY_DURATION)
	_tween.tween_property(_button, "modulate:a", 0.0, 0.6).set_delay(FLY_DURATION - 0.6).set_trans(Tween.TRANS_SINE)
	_tween.set_parallel(false)
	_tween.tween_callback(hide)

func _on_pressed() -> void:
	var gain := GameState.coins * 0.5
	GameState.add_coins(gain)
	AudioManager.play_ach()
	_fx.spawn_float_at(gain, _button.position + _button.size / 2.0, false, true)
	_fx.show_toast((("Анжела дарит +%s монет!" % GameState.format_num(gain)) if Loc.ru() else ("Angela gifts +%s!" % GameState.format_num(gain))))
	hide()
	_time = randf_range(20.0, 45.0)
