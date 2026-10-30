extends Node3D
## The Lantern & Ladle: Hollowmere's tavern. Evenings (18-21:30) the villagers gather here.

const DUN := "res://assets/kaykit/dungeon/"
const SCALE := 0.9
const T := 4.0 * SCALE
const VillagerScript := preload("res://world/npc.gd")

@onready var player: CharacterBody3D = $Player
@onready var cam_rig: Node3D = $CameraRig
var _shot_path := ""
var _shot_frames := 0
var _candles: Array[Node3D] = []


func _ready() -> void:
	_build_environment()
	_build_room(Vector3(0, 0, -5), 4, 4)
	_build_furniture()
	_build_people()
	if GameState.spawn_at != Vector3.INF:
		player.global_position = GameState.spawn_at
		cam_rig.set_view(GameState.spawn_yaw, -0.45, 9.0)
		GameState.spawn_at = Vector3.INF
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		if arg.begins_with("--cam="):
			var v := arg.get_slice("=", 1).split(",")
			player.global_position = Vector3(float(v[0]), 0.1, float(v[1]))
			cam_rig.set_view(float(v[2]), float(v[3]) if v.size() > 3 else -0.42, float(v[4]) if v.size() > 4 else 9.0)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in _candles.size():
		_candles[i].scale.y = 1.0 + sin(t * 9.0 + i) * 0.08
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
	env.background_color = Color(0.06, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.42, 0.35)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.8, 0.6)
	key.light_energy = 0.5
	key.rotation = Vector3(deg_to_rad(-60), deg_to_rad(20), 0)
	key.shadow_enabled = true
	add_child(key)


func _build_room(c: Vector3, w: int, d: int) -> void:
	var x0 := c.x - (w - 1) * T / 2.0
	var z0 := c.z - (d - 1) * T / 2.0
	for i in w:
		for j in d:
			_place(DUN + "floor_wood_large_dark.gltf.glb", Vector3(x0 + i * T, 0, z0 + j * T), 0.0)
	var n_edge := c.z - d * T / 2.0
	var s_edge := c.z + d * T / 2.0
	var w_edge := c.x - w * T / 2.0
	var e_edge := c.x + w * T / 2.0
	for i in w:
		var x := x0 + i * T
		_place(DUN + ("wall_shelves.gltf.glb" if i % 2 == 1 else "wall.gltf.glb"), Vector3(x, 0, n_edge), 0.0)
		_collider_box(Vector3(x, 3, n_edge), Vector3(T + 0.3, 6, 0.6))
		if i == 1:
			_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(x, 0, s_edge), PI)
		else:
			_place(DUN + ("wall_window_open.gltf.glb" if i == 3 else "wall.gltf.glb"), Vector3(x, 0, s_edge), PI)
			_collider_box(Vector3(x, 3, s_edge), Vector3(T + 0.3, 6, 0.6))
	for j in d:
		var z := z0 + j * T
		_place(DUN + ("wall_archedwindow_open.gltf.glb" if j % 2 == 0 else "wall.gltf.glb"), Vector3(w_edge, 0, z), PI / 2.0)
		_place(DUN + ("wall_archedwindow_open.gltf.glb" if j % 2 == 1 else "wall.gltf.glb"), Vector3(e_edge, 0, z), -PI / 2.0)
		_collider_box(Vector3(w_edge, 3, z), Vector3(0.6, 6, T + 0.3))
		_collider_box(Vector3(e_edge, 3, z), Vector3(0.6, 6, T + 0.3))
	for corner in [Vector3(w_edge, 0, n_edge), Vector3(e_edge, 0, n_edge), Vector3(w_edge, 0, s_edge), Vector3(e_edge, 0, s_edge)]:
		_place(DUN + "column.gltf.glb", corner, 0.0, 2.2)
	var door := Node3D.new()
	door.position = Vector3(x0 + T, 0, s_edge - 0.4)
	door.set_script(load("res://world/tavern_door.gd"))
	add_child(door)


func _build_furniture() -> void:
	# Bar along the north wall
	_place(DUN + "table_long.gltf.glb", Vector3(-2.0, 0, -10.0), 0.0, 0.9)
	_place(DUN + "table_long.gltf.glb", Vector3(2.0, 0, -10.0), 0.0, 0.9)
	_collider_box(Vector3(0, 0.5, -10.0), Vector3(8.0, 1.0, 1.4))
	for x in [-3.0, -1.5, 0.0, 1.5, 3.0]:
		_place(DUN + ["bottle_A_green.gltf.glb", "bottle_B_brown.gltf.glb", "bottle_C_brown.gltf.glb", "keg.gltf.glb", "plate_stack.gltf.glb"][int((x + 3.0) / 1.5)], Vector3(x, 0.85, -10.1), 0.0, 0.6)
	_place(DUN + "keg_decorated.gltf.glb", Vector3(-5.8, 0, -9.5), 0.3, 0.85)
	_place(DUN + "barrel_small_stack.gltf.glb", Vector3(5.8, 0, -9.5), 0.0, 0.85)
	# Hearth on the east wall
	var hearth := Node3D.new()
	hearth.position = Vector3(6.4, 0, -4.0)
	hearth.set_script(load("res://world/dark_lantern.gd"))
	hearth.setup("tavern_hearth")
	GameState.lanterns_lit["tavern_hearth"] = true
	add_child(hearth)
	_collider_box(Vector3(6.4, 0.5, -4.0), Vector3(1.2, 1.0, 1.2))
	# Three tables with stools, candles
	for tc in [Vector3(-3.5, 0, -4.0), Vector3(0.0, 0, -1.5), Vector3(3.0, 0, -5.5)]:
		_place(DUN + "table_medium_tablecloth.gltf.glb", tc, randf() * 0.4, 0.85)
		_collider_box(tc + Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 1.4))
		var cd := _place(DUN + "candle_lit.gltf.glb", tc + Vector3(0, 0.8, 0), 0.0, 0.7)
		_candles.append(cd)
		for off in [Vector3(-1.3, 0, 0.3), Vector3(1.3, 0, -0.3), Vector3(0.2, 0, 1.1)]:
			_place(DUN + "stool.gltf.glb", tc + off, randf() * TAU, 0.85)
	_place(DUN + "banner_patternC_red.gltf.glb", Vector3(-6.4, 1.3, -6.0), PI / 2.0, 0.9)
	_place(DUN + "banner_patternC_red.gltf.glb", Vector3(-6.4, 1.3, -2.0), PI / 2.0, 0.9)
	var rug := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(6.0, 0.03, 4.0)
	rug.mesh = rb
	rug.position = Vector3(0, 0.04, -3.0)
	rug.material_override = _mat(Color(0.45, 0.2, 0.18), 1.0)
	add_child(rug)
	for p in [Vector3(-3.5, 2.8, -4.0), Vector3(3.0, 2.8, -5.5), Vector3(0, 2.8, -1.5), Vector3(0, 2.8, -9.5)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.omni_range = 7.0
		l.light_energy = 0.9
		l.position = p
		add_child(l)
	var board := Node3D.new()
	board.position = Vector3(-6.3, 0, -8.5)
	board.set_script(load("res://world/tavern_board.gd"))
	add_child(board)
	var cat := Node3D.new()
	cat.position = Vector3(5.0, 0, -1.0)
	cat.set_script(load("res://world/cat.gd"))
	cat.tint = Color(0.3, 0.28, 0.32)
	add_child(cat)


func _build_people() -> void:
	for id in Story.NPCS:
		var d: Dictionary = Story.NPCS[id]
		if d.get("hidden", false):
			continue
		for e in d.get("schedule", []):
			if e.size() > 4 and str(e[4]) == "tavern":
				var v := VillagerScript.new()
				v.setup(id)
				add_child(v)
				break


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
