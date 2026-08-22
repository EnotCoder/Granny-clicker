class_name UIRobot
extends RefCounted

var _root: Control
var _fx: UIFx
var _robot: Sprite2D
var _meme_button: TextureButton
var _active: bool = true
var _rest: Vector2
var _strike_dir: Vector2
var _accum: float = 0.0
var _tween: Tween
var _dir_ready: bool = false

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_robot = root.get_node("%RobotSprite")
	_meme_button = root.get_node("%MemeButton")
	_rest = _robot.position
	GameState.upgrades_changed.connect(_update_visibility)
	GameState.loaded.connect(_update_visibility)
	GameState.active_changed.connect(_on_active_changed)
	_update_visibility()

func _ready_dir() -> void:
	if _dir_ready:
		return
	_strike_dir = (_meme_button.global_position + _meme_button.size * 0.5 - _robot.global_position).normalized()
	_dir_ready = true

func _on_active_changed(active: bool) -> void:
	_active = active

func _update_visibility() -> void:
	_robot.visible = GameState.auto_level > 0

func process(delta: float) -> void:
	if not _active:
		return
	var level := GameState.auto_level
	if level <= 0:
		return
	_accum += delta
	var interval := 1.0 / float(level)
	while _accum >= interval:
		_accum -= interval
		_click()

func _click() -> void:
	AudioManager.play_click()
	var gain := GameState.auto_click()
	_fx.spawn_float_at(gain, _meme_button.global_position + _meme_button.size * 0.5)
	_ready_dir()
	_animate()

func _animate() -> void:
	if _tween:
		_tween.kill()
	var strike := _rest + _strike_dir * 60.0
	_tween = _root.create_tween()
	_tween.tween_property(_robot, "position", strike, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_robot, "position", _rest, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)