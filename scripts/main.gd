extends Control

var _fx: UIFx
var _hud: UIHud
var _upgrades: UIUpgrades
var _prestige: UIPrestige
var _achievements: UIAchievements
var _settings: UISettings
var _frenzy: UIFrenzy
var _angela: UIAngela
var _robot: UIRobot
var _ads: AdsController
var _upgrade_panel: Control
var _panel_toggle: Button
var _panel_shown_left: float = NAN
var _panel_shown_right: float = NAN
var _panel_visible: bool = true

const BG_TEXTURES := [
	preload("res://assets/fons/fon_1.png"),
	preload("res://assets/fons/fon_2.png"),
	preload("res://assets/fons/fon_3.png"),
	preload("res://assets/fons/fon_4.png"),
	preload("res://assets/fons/fon_5.png"),
]

func _ready() -> void:
	_fx = UIFx.new(self)
	_hud = UIHud.new(self)
	_upgrades = UIUpgrades.new(self, _fx)
	_prestige = UIPrestige.new(self)
	_achievements = UIAchievements.new(self, _fx)
	_settings = UISettings.new(self, _fx)
	_settings._on_refresh = _refresh_all
	_frenzy = UIFrenzy.new(self, _fx)
	_angela = UIAngela.new(self, _fx)
	_robot = UIRobot.new(self, _fx)
	_frenzy._angela = _angela
	_ads = AdsController.new(self, _fx)
	_upgrade_panel = get_node("%UpgradePanel")
	_panel_toggle = get_node("%PanelToggle")
	_panel_toggle.pressed.connect(_toggle_panel)
	_fx.setup_shadows()
	YandexSDK.data_loaded.connect(GameState.from_save_data)
	GameState.frenzy_started.connect(_fx.frenzy_burst)
	GameState.prestiged.connect(_fx.screamer)
	GameState.loaded.connect(_apply_background)
	GameState.prestiged.connect(_apply_background)
	_apply_background()
	AudioManager.set_muted(not GameState.sound_on)
	_fx.pulse_loop(%Oname, 0.55, 0.7)
	_fx.start_meme_bob()
	_fx.animate_intro(%UpgradePanel)

func _process(delta: float) -> void:
	_frenzy.tick(delta)
	_angela.process(delta)
	_robot.process(delta)
	if _ads:
		_ads.tick(delta)

func _notification(what: int) -> void:
	if not _ads:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_ads.on_focus_out()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_ads.on_focus_in()

func _refresh_all() -> void:
	_hud.update_all()
	_upgrades.update()
	_prestige.update()
	_frenzy.update_button()

func _apply_background() -> void:
	var idx := clampi(GameState.prestige_count, 0, BG_TEXTURES.size() - 1)
	var bg := get_node_or_null("%Background")
	if bg != null:
		bg.texture = BG_TEXTURES[idx]

func _toggle_panel() -> void:
	if _upgrade_panel == null or _panel_toggle == null:
		return
	if is_nan(_panel_shown_left):
		_panel_shown_left = _upgrade_panel.offset_left
		_panel_shown_right = _upgrade_panel.offset_right
	_panel_visible = not _panel_visible
	var width := _panel_shown_right - _panel_shown_left
	var tl := _panel_shown_left if _panel_visible else _panel_shown_right + 40.0
	var tr := _panel_shown_right if _panel_visible else _panel_shown_right + width + 40.0
	var tw := create_tween()
	tw.tween_property(_upgrade_panel, "offset_left", tl, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_upgrade_panel, "offset_right", tr, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_panel_toggle.text = "→" if _panel_visible else "←"
