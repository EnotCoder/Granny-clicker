extends Node
## Обёртка над Яндекс Игры SDK (window.__yandex, задаётся в html/head_include).
## На рабочем столе без браузера работает фолбэк через файл (user://).
## На Android реклама идёт через плагин AndroidYandexAds (addons/yandex_mobile_ads).

signal sdk_ready
signal data_loaded(data: Dictionary)
signal fullscreen_adv_closed
signal launch_adv_closed
signal rewarded_result(rewarded: bool)
signal fullscreen_checked
signal language_loaded(lang: String)

# Block ID из кабинета Yandex Mobile Ads.
const REWARDED_BLOCK_ID := "R-M-19778276-1"
const INTERSTITIAL_BLOCK_ID := "R-M-19778276-2"

const _fallback_file := "user://meme_click_save.json"

var _sdk: Variant = null   # прокси объект window.__yandex (JavaScriptObject) или null
var _is_sdk: bool = false
var _cb_refs: Array = []   # держим JS-коботы живыми, пока SDK их не вызовет
var _android: Variant = null   # синглтон плагина AndroidYandexAds или null
var _launch_pending: bool = false   # ждём закрытия запуск-интерстишала
var _launch_waiting: bool = false   # ждём готовности интерстишала перед показом
const _LAUNCH_AD_MAX_WAIT_S := 6.0
var is_online: bool = false
var fullscreen_available: bool = false
var language: String = "ru"   # язык интерфейса из SDK (i18n)

func _ready() -> void:
	# Откладываем старт, чтобы main._ready успел подключить сигналы.
	call_deferred("_delayed_init")

func _delayed_init() -> void:
	if Engine.has_singleton("AndroidYandexAds"):
		_android = Engine.get_singleton("AndroidYandexAds")
		is_online = true
		_android.init(REWARDED_BLOCK_ID, INTERSTITIAL_BLOCK_ID)
		_android.rewarded_result.connect(_on_android_rewarded)
		_android.rewarded_failed.connect(_on_android_rewarded_failed)
		_android.interstitial_closed.connect(_on_android_interstitial_closed)
		_android.interstitial_failed.connect(_on_android_interstitial_failed)
		_android.interstitial_ready.connect(_on_android_interstitial_ready)
		fullscreen_available = false
		_load_fallback()
		_request_language()
		sdk_ready.emit()
	elif Engine.has_singleton("JavaScriptBridge"):
		_sdk = JavaScriptBridge.get_interface("__yandex")
		if _sdk == null:
			# Headless / нет JS-обёртки — локальный режим
			_is_sdk = false
			_load_fallback()
			sdk_ready.emit()
			return
		_is_sdk = true
		is_online = true
		var cb := JavaScriptBridge.create_callback(_on_init_result)
		_cb_refs.append(cb)
		_sdk.init(cb)
	else:
		# Desktop-запуск в редакторе
		_is_sdk = false
		_load_fallback()
		sdk_ready.emit()

# JS вызывает колбэк с массивом аргументов: args = [ok:bool]
func _on_init_result(args: Array) -> void:
	var ok := bool(args.size() > 0 and args[0])
	if not ok:
		_load_fallback()
		sdk_ready.emit()
		return
	_check_fullscreen()
	_request_language()
	var cb := JavaScriptBridge.create_callback(_on_data_result)
	_cb_refs.append(cb)
	_sdk.getData(cb)

# args = [save_json:String | null]
func _on_data_result(args: Array) -> void:
	var saved: Variant = args[0] if args.size() > 0 else null
	if saved is String and saved != "":
		var json := JSON.new()
		if json.parse(saved) == OK and json.data is Dictionary:
			data_loaded.emit(json.data)
	else:
		_load_fallback()
	sdk_ready.emit()

# --- Сохранение ---
func save_all() -> void:
	if _is_sdk and _sdk != null:
		_sdk.setData(JSON.stringify(GameState.to_save_data()))
	else:
		_save_fallback()

func _save_fallback() -> void:
	var f := FileAccess.open(_fallback_file, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(GameState.to_save_data()))
		f.close()

func _load_fallback() -> void:
	if not FileAccess.file_exists(_fallback_file):
		data_loaded.emit({})
		return
	var f := FileAccess.open(_fallback_file, FileAccess.READ)
	if f:
		var json := JSON.new()
		if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
			data_loaded.emit(json.data)
			return
		f.close()
	data_loaded.emit({})

func clear_save() -> void:
	if _is_sdk and _sdk != null:
		_sdk.clearData()
	else:
		if FileAccess.file_exists(_fallback_file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_fallback_file))

# --- Реклама ---
func _check_fullscreen() -> void:
	if _android != null:
		fullscreen_available = false
		fullscreen_checked.emit()
		return
	if _is_sdk and _sdk != null:
		var cb := JavaScriptBridge.create_callback(_on_fullscreen_avail)
		_cb_refs.append(cb)
		_sdk.fullscreenAvailable(cb)
	else:
		fullscreen_available = false

func _on_fullscreen_avail(args: Array) -> void:
	fullscreen_available = bool(args[0]) if args.size() > 0 and args[0] != null else false
	fullscreen_checked.emit()

# --- Язык интерфейса (п.2.14) ---
func _request_language() -> void:
	if _is_sdk and _sdk != null:
		var cb := JavaScriptBridge.create_callback(_on_language_result)
		_cb_refs.append(cb)
		_sdk.getLanguage(cb)
	else:
		language = "ru"
		language_loaded.emit(language)

func _on_language_result(args: Array) -> void:
	language = String(args[0]) if args.size() > 0 and args[0] != null else "ru"
	language_loaded.emit(language)

func show_fullscreen_adv() -> void:
	print("рекламмааа")
	if _android != null:
		gameplay_stop()
		_android.showInterstitial()
	elif _is_sdk and _sdk != null:
		var cb := JavaScriptBridge.create_callback(_on_fullscreen_closed)
		_cb_refs.append(cb)
		_sdk.showFullscreen(cb)
	else:
		print("рекламмааа (имитация десктоп)")
		fullscreen_adv_closed.emit()

func request_fullscreen() -> void:
	if _is_sdk and _sdk != null:
		_sdk.requestFullscreen()

func enter_fullscreen() -> void:
	# Показать полноэкранную рекламу, затем войти в полноэкранный режим.
	gameplay_stop()
	show_fullscreen_adv()

# При запуске игры (только Android): интерстишал до активации геймплея.
func show_launch_adv() -> void:
	print("рекламмааа")
	if _android != null:
		gameplay_stop()
		if _android.isInterstitialReady():
			print("[YandexSDK] launch interstitial: ready, showing")
			_launch_pending = true
			_android.showInterstitial()
		else:
			# Реклама ещё грузится — ждём сигнал готовности (с таймаутом).
			print("[YandexSDK] launch interstitial: not ready, waiting (max ", _LAUNCH_AD_MAX_WAIT_S, "s)")
			_launch_pending = true
			_launch_waiting = true
			get_tree().create_timer(_LAUNCH_AD_MAX_WAIT_S).timeout.connect(_on_launch_adv_timeout)
	else:
		print("рекламмааа (имитация десктоп)")
		launch_adv_closed.emit()

func _on_android_interstitial_ready() -> void:
	print("[YandexSDK] interstitial_ready")
	if _launch_waiting:
		_launch_waiting = false
		_android.showInterstitial()

func _on_launch_adv_timeout() -> void:
	print("[YandexSDK] launch interstitial: timeout, starting without ad")
	if _launch_waiting:
		_launch_waiting = false
		_launch_pending = false
		launch_adv_closed.emit()

func show_rewarded_adv() -> void:
	print("рекламмааа")
	if _android != null:
		gameplay_stop()
		_android.showRewarded()
	elif _is_sdk and _sdk != null:
		gameplay_stop()
		var cb := JavaScriptBridge.create_callback(_on_reward_result)
		_cb_refs.append(cb)
		_sdk.showRewarded(cb)
	else:
		print("рекламмааа (имитация десктоп)")
		rewarded_result.emit(false)

# --- Колбэки Android-плагина (Yandex Mobile Ads) ---
func _on_android_rewarded(rewarded: bool) -> void:
	print("[YandexSDK] android rewarded result: ", rewarded)
	_android.loadRewarded() # Принудительная перезагрузка, т.к. плагин сам этого не делает
	gameplay_start()
	rewarded_result.emit(rewarded)

func _on_android_rewarded_failed(_error: String) -> void:
	print("[YandexSDK] rewarded_failed: ", _error)
	_android.loadRewarded() # Пытаемся загрузить снова после ошибки
	gameplay_start()
	rewarded_result.emit(false)

func _on_android_interstitial_closed() -> void:
	if _launch_pending:
		_launch_pending = false
		launch_adv_closed.emit()
		return
	gameplay_start()
	fullscreen_adv_closed.emit()

func _on_android_interstitial_failed(_error: String) -> void:
	print("[YandexSDK] interstitial_failed: ", _error)
	if _launch_pending:
		_launch_pending = false
		launch_adv_closed.emit()
		return
	gameplay_start()
	fullscreen_adv_closed.emit()

# args = [] (колбек без аргументов)
func _on_fullscreen_closed(_args: Array) -> void:
	request_fullscreen()
	gameplay_start()
	fullscreen_adv_closed.emit()

# args = [rewarded:bool]
func _on_reward_result(args: Array) -> void:
	var rewarded := bool(args[0]) if args.size() > 0 else false
	if _is_sdk:
		gameplay_start()
	rewarded_result.emit(rewarded)

# --- Статусы ---
func loading_ready() -> void:
	if _is_sdk and _sdk != null:
		_sdk.loadingReady()

func gameplay_start() -> void:
	if _is_sdk and _sdk != null:
		_sdk.gameplayStart()
	elif _android != null:
		# Для Android эмулируем старт геймплея, чтобы AdsController.tick работал
		pass

func gameplay_stop() -> void:
	if _is_sdk and _sdk != null:
		_sdk.gameplayStop()
	elif _android != null:
		# Для Android эмулируем стоп геймплея
		pass
