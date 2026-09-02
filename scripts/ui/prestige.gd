class_name UIPrestige
extends RefCounted

var _root: Control
var _souls_label: Label
var _prestige_button: Button
var _prestige_panel: ColorRect
var _prestige_info: Label

func _init(root: Control) -> void:
	_root = root
	_souls_label = root.get_node("%SoulsLabel")
	_prestige_button = root.get_node("%PrestigeButton")
	_prestige_panel = root.get_node("%PrestigePanel")
	_prestige_info = root.get_node("%PrestigeInfo")
	_prestige_button.pressed.connect(_on_pressed)
	root.get_node("%PrestigeConfirmButton").pressed.connect(_on_confirm)
	root.get_node("%PrestigeCancelButton").pressed.connect(_close_panel)
	GameState.souls_changed.connect(update)
	GameState.coins_changed.connect(update)
	GameState.achievements_changed.connect(update)
	GameState.language_changed.connect(_apply_language)
	GameState.loaded.connect(_apply_language)
	YandexSDK.language_loaded.connect(_apply_language)
	_apply_language()

func _apply_language() -> void:
	_root.get_node("%PrestigeTitle").text = "Перерождение" if Loc.ru() else "Rebirth"
	_root.get_node("%PrestigeConfirmButton").text = "Переродиться" if Loc.ru() else "Reborn"
	_root.get_node("%PrestigeCancelButton").text = "Отмена" if Loc.ru() else "Cancel"
	update()

func update() -> void:
	if _souls_label == null:
		return
	var ru := Loc.ru()
	var bonus := GameState.prestige_souls * 10
	var need := GameState.next_prestige_cost()
	var left := GameState.prestiges_left()
	if ru:
		_souls_label.text = "Души бабушек: %d (+%d%%)\nПерерождений: %d/%d\nЦена перерождения: %s" % [GameState.prestige_souls, bonus, left, GameState.MAX_PRESTIGES, GameState.format_num(need)]
	else:
		_souls_label.text = "Granny souls: %d (+%d%%)\nRebirths: %d/%d\nRebirth price: %s" % [GameState.prestige_souls, bonus, left, GameState.MAX_PRESTIGES, GameState.format_num(need)]
	if GameState.is_web():
		_prestige_button.disabled = true
	else:
		_prestige_button.disabled = not GameState.can_prestige()
	_apply_prestige_label()

func _apply_prestige_label() -> void:
	var ru := Loc.ru()
	if GameState.prestiges_left() <= 0:
		_prestige_button.text = "Максимум" if ru else "Maximum"
	elif GameState.can_prestige():
		var gain := GameState.souls_available()
		if ru:
			_prestige_button.text = "Перерождение (+%d душ)" % gain
		else:
			_prestige_button.text = "Rebirth (+%d souls)" % gain
	else:
		_prestige_button.text = "Перерождение" if ru else "Rebirth"

func _on_pressed() -> void:
	if GameState.is_web():
		return
	if not GameState.can_prestige():
		return
	var ru := Loc.ru()
	var gain := GameState.souls_available()
	var need := GameState.next_prestige_cost()
	if ru:
		_prestige_info.text = "Перерождение сбросит монеты и все апгрейды.\n\nВы получите: +%d душ бабушек (+%d%% к доходу навсегда).\nТребуется заработать за жизнь: %s\n\nАчивки станут сложнее, но награды вырастут (цели ×%.0f, награды ×%.0f)." % [gain, gain * 10, GameState.format_num(need), GameState.ACH_TARGET_GROWTH, GameState.ACH_REWARD_GROWTH]
	else:
		_prestige_info.text = "Rebirth will reset coins and all upgrades.\n\nYou will get: +%d granny souls (+%d%% income forever).\nRequires %s earned this life.\n\nAchievements get harder, rewards grow (targets ×%.0f, rewards ×%.0f)." % [gain, gain * 10, GameState.format_num(need), GameState.ACH_TARGET_GROWTH, GameState.ACH_REWARD_GROWTH]
	_prestige_panel.visible = true

func _on_confirm() -> void:
	GameState.do_prestige()
	AudioManager.play_prestige()
	_close_panel()
	update()

func _close_panel() -> void:
	_prestige_panel.visible = false