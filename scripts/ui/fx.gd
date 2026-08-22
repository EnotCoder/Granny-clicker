class_name UIFx
extends RefCounted

const THEME := preload("res://scripts/ui_theme.gd")

var _root: Control
var _meme_button: TextureButton
var _ring: TextureRect
var _toast: Label
var _pulse_tween: Tween
var _toast_tween: Tween
var _shake_tween: Tween
var _flash_overlay: ColorRect
var _blood_tex: Texture2D

func _init(root: Control) -> void:
	_root = root
	_meme_button = root.get_node("%MemeButton")
	_ring = root.get_node("%MemeRing")
	_toast = root.get_node("%Toast")
	_blood_tex = _make_circle_texture(16)
	_meme_button.pressed.connect(_on_meme_pressed)
	_meme_button.mouse_entered.connect(_on_meme_hover_on)
	_meme_button.mouse_exited.connect(_on_meme_hover_off)

func _make_circle_texture(size: int) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := size / 2.0 - 1.0
	for y in range(size):
		for x in range(size):
			var dx := x - size / 2.0
			var dy := y - size / 2.0
			if dx * dx + dy * dy <= r * r:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

# --- Экранная тряска (двигает весь корень) ---
func shake(strength: float, duration: float) -> void:
	if _shake_tween:
		_shake_tween.kill()
	var base := _root.position
	_shake_tween = _root.create_tween()
	_shake_tween.tween_method(func(amp: float) -> void:
		_root.position = base + Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	, strength, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_shake_tween.chain().tween_callback(func() -> void:
		_root.position = base)

# --- Красная вспышка на весь экран ---
func red_flash(intensity: float, duration: float) -> void:
	var ov := _flash_overlay
	if ov == null:
		ov = ColorRect.new()
		ov.color = Color(0.62, 0.02, 0.02, 1.0)
		ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ov.anchor_right = 1.0
		ov.anchor_bottom = 1.0
		ov.z_index = 100
		_root.add_child(ov)
		_flash_overlay = ov
	ov.modulate.a = 0.0
	ov.visible = true
	var tw := _root.create_tween()
	tw.tween_property(ov, "modulate:a", intensity, 0.05)
	tw.tween_property(ov, "modulate:a", 0.0, duration)
	tw.tween_callback(func() -> void: ov.visible = false)

# --- Кровь: брызги из маленьких капель (без спрайтов) ---
func blood_burst(pos: Vector2, count: int = 10) -> void:
	for i in count:
		var sz := randf_range(6.0, 16.0)
		var d := TextureRect.new()
		d.texture = _blood_tex
		d.size = Vector2(sz, sz)
		d.pivot_offset = Vector2(sz, sz) * 0.5
		d.position = pos + Vector2(randf_range(-24, 24), randf_range(-24, 24))
		d.modulate = Color(0.6, 0.05, 0.05, randf_range(0.8, 1.0))
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(d)
		var up := Vector2(randf_range(-70, 70), randf_range(-180, -60))
		var fall := randf_range(60, 150)
		var tw := _root.create_tween()
		tw.tween_property(d, "position", d.position + up, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "position:y", d.position.y + up.y + fall, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(d, "modulate:a", 0.0, 0.3).set_delay(0.25)
		tw.tween_callback(d.queue_free)

# --- Глитч-пульсация мема (резкая деформация/дёрганье) ---
func meme_glitch() -> void:
	if _meme_button == null:
		return
	var base_pos := _meme_button.position
	var base_scale := _meme_button.scale
	_meme_button.pivot_offset = _meme_button.size / 2.0
	var tw := _root.create_tween()
	tw.tween_property(_meme_button, "scale", Vector2(base_scale.x * 1.15, base_scale.y * 0.9), 0.06)
	tw.parallel().tween_property(_meme_button, "position", base_pos + Vector2(-9, 0), 0.06)
	tw.tween_property(_meme_button, "scale", Vector2(base_scale.x * 0.9, base_scale.y * 1.15), 0.07)
	tw.parallel().tween_property(_meme_button, "position", base_pos + Vector2(9, 0), 0.07)
	tw.tween_property(_meme_button, "scale", base_scale, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_meme_button, "position", base_pos, 0.14)

# --- Скример при престиже: мем-бабушка выпрыгивает на весь экран ---
func screamer() -> void:
	if _meme_button == null:
		return
	red_flash(0.5, 0.75)
	shake(22.0, 0.7)
	var orig_pos := _meme_button.position
	var orig_pivot := _meme_button.pivot_offset
	var orig_scale := _meme_button.scale
	var orig_z := _meme_button.z_index
	_meme_button.pivot_offset = _meme_button.size / 2.0
	_meme_button.z_index = 90
	var tw := _root.create_tween()
	tw.tween_property(_meme_button, "scale", orig_scale * 2.4, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_meme_button, "modulate", Color(1.0, 0.85, 0.85, 1.0), 0.08)
	for i in 3:
		tw.tween_interval(0.07)
		tw.tween_property(_meme_button, "position", orig_pos + Vector2(randf_range(-16, 16), randf_range(-12, 12)), 0.03)
	tw.tween_interval(0.45)
	tw.tween_property(_meme_button, "scale", orig_scale, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_meme_button, "modulate", Color.WHITE, 0.25)
	tw.tween_callback(func() -> void:
		_meme_button.position = orig_pos
		_meme_button.pivot_offset = orig_pivot
		_meme_button.z_index = orig_z)
	blood_burst(_meme_button.global_position + _meme_button.size * 0.5, 28)

func frenzy_burst() -> void:
	shake(16.0, 0.5)
	red_flash(0.4, 0.6)
	meme_glitch()
	if _meme_button:
		blood_burst(_meme_button.global_position + _meme_button.size * 0.5, 22)

func show_toast(text: String) -> void:
	if _toast_tween:
		_toast_tween.kill()
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast.visible = true
	_toast_tween = _root.create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)

func pulse_loop(node: Control, min_a: float, dur: float) -> void:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return
	_pulse_tween = _root.create_tween()
	_pulse_tween.tween_property(node, "modulate:a", min_a, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(node, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_callback(func() -> void:
		if is_instance_valid(node) and node.is_inside_tree():
			pulse_loop(node, min_a, dur))

func stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null

func start_meme_bob() -> void:
	if _meme_button == null:
		return
	var tw := _root.create_tween()
	tw.tween_property(_meme_button, "rotation", 0.03, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_meme_button, "rotation", -0.03, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_meme_button, "rotation", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_meme_button) and _meme_button.is_inside_tree():
			start_meme_bob())

func animate_intro(panel: Control) -> void:
	panel.offset_left += 620.0
	panel.offset_right += 620.0
	var tw := _root.create_tween()
	tw.tween_property(panel, "offset_left", panel.offset_left - 620.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(panel, "offset_right", panel.offset_right - 620.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func spawn_float(amount: float, is_crit: bool = false) -> void:
	var vp := _root.get_viewport_rect().size
	spawn_float_at(amount, vp * Vector2(0.31, 0.52) + Vector2(randf_range(-80, 80), randf_range(-20, 20)), is_crit)

func spawn_float_at(amount: float, pos: Vector2, is_crit: bool = false, angela: bool = false) -> void:
	var f := Label.new()
	var frenz := GameState.is_frenzy()
	f.text = "+%s" % GameState.format_num(amount)
	var col := THEME.GOLD
	var sz := 40
	if angela:
		col = Color("#ff5b8a")
		sz = 52
	if is_crit:
		col = Color("#ff5b5b")
		sz = 46
	if frenz and not angela:
		col = Color("#ff8a3d")
		sz = 44
	f.add_theme_color_override("font_color", col)
	f.add_theme_font_size_override("font_size", sz)
	f.add_theme_constant_override("outline_size", 6)
	f.add_theme_color_override("font_outline_color", Color("#3a2400"))
	_root.add_child(f)
	f.position = pos
	f.pivot_offset = Vector2(f.size.x / 2.0, 10.0)
	f.scale = Vector2(0.3, 0.3)
	if angela:
		f.text = "Анжела! " + f.text
	elif is_crit:
		f.text = "КРИТ! " + f.text
	elif frenz:
		f.text = "ДЕДЪ! " + f.text
	var tw := _root.create_tween()
	tw.tween_property(f, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(f, "position:y", f.position.y - 140.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(f, "modulate:a", 0.0, 0.7).set_delay(0.6)
	tw.tween_callback(f.queue_free)

func setup_shadows() -> void:
	pass

func punch(node: Control) -> void:
	if node == null:
		return
	node.pivot_offset = node.size / 2.0
	var base := node.scale
	var tw := _root.create_tween()
	tw.tween_property(node, "scale", base * 1.06, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", base, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_meme_hover_on() -> void:
	if _ring:
		var tw := _root.create_tween()
		tw.tween_property(_ring, "modulate:a", 0.9, 0.14)

func _on_meme_hover_off() -> void:
	if _ring:
		var tw := _root.create_tween()
		tw.tween_property(_ring, "modulate:a", 0.0, 0.2)

func _on_meme_pressed() -> void:
	var val := GameState.do_click()
	AudioManager.play_click()
	spawn_float(val, GameState.last_crit)
	blood_burst(_meme_button.global_position + _meme_button.size * 0.5, 3)
	if GameState.last_crit:
		red_flash(0.16, 0.25)
		shake(7.0, 0.25)
		blood_burst(_meme_button.global_position + _meme_button.size * 0.5, 14)
		meme_glitch()
	if _meme_button:
		var tw := _root.create_tween()
		tw.parallel().tween_property(_meme_button, "scale", Vector2(0.9, 0.9), 0.05)
		tw.parallel().tween_property(_meme_button, "scale", Vector2(1.06, 1.06), 0.09)
		tw.parallel().tween_property(_meme_button, "scale", Vector2.ONE, 0.08)