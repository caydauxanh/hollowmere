extends Node3D
## The apprentice's own cottage: the old apothecary, above the garden. Bed, cauldron, trophy shelf, a cat.

const DUN := "res://assets/kaykit/dungeon/"
const SCALE := 0.9
const T := 4.0 * SCALE

@onready var player: CharacterBody3D = $Player
@onready var cam_rig: Node3D = $CameraRig
var _shot_path := ""
var _shot_frames := 0


func _ready() -> void:
	_build_environment()
	_build_room(Vector3(0, 0, -4), 4, 3)
	_build_furniture()
	if GameState.spawn_at != Vector3.INF:
		player.global_position = GameState.spawn_at
		cam_rig.set_view(GameState.spawn_yaw, -0.45, 8.0)
		GameState.spawn_at = Vector3.INF
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		if arg.begins_with("--cam="):
			var v := arg.get_slice("=", 1).split(",")
			player.global_position = Vector3(float(v[0]), 0.1, float(v[1]))
			cam_rig.set_view(float(v[2]), float(v[3]) if v.size() > 3 else -0.42, float(v[4]) if v.size() > 4 else 8.0)


func _process(_delta: float) -> void:
	if _shot_path != "":
		_shot_frames += 1
		if _shot_frames == 100:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			get_tree().quit()


func _build_environment() -> void:
	var ground := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = WorldBoundaryShape3D.new()
	ground.add_child(col)
	ground.position.y = 0.05
	add_child(ground)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.035, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.5, 0.45)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.85, 0.7)
	key.light_energy = 0.7
	key.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-30), 0)
	key.shadow_enabled = true
	add_child(key)
	var hearth := OmniLight3D.new()
	hearth.light_color = Color(1.0, 0.65, 0.35)
	hearth.omni_range = 12.0
	hearth.light_energy = 1.6
	hearth.position = Vector3(-5.5, 1.5, -6.5)
	add_child(hearth)
	var win := OmniLight3D.new()
	win.light_color = Color(0.8, 0.9, 1.0)
	win.omni_range = 9.0
	win.light_energy = 0.9 if not GameState.is_night() else 0.3
	win.position = Vector3(4.0, 2.5, -8.0)
	add_child(win)


func _build_room(c: Vector3, w: int, d: int) -> void:
	var x0 := c.x - (w - 1) * T / 2.0
	var z0 := c.z - (d - 1) * T / 2.0
	for i in w:
		for j in d:
			_place(DUN + "floor_wood_large.gltf.glb", Vector3(x0 + i * T, 0, z0 + j * T), 0.0)
	var n_edge := c.z - d * T / 2.0
	var s_edge := c.z + d * T / 2.0
	var w_edge := c.x - w * T / 2.0
	var e_edge := c.x + w * T / 2.0
	for i in w:
		var x := x0 + i * T
		var north := "wall_window_open.gltf.glb" if i == 2 else "wall.gltf.glb"
		_place(DUN + north, Vector3(x, 0, n_edge), 0.0)
		_collider_box(Vector3(x, 3, n_edge), Vector3(T + 0.3, 6, 0.6))
		if i == 1:
			_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(x, 0, s_edge), PI)
		else:
			_place(DUN + "wall.gltf.glb", Vector3(x, 0, s_edge), PI)
			_collider_box(Vector3(x, 3, s_edge), Vector3(T + 0.3, 6, 0.6))
	for j in d:
		var z := z0 + j * T
		_place(DUN + ("wall_shelves.gltf.glb" if j == 1 else "wall.gltf.glb"), Vector3(w_edge, 0, z), PI / 2.0)
		_place(DUN + ("wall_archedwindow_open.gltf.glb" if j == 1 else "wall.gltf.glb"), Vector3(e_edge, 0, z), -PI / 2.0)
		_collider_box(Vector3(w_edge, 3, z), Vector3(0.6, 6, T + 0.3))
		_collider_box(Vector3(e_edge, 3, z), Vector3(0.6, 6, T + 0.3))
	for corner in [Vector3(w_edge, 0, n_edge), Vector3(e_edge, 0, n_edge), Vector3(w_edge, 0, s_edge), Vector3(e_edge, 0, s_edge)]:
		_place(DUN + "column.gltf.glb", corner, 0.0, 2.2)
	# exit door (south, middle)
	var door := Node3D.new()
	door.position = Vector3(x0 + T, 0, s_edge - 0.4)
	door.set_script(load("res://world/home_door.gd"))
	add_child(door)


func _build_furniture() -> void:
	# Bed (sleep) in the north-east corner
	_place(DUN + "bed_decorated.gltf.glb", Vector3(4.5, 0, -8.0), 0.0, 0.9)
	_collider_box(Vector3(4.5, 0.4, -8.0), Vector3(1.8, 0.8, 2.8))
	var bed := Node3D.new()
	bed.position = Vector3(4.5, 0, -6.4)
	bed.set_script(load("res://world/home_bed.gd"))
	add_child(bed)
	# Hearth (west) with brazier flame
	var br := Node3D.new()
	br.position = Vector3(-5.6, 0, -6.5)
	br.set_script(load("res://world/dark_lantern.gd"))
	br.setup("home_hearth")
	GameState.lanterns_lit["home_hearth"] = true
	add_child(br)
	_collider_box(Vector3(-5.6, 0.5, -6.5), Vector3(1.2, 1.0, 1.2))
	# Work table with bottles, a small cauldron, chest, trunk
	_place(DUN + "table_medium_decorated_A.gltf.glb", Vector3(-1.5, 0, -8.2), 0.0, 0.85)
	_collider_box(Vector3(-1.5, 0.5, -8.2), Vector3(2.0, 1.0, 1.4))
	_place(DUN + "bottle_A_labeled_green.gltf.glb", Vector3(-2.0, 0.8, -8.3), 0.0, 0.6)
	_place(DUN + "bottle_B_brown.gltf.glb", Vector3(-1.2, 0.8, -8.0), 0.4, 0.6)
	_place(DUN + "candle_lit.gltf.glb", Vector3(-0.6, 0.8, -8.4), 0.0, 0.6)
	var cup := Node3D.new()
	cup.position = Vector3(-1.0, 0.8, -7.7)
	cup.set_script(load("res://world/drink.gd"))
	add_child(cup)
	var caul := Node3D.new()
	caul.position = Vector3(-4.0, 0, -2.0)
	caul.set_script(load("res://world/cauldron.gd"))
	add_child(caul)
	_collider_box(Vector3(-4.0, 0.6, -2.0), Vector3(1.4, 1.2, 1.4))
	_place(DUN + "chest.glb", Vector3(5.2, 0, -1.5), -0.6, 0.8)
	_place(DUN + "trunk_medium_A.gltf.glb", Vector3(5.5, 0, -4.2), 0.0, 0.8)
	_place(DUN + "stool.gltf.glb", Vector3(-2.8, 0, -7.0), 0.3, 0.85)
	# Rug and trophy shelf (south-west)
	var rug := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(5.0, 0.03, 3.5)
	rug.mesh = rb
	rug.position = Vector3(0, 0.04, -3.5)
	rug.material_override = _mat(Color(0.5, 0.25, 0.25), 1.0)
	add_child(rug)
	var shelf := Node3D.new()
	shelf.position = Vector3(2.0, 0, -8.6)
	shelf.set_script(load("res://world/trophy_shelf.gd"))
	add_child(shelf)
	# The cat, if you have petted enough cats (friend of cats): just always here, asleep by the hearth
	var cat := CharacterBody3D.new()
	cat.position = Vector3(-4.0, 0, -5.0)
	cat.set_script(load("res://world/cat.gd"))
	cat.tint = Color(0.9, 0.6, 0.3)
	add_child(cat)
	for id in GameState.home_decor:
		var d: Dictionary = Story.HOME_DECOR[id]
		_place("res://assets/kaykit/" + d["model"], d["pos"], deg_to_rad(d["rot"]), d["scale"])
	# Order banner once sorted
	if GameState.order != "":
		_place(DUN + "banner_shield_%s.gltf.glb" % Story.ORDERS[GameState.order]["banner"], Vector3(0.0, 1.4, -9.3), 0.0, 0.9)


func _place(path: String, pos: Vector3, rot_y: float, s: float = SCALE) -> Node3D:
	var n: Node3D = load(path).instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * s
	add_child(n)
	return n


func _collider_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	col.shape = b
	body.position = center
	body.add_child(col)
	add_child(body)


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
