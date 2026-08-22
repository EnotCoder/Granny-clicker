extends Node
## Аудио-менеджер: SFX и фоновая музыка. Пауза при рекламе/сворачивании (п.4.7).

const CLICK := preload("res://assets/audio/click.wav")
const BUY := preload("res://assets/audio/buy.wav")
const ACH := preload("res://assets/audio/ach.wav")
const PRESTIGE := preload("res://assets/audio/prestige.wav")
const MUSIC := preload("res://assets/audio/music.wav")

var _sfx: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _muted: bool = false
var _paused: bool = false

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.stream = MUSIC
	_music.volume_db = -12.0
	add_child(_music)
	_music.play()
	for stream in [CLICK, BUY, ACH, PRESTIGE]:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		add_child(p)
		_sfx.append(p)
	GameState.active_changed.connect(_on_active_changed)
	_apply()

func _on_active_changed(active: bool) -> void:
	_paused = not active
	_apply()

func set_muted(v: bool) -> void:
	_muted = v
	_apply()

func is_muted() -> bool:
	return _muted

func pause() -> void:
	_paused = true
	_apply()

func resume() -> void:
	_paused = false
	_apply()

func play() -> void:
	if not _paused and not _muted:
		if _music and not _music.playing:
			_music.play()
	_apply()

func _apply() -> void:
	if _music:
		_music.stream_paused = _paused or _muted
	for p in _sfx:
		p.stream_paused = _paused

func _play_stream(stream: AudioStream) -> void:
	if _muted or _paused:
		return
	for p in _sfx:
		if p.stream == stream:
			p.play()
			return

func play_click() -> void:
	_play_stream(CLICK)

func play_buy() -> void:
	_play_stream(BUY)

func play_ach() -> void:
	_play_stream(ACH)

func play_prestige() -> void:
	_play_stream(PRESTIGE)
