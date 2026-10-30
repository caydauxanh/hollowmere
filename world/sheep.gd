extends Node3D
## A low-poly sheep built from primitives; wanders inside a pen.

var pen_center := Vector3.ZERO
var pen_radius := 6.0
var _target := Vector3.ZERO
var _wait := 0.0
var _body: Node3D
var is_lost_candidate := false
var _lost := false
var _following := false

func _ready() -> void:
	add_to_group("interactable")
	if is_lost_candidate:
		add_to_group("lost_sheep")
	_body = Node3D.new()
	add_child(_body)
	var wool := StandardMaterial3D.new()
	wool.albedo_color = Color(0.95, 0.93, 0.88)
	wool.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.2, 0.17, 0.18)
	var b := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.5
	bm.height = 0.8
	b.mesh = bm
	b.scale = Vector3(1.3, 1.0, 1.0)
	b.material_override = wool
	b.position = Vector3(0, 0.6, 0)
	_body.add_child(b)
	var h := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.32, 0.3, 0.4)
	h.mesh = hm
	h.material_override = dark
	h.position = Vector3(0, 0.72, 0.62)
	_body.add_child(h)
	for e in [-0.18, 0.18]:
		var ear := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = Vector3(0.14, 0.06, 0.18)
		ear.mesh = em
		ear.material_override = dark
		ear.position = Vector3(e, 0.86, 0.55)
		_body.add_child(ear)
	for lx in [-0.22, 0.22]:
		for lz in [-0.28, 0.28]:
			var leg := MeshInstance3D.new()
			var lm := CylinderMesh.new()
			lm.top_radius = 0.06
			lm.bottom_radius = 0.06
			lm.height = 0.4
			leg.mesh = lm
			leg.material_override = dark
			leg.position = Vector3(lx, 0.2, lz)
			_body.add_child(leg)
	_target = position
	_wait = randf_range(0.5, 3.0)

func wander_off() -> void:
	_lost = true
	_following = false
	var spots := [Vector3(48.0, 0, -44.0), Vector3(40.0, 0, 2.0), Vector3(52.0, 0, -20.0)]
	position = spots[randi() % spots.size()]
	_target = position


func get_prompt() -> String:
	if _lost and not _following:
		return "[F] The stubborn sheep"
	return "[F] Pet the sheep"

func get_action_anim() -> String:
	return "Interact"

func interact() -> void:
	if _lost and not _following:
		_following = true
		GameState.say("The sheep looks at you, decides, and follows. Lead it back to the pen at Ashford.")
		return
	GameState.say(["Baa.", "The sheep leans into your hand.", "It chews. It considers you. It chews.", "Soft. Very soft."][randi() % 4])
	if randf() < 0.15:
		GameState.add_ember(1)
		GameState.say("The sheep is pleased. +1 Ember")

func _process(delta: float) -> void:
	if _following:
		var pl := get_tree().get_first_node_in_group("player") as Node3D
		if pl:
			var tp := pl.global_position - position
			tp.y = 0.0
			if tp.length() > 2.2:
				position += tp.normalized() * minf(3.2 * delta, tp.length() - 2.0)
				_body.rotation.y = lerp_angle(_body.rotation.y, atan2(tp.x, tp.z), 5.0 * delta)
				_body.position.y = absf(sin(Time.get_ticks_msec() / 110.0)) * 0.05
			if position.distance_to(pen_center) < pen_radius + 1.5:
				_following = false
				_lost = false
				_target = pen_center
				GameState.sheep_day = Story.today_key()
				GameState.coins += 10
				GameState.add_ember(1)
				GameState.add_friend("nell", 2)
				GameState.add_marks(1, "The stubborn sheep")
				GameState.mark_dirty()
				GameState.say("Home. The sheep rejoins the flock as if nothing happened.  +10 coins, +1 Ember")
		return
	var to := _target - position
	to.y = 0.0
	if to.length() > 0.2:
		position += to.normalized() * minf(0.9 * delta, to.length())
		_body.rotation.y = lerp_angle(_body.rotation.y, atan2(to.x, to.z), 4.0 * delta)
		_body.position.y = absf(sin(Time.get_ticks_msec() / 120.0)) * 0.04
	else:
		_wait -= delta
		if _wait <= 0.0:
			var a := randf() * TAU
			_target = pen_center + Vector3(cos(a), 0, sin(a)) * randf() * pen_radius
			_wait = randf_range(1.0, 4.0)
