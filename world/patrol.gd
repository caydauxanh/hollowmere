extends Node3D
## Night Patrol: four lantern posts to visit in order, started by Sir Pellam after 22:00.

const POSTS := [Vector3(-35, 0, -9), Vector3(31, 0, -9), Vector3(2, 0, 28), Vector3(-30, 0, -32)]
const NAMES := ["Hearth Row", "Lantern Market", "Festival Green", "Trial Field"]
var _running := false
var _next := 0
var _t := 0.0
var _marker: MeshInstance3D
var _l: OmniLight3D

func _ready() -> void:
	add_to_group("patrol")
	_marker = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.4
	tm.outer_radius = 1.8
	_marker.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.6, 0.8, 1.0, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker.material_override = m
	_marker.rotation.x = PI / 2.0
	_marker.visible = false
	add_child(_marker)
	_l = OmniLight3D.new()
	_l.light_color = Color(0.6, 0.8, 1.0)
	_l.omni_range = 8.0
	_l.light_energy = 0.0
	add_child(_l)

func start() -> void:
	_running = true
	_next = 0
	_t = 180.0
	_place()

func _place() -> void:
	_marker.global_position = POSTS[_next] + Vector3(0, 0.3, 0)
	_marker.visible = true
	_l.global_position = POSTS[_next] + Vector3(0, 2.5, 0)
	_l.light_energy = 2.0
	GameState.say("Patrol: next post, %s.  (%d / 4)" % [NAMES[_next], _next + 1])

func _process(delta: float) -> void:
	if not _running:
		return
	_t -= delta
	_marker.rotation.z += delta
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	if pl and pl.global_position.distance_to(POSTS[_next]) < 3.5:
		_next += 1
		if _next >= POSTS.size():
			_finish(true)
		else:
			_place()
	if _t <= 0.0:
		_finish(false)

func _finish(ok: bool) -> void:
	_running = false
	_marker.visible = false
	_l.light_energy = 0.0
	if ok:
		GameState.patrol_day = Story.today_key()
		GameState.coins += 20
		GameState.add_ember(2)
		GameState.add_marks(2, "Night Patrol")
		GameState.add_friend("pellam", 2)
		GameState.mark_dirty()
		GameState.say("Patrol complete in %d s. Pellam will be unbearable about it.  +20 coins, +2 Ember" % int(180.0 - _t))
	else:
		GameState.say("Patrol timed out. The lanterns kept themselves tonight.")
