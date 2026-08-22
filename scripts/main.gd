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
	_fx.setup_shadows()
	YandexSDK.data_loaded.connect(GameState.from_save_data)
	GameState.frenzy_started.connect(_fx.frenzy_burst)
	GameState.prestiged.connect(_fx.screamer)
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
