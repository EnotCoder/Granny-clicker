extends Node
## Глобальное состояние игры: монеты, апгрейды, престиж, ачивки, сейвы.

signal coins_changed(value: float)
signal upgrades_changed()
signal loaded()
signal souls_changed()
signal active_changed(active: bool)
signal achievement_unlocked(id: String)
signal achievements_changed()
signal frenzy_started()
signal frenzy_ended()
signal web_started()
signal web_ended()
signal auto_clicked(amount: float)
signal language_changed()
signal prestiged()

# --- Игровые значения ---
var coins: float = 0.0

# --- Уровни апгрейдов ---
var click_level: int = 0
var passive_level: int = 0
var crit_level: int = 0
var auto_level: int = 0
var gold_level: int = 0

# --- Престиж ---
var prestige_souls: int = 0
var prestige_count: int = 0
var lifetime_coins: float = 0.0
var run_coins: float = 0.0

# --- Счётчики / прогресс ---
var clicks_total: int = 0
var buys_total: int = 0
var last_crit: bool = false

# --- Ачивки / настройки ---
var sound_on: bool = true
var achievements_claimed: Dictionary = {}
# Пусто — auto (из SDK), иначе "ru" / "en"
var language_override: String = ""

# --- Экономика ---
const COST_GROWTH: float = 1.5
const PRESTIGE_SCALE: float = 1_000_000.0
const MAX_PRESTIGES: int = 5

# --- Масштабирование ачивок по перерождениям ---
const ACH_TARGET_GROWTH: float = 2.0 # Цели ачивок ×2 за каждое перерождение
const ACH_REWARD_GROWTH: float = 3.0 # Награды ×3 за каждое перерождение
const ACH_LVL_STEP: float = 5.0      # Уровневые цели: +5 за каждое перерождение

const UPGRADE_IDS := ["click", "passive", "crit", "auto", "gold"]
const UPGRADE_BASE := {
	"click": 15.0,
	"passive": 40.0,
	"crit": 250.0,
	"auto": 800.0,
	"gold": 5000.0,
}

const ACHIEVEMENTS := [
	{"id": "c_100", "kind": "coins", "target": 100.0, "reward": 40.0, "ru": "Заработай 100 монет", "en": "Earn 100 coins"},
	{"id": "c_1000", "kind": "coins", "target": 1000.0, "reward": 180.0, "ru": "Заработай 1000 монет", "en": "Earn 1000 coins"},
	{"id": "c_1m", "kind": "coins", "target": 1000000.0, "reward": 10000.0, "ru": "Заработай 1 млн монет", "en": "Earn 1 million coins"},
	{"id": "first_buy", "kind": "buys", "target": 1.0, "reward": 30.0, "ru": "Купи первый апгрейд", "en": "Buy your first upgrade"},
	{"id": "clicks_100", "kind": "clicks", "target": 100.0, "reward": 60.0, "ru": "Сделай 100 кликов", "en": "Make 100 clicks"},
	{"id": "clicks_1000", "kind": "clicks", "target": 1000.0, "reward": 350.0, "ru": "Сделай 1000 кликов", "en": "Make 1000 clicks"},
	{"id": "click_lvl10", "kind": "clicklvl", "target": 10.0, "reward": 500.0, "ru": "Прокачай силу клика до 10 ур.", "en": "Reach click power level 10"},
	{"id": "passive_lvl5", "kind": "passivelvl", "target": 5.0, "reward": 600.0, "ru": "Прокачай пассивный доход до 5 ур.", "en": "Reach passive income level 5"},
	{"id": "souls_1", "kind": "souls", "target": 1.0, "reward": 500.0, "ru": "Получи первую душу бабушки", "en": "Get your first granny soul"},
	{"id": "all_upgrades", "kind": "allupgrades", "target": 1.0, "reward": 800.0, "ru": "Купи каждый вид апгрейда", "en": "Buy every upgrade type"},
]

# Версия сейва для Яндекс Player API
const SAVE_VERSION: int = 2
const AUTOSAVE_INTERVAL: float = 5.0

# --- Бешеный дедушка (frenzy) ---
const FRENZY_DURATION: float = 8.0
const FRENZY_COOLDOWN: float = 30.0
const FRENZY_MULT: float = 2.5

# --- Паутина (web trap) ---
const WEB_DURATION: float = 15.0
const WEB_COOLDOWN: float = 20.0
const WEB_MULT: float = 2.0

var _time_since_save: float = 0.0
var _last_shown: String = ""
var _active: bool = true
var _notified_achievements: Dictionary = {}
var frenzy_time: float = 0.0
var _frenzy_cd: float = 0.0
var web_time: float = 0.0
var _web_cd: float = 0.0

func is_frenzy() -> bool:
	return frenzy_time > 0.0

func can_start_frenzy() -> bool:
	return not is_frenzy() and _frenzy_cd <= 0.0

func frenzy_cd_left() -> float:
	return maxf(_frenzy_cd, 0.0)

func start_frenzy() -> void:
	if not can_start_frenzy():
		return
	frenzy_time = FRENZY_DURATION
	_frenzy_cd = FRENZY_COOLDOWN
	frenzy_started.emit()
	coins_changed.emit()

# --- Паутина (web trap) ---
func is_web() -> bool:
	return web_time > 0.0

func can_start_web() -> bool:
	return not is_web() and _web_cd <= 0.0

func web_cd_left() -> float:
	return maxf(_web_cd, 0.0)

func start_web() -> void:
	if not can_start_web():
		return
	web_time = WEB_DURATION
	_web_cd = WEB_COOLDOWN
	web_started.emit()
	coins_changed.emit()

func set_active(v: bool) -> void:
	if _active == v:
		return
	_active = v
	active_changed.emit(v)

func _process(delta: float) -> void:
	if _active:
		var passive_ps := float(passive_level) * income_mult()
		if passive_ps > 0.0:
			add_coins(passive_ps * delta, false)
			var shown := format_num(coins)
			if shown != _last_shown:
				_last_shown = shown
				coins_changed.emit()
		if frenzy_time > 0.0:
			frenzy_time = maxf(frenzy_time - delta, 0.0)
			if frenzy_time == 0.0:
				frenzy_ended.emit()
		if _frenzy_cd > 0.0:
			var was_ready := can_start_frenzy()
			_frenzy_cd = maxf(_frenzy_cd - delta, 0.0)
			if not was_ready and can_start_frenzy():
				coins_changed.emit()
		if web_time > 0.0:
			web_time = maxf(web_time - delta, 0.0)
			if web_time == 0.0:
				web_ended.emit()
		if _web_cd > 0.0:
			var was_ready_web := can_start_web()
			_web_cd = maxf(_web_cd - delta, 0.0)
			if not was_ready_web and can_start_web():
				coins_changed.emit()
	_time_since_save += delta
	if _time_since_save >= AUTOSAVE_INTERVAL:
		_time_since_save = 0.0
		YandexSDK.save_all()

# --- Доход ---
func click_power() -> float:
	return 1.0 + float(click_level) * float(click_level + 1) / 2.0

func crit_chance() -> float:
	return minf(0.5, float(crit_level) * 0.02)

func crit_mult() -> float:
	return 2.0 + 0.5 * float(crit_level)

func income_mult() -> float:
	var mult := (1.0 + 0.1 * float(gold_level)) * (1.0 + 0.10 * float(prestige_souls))
	if is_web():
		mult *= WEB_MULT
	return mult

func get_money_per_sec() -> float:
	var base := float(passive_level) + float(auto_level) * click_power()
	return base * income_mult()

# --- Основные операции ---
func add_coins(amount: float, emit: bool = true, count_as_earned: bool = true) -> void:
	if amount <= 0.0:
		return
	coins += amount
	if count_as_earned:
		lifetime_coins += amount
		run_coins += amount
	if emit:
		coins_changed.emit()
	_check_achievements()

func can_afford(cost: float) -> bool:
	return coins >= cost

func spend(cost: float) -> void:
	coins -= cost
	coins_changed.emit()

func do_click() -> float:
	clicks_total += 1
	last_crit = randf() < crit_chance()
	var val := click_power()
	if last_crit:
		val *= crit_mult()
	if is_frenzy():
		val *= FRENZY_MULT
	val *= income_mult()
	add_coins(val, true)
	return val

func auto_click() -> float:
	var gain := click_power() * income_mult()
	add_coins(gain)
	auto_clicked.emit(gain)
	return gain

# --- Апгрейды ---
func upgrade_level(id: String) -> int:
	match id:
		"click": return click_level
		"passive": return passive_level
		"crit": return crit_level
		"auto": return auto_level
		"gold": return gold_level
	return 0

func _set_level(id: String, lv: int) -> void:
	match id:
		"click": click_level = lv
		"passive": passive_level = lv
		"crit": crit_level = lv
		"auto": auto_level = lv
		"gold": gold_level = lv

func upgrade_cost(id: String) -> float:
	var base: float = UPGRADE_BASE.get(id, 10.0)
	return base * pow(COST_GROWTH, upgrade_level(id))

func buy_upgrade(id: String) -> bool:
	if is_web():
		return false
	var cost := upgrade_cost(id)
	if not can_afford(cost):
		return false
	spend(cost)
	_set_level(id, upgrade_level(id) + 1)
	buys_total += 1
	upgrades_changed.emit()
	_check_achievements()
	YandexSDK.save_all()
	return true

# --- Престиж ---
## Душ, доступных к получению за текущую жизнь (растёт сложность каждой следующей).
func souls_available() -> int:
	return maxi(int(sqrt(run_coins / PRESTIGE_SCALE)) - prestige_souls, 0)

## Возможность переродиться: нужно заработать за текущую жизнь больше, чем уже накоплено душ.
func can_prestige() -> bool:
	return souls_available() > 0 and prestige_count < MAX_PRESTIGES

func prestiges_left() -> int:
	return maxi(MAX_PRESTIGES - prestige_count, 0)

## Цена перерождения: сколько монет нужно заработать за эту жизнь.
func next_prestige_cost() -> float:
	return float(prestige_souls + 1) * float(prestige_souls + 1) * PRESTIGE_SCALE

func do_prestige() -> void:
	var gain := souls_available()
	if gain <= 0:
		return
	if prestige_count >= MAX_PRESTIGES:
		return
	prestige_souls += gain
	prestige_count += 1
	coins = 0.0
	run_coins = 0.0
	click_level = 0
	passive_level = 0
	crit_level = 0
	auto_level = 0
	gold_level = 0
	clicks_total = 0
	buys_total = 0
	coins_changed.emit()
	upgrades_changed.emit()
	souls_changed.emit()
	achievements_changed.emit()
	_check_achievements()
	prestiged.emit()
	YandexSDK.save_all()

# --- Ачивки ---
func ach_progress(id: String) -> float:
	for a in ACHIEVEMENTS:
		if a.id != id:
			continue
		return _kind_value(a.kind)
	return 0.0

func ach_target(id: String) -> float:
	for a in ACHIEVEMENTS:
		if a.id == id:
			var base: float = a.target
			# Уровневые цели растут аддитивно, остальные — мультипликативно
			match a.kind:
				"clicklvl", "passivelvl", "allupgrades":
					return base + ACH_LVL_STEP * float(prestige_count)
				_:
					return base * pow(ACH_TARGET_GROWTH, prestige_count)
	return 0.0

func ach_reward(id: String) -> float:
	for a in ACHIEVEMENTS:
		if a.id == id:
			return a.reward * pow(ACH_REWARD_GROWTH, prestige_count)
	return 0.0

func ach_localized(id: String) -> String:
	for a in ACHIEVEMENTS:
		if a.id == id:
			return a.ru if effective_language().begins_with("ru") else a.en
	return ""

func _kind_value(kind: String) -> float:
	match kind:
		"coins": return coins
		"clicks": return clicks_total
		"buys": return buys_total
		"clicklvl": return click_level
		"passivelvl": return passive_level
		"souls": return prestige_souls
		"allupgrades":
			var m := INF
			for id in UPGRADE_IDS:
				m = minf(m, float(upgrade_level(id)))
			return m if m != INF else 0.0
	return 0.0

func is_achieved(id: String) -> bool:
	return ach_progress(id) >= ach_target(id)

func is_claimed(id: String) -> bool:
	return achievements_claimed.get(id, false)

func _check_achievements() -> void:
	for a in ACHIEVEMENTS:
		var id: String = a.id
		if is_achieved(id) and not _notified_achievements.has(id):
			_notified_achievements[id] = true
			achievement_unlocked.emit(id)

func claim_achievement(id: String) -> bool:
	if not is_achieved(id) or is_claimed(id):
		return false
	achievements_claimed[id] = true
	add_coins(ach_reward(id), true, false)
	achievements_changed.emit()
	YandexSDK.save_all()
	return true

func unclaimed_count() -> int:
	var n := 0
	for a in ACHIEVEMENTS:
		if is_achieved(a.id) and not is_claimed(a.id):
			n += 1
	return n

# --- Звук ---
func set_sound(v: bool) -> void:
	sound_on = v
	YandexSDK.save_all()

# --- Язык ---
func effective_language() -> String:
	if language_override != "":
		return language_override
	return YandexSDK.language

func set_language(code: String) -> void:
	if code != "ru" and code != "en":
		code = ""
	if language_override == code:
		return
	language_override = code
	language_changed.emit()
	YandexSDK.save_all()

# --- Сохранение (набор данных для Yandex) ---
func to_save_data() -> Dictionary:
	return {
		"v": SAVE_VERSION,
		"coins": coins,
		"click_level": click_level,
		"passive_level": passive_level,
		"crit_level": crit_level,
		"auto_level": auto_level,
		"gold_level": gold_level,
	"prestige_souls": prestige_souls,
	"prestige_count": prestige_count,
	"lifetime_coins": lifetime_coins,
		"run_coins": run_coins,
		"clicks_total": clicks_total,
		"buys_total": buys_total,
		"sound_on": sound_on,
		"achievements_claimed": achievements_claimed,
		"language_override": language_override,
	}

func from_save_data(data: Dictionary) -> void:
	coins = float(data.get("coins", 0.0))
	click_level = int(data.get("click_level", 0))
	passive_level = int(data.get("passive_level", 0))
	crit_level = int(data.get("crit_level", 0))
	auto_level = int(data.get("auto_level", 0))
	gold_level = int(data.get("gold_level", 0))
	prestige_souls = int(data.get("prestige_souls", 0))
	prestige_count = int(data.get("prestige_count", 0))
	if prestige_count == 0 and prestige_souls > 0:
		prestige_count = mini(prestige_souls, MAX_PRESTIGES)
	lifetime_coins = float(data.get("lifetime_coins", 0.0))
	run_coins = float(data.get("run_coins", 0.0))
	clicks_total = int(data.get("clicks_total", 0))
	buys_total = int(data.get("buys_total", 0))
	sound_on = bool(data.get("sound_on", true))
	language_override = str(data.get("language_override", ""))
	var ach: Variant = data.get("achievements_claimed", {})
	achievements_claimed = ach if ach is Dictionary else {}
	coins_changed.emit()
	upgrades_changed.emit()
	souls_changed.emit()
	achievements_changed.emit()
	language_changed.emit()
	loaded.emit()

func reset() -> void:
	coins = 0.0
	click_level = 0
	passive_level = 0
	crit_level = 0
	auto_level = 0
	gold_level = 0
	prestige_souls = 0
	prestige_count = 0
	lifetime_coins = 0.0
	run_coins = 0.0
	clicks_total = 0
	buys_total = 0
	achievements_claimed = {}
	_notified_achievements = {}
	emit_signal("coins_changed")
	emit_signal("upgrades_changed")
	emit_signal("souls_changed")
	emit_signal("achievements_changed")
	YandexSDK.clear_save()
	YandexSDK.save_all()

# --- Форматирование чисел ---
func format_num(n: float) -> String:
	if n < 1000.0:
		return str(int(round(n)))
	var suffixes := ["K", "M", "B", "T", "Qa", "Qi"]
	var val: float = float(n)
	var idx: int = -1
	while val >= 1000.0 and idx < suffixes.size() - 1:
		val /= 1000.0
		idx += 1
	if idx < 0:
		return str(int(round(n)))
	return "%.2f%s" % [val, suffixes[idx]]
