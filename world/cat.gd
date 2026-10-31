extends Walker
## A village cat built from primitives: naps, stretches, wanders a little, likes being petted.
## Walks with real collision (Walker), so it goes around furniture and legs instead of through them.

var home := Vector3.ZERO
var tint := Color(0.3, 0.28, 0.3)
var _target := Vector3.ZERO
var _wait := 0.0
var _body: Node3D
var _tail: MeshInstance3D
var _pets := 0
var companion := false   # the orange village cat: follows you once befriended

func _ready() -> void:
	add_to_group("interactable")
	home = position
	body_radius = 0.2
	body_height = 0.45
	walk_speed = 1.1
	turn_speed = 6.0
	if _col:
		(_col.shape as CapsuleShape3D).radius = body_radius
		(_col.shape as CapsuleShape3D).height = body_height
		_col.position.y = body_height * 0.5 + 0.02
	_body = Node3D.new()
	add_child(_body)
	skin = _body
	var fur := StandardMaterial3D.new()
	fur.albedo_color = tint
	fur.roughness = 1.0
	var b := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.16
	bm.height = 0.7
	b.mesh = bm
	b.rotation.x = PI / 2.0
	b.position = Vector3(0, 0.22, 0)
	b.material_override = fur
	_body.add_child(b)
	var h := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.15
	hm.height = 0.3
	h.mesh = hm
	h.material_override = fur
	h.position = Vector3(0, 0.34, 0.36)
	_body.add_child(h)
	for e in [-0.08, 0.08]:
		var ear := MeshInstance3D.new()
		var em := PrismMesh.new()
		em.size = Vector3(0.08, 0.1, 0.06)
		ear.mesh = em
		ear.material_override = fur
		ear.position = Vector3(e, 0.48, 0.34)
		_body.add_child(ear)
	_tail = MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.025
	tm.bottom_radius = 0.04
	tm.height = 0.45
	_tail.mesh = tm
	_tail.material_override = fur
	_tail.position = Vector3(0, 0.3, -0.4)
	_tail.rotation.x = -0.9
	_body.add_child(_tail)
	_target = position
	_wait = randf_range(2.0, 8.0)

func get_action_anim() -> String:
	return "Interact"

func interact() -> void:
	_pets += 1
	GameState.cat_pets += 1
	GameState.mark_dirty()
	GameState.say(["The cat permits it.", "Purring. Loud, for something so small.", "The cat rolls over, then regrets it.", "It headbutts your hand and walks away satisfied."][randi() % 4])
	if _pets % 5 == 0:
		GameState.add_ember(1)
		GameState.say("The cat is fond of you now. +1 Ember")
	if companion and GameState.cat_name == "" and GameState.cat_pets >= 15:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			var choices := []
			for nm in ["Ember", "Biscuit", "Moth", "Parsnip", "Quill Jr."]:
				choices.append({"label": nm, "enabled": true, "call": "name_cat", "arg": nm})
			hud.call_deferred("open_dialogue", self, {"pages": [["The orange cat", "It has decided. It is yours now, or you are its. It needs a name."]], "choices": choices})


func name_cat(nm: String) -> void:
	GameState.cat_name = nm
	GameState.add_ember(2)
	GameState.mark_dirty()
	GameState.say("%s follows you from now on (in the village). +2 Ember" % nm)


func get_prompt() -> String:
	return "[F] Pet %s" % GameState.cat_name if companion and GameState.cat_name != "" else "[F] Pet the cat"

func _process(delta: float) -> void:
	_tail.rotation.z = sin(Time.get_ticks_msec() / 350.0) * 0.4
	if companion and GameState.cat_name != "":
		var pl := get_tree().get_first_node_in_group("player") as Node3D
		if pl:
			var tp := pl.global_position - global_position
			tp.y = 0.0
			if tp.length() > 40.0:
				teleport(pl.global_position + Vector3(1.5, 0, 1.5))
			elif tp.length() > 3.0:
				walk_speed = 4.6 if tp.length() > 8.0 else 2.2
				go_to(pl.global_position - tp.normalized() * 2.2)
			elif tp.length() < 2.2 and is_walking():
				stop()
		return
	if is_walking():
		return
	_wait -= delta
	if _wait <= 0.0:
		var a := randf() * TAU
		var p := home + Vector3(cos(a), 0, sin(a)) * randf() * 3.5
		if _nav == null or not _nav.built or _nav.line_clear(global_position, p):
			walk_speed = 1.1
			go_to(p)
		_wait = randf_range(3.0, 10.0)


func _on_walk(_delta: float, speed: float) -> void:
	_body.position.y = absf(sin(Time.get_ticks_msec() / 110.0)) * 0.03 * clampf(speed, 0.0, 1.0)
