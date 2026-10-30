extends Node3D
## Broom ring course on Festival Green: fly through 8 rings in order, fastest time wins.

var _rings: Array[Node3D] = []
var _next := 0
var _running := false
var _t := 0.0
var _tag: Label3D
var _hint: Label3D

var RINGS: Array = [Vector3(0, 5, 0), Vector3(10, 8, -6), Vector3(18, 12, 4), Vector3(10, 15, 14), Vector3(-4, 13, 18), Vector3(-16, 10, 10), Vector3(-18, 7, -4), Vector3(-6, 5, -8)]
var course_name := "Broom Course"
var best_key := "best_broom"


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("broom_course")
	_tag = Label3D.new()
	_tag.text = course_name
	_tag.font_size = 40
	_tag.pixel_size = 0.006
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.outline_size = 10
	_tag.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	_tag.modulate = Color(0.8, 0.9, 1.0)
	_tag.position.y = 2.6
	add_child(_tag)
	_hint = Label3D.new()
	_hint.font_size = 30
	_hint.pixel_size = 0.006
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.no_depth_test = true
	_hint.outline_size = 8
	_hint.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	_hint.position.y = 2.1
	add_child(_hint)
	for i in RINGS.size():
		var r := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 2.0
		tm.outer_radius = 2.35
		r.mesh = tm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.9, 0.8, 0.4)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.8, 0.3)
		m.emission_energy_multiplier = 0.6
		r.material_override = m
		r.position = RINGS[i]
		r.rotation.x = PI / 2.0
		r.visible = false
		add_child(r)
		_rings.append(r)
	_hint.text = "best %.1f s" % _best() if _best() > 0.0 else "no time yet"
	var post := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.08
	c.bottom_radius = 0.1
	c.height = 1.8
	post.mesh = c
	post.position.y = 0.9
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.45, 0.3, 0.18)
	post.material_override = wm
	add_child(post)


func _best() -> float:
	return GameState.best_broom if best_key == "best_broom" else GameState.best_broom2

func _set_best(v: float) -> void:
	if best_key == "best_broom":
		GameState.best_broom = v
	else:
		GameState.best_broom2 = v


func get_prompt() -> String:
	return "[F] %s" % course_name if not _running else "[F] course running…"


func build_dialogue() -> Dictionary:
	if not GameState.broom:
		return {"pages": [[course_name, "Golden rings to fly through, for anyone with a broom. Gorrin at the Lantern Market sells one."]]}
	if _running:
		return {"pages": [[course_name, "Ring %d of %d.  %.1f s" % [_next + 1, RINGS.size(), _t]]]}
	return {"pages": [[course_name, "Fly through all the rings in order. The next ring glows brighter. Beat your best time for a Mark; every run pays coins.\n\nBest: %s" % ("%.1f s" % _best() if _best() > 0.0 else "none")]], "choices": [{"label": "Start the course", "enabled": true, "call": "start", "arg": null}]}


func start(_a) -> void:
	_running = true
	_next = 0
	_t = 0.0
	for r in _rings:
		r.visible = true
	_highlight()
	var pl = get_tree().get_first_node_in_group("player")
	if pl and not pl.flying:
		pl.set_flying(true)


func _highlight() -> void:
	for i in _rings.size():
		var m: StandardMaterial3D = _rings[i].material_override
		m.emission_energy_multiplier = 2.5 if i == _next else 0.4
		m.albedo_color = Color(1.0, 0.95, 0.6) if i == _next else Color(0.7, 0.6, 0.35)


func _process(delta: float) -> void:
	for r in _rings:
		r.rotation.z += delta * 0.6
	if not _running:
		return
	_t += delta
	_hint.text = "ring %d/%d · %.1f s" % [_next + 1, RINGS.size(), _t]
	var pl = get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	if (pl as Node3D).global_position.distance_to(_rings[_next].global_position) < 2.4:
		_next += 1
		if _next >= RINGS.size():
			_finish()
		else:
			_highlight()
			GameState.say("Ring %d!" % _next)
	if _t > 120.0:
		_running = false
		for r in _rings:
			r.visible = false
		GameState.say("Course timed out. Try again.")
		_hint.text = "best %.1f s" % _best() if _best() > 0.0 else "no time yet"


func _finish() -> void:
	_running = false
	for r in _rings:
		r.visible = false
	var msg := "Course complete in %.1f s!  +12 coins" % _t
	GameState.coins += 12
	if _best() <= 0.0 or _t < _best():
		_set_best(_t)
		msg += "  New best!"
		GameState.add_marks(1, course_name + " record")
	GameState.add_ember(1)
	GameState.mark_dirty()
	GameState.say(msg)
	_hint.text = "best %.1f s" % _best()


func interact() -> void:
	pass
