extends CanvasLayer
## HUD: clock, bag, interaction prompt, toasts, and on-screen controls
## (virtual joystick + buttons) so the game plays with mouse or touch, no keyboard needed.

const INTERACT_RANGE := 2.6

var player: Node3D
var _clock: Label
var _bag: Label
var _hint: Label
var _last_lesson := "__init"
var _tap_target: Node3D = null
var _tap_marker: MeshInstance3D
var _prompt: Label
var _toast: Label
var _help: Label
var _toast_time := 0.0
var _target: Node3D

# --- virtual joystick
var _stick_base: Control
var _stick_knob: Control
var _stick_touch := -1
var _stick_vec := Vector2.ZERO
var _stick_origin := Vector2.ZERO
const STICK_RADIUS := 60.0

# --- camera drag (right side of screen)
var _cam_touch := -1
var _cam_last := Vector2.ZERO

var _buttons := {}
# --- dialogue
var _dlg_panel: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _dlg_hint: Label
var _dlg_choices: VBoxContainer
var _dlg_pages := []
var _dlg_page := 0
var _dlg_source: Node = null
var _dlg_data := {}
var _dlg_open := false
var _journal: PanelContainer
var _journal_text: Label
var _ember_label: Label
var _spell_buttons := {}
var _dlg_portrait: TextureRect
var _cards: PanelContainer
var _dbg: Label
var _last_key := "-"
var _last_mouse := "-"
var _press_pos := Vector2.ZERO


func _ready() -> void:
	add_to_group("hud")
	# iPhone notch / rounded corners: keep controls a little in from the edges
	if DisplayServer.is_touchscreen_available():
		var sa := DisplayServer.get_display_safe_area()
		var win := DisplayServer.window_get_size()
		var inset := maxi(sa.position.x, win.x - sa.end.x)
		if inset > 0:
			_safe_inset = float(inset)
	player = get_parent().get_node("Player")
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.add_theme_stylebox_override("panel", _box(Color(0.12, 0.09, 0.2, 0.72)))
	add_child(panel)
	var col := VBoxContainer.new()
	panel.add_child(col)
	_clock = _label(16, Color(1.0, 0.92, 0.75))
	col.add_child(_clock)
	_bag = _label(13, Color(0.92, 0.9, 1.0, 0.85))
	col.add_child(_bag)
	_hint = _label(13, Color(1.0, 0.85, 0.5, 0.95))
	col.add_child(_hint)

	_prompt = _label(24, Color.WHITE)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_top = -190
	_prompt.offset_bottom = -150
	_prompt.offset_left = -500
	_prompt.offset_right = 500
	_prompt.add_theme_constant_override("outline_size", 8)
	_prompt.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	add_child(_prompt)

	_toast = _label(22, Color(1.0, 0.9, 0.55))
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 40
	_toast.offset_left = -500
	_toast.offset_right = 500
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	add_child(_toast)

	_help = _label(15, Color(1, 1, 1, 0.75))
	_help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help.offset_top = -34
	_help.offset_left = -500
	_help.offset_right = 500
	_help.text = "WASD / joystick to move  ·  drag right side to look  ·  F harvest / brew  ·  Shift run  ·  Space jump  ·  T fast-forward time"
	_help.add_theme_constant_override("outline_size", 6)
	_help.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_help.visible = false
	add_child(_help)

	_build_vignette()
	_build_title_card()
	_build_controls()
	_build_dialogue()
	_build_journal()
	_build_spell_buttons()
	_build_cards()
	_build_clock_button()
	_build_map()
	GameState.spells_changed.connect(_refresh_spell_buttons)
	GameState.ember_changed.connect(_refresh_bag)
	call_deferred("show_intro_if_needed")
	_dbg = _label(12, Color(1, 1, 1, 0.7))
	_dbg.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_dbg.offset_left = -230
	_dbg.offset_top = -22
	_dbg.add_theme_constant_override("outline_size", 4)
	_dbg.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	add_child(_dbg)

	GameState.inventory_changed.connect(_refresh_bag)
	GameState.toast.connect(_show_toast)
	_refresh_bag()


func _build_controls() -> void:
	_stick_base = _circle(Color(1, 1, 1, 0.08), STICK_RADIUS * 2.0)
	_stick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stick_base.position = Vector2(50 + _safe_inset, -STICK_RADIUS * 2.0 - 60)
	add_child(_stick_base)
	_stick_knob = _circle(Color(1, 0.9, 0.7, 0.4), 52.0)
	_stick_knob.position = Vector2(STICK_RADIUS - 26, STICK_RADIUS - 26)
	_stick_base.add_child(_stick_knob)

	var specs := [["interact", "ACT", Color(0.95, 0.7, 0.35, 0.85), Vector2(-100, -150)],
		["jump", "UP", Color(0.6, 0.7, 1.0, 0.75), Vector2(-180, -90)],
		["run", "DOWN", Color(0.7, 0.95, 0.7, 0.75), Vector2(-100, -60)]]
	for sp in specs:
		var b := Button.new()
		b.text = sp[1]
		b.custom_minimum_size = Vector2(72, 72) if sp[0] != "interact" else Vector2(84, 84)
		b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		b.position = sp[3] - b.custom_minimum_size - Vector2(_safe_inset, 0)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Color(0.1, 0.07, 0.15))
		var st := StyleBoxFlat.new()
		st.bg_color = sp[2]
		st.set_corner_radius_all(42)
		for k in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(k, st)
		b.button_down.connect(_on_btn.bind(sp[0], true))
		b.button_up.connect(_on_btn.bind(sp[0], false))
		add_child(b)
		_buttons[sp[0]] = b
		b.visible = sp[0] == "interact"


func _on_btn(action: String, down: bool) -> void:
	if down:
		Input.action_press(action)
	else:
		Input.action_release(action)


## The Academy letter, once, after the title screen is gone.
func show_intro_if_needed() -> void:
	if GameState.ui_locked or GameState.intro_seen:
		return
	GameState.intro_seen = true
	GameState.mark_dirty()
	open_dialogue(null, {"pages": Story.INTRO})


func _input(event: InputEvent) -> void:
	if GameState.ui_locked:
		return
	if event is InputEventKey:
		_last_key = ("DOWN " if event.pressed else "UP ") + OS.get_keycode_string(event.physical_keycode)
	if event is InputEventMouseButton:
		_last_mouse = ("click " if event.pressed else "release ") + str(event.position.round())
	if event is InputEventScreenTouch and event.pressed:
		_press_pos = event.position
	if event is InputEventScreenTouch and not event.pressed and event.index == _cam_touch and _press_pos.distance_to(event.position) < 12.0:
		if _dlg_open:
			if _dlg_choices.get_child_count() == 0:
				advance_dialogue()
		elif not _journal.visible:
			_click_to_move(event.position)
	# Touch and mouse both come in as screen touch / drag thanks to emulate_touch_from_mouse.
	if event is InputEventScreenTouch:
		var vp := get_viewport().get_visible_rect().size
		if event.pressed:
			if _dlg_open and _dlg_choices.get_child_count() == 0 and event.position.y > vp.y * 0.55:
				advance_dialogue()
				get_viewport().set_input_as_handled()
				return
			if _stick_touch == -1 and not _dlg_open and event.position.x < vp.x * 0.45 and event.position.y > vp.y * 0.35:
				_stick_touch = event.index
				_stick_origin = event.position
				_stick_base.position = event.position - Vector2(STICK_RADIUS, STICK_RADIUS)
				_stick_base.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
				_update_stick(event.position)
				get_viewport().set_input_as_handled()
			elif _cam_touch == -1 and event.position.x >= vp.x * 0.45:
				_cam_touch = event.index
				_cam_last = event.position
		else:
			if event.index == _stick_touch:
				_stick_touch = -1
				_update_stick(_stick_origin)
			if event.index == _cam_touch:
				_cam_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == _stick_touch:
			_update_stick(event.position)
			get_viewport().set_input_as_handled()
		elif event.index == _cam_touch and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			var rig := get_parent().get_node("CameraRig")
			var d: Vector2 = event.position - _cam_last
			_cam_last = event.position
			rig.yaw -= d.x * 0.006
			rig.pitch = clampf(rig.pitch - d.y * 0.004, rig.min_pitch, rig.max_pitch)


func _click_to_move(screen: Vector2) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(screen)
	var dirv := cam.project_ray_normal(screen)
	if absf(dirv.y) < 0.001:
		return
	var t := -from.y / dirv.y
	if t < 0.0:
		return
	var hit := from + dirv * t
	player.move_target = Vector3(hit.x, 0.0, hit.z)
	# Tap on an interactable: walk to it and act when close
	var best: Node3D = null
	var bd := 2.2
	for n in get_tree().get_nodes_in_group("interactable"):
		var d := (n as Node3D).global_position.distance_to(Vector3(hit.x, (n as Node3D).global_position.y, hit.z))
		if d < bd:
			bd = d
			best = n
	_tap_target = best
	_show_tap_marker(player.move_target)
	_last_mouse = "walk to " + str(Vector2(hit.x, hit.z).round())


func _update_stick(pos: Vector2) -> void:
	var v := (pos - _stick_origin)
	if v.length() > STICK_RADIUS:
		v = v.normalized() * STICK_RADIUS
	_stick_knob.position = Vector2(STICK_RADIUS - 26, STICK_RADIUS - 26) + v
	_stick_vec = v / STICK_RADIUS
	if _stick_vec.length() < 0.15:
		_stick_vec = Vector2.ZERO
	player.stick_mag = _stick_vec.length() if (_stick_touch != -1 and _stick_vec != Vector2.ZERO) else -1.0
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("up")
	Input.action_release("down")
	if _stick_vec.x < 0: Input.action_press("left", -_stick_vec.x)
	if _stick_vec.x > 0: Input.action_press("right", _stick_vec.x)
	if _stick_vec.y < 0: Input.action_press("up", -_stick_vec.y)
	if _stick_vec.y > 0: Input.action_press("down", _stick_vec.y)


func _process(delta: float) -> void:
	var h := GameState.hour_of_day()
	var hh := int(h)
	var mm := int((h - hh) * 60.0)
	var part := "Night"
	if h >= 5.5 and h < 11.0: part = "Morning"
	elif h >= 11.0 and h < 14.0: part = "Midday"
	elif h >= 14.0 and h < 17.5: part = "Afternoon"
	elif h >= 17.5 and h < 19.5: part = "Dusk"
	var fast := "   >> fast" if GameState.time_scale > 1.0 else ""
	var badge := ""
	if GameState.order != "":
		badge = "  ·  %s" % Story.ORDERS[GameState.order]["name"]
	_clock.text = "%02d:%02d  ·  %s%s%s" % [hh, mm, part, fast, badge]
	_update_title_card(delta)
	if _dlg_open and _dlg_text.visible_characters >= 0 and _dlg_text.visible_characters < _dlg_text.get_total_character_count():
		_type_t += delta * 90.0
		_dlg_text.visible_characters = int(_type_t)
	if Engine.get_process_frames() % 20 == 0:
		_fade_tags()
	if Engine.get_process_frames() % 180 == 0:
		GameState.check_honours()
	if Engine.get_process_frames() % 90 == 45:
		_tutorial_tick()
	if Engine.get_process_frames() % 30 == 0:
		_refresh_bag()
		_hint.text = "▸ " + _objective()
		var lid := Story.lesson_now()
		if lid != _last_lesson:
			if _last_lesson != "__init" and lid != "" and GameState.gate_open:
				Sound.bell()
				var L: Dictionary = Story.LESSONS[lid]
				GameState.say("The Academy bell: %s with %s, %s." % [L["name"], Story.NPCS[L["teacher"]]["name"], L["room"]])
			_last_lesson = lid
		var ev := Story.todays_event()
		if ev.get("id", "") == "lantern" and h >= 19.0 and h < 21.0 and GameState.lantern_walk_day != Story.today_key() and player.global_position.distance_to(Vector3(2, 0, 28)) < 14.0:
			GameState.lantern_walk_day = Story.today_key()
			GameState.add_ember(3)
			GameState.mark_dirty()
			GameState.say("Lantern Walk: the whole village is on the green with lanterns.  +3 Ember")

	_target = _nearest_interactable()
	if _tap_target and is_instance_valid(_tap_target) and not _dlg_open:
		if _tap_target.global_position.distance_to(player.global_position) < INTERACT_RANGE:
			var tt := _tap_target
			_tap_target = null
			player.move_target = Vector3.INF
			_interact_with(tt)
	elif _tap_target and not is_instance_valid(_tap_target):
		_tap_target = null
	if _tap_marker and player.move_target == Vector3.INF:
		_tap_marker.visible = false
	_prompt.text = _target.get_prompt() if _target and not _dlg_open else ""
	_buttons["interact"].visible = _target != null and not _dlg_open and not player.flying
	_buttons["jump"].visible = player.flying
	_buttons["run"].visible = player.flying
	if _broom_btn:
		_broom_btn.visible = GameState.broom and not _dlg_open
		_broom_btn.text = "B  Land" if player.flying else "B  Broom"

	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)
		if _toast_time <= 0.0 and not _toast_queue.is_empty():
			var nxt: String = _toast_queue.pop_front()
			_toast.text = nxt
			_toast_time = 3.0 + minf(nxt.length() / 40.0, 3.0)
			_toast.modulate.a = 1.0
	_web_bridge(delta)
	_dbg.text = "build 20261111-1620  ·  Hollowmere"
	_update_compass()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_locked:
		return
	if event.is_action_pressed("interact"):
		if _dlg_open:
			advance_dialogue()
			return
		if _target:
			_interact_with(_target)
	if event.is_action_pressed("ui_cancel"):
		_journal.visible = false
		_cards.visible = false
		if _map:
			_map.visible = false
	if event.is_action_pressed("spell1"):
		cast_spell("kindle")
	if event.is_action_pressed("spell2"):
		cast_spell("verdant")
	if event.is_action_pressed("spell3"):
		cast_spell("glimmer")
	if event.is_action_pressed("spell4"):
		cast_spell("mend")
	if event.is_action_pressed("broom") and not _dlg_open:
		toggle_broom()
	if event.is_action_pressed("map"):
		_toggle_map()
	if event.is_action_pressed("photo"):
		_toggle_photo()


func _interact_with(t: Node) -> void:
	if t.has_method("build_dialogue"):
		if t.has_method("is_available") and not t.is_available():
			GameState.say("They are asleep. Come back in the morning." if not Story.NPCS.get(t.get("npc_id"), {}).get("night_only", false) else "Only after dark.")
			return
		if t.has_method("get_action_anim") and not t.has_method("brew"):
			player.do_action(t.get_action_anim())
		open_dialogue(t, t.build_dialogue())
		return
	if t.has_method("get_action_anim"):
		player.do_action(t.get_action_anim())
	t.interact()


func _nearest_interactable() -> Node3D:
	var best: Node3D = null
	var best_d := INTERACT_RANGE
	for n in get_tree().get_nodes_in_group("interactable"):
		var d := (n as Node3D).global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best


func _refresh_bag() -> void:
	var inv := GameState.inventory
	var potions := 0
	for k in ["potion", "tonic", "draught", "elixir", "oil", "broth", "shade", "glow", "pie"]:
		potions += int(inv.get(k, 0))
	var fish: int = inv.get("minnow", 0) + inv.get("perch", 0) + inv.get("moonfish", 0)
	_bag.text = "Moonpetal %d · Emberroot %d · Whisperleaf %d · Potions %d · Fish %d\nEmber %d/%d · Coins %d · Marks %d (%s)" % [
		inv["moonpetal"], inv["emberroot"], inv["whisperleaf"], potions, fish, GameState.ember, Story.EMBER_GATE, GameState.coins, GameState.marks, Story.rank_for(GameState.marks)]


var _toast_queue: Array = []

func _show_toast(text: String) -> void:
	# Queue toasts so quick successive messages are all readable
	if _toast_time > 0.8 and _toast.text != "":
		_toast_queue.append(text)
		return
	_toast.text = text
	_toast_time = 3.0 + minf(text.length() / 40.0, 3.0)
	_toast.modulate.a = 1.0


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _circle(c: Color, size: float) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = c
	st.set_corner_radius_all(int(size / 2.0))
	p.add_theme_stylebox_override("panel", st)
	return p


func _box(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(14)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.border_color = Color(0.8, 0.65, 1.0, 0.5)
	s.set_border_width_all(2)
	return s


# ---------------------------------------------------------------- dialogue

func _build_dialogue() -> void:
	_dlg_panel = PanelContainer.new()
	_dlg_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dlg_panel.offset_left = -420
	_dlg_panel.offset_right = 420
	_dlg_panel.offset_top = -250
	_dlg_panel.offset_bottom = -60
	_dlg_panel.add_theme_stylebox_override("panel", _box(Color(0.1, 0.07, 0.18, 0.92)))
	_dlg_panel.visible = false
	add_child(_dlg_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_dlg_panel.add_child(row)
	_dlg_portrait = TextureRect.new()
	_dlg_portrait.custom_minimum_size = Vector2(128, 160)
	_dlg_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dlg_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_dlg_portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_dlg_name = _label(18, Color(1.0, 0.85, 0.5))
	col.add_child(_dlg_name)
	_dlg_text = _label(19, Color(0.95, 0.93, 1.0))
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(0, 90)
	_dlg_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_dlg_text)
	_dlg_choices = VBoxContainer.new()
	_dlg_choices.add_theme_constant_override("separation", 4)
	col.add_child(_dlg_choices)
	_dlg_hint = _label(13, Color(1, 1, 1, 0.55))
	_dlg_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dlg_hint.text = "click / F to continue"
	col.add_child(_dlg_hint)


func open_dialogue(source: Node, data: Dictionary) -> void:
	_dlg_source = source
	_dlg_data = data
	_dlg_pages = data.get("pages", [])
	_dlg_page = 0
	_dlg_open = true
	_dlg_panel.visible = true
	_show_page()


func _show_page() -> void:
	for c in _dlg_choices.get_children():
		c.queue_free()
	if _dlg_page >= _dlg_pages.size():
		_close_dialogue()
		return
	var pg: Array = _dlg_pages[_dlg_page]
	_dlg_name.text = pg[0]
	_dlg_name.visible = pg[0] != ""
	var pid := ""
	if _dlg_source and _dlg_source.has_method("build_dialogue") and "npc_id" in _dlg_source:
		pid = _dlg_source.npc_id
		_dlg_name.add_theme_color_override("font_color", Story.NPCS[pid]["color"])
	else:
		_dlg_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_dlg_portrait.visible = pid != ""
	if pid != "":
		_dlg_portrait.texture = Portraits.get_portrait(pid)
	_dlg_text.text = pg[1]
	_dlg_text.visible_characters = 0
	_type_t = 0.0
	var last := _dlg_page == _dlg_pages.size() - 1
	if last and _dlg_data.has("choices"):
		_dlg_hint.text = "choose one, or click to close"
		for ch in _dlg_data["choices"]:
			var b := Button.new()
			b.text = ch["label"]
			b.disabled = not ch["enabled"]
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", 16)
			b.pressed.connect(_on_choice.bind(ch))
			_dlg_choices.add_child(b)
	else:
		_dlg_hint.text = "click / F to continue" if not last else "click / F to close"


func _on_choice(ch: Dictionary) -> void:
	if _dlg_source and _dlg_source.has_method("brew") and ch.has("recipe"):
		_dlg_source.brew(ch["recipe"])
		player.do_action("Spellcast_Raise")
	elif _dlg_source and ch.has("call") and _dlg_source.has_method(ch["call"]):
		_dlg_source.call(ch["call"], ch.get("arg"))
	_close_dialogue()


var _type_t := 0.0

func advance_dialogue() -> void:
	# First press: finish the typewriter; second press: next page.
	if _dlg_text.visible_characters >= 0 and _dlg_text.visible_characters < _dlg_text.get_total_character_count():
		_dlg_text.visible_characters = -1
		return
	if _dlg_data.has("choices") and _dlg_page == _dlg_pages.size() - 1:
		_close_dialogue()
		return
	_dlg_page += 1
	_show_page()


func _close_dialogue() -> void:
	_dlg_open = false
	_dlg_panel.visible = false
	if _dlg_data.has("deliver") and _dlg_source and _dlg_source.has_method("deliver"):
		_dlg_source.deliver(_dlg_data["deliver"])
	if _dlg_data.has("enter_academy"):
		GameState.save_game()
		GameState.spawn_at = Vector3(0, 0.1, 1.5)
		GameState.spawn_yaw = 0.0
		get_tree().call_deferred("change_scene_to_file", "res://world/academy.tscn")
	_dlg_data = {}
	_dlg_source = null


# ---------------------------------------------------------------- journal

func _build_journal() -> void:
	var btn := Button.new()
	btn.text = "Journal"
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-110, 12)
	btn.custom_minimum_size = Vector2(96, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(_toggle_journal)
	add_child(btn)
	_journal = PanelContainer.new()
	_journal.set_anchors_preset(Control.PRESET_CENTER)
	_journal.offset_left = -300
	_journal.offset_right = 300
	_journal.offset_top = -220
	_journal.offset_bottom = 220
	_journal.add_theme_stylebox_override("panel", _box(Color(0.1, 0.07, 0.18, 0.95)))
	_journal.visible = false
	add_child(_journal)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_journal.add_child(sc)
	_journal_text = _label(16, Color(0.95, 0.93, 1.0))
	_journal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_text.custom_minimum_size = Vector2(560, 0)
	sc.add_child(_journal_text)
	_journal.offset_left = -320
	_journal.offset_right = 320
	_journal.offset_top = -250
	_journal.offset_bottom = 250
	var photo_btn := Button.new()
	photo_btn.text = "📷"
	photo_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	photo_btn.position = Vector2(-662, 12)
	photo_btn.custom_minimum_size = Vector2(36, 36)
	photo_btn.focus_mode = Control.FOCUS_NONE
	photo_btn.add_theme_font_size_override("font_size", 14)
	photo_btn.pressed.connect(_toggle_photo)
	add_child(photo_btn)
	var save_btn := Button.new()
	save_btn.text = "Save code"
	save_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	save_btn.position = Vector2(-620, 12)
	save_btn.position.x = -620
	save_btn.custom_minimum_size = Vector2(90, 36)
	save_btn.focus_mode = Control.FOCUS_NONE
	save_btn.add_theme_font_size_override("font_size", 13)
	save_btn.pressed.connect(_toggle_save_panel)
	add_child(save_btn)
	var mute := Button.new()
	mute.text = "♪"
	mute.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mute.position = Vector2(-372, 12)
	mute.custom_minimum_size = Vector2(36, 36)
	mute.focus_mode = Control.FOCUS_NONE
	mute.add_theme_font_size_override("font_size", 16)
	mute.pressed.connect(func():
		Sound.toggle_mute()
		mute.text = "♪" if not Sound.muted else "✕"
		GameState.say("Sound off" if Sound.muted else "Sound on"))
	mute.text = "♪" if not Sound.muted else "✕"
	add_child(mute)
	var q := Button.new()
	q.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	q.position = Vector2(-520, 12)
	q.custom_minimum_size = Vector2(72, 36)
	q.focus_mode = Control.FOCUS_NONE
	q.add_theme_font_size_override("font_size", 13)
	q.text = "HQ" if GameState.quality == "high" else "LQ"
	q.pressed.connect(func():
		GameState.set_quality("low" if GameState.quality == "high" else "high")
		q.text = "HQ" if GameState.quality == "high" else "LQ"
		GameState.say("Graphics: %s quality" % GameState.quality))
	add_child(q)


func _build_clock_button() -> void:
	var btn := Button.new()
	btn.text = "Time +6h"
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-330, 12)
	btn.custom_minimum_size = Vector2(100, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func():
		GameState.time_offset = fmod(GameState.time_offset + 6.0 * 3600.0, 24.0 * 3600.0)
		GameState.mark_dirty()
		GameState.say("Clock shifted. Offset: +%dh (real time when 0)" % int(GameState.time_offset / 3600.0)))
	add_child(btn)


func _build_cards() -> void:
	var btn := Button.new()
	btn.text = "Villagers"
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-218, 12)
	btn.custom_minimum_size = Vector2(100, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(_toggle_cards)
	add_child(btn)
	_cards = PanelContainer.new()
	_cards.set_anchors_preset(Control.PRESET_CENTER)
	_cards.offset_left = -440
	_cards.offset_right = 440
	_cards.offset_top = -250
	_cards.offset_bottom = 250
	_cards.add_theme_stylebox_override("panel", _box(Color(0.08, 0.06, 0.14, 0.96)))
	_cards.visible = false
	add_child(_cards)


func _toggle_cards() -> void:
	_cards.visible = not _cards.visible
	_journal.visible = false
	if not _cards.visible:
		return
	for c in _cards.get_children():
		c.queue_free()
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_cards.add_child(col)
	var title := _label(22, Color(1.0, 0.85, 0.5))
	title.text = "VILLAGERS OF HOLLOWMERE  ·  %d / %d met" % [GameState.met.size(), Story.NPCS.size() - 3]
	col.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	for id in Story.NPCS:
		var d: Dictionary = Story.NPCS[id]
		if d.get("hidden", false):
			continue
		var met: bool = GameState.met.has(id)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(128, 164)
		var st := _box(Color(0.14, 0.1, 0.24, 0.95) if met else Color(0.1, 0.09, 0.14, 0.9))
		st.border_color = d["color"] if met else Color(0.3, 0.3, 0.35)
		card.add_theme_stylebox_override("panel", st)
		grid.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		card.add_child(v)
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(0, 84)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if met:
			pic.texture = Portraits.get_portrait(id)
		else:
			pic.modulate = Color(0, 0, 0, 0.6)
			pic.texture = Portraits.get_portrait(id)
		v.add_child(pic)
		var nm := _label(12, d["color"] if met else Color(0.5, 0.5, 0.55))
		nm.text = d["name"] if met else "???"
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nm)
		var role := _label(10, Color(0.8, 0.78, 0.9, 0.8))
		role.text = d["role"] if met else d.get("scene", "village").capitalize()
		role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(role)
		var stars := _label(13, Color(1.0, 0.85, 0.4))
		var lvl := GameState.friend_level(id) if met else -1
		stars.text = ["☆☆☆", "★☆☆", "★★☆", "★★★"][lvl + 1]
		stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(stars)
		if met:
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.gui_input.connect(func(ev: InputEvent):
				if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
					_show_villager_info(id))


func _toggle_journal() -> void:
	_journal.visible = not _journal.visible
	_cards.visible = false
	if _journal.visible:
		var lines := ["APPRENTICE'S JOURNAL — %s" % Story.today_key(), ""]
		lines.append("BAG")
		var bag_parts := []
		for k in GameState.inventory:
			if int(GameState.inventory[k]) > 0:
				bag_parts.append("%s ×%d" % [GameState.ITEM_NAMES.get(k, k), int(GameState.inventory[k])])
		lines.append("  " + (", ".join(bag_parts) if not bag_parts.is_empty() else "empty"))
		lines.append("")
		lines.append("TODAY")
		for r in Story.todays_requests():
			var done := GameState.quests_done.has(r["id"])
			lines.append("  %s %s wants %d × %s%s" % ["✓" if done else "•", Story.NPCS[r["npc"]]["name"], r["amount"], Story.item_name(r["item"]), "  (homework, +2 Marks)" if r.get("homework", false) else ""])
		var left := []
		for id in Story.LESSONS:
			if not GameState.lessons_done.has("%s/%s" % [Story.today_key(), id]):
				left.append("%s %02d-%02d" % [Story.LESSONS[id]["name"], int(Story.LESSONS[id]["start"]), int(Story.LESSONS[id]["end"])])
		lines.append("  Lessons left: " + (", ".join(left) if not left.is_empty() else "none — well done"))
		lines.append("  Fireworks over Festival Green at 20:00  ·  Market 8-18  ·  Duelling 14-16  ·  Tavern evenings 18-21:30")
		var ev := Story.todays_event()
		if not ev.is_empty():
			lines.append("  ★ %s — %s" % [ev["name"], ev["text"]])
		for bid in Story.birthday_today():
			lines.append("  🎂 %s's birthday — gifts count triple" % Story.NPCS[bid]["name"])
		lines.append("")
		lines.append("Village Ember: %d / %d%s" % [GameState.ember, Story.EMBER_GATE, "   (gate open)" if GameState.gate_open else ""])
		lines.append("Coins: %d   ·   Decorations: %d / %d" % [GameState.coins, GameState.decor.size(), Story.DECOR.size()])
		lines.append("")
		lines.append("Villagers")
		for id in Story.NPCS:
			if Story.NPCS[id].get("hidden", false):
				continue
			var lvl := GameState.friend_level(id)
			var stars: String = ["new", "friend", "close friend"][lvl]
			lines.append("  %s, %s — %s" % [Story.NPCS[id]["name"], Story.NPCS[id]["role"], stars if GameState.met.has(id) else "not met yet"])
		lines.append("")
		lines.append("Recipes")
		for id in Story.RECIPES:
			var r: Dictionary = Story.RECIPES[id]
			if r.get("locked", false) and not GameState.recipes_unlocked.has(id):
				lines.append("  %s: ??? (%s)" % [r["name"], {"elixir": "finish Quill's catalogue", "shade": "bring Wennet in the Hollow Wood 2 Nightcap + 1 Moonpetal", "pie": "bring Dilly in Fernmoor 1 Reed Perch + 1 Whisperleaf", "glow": "Isolde, after Chapter 3, once you are friends"}.get(id, "full marks in Corvin's Potions lesson")])
				continue
			var parts := []
			for k in r["needs"]:
				parts.append("%d %s" % [r["needs"][k], GameState.ITEM_NAMES[k]])
			lines.append("  %s: %s — %s" % [r["name"], ", ".join(parts), r["blurb"]])
		lines.append("")
		lines.append("Spells")
		for id in Story.SPELLS:
			var sp: Dictionary = Story.SPELLS[id]
			lines.append("  %s (key %d): %s" % [sp["name"], sp["key"], sp["blurb"] if GameState.spells.has(id) else "not learned yet. Ask at the Academy."])
		lines.append("")
		lines.append("Chapter 2: dark lanterns lit %d / %d%s" % [GameState.village_lanterns_lit(), Story.DARK_LANTERNS, "  — complete" if GameState.chapter2_done else ""])
		lines.append("Chapter 3: pages %d / %d, books %d / %d%s" % [GameState.pages_found.size(), Story.PAGES_TOTAL, Story.public_books_read(), Story.public_books_total(), "  — complete" if GameState.chapter3_done else ""])
		lines.append("Today: %s, %s" % [Story.season(), Story.weather()])
		lines.append("")
		lines.append("Academy: %d Marks — rank %s   ·   Spark Targets best: %d" % [GameState.marks, Story.rank_for(GameState.marks), GameState.best_targets])
		if GameState.order != "":
			var o: Dictionary = Story.ORDERS[GameState.order]
			lines.append("Order: %s (%s) — '%s'" % [o["name"], o["virtue"], o["motto"]])
			var task: Dictionary = Story.ORDER_TASKS[GameState.order]
			lines.append("  Order task (ask %s): %s  %d / %d%s" % [Story.NPCS[task["student"]]["name"], task["text"], GameState.order_task_progress(), int(task["need"]), "  ✓" if GameState.quests_done.has("%s/ordertask" % Story.today_key()) else ""])
		else:
			lines.append("Order: not yet sorted — speak to the Headmistress at the Academy.")
		lines.append("Chapter 4: constellations found %d / 3%s" % [GameState.stars_seen.size(), "  — complete" if GameState.chapter4_done else ""])
		lines.append("Chapter 5: the Watchtower brazier (north-east hill, after Chapter 4)%s" % ("  — complete" if GameState.chapter5_done else ""))
		lines.append("Fish caught: %d   ·   Duelling Club best: %d / 8" % [GameState.fish_caught, GameState.best_duel])
		lines.append("Broom: %s   ·   Broom Course best: %s   ·   Wood Run best: %s" % ["owned (B to fly)" if GameState.broom else "Gorrin sells one for 60 coins", ("%.1f s" % GameState.best_broom) if GameState.best_broom > 0.0 else "—", ("%.1f s" % GameState.best_broom2) if GameState.best_broom2 > 0.0 else "—"])
		lines.append("Chapter 6: the Heron Isle lantern, after dark, once the Watchtower burns%s" % ("  — complete" if GameState.chapter6_done else ""))
		lines.append("Chapter 7: the small star — the telescope at midnight, after Chapter 6%s" % ("  — complete" if GameState.chapter7_done else ""))
		lines.append("Cats petted: %d%s" % [GameState.cat_pets, ("   ·   companion: " + GameState.cat_name) if GameState.cat_name != "" else "   (15 pets and the orange one adopts you)"])
		lines.append("Pumpkin: %s   ·   best %d lb   ·   contest Saturdays on the green" % [("day %d" % GameState.pumpkin_days()) if GameState.pumpkin_days() >= 0 else "none planted (seed from Tamsin)", GameState.pumpkin_best])
		lines.append("Garden: %d beds (Tamsin sells expansions)" % (3 + GameState.garden_level * 3))
		lines.append("Founders' Cards: %d / %d" % [GameState.cards.size(), Story.CARDS.size()])
		for cid in Story.CARDS:
			lines.append("  %s %s" % ["✓" if GameState.cards.has(cid) else "•", Story.CARDS[cid]["name"] if GameState.cards.has(cid) else "??? — a chest near " + Story.CARDS[cid]["pos"]])
		lines.append("Student favours: %d / %d" % [GameState.favours.size(), Story.FAVOURS.size()])
		for fid in Story.FAVOURS:
			if GameState.quests_done.has("favour_asked_" + fid):
				lines.append("  %s %s: %s" % ["✓" if GameState.favours.has(fid) else "•", Story.NPCS[fid]["name"], Story.FAVOURS[fid]["text"]])
		lines.append("Honours: %d / %d" % [GameState.honours.size(), Story.HONOURS.size()])
		for hid in Story.HONOURS:
			lines.append("  %s %s — %s" % ["★" if GameState.honours.has(hid) else "☆", Story.HONOURS[hid]["name"], Story.HONOURS[hid]["text"]])
		lines.append("Sky lanterns (fly through them on the broom): %d / %d" % [GameState.sky_lanterns.size(), Story.SKY_LANTERNS.size()])
		lines.append("Star shards (Glimmer after dark): %d / %d   ·   Repairs (Mend): %d / %d" % [GameState.shards.size(), Story.SHARDS.size(), GameState.mended.size(), Story.BROKEN.size()])
		lines.append("Timetable (talk to the teacher in the room during the hour):")
		for id in Story.LESSONS:
			var L: Dictionary = Story.LESSONS[id]
			var done := GameState.lessons_done.has("%s/%s" % [Story.today_key(), id])
			var prac := GameState.lessons_done.has("%s/%s/practical" % [Story.today_key(), id])
			lines.append("  %02d:00-%02d:00  %s — %s, %s%s%s" % [int(L["start"]), int(L["end"]), L["name"], Story.NPCS[L["teacher"]]["name"], L["room"], "  ✓ lesson" if done else "", "  ✓ practical" if prac else ""])
		lines.append("")
		lines.append("Districts: Hearth Row (homes, west) · Lantern Market (east, 8-18) · Festival Green (south) · Trial Field (practice, north-west) · Ashenvale Academy (north, through the gate)")
		lines.append("")
		lines.append("The Quiet Night took the Academy's light. Every potion brewed and every request filled brings a little back.")
		_journal_text.text = "\n".join(lines)


# ---------------------------------------------------------------- spells

var _broom_btn: Button
var _map: PanelContainer

func toggle_broom() -> void:
	if not GameState.broom:
		return
	player.set_flying(not player.flying)


func _build_spell_buttons() -> void:
	_broom_btn = Button.new()
	_broom_btn.text = "B  Broom"
	_broom_btn.custom_minimum_size = Vector2(120, 40)
	_broom_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_broom_btn.position = Vector2(-150, -250 - 4 * 48)
	_broom_btn.focus_mode = Control.FOCUS_NONE
	_broom_btn.add_theme_font_size_override("font_size", 15)
	_broom_btn.add_theme_color_override("font_color", Color(0.1, 0.07, 0.15))
	var bst := StyleBoxFlat.new()
	bst.bg_color = Color(0.9, 0.75, 0.5)
	bst.set_corner_radius_all(12)
	for k in ["normal", "hover", "pressed", "focus"]:
		_broom_btn.add_theme_stylebox_override(k, bst)
	_broom_btn.pressed.connect(toggle_broom)
	_broom_btn.visible = false
	add_child(_broom_btn)
	var i := 0
	for id in Story.SPELLS:
		var sp: Dictionary = Story.SPELLS[id]
		var b := Button.new()
		b.text = "%d  %s" % [sp["key"], sp["name"]]
		b.custom_minimum_size = Vector2(120, 40)
		b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		b.position = Vector2(-150, -250 - i * 48)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", Color(0.1, 0.07, 0.15))
		var st := StyleBoxFlat.new()
		st.bg_color = sp["color"]
		st.set_corner_radius_all(12)
		for k in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(k, st)
		b.pressed.connect(cast_spell.bind(id))
		add_child(b)
		_spell_buttons[id] = b
		i += 1
	_refresh_spell_buttons()


func _refresh_spell_buttons() -> void:
	for id in _spell_buttons:
		_spell_buttons[id].visible = GameState.spells.has(id)


func cast_spell(id: String) -> void:
	if not GameState.spells.has(id) or _dlg_open:
		return
	var sp: Dictionary = Story.SPELLS[id]
	player.cast(sp["color"])
	Sound.spell()
	var hit := false
	for d in get_tree().get_nodes_in_group("duel"):
		if d._running:
			d.on_cast(id)
			return
	if id == "kindle":
		for n in get_tree().get_nodes_in_group("spark_targets"):
			if n.kindle_at(player.global_position):
				hit = true
		for n in get_tree().get_nodes_in_group("dark_lantern"):
			if (n as Node3D).global_position.distance_to(player.global_position) < 5.0 and n.has_method("kindle"):
				if n.kindle():
					hit = true
	elif id == "verdant":
		var best: Node = null
		var bd := 4.5
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is HerbPlot:
				var d := (n as Node3D).global_position.distance_to(player.global_position)
				if d < bd:
					bd = d
					best = n
		if best:
			hit = best.verdant()
	elif id == "glimmer":
		GameState.glimmer_until = Time.get_ticks_msec() / 1000.0 + 60.0
		hit = true
		GameState.say("Glimmer. Your staff burns bright for a minute." + ("  Star shards shimmer in the dark." if GameState.is_night() else "  (After dark it also reveals star shards.)"))
	elif id == "mend":
		for n in get_tree().get_nodes_in_group("mendable"):
			if (n as Node3D).global_position.distance_to(player.global_position) < 5.0 and n.mend():
				hit = true
	if not hit:
		GameState.say({"kindle": "Kindle fizzles. Nothing nearby answers.", "verdant": "No herb bed close enough.", "mend": "Nothing broken within reach."}.get(id, "Nothing happens."))


# ---------------------------------------------------------------- vignette & district title cards

var _title_card: Label
var _title_sub: Label
var _title_time := 0.0
var _title_district := ""

func _build_vignette() -> void:
	var v := ColorRect.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 d = (UV - vec2(0.5)) * vec2(1.25, 1.0);
	float v = smoothstep(0.45, 1.05, length(d));
	COLOR = vec4(0.05, 0.02, 0.1, v * 0.55);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	v.material = m
	add_child(v)
	move_child(v, 0)


func _build_title_card() -> void:
	_title_card = _label(44, Color(1.0, 0.93, 0.75))
	_title_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_card.offset_top = 110
	_title_card.offset_left = -500
	_title_card.offset_right = 500
	_title_card.add_theme_constant_override("outline_size", 12)
	_title_card.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	_title_card.modulate.a = 0.0
	add_child(_title_card)
	_title_sub = _label(18, Color(0.9, 0.88, 1.0))
	_title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_sub.offset_top = 165
	_title_sub.offset_left = -500
	_title_sub.offset_right = 500
	_title_sub.add_theme_constant_override("outline_size", 8)
	_title_sub.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	_title_sub.modulate.a = 0.0
	add_child(_title_sub)


func _update_title_card(delta: float) -> void:
	if _title_card == null:
		return
	var here := ""
	var sub := ""
	if get_tree().current_scene.name == "Village" and get_tree().current_scene.get("env") != null:
		for id in Story.DISTRICTS:
			if (Story.DISTRICTS[id]["pos"] as Vector3).distance_to(player.global_position) < 17.0:
				here = Story.DISTRICTS[id]["name"]
				sub = {"hearth": "Where Hollowmere sleeps", "market": "Herbs in, potions out", "green": "Maypole, pond, targets and rings", "trial": "Practice for the Academy"}.get(id, "")
		if here == "" and player.global_position.distance_to(Vector3(58, 0, 14)) < 26.0:
			here = "Lake Mirren"
			sub = "Deeper than it should be"
		elif here == "" and player.global_position.distance_to(Vector3(-58, 0, 46)) < 18.0:
			here = "Fernmoor"
			sub = "Smaller, quieter, and they like it that way"
		elif here == "" and player.global_position.distance_to(Vector3(56, 0, -56)) < 16.0:
			here = "The Old Watchtower"
			sub = "A light last winter. Nobody went to look."
		elif here == "" and player.global_position.length() < 14.0:
			here = "Hollowmere Square"
			sub = "The shrine candle never went out"
	if here != _title_district:
		_title_district = here
		if here != "":
			_title_card.text = here
			_title_sub.text = sub
			_title_time = 3.2
	if _title_time > 0.0:
		_title_time -= delta
		var a := clampf(minf(_title_time, 3.2 - _title_time) * 1.6, 0.0, 1.0)
		_title_card.modulate.a = a
		_title_sub.modulate.a = a * 0.9


# ---------------------------------------------------------------- world map

func _build_map() -> void:
	var btn := Button.new()
	btn.text = "Map"
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-440, 12)
	btn.custom_minimum_size = Vector2(60, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_toggle_map)
	add_child(btn)
	_map = PanelContainer.new()
	_map.set_anchors_preset(Control.PRESET_CENTER)
	_map.offset_left = -290
	_map.offset_right = 290
	_map.offset_top = -290
	_map.offset_bottom = 290
	_map.add_theme_stylebox_override("panel", _box(Color(0.1, 0.07, 0.18, 0.95)))
	_map.visible = false
	add_child(_map)
	var wm := Control.new()
	wm.set_script(load("res://ui/world_map.gd"))
	wm.player = player
	_map.add_child(wm)


func _toggle_map() -> void:
	if _map == null:
		return
	_map.visible = not _map.visible
	if _map.visible:
		_journal.visible = false
		_cards.visible = false


## One-line objective shown under the bag: what would move the story along right now.
func _objective() -> String:
	var scene := get_tree().current_scene.name
	if not GameState.gate_open:
		if GameState.ember < Story.EMBER_GATE:
			return "Open the Academy gate: Ember %d / %d  (requests, brewing, gifts, fishing)" % [GameState.ember, Story.EMBER_GATE]
		return "Ember is high enough — go to the Academy gate on the hill road north"
	if GameState.order == "":
		return "At the Academy, speak to Headmistress Vance for the Sorting"
	var lid := Story.lesson_now()
	if lid != "" and not GameState.lessons_done.has("%s/%s" % [Story.today_key(), lid]):
		var L: Dictionary = Story.LESSONS[lid]
		return "Lesson now: %s with %s — %s%s" % [L["name"], Story.NPCS[L["teacher"]]["name"], L["room"], "" if scene == "Academy" else " (Academy)"]
	for r in Story.todays_requests():
		if not GameState.quests_done.has(r["id"]):
			return "%s wants %d × %s%s" % [Story.NPCS[r["npc"]]["name"], r["amount"], Story.item_name(r["item"]), "  (homework)" if r.get("homework", false) else ""]
	if not GameState.spells.has("kindle"):
		return "Learn Kindle from Professor Alder (Hall of Flame, Academy)"
	if not GameState.chapter2_done:
		return "Chapter 2: light the dark lanterns of Hollowmere with Kindle (%d / %d)" % [GameState.village_lanterns_lit(), Story.DARK_LANTERNS]
	if not GameState.chapter3_done:
		return "Chapter 3: find Quill's lost pages (%d / %d) and read the library books (%d / %d)" % [GameState.pages_found.size(), Story.PAGES_TOTAL, Story.public_books_read(), Story.public_books_total()]
	if not GameState.chapter4_done:
		return "Chapter 4: find the three constellations at the Astronomy Tower telescope after dark (%d / 3)" % GameState.stars_seen.size()
	if not GameState.chapter5_done:
		return "Chapter 5: Kindle the Watchtower brazier on the north-east hill"
	if not GameState.chapter6_done:
		return "Chapter 6: row to Heron Isle and Kindle its lantern after dark"
	if not GameState.chapter7_done:
		return "Chapter 7: the telescope at midnight"
	return "The valley is yours. Lessons, market, fishing, sky lanterns, cards, friends."


var _tags: Array = []
var _tags_t := 0.0

## World labels only show near the player (keeps the screen clean in a big valley).
func _fade_tags() -> void:
	_tags_t -= 20.0 / 60.0
	if _tags.is_empty() or _tags_t <= 0.0:
		_tags_t = 6.0
		_tags = get_tree().current_scene.find_children("*", "Label3D", true, false)
	var pp := player.global_position
	for t in _tags:
		if not is_instance_valid(t):
			continue
		var lb := t as Label3D
		if lb.get_parent() is Villager:
			continue
		var d := lb.global_position.distance_to(pp)
		var limit := 30.0 if lb.text.begins_with("→") else 20.0
		var par := lb.get_parent()
		var hidden_by_state: bool = par != null and par.has_method("is_lit") and par.is_lit() and lb.name == "Tag"
		lb.visible = d < limit and not hidden_by_state


func _show_villager_info(id: String) -> void:
	_cards.visible = false
	var d: Dictionary = Story.NPCS[id]
	var lvl := GameState.friend_level(id)
	var lines := []
	lines.append("%s — %s" % [d["name"], d["role"]])
	lines.append("Friendship: %s (%d points)" % [["new acquaintance", "friend", "close friend"][lvl], int(GameState.friendship.get(id, 0))])
	if lvl >= 1 and Story.FAVOURITES.has(id):
		lines.append("Favourite gift: %s" % GameState.ITEM_NAMES[Story.FAVOURITES[id]])
	else:
		lines.append("Favourite gift: ??? (become friends to learn it)")
	if Story.BIRTHDAYS.has(id):
		var bd: int = Story.BIRTHDAYS[id]
		var suf := "th"
		if bd % 10 == 1 and bd != 11: suf = "st"
		elif bd % 10 == 2 and bd != 12: suf = "nd"
		elif bd % 10 == 3 and bd != 13: suf = "rd"
		lines.append("Birthday: the %d%s of every month" % [bd, suf])
	if Story.MEMORIES.has(id):
		lines.append("Their story: %s" % ("heard" if GameState.memories_heard.has(id) else "not yet (close friends only)"))
	var sched: Array = d.get("schedule", [])
	if not sched.is_empty():
		var parts := []
		for e in sched:
			parts.append("%02d-%02d" % [int(e[0]), int(e[1])])
		lines.append("Out and about: " + ", ".join(parts))
	if d.get("night_only", false):
		lines.append("Only after dark.")
	open_dialogue(null, {"pages": [[d["name"], "\n".join(lines)]]})


func _show_tap_marker(at: Vector3) -> void:
	if _tap_marker == null:
		_tap_marker = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.35
		tm.outer_radius = 0.5
		_tap_marker.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.9, 0.5, 0.8)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_tap_marker.material_override = m
		get_tree().current_scene.add_child(_tap_marker)
	_tap_marker.global_position = at + Vector3(0, 0.08, 0)
	_tap_marker.visible = true


# ---------------------------------------------------------------- save code (move progress between devices)

var _save_panel: PanelContainer
var _save_edit: TextEdit

func _toggle_save_panel() -> void:
	if _save_panel == null:
		_save_panel = PanelContainer.new()
		_save_panel.set_anchors_preset(Control.PRESET_CENTER)
		_save_panel.offset_left = -300
		_save_panel.offset_right = 300
		_save_panel.offset_top = -170
		_save_panel.offset_bottom = 170
		_save_panel.add_theme_stylebox_override("panel", _box(Color(0.1, 0.07, 0.18, 0.97)))
		_save_panel.visible = false
		add_child(_save_panel)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		_save_panel.add_child(col)
		var t := _label(16, Color(1.0, 0.85, 0.5))
		t.text = "SAVE CODE — copy this to play on another device"
		col.add_child(t)
		var h := _label(12, Color(0.9, 0.88, 1.0, 0.8))
		h.text = "Select all, copy. On the other device: paste it here and press Load. (Or press Copy / Paste.)"
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(h)
		_save_edit = TextEdit.new()
		_save_edit.custom_minimum_size = Vector2(560, 180)
		_save_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		_save_edit.add_theme_font_size_override("font_size", 11)
		col.add_child(_save_edit)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		col.add_child(row)
		for spec in [["Copy", "copy"], ["Paste", "paste"], ["Load", "load"], ["Close", "close"]]:
			var b := Button.new()
			b.text = spec[0]
			b.custom_minimum_size = Vector2(90, 34)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_save_action.bind(spec[1]))
			row.add_child(b)
	_save_panel.visible = not _save_panel.visible
	if _save_panel.visible:
		GameState.save_game()
		var raw := FileAccess.get_file_as_string(GameState.SAVE_PATH)
		_save_edit.text = Marshalls.utf8_to_base64(raw) if raw != "" else ""


func _save_action(what: String) -> void:
	match what:
		"copy":
			DisplayServer.clipboard_set(_save_edit.text)
			GameState.say("Save code copied.")
		"paste":
			_save_edit.text = DisplayServer.clipboard_get()
		"load":
			var txt := Marshalls.base64_to_utf8(_save_edit.text.strip_edges())
			var parsed = JSON.parse_string(txt)
			if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("inventory"):
				GameState.say("That is not a Hollowmere save code.")
				return
			var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
			if f:
				f.store_string(txt)
				f.close()
			GameState.load_game()
			GameState.say("Save loaded. Reloading the valley…")
			get_tree().call_deferred("change_scene_to_file", "res://world/village.tscn")
		"close":
			_save_panel.visible = false


# ---------------------------------------------------------------- photo mode (hide the UI)

var _photo := false
var _safe_inset := 0.0

var _photo_layer: CanvasLayer

func _toggle_photo() -> void:
	_photo = not _photo
	visible = not _photo
	if _photo_layer == null:
		_photo_layer = CanvasLayer.new()
		_photo_layer.layer = 30
		var b := Button.new()
		b.text = "📷  exit photo mode (P)"
		b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		b.position = Vector2(-230, -50)
		b.custom_minimum_size = Vector2(210, 36)
		b.focus_mode = Control.FOCUS_NONE
		b.modulate.a = 0.6
		b.pressed.connect(_toggle_photo)
		_photo_layer.add_child(b)
		get_parent().add_child.call_deferred(_photo_layer)
	_photo_layer.visible = _photo


# ---------------------------------------------------------------- first-day guidance

func _tut(id: String, text: String) -> void:
	if GameState.tutorial.has(id):
		return
	GameState.tutorial[id] = true
	GameState.mark_dirty()
	GameState.say("Tip: " + text)


func _tutorial_tick() -> void:
	if _dlg_open or GameState.ui_locked or get_tree().current_scene.name != "Village":
		return
	var inv := GameState.inventory
	var herbs: int = inv["moonpetal"] + inv["emberroot"] + inv["whisperleaf"]
	if not GameState.tutorial.has("t1") and GameState.intro_seen:
		_tut("t1", "the herb beds are just west of the square. Walk up and press F (or tap them) to harvest.")
		return
	if herbs >= 3 and not GameState.tutorial.has("t2"):
		_tut("t2", "the cauldron next to the beds brews potions. One of each herb makes a Starlight Potion.")
		return
	if inv["potion"] + inv["tonic"] + inv["draught"] > 0 and not GameState.tutorial.has("t3"):
		_tut("t3", "check the notice board by the shrine; villagers with a ! above them want something today.")
		return
	if GameState.quests_done.size() >= 1 and not GameState.tutorial.has("t4"):
		_tut("t4", "each delivery warms the village Ember. At 12 the Academy gate opens — it is on the hill road north.")
		return
	if GameState.gate_open and not GameState.tutorial.has("t5"):
		_tut("t5", "press M for the valley map. There is a lot out there: a lake, two villages, a wood, an isle.")
		return
	if GameState.spells.has("kindle") and not GameState.tutorial.has("t6"):
		_tut("t6", "press 1 near a dark lantern to Kindle it. Four went dark in Hollowmere; the journal counts them.")
		return
	if GameState.coins >= 60 and not GameState.broom and not GameState.tutorial.has("t7"):
		_tut("t7", "Gorrin at the Lantern Market sells a broom for 60 coins. B to fly, Space up, Shift down.")
		return


# ---------------------------------------------------------------- web test bridge (browser automation reads/writes window.__dbg / window.__cmd)

var _bridge_t := 0.0

func _web_bridge(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_bridge_t -= delta
	if _bridge_t > 0.0:
		return
	_bridge_t = 0.25
	var p := player.global_position
	JavaScriptBridge.eval("window.__dbg={x:%.2f,y:%.2f,z:%.2f,vx:%.2f,vz:%.2f,flying:%s,scene:'%s',dlg:%s,locked:%s}" % [p.x, p.y, p.z, player.velocity.x, player.velocity.z, str(player.flying).to_lower(), get_tree().current_scene.name, str(_dlg_open).to_lower(), str(GameState.ui_locked).to_lower()], true)
	var cmd = JavaScriptBridge.eval("(function(){var c=window.__cmd||'';window.__cmd='';return c;})()", true)
	if cmd is String and cmd != "":
		var parts: PackedStringArray = (cmd as String).split(" ")
		match parts[0]:
			"tp":
				player.global_position = Vector3(float(parts[1]), float(parts[2]), float(parts[3]))
				player.velocity = Vector3.ZERO
			"close":
				_close_dialogue()
			"begin":
				for t in get_tree().current_scene.get_children():
					if t.has_method("_start"):
						t._start()
				for t in get_tree().current_scene.get_children():
					if t.has_method("finish_intro"):
						t.finish_intro()
				GameState.ui_locked = false
			"hour":
				GameState.forced_hour = float(parts[1])
			"fly":
				player.set_flying(parts[1] == "1")


# ---------------------------------------------------------------- quest compass

var _compass: Control
var _compass_arrow: Polygon2D
var _compass_lbl: Label
var _compass_target := Vector3.INF
var _compass_t := 0.0

func _script_pos(file: String) -> Vector3:
	for n in get_tree().get_nodes_in_group("interactable"):
		var sc: Script = n.get_script()
		if sc and sc.resource_path.get_file() == file:
			return (n as Node3D).global_position
	return Vector3.INF


func _npc_pos(id: String) -> Vector3:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Villager and (n as Villager).npc_id == id:
			return (n as Node3D).global_position
	return Vector3.INF


## Where the current objective is, in this scene (or the door that leads to it).
func _objective_target() -> Vector3:
	var scene := get_tree().current_scene.name
	var in_v := scene == "Village"
	var in_a := scene == "Academy"
	if not in_v and not in_a:
		return _script_pos("exit_door.gd")
	var way_out := _script_pos("gate.gd") if in_v else _script_pos("exit_door.gd")
	var here := "village" if in_v else "academy"
	if not GameState.gate_open:
		if GameState.ember < Story.EMBER_GATE:
			for r in Story.todays_requests():
				if not GameState.quests_done.has(r["id"]) and Story.NPCS[r["npc"]].get("scene", "village") == "village":
					return _npc_pos(r["npc"])
			return _script_pos("notice_board.gd")
		return way_out
	if GameState.order == "":
		return _npc_pos("oriel") if in_a else way_out
	var lid := Story.lesson_now()
	if lid != "" and not GameState.lessons_done.has("%s/%s" % [Story.today_key(), lid]):
		return _npc_pos(Story.LESSONS[lid]["teacher"]) if in_a else way_out
	for r in Story.todays_requests():
		if not GameState.quests_done.has(r["id"]):
			return _npc_pos(r["npc"]) if Story.NPCS[r["npc"]].get("scene", "village") == here else way_out
	if not GameState.spells.has("kindle"):
		return _npc_pos("alder") if in_a else way_out
	if not GameState.chapter2_done:
		if not in_v:
			return way_out
		var best := Vector3.INF
		var bd := 1e9
		for n in get_tree().get_nodes_in_group("dark_lantern"):
			if str(n.lantern_id).begins_with("village_") and not n.is_lit():
				var d: float = (n as Node3D).global_position.distance_to(player.global_position)
				if d < bd:
					bd = d
					best = (n as Node3D).global_position
		return best
	if not GameState.chapter3_done:
		return _npc_pos("quill") if in_a else way_out
	if not GameState.chapter4_done:
		return _script_pos("telescope.gd") if in_a else way_out
	if not GameState.chapter5_done:
		return Vector3(59.5, 0.4, -58.0) if in_v else way_out
	if not GameState.chapter6_done:
		return _script_pos("boat.gd") if in_v else way_out
	if not GameState.chapter7_done:
		return _script_pos("telescope.gd") if in_a else way_out
	return Vector3.INF


func _build_compass() -> void:
	_compass = Control.new()
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_compass)
	move_child(_compass, 1)
	_compass_arrow = Polygon2D.new()
	_compass_arrow.polygon = PackedVector2Array([Vector2(0, -15), Vector2(11, 0), Vector2(0, 15), Vector2(-11, 0)])
	_compass_arrow.color = Color(1.0, 0.82, 0.35, 0.95)
	_compass.add_child(_compass_arrow)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)])
	inner.color = Color(0.25, 0.14, 0.3, 0.9)
	_compass_arrow.add_child(inner)
	_compass_lbl = _label(13, Color(1.0, 0.92, 0.7))
	_compass_lbl.add_theme_constant_override("outline_size", 6)
	_compass_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.2))
	_compass_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compass_lbl.size = Vector2(80, 18)
	_compass.add_child(_compass_lbl)


func _update_compass() -> void:
	if _compass == null:
		_build_compass()
	_compass_t -= get_process_delta_time()
	if _compass_t <= 0.0:
		_compass_t = 0.5
		_compass_target = _objective_target()
	var cam := get_viewport().get_camera_3d()
	var show := cam != null and _compass_target != Vector3.INF and not _dlg_open and not _journal.visible and not _photo and not GameState.ui_locked
	var world := _compass_target + Vector3(0, 2.6, 0)
	var dist := 0.0
	if show:
		dist = Vector2(_compass_target.x - player.global_position.x, _compass_target.z - player.global_position.z).length()
		show = dist > 3.5
	_compass.visible = show
	if not show:
		return
	var vp := get_viewport().get_visible_rect().size
	var sp := cam.unproject_position(world)
	var behind := cam.is_position_behind(world)
	var c := vp * 0.5
	if behind:
		sp = c - (sp - c)
	var m := Vector2(46, 130)
	var inside := not behind and sp.x > m.x and sp.x < vp.x - m.x and sp.y > m.y and sp.y < vp.y - 150.0
	if not inside:
		var dir := (sp - c)
		if dir.length() < 1.0:
			dir = Vector2(0, -1)
		dir = dir.normalized()
		if behind:
			dir.y = absf(dir.y) * 0.3 + 0.2   # things behind you point down-and-sideways
			dir = dir.normalized()
		var kx := (vp.x * 0.5 - m.x) / maxf(absf(dir.x), 0.001)
		var ky := ((vp.y * 0.5 - m.y) if dir.y < 0.0 else (vp.y * 0.5 - 150.0)) / maxf(absf(dir.y), 0.001)
		sp = c + dir * minf(kx, ky)
		_compass_arrow.rotation = dir.angle() + PI / 2.0
		_compass_arrow.scale = Vector2(0.8, 1.5)
	else:
		_compass_arrow.rotation = 0.0
		_compass_arrow.scale = Vector2.ONE * (1.0 + 0.12 * sin(Time.get_ticks_msec() / 220.0))
	_compass_arrow.position = sp
	_compass_lbl.text = "%d m" % int(dist)
	_compass_lbl.position = sp + Vector2(-40, 16)
