class_name UIUpgrades
extends RefCounted

var _root: Control
var _fx: UIFx
var _title: Label
var _buttons: Dictionary = {}
var _last_disabled: Dictionary = {}

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_title = root.get_node("%UpgradePanel/Title")
	_buttons = {
		"click": root.get_node("%ClickUpgradeButton"),
		"passive": root.get_node("%PassiveUpgradeButton"),
		"crit": root.get_node("%CritUpgradeButton"),
		"auto": root.get_node("%AutoUpgradeButton"),
		"gold": root.get_node("%GoldUpgradeButton"),
	}
	for id in _buttons:
		_last_disabled[id] = true
		_buttons[id].pressed.connect(_on_pressed.bind(id))
	GameState.coins_changed.connect(update)
	GameState.upgrades_changed.connect(update)
	GameState.language_changed.connect(update)
	GameState.loaded.connect(update)
	YandexSDK.language_loaded.connect(update)
	update()

func _on_pressed(id: String) -> void:
	if GameState.buy_upgrade(id):
		AudioManager.play_buy()

func update() -> void:
	var ru := Loc.ru()
	if _title:
		_title.text = "Апгрейды" if ru else "Upgrades"
	var web_blocked := GameState.is_web()
	for id in _buttons:
		var btn: Button = _buttons[id]
		btn.text = _upgrade_text(id, ru)
		if web_blocked:
			btn.disabled = true
			continue
		var afford := GameState.can_afford(GameState.upgrade_cost(id))
		if btn.disabled == afford and _last_disabled.get(id, true):
			_fx.punch(btn)
		_last_disabled[id] = not afford
		btn.disabled = not afford

func _upgrade_text(id: String, ru: bool) -> String:
	var lv := GameState.upgrade_level(id)
	var cost := GameState.format_num(GameState.upgrade_cost(id))
	if ru:
		match id:
			"click": return "Сила клика\nУр. %d — %s монет" % [lv, cost]
			"passive": return "Пассивный доход (+%d/с)\nУр. %d — %s монет" % [lv + 1, lv, cost]
			"crit": return "Крит (шанс %d%%, x%.1f)\nУр. %d — %s монет" % [int(GameState.crit_chance() * 100), GameState.crit_mult(), lv, cost]
			"auto": return "Авто-кликер (+%d×сила/с)\nУр. %d — %s монет" % [lv + 1, lv, cost]
			"gold": return "Золотая бабушка (+%d%% доход)\nУр. %d — %s монет" % [(lv + 1) * 10, lv, cost]
	else:
		match id:
			"click": return "Click power\nLvl %d — %s coins" % [lv, cost]
			"passive": return "Passive income (+%d/s)\nLvl %d — %s coins" % [lv + 1, lv, cost]
			"crit": return "Crit (%d%% chance, x%.1f)\nLvl %d — %s coins" % [int(GameState.crit_chance() * 100), GameState.crit_mult(), lv, cost]
			"auto": return "Auto-clicker (+%d×power/s)\nLvl %d — %s coins" % [lv + 1, lv, cost]
			"gold": return "Golden grandma (+%d%% income)\nLvl %d — %s coins" % [(lv + 1) * 10, lv, cost]
	return ""