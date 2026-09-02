class_name AdsController
extends RefCounted

const LAUNCH_AD_COOLDOWN_MS := 180_000   # интерстишал каждые 3 минуты
const LAUNCH_AD_DELAY_S := 2.0           # задержка перед запуск-рекламой, чтобы сплэш успел скрыться

var _root: Control
var _fx: UIFx
var _overlay: ColorRect
var _offline_label: Label
var _last_launch_adv_ms := -INF
var _timer_ms: float = 0.0

func _init(root: Control, fx: UIFx) -> void:
	_root = root
	_fx = fx
	_overlay = root.get_node("%LoadingOverlay")
	_offline_label = root.get_node("%OfflineLabel")
	root.get_node("%AdvButton").pressed.connect(_on_adv_pressed)
	root.get_node("%FullscreenButton").pressed.connect(_on_fullscreen_pressed)
	YandexSDK.sdk_ready.connect(_on_sdk_ready)
	YandexSDK.rewarded_result.connect(_on_rewarded)
	YandexSDK.fullscreen_adv_closed.connect(_on_fullscreen_adv_closed)
	YandexSDK.launch_adv_closed.connect(_on_launch_adv_closed)
	GameState.language_changed.connect(_apply_language)
	GameState.loaded.connect(_apply_language)
	GameState.web_started.connect(_update_adv_button)
	GameState.web_ended.connect(_update_adv_button)
	YandexSDK.language_loaded.connect(_apply_language)
	_apply_language()
	# Показываем экран загрузки сразу, чтобы скрыть момент отрисовки первого кадра.
	_overlay.visible = true

func _apply_language() -> void:
	_root.get_node("%AdvButton").text = "Реклама: x2 монет" if Loc.ru() else "Ad: x2 coins"
	_update_adv_button()

func _update_adv_button() -> void:
	var btn: Button = _root.get_node("%AdvButton")
	if btn:
		btn.disabled = GameState.is_web()

func _on_adv_pressed() -> void:
	if GameState.is_web():
		return
	GameState.set_active(false)
	AudioManager.pause()
	_timer_ms = 0.0 # Сбрасываем таймер при показе любой рекламы
	YandexSDK.show_rewarded_adv()

func _on_fullscreen_pressed() -> void:
	GameState.set_active(false)
	AudioManager.pause()
	YandexSDK.enter_fullscreen()
	_update_fullscreen_button()

func _on_fullscreen_adv_closed() -> void:
	GameState.set_active(true)
	AudioManager.resume()

func _on_rewarded(rewarded: bool) -> void:
	GameState.set_active(true)
	AudioManager.resume()
	if rewarded:
		var bonus: float = maxf(GameState.coins, 10.0)
		GameState.add_coins(bonus)
		_fx.spawn_float(bonus)

func _update_fullscreen_button() -> void:
	var btn: Button = _root.get_node("%FullscreenButton")
	if btn:
		btn.visible = YandexSDK.fullscreen_available

func _on_sdk_ready() -> void:
	if not YandexSDK.is_online:
		if _offline_label:
			_offline_label.visible = true
	_update_fullscreen_button()
	if _should_show_launch_adv():
		# Ждём пару секунд, чтобы сплэш успел скрыться и игра отрисовала
		# первый кадр. Иначе полноэкранная реклама может «застрять» на экране
		# загрузки (синий/чёрный экран вместо игры) на Android.
		_root.get_tree().create_timer(LAUNCH_AD_DELAY_S).timeout.connect(func() -> void:
			_yandex_sdk_show_launch_adv())
		return
	_finish_loading()

func _yandex_sdk_show_launch_adv() -> void:
	# Пока реклама не закрылась, держим экран загрузки видимым.
	var overlay := _root.get_node_or_null("%LoadingOverlay") as ColorRect
	if overlay:
		overlay.visible = true
	YandexSDK.show_launch_adv()

func _should_show_launch_adv() -> bool:
	if not YandexSDK.is_online:
		return false
	if not Engine.has_singleton("AndroidYandexAds"):
		return false
	return Time.get_ticks_msec() - _last_launch_adv_ms >= LAUNCH_AD_COOLDOWN_MS

func _finish_loading() -> void:
	if _overlay:
		_fx.stop_pulse()
		var tw := _root.create_tween()
		tw.tween_property(_overlay, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(_overlay.queue_free)
	YandexSDK.loading_ready()
	YandexSDK.gameplay_start()
	AudioManager.play()

func _on_launch_adv_closed() -> void:
	_last_launch_adv_ms = Time.get_ticks_msec()
	_finish_loading()
	_kick_renderer()

func _kick_renderer() -> void:
	# Принудительно просим движок перерисовать кадр после возврата из
	# полноэкранной Activity рекламы (на некоторых устройствах GL-сцена
	# не перерисовывается сама, и игрок видит «синий экран»).
	RenderingServer.force_draw()
	if _root:
		_root.queue_redraw()

func on_focus_out() -> void:
	GameState.set_active(false)
	AudioManager.pause()
	YandexSDK.save_all()
	YandexSDK.gameplay_stop()

func on_focus_in() -> void:
	GameState.set_active(true)
	AudioManager.resume()
	YandexSDK.gameplay_start()
	_kick_renderer()

func tick(delta: float) -> void:
	if not YandexSDK.is_online:
		return
	
	_timer_ms += delta * 1000.0
	if _timer_ms >= LAUNCH_AD_COOLDOWN_MS:
		_timer_ms = 0.0
		# Вызываем интерстишал (без награды)
		GameState.set_active(false)
		AudioManager.pause()
		YandexSDK.show_fullscreen_adv()
