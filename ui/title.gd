extends CanvasLayer
## Title screen overlay shown on first load of the village: logo, tagline, Continue / New game.

var _root: Control


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.03, 0.1, 0.55)
	_root.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -170
	box.offset_bottom = 170
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	_root.add_child(box)
	var title := Label.new()
	title.text = "HOLLOWMERE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.35))
	box.add_child(title)
	var sub := Label.new()
	sub.text = "a cozy valley below Ashenvale Academy  ·  grow, brew, learn, fly"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.9, 0.88, 1.0, 0.9))
	sub.add_theme_constant_override("outline_size", 6)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	box.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	box.add_child(spacer)
	var has_save := FileAccess.file_exists(GameState.SAVE_PATH) and GameState.intro_seen
	var b1 := _button("Continue" if has_save else "Begin", Color(1.0, 0.8, 0.45))
	b1.pressed.connect(_start)
	box.add_child(b1)
	if has_save:
		var b2 := _button("New game", Color(0.6, 0.65, 0.9))
		b2.pressed.connect(_new_game)
		box.add_child(b2)
	var hint := Label.new()
	var ch := 0
	for f in [GameState.gate_open, GameState.chapter2_done, GameState.chapter3_done, GameState.chapter4_done, GameState.chapter5_done, GameState.chapter6_done, GameState.chapter7_done]:
		if f:
			ch += 1
	var order_s: String = (" · " + Story.ORDERS[GameState.order]["name"]) if GameState.order != "" else ""
	hint.text = "Ember %d · %d villagers met · %d Marks (%s)%s · chapters %d/7 · %s" % [GameState.ember, GameState.met.size(), GameState.marks, Story.rank_for(GameState.marks), order_s, ch, Story.season().capitalize()]
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	box.add_child(hint)
	var keys := Label.new()
	keys.text = "WASD / joystick · F act · 1-4 spells · B broom · M map · T time · Esc close"
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keys.add_theme_font_size_override("font_size", 12)
	keys.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	box.add_child(keys)
	if GameState.order != "":
		var crest := Label.new()
		var o: Dictionary = Story.ORDERS[GameState.order]
		crest.text = "✦ %s — %s ✦" % [o["name"], o["motto"]]
		crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		crest.add_theme_font_size_override("font_size", 15)
		crest.add_theme_color_override("font_color", o["color"])
		crest.add_theme_constant_override("outline_size", 6)
		crest.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		box.add_child(crest)


func _button(text: String, c: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 48)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color(0.12, 0.08, 0.18))
	var st := StyleBoxFlat.new()
	st.bg_color = c
	st.set_corner_radius_all(14)
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, st)
	return b


func _start() -> void:
	if not GameState.intro_seen and get_parent().has_node("CameraRig"):
		var intro := CanvasLayer.new()
		intro.set_script(load("res://ui/intro.gd"))
		get_parent().add_child(intro)
		queue_free()
		return
	GameState.ui_locked = false
	var hud := get_parent().get_node_or_null("HUD")
	if hud:
		hud.show_intro_if_needed()
	queue_free()


func _new_game() -> void:
	DirAccess.remove_absolute(GameState.SAVE_PATH)
	GameState.reset()
	GameState.ui_locked = false
	get_tree().reload_current_scene()
