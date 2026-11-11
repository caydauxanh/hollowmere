extends CanvasLayer
## Opening: five slow shots of the valley telling the Quiet Night, then the game begins.
## Tap / F / Space = next shot. "Skip" ends it. Runs once (first Begin on the title screen).

const SHOTS := [
	{"hour": 23.5, "point": Vector3(4, 7, -34), "yaw": 180.0, "pitch": -0.22, "dist": 34.0, "spin": 0.04,
		"text": "Nine years ago, on the longest night of the year,\nevery flame in Ashenvale Academy went out at once."},
	{"hour": 1.0, "point": Vector3(0, 2, 2), "yaw": 35.0, "pitch": -0.38, "dist": 18.0, "spin": -0.05,
		"text": "The lanterns of Hollowmere guttered and went dark.\nThe teachers left. The students were sent home.\nThe valley calls it the Quiet Night."},
	{"hour": 3.0, "point": Vector3(0, 1.8, 0), "yaw": 200.0, "pitch": -0.18, "dist": 7.0, "spin": 0.08,
		"text": "One light did not go out: the candle at the village shrine.\nNo one has ever been able to say why."},
	{"hour": 6.3, "point": Vector3(-4.5, 1.6, -7), "yaw": 150.0, "pitch": -0.3, "dist": 11.0, "spin": -0.06,
		"text": "The apothecary has stood empty ever since.\nThe herb beds went to seed. The cauldron went cold."},
	{"hour": 8.0, "point": Vector3(0, 1.5, 10), "yaw": 0.0, "pitch": -0.3, "dist": 7.5, "spin": 0.05,
		"text": "This morning, for the first time in nine years,\nthe Academy has sent an apprentice down the hill.\n\nGrow. Brew. Help. Bring the light back."},
]

var _i := -1
var _t := 0.0
var _fade: ColorRect
var _text: Label
var _hint: Label
var _rig: Node3D
var _prev_hour := -1.0
var _busy := false
var _done := false


func _ready() -> void:
	layer = 60
	_rig = get_parent().get_node("CameraRig")
	_prev_hour = GameState.forced_hour
	GameState.ui_locked = true
	var hud := get_parent().get_node_or_null("HUD")
	if hud:
		hud.visible = false
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0.02, 0.01, 0.05)
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.72
		bar.anchor_bottom = 0.1 if top else 1.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
	_text = Label.new()
	_text.anchor_left = 0.08
	_text.anchor_right = 0.92
	_text.anchor_top = 0.74
	_text.anchor_bottom = 0.96
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 22)
	_text.add_theme_color_override("font_color", Color(0.97, 0.92, 0.8))
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_hint = Label.new()
	_hint.text = "tap to continue"
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.5
	_hint.anchor_top = 0.955
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -200
	_hint.offset_right = 200
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	var skip := Button.new()
	skip.text = "Skip  ▸"
	skip.focus_mode = Control.FOCUS_NONE
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -120
	skip.offset_right = -16
	skip.offset_top = 14
	skip.offset_bottom = 50
	skip.pressed.connect(finish_intro)
	add_child(skip)
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.01, 0.05, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_next()


func _next() -> void:
	if _busy or _done:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.45)
	await tw.finished
	if _done:
		return
	_i += 1
	if _i >= SHOTS.size():
		finish_intro()
		return
	var s: Dictionary = SHOTS[_i]
	GameState.forced_hour = s["hour"]
	_rig.set_view(s["yaw"], s["pitch"], s["dist"])
	_rig.cine_point = s["point"]
	_rig.cine_spin = s["spin"]
	_text.text = s["text"]
	_t = 0.0
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.7)
	await tw2.finished
	_busy = false


func _process(delta: float) -> void:
	if _done or _busy:
		return
	_t += delta
	if _t > 7.5:
		_next()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var go := false
	if event is InputEventScreenTouch and event.pressed and event.position.y > 60.0:
		go = true
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_F, KEY_SPACE, KEY_ENTER]:
		go = true
	if go:
		get_viewport().set_input_as_handled()
		if _t > 0.6:
			_next()


func finish_intro() -> void:
	if _done:
		return
	_done = true
	GameState.forced_hour = _prev_hour
	GameState.ui_locked = false
	_rig.cine_point = Vector3.INF
	_rig.set_view(0.0, -0.42, 9.5)
	var hud := get_parent().get_node_or_null("HUD")
	if hud:
		hud.visible = true
		hud.show_intro_if_needed()
	queue_free()
