class_name UIAngela
extends RefCounted

const SZ := Vector2(330, 330)

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

func _clamp_target(target: Vector2) -> Vector2:
	var vp := _root.get_viewport_rect().size
	var max_x := maxf(vp.x - SZ.x, 0.0)
	var max_y := maxf(vp.y - SZ.y, 0.0)
	var panel: Control = _root.get_node("%UpgradePanel")
	if panel != null:
		var right_limit := panel.get_global_rect().position.x - SZ.x - 24.0
		max_x = maxf(0.0, mini(max_x, right_limit))
	return target.clamp(Vector2(24, 24), Vector2(maxf(max_x, 24.0), maxf(max_y, 24.0)))

func _spawn() -> void:
	var vp := _root.get_viewport_rect().size
	var edge := randi() % 4
	var start: Vector2
	var target: Vector2
	var from_center := vp * Vector2(0.5, 0.5) + Vector2(randf_range(-240, 240), randf_range(-120, 120))
	match edge:
		0:
			start = Vector2(from_center.x, -SZ.y + 60)
			target = Vector2(from_center.x, -110)
		1:
			start = Vector2(from_center.x, vp.y + 60)
			target = Vector2(from_center.x, vp.y - SZ.y + 110)
		2:
			start = Vector2(-SZ.x + 60, from_center.y)
			target = Vector2(-110, from_center.y)
		_:
			start = Vector2(vp.x + 60, from_center.y)
			target = Vector2(vp.x - SZ.x + 110, from_center.y)
	target = _clamp_target(target)
	_button.position = start
	_button.scale = Vector2(0.85, 0.85)
	_button.modulate.a = 0.0
	_button.visible = true
	_lifetime = 7.0
	if _tween:
		_tween.kill()
	_tween = _root.create_tween()
	_tween.set_parallel(false)
	_tween.tween_property(_button, "position", target, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_button, "modulate:a", 1.0, 0.35)
	_tween.parallel().tween_property(_button, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(6.2)
	_tween.tween_property(_button, "modulate:a", 0.0, 0.35)
	_tween.tween_callback(hide)

func _on_pressed() -> void:
	var gain := GameState.coins * 0.5
	GameState.add_coins(gain)
	AudioManager.play_ach()
	_fx.spawn_float_at(gain, _button.position + _button.size / 2.0, false, true)
	_fx.show_toast((("Анжела дарит +%s монет!" % GameState.format_num(gain)) if Loc.ru() else ("Angela gifts +%s!" % GameState.format_num(gain))))
	hide()
	_time = randf_range(20.0, 45.0)
