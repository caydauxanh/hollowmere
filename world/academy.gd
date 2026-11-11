extends Node3D
## Ashenvale Academy, ground floor: great hall, Hall of Flame (east), Greenhouse room (west).
## Built from the KayKit Dungeon set. Tile = 4 units × SCALE.

const DUN := "res://assets/kaykit/dungeon/"
const VillagerScript := preload("res://world/npc.gd")
const HerbPlotScript := preload("res://world/herb_plot.gd")
const SCALE := 0.9
const T := 4.0 * SCALE          # one floor tile

@onready var player: CharacterBody3D = $Player
@onready var cam_rig: Node3D = $CameraRig

var torches: Array[OmniLight3D] = []
var _candles: Array[Node3D] = []
var _shot_path := ""
var _shot_frames := 0


func _ready() -> void:
	Toon.apply.call_deferred(self)
	_build_environment()
	_build_room(Vector3(0, 0, -6), 5, 5, "hall")        # great hall, 18 × 18
	_build_room(Vector3(T * 4, 0, -4), 3, 3, "flame")   # east classroom
	_build_room(Vector3(-T * 4, 0, -4), 3, 3, "green")  # west classroom
	_build_room(Vector3(0, 0, -15 - T * 1.5), 3, 3, "library")  # north: library
	_build_room(Vector3(T * 3.5, 0, -15 - T * 1.5), 4, 3, "dorm")      # east of library: common room
	_build_room(Vector3(-T * 3.5, 0, -15 - T * 1.5), 4, 3, "potions")  # west of library: potions dungeon
	_build_room(Vector3(0, 0, -15 - T * 4.5), 3, 3, "tower")           # north of library: astronomy tower
	_build_room(Vector3(T * 7.0, 0, -15 - T * 1.5), 3, 3, "study")      # east of the common room: Headmistress's study
	_build_room(Vector3(-T * 6.5, 0, -15 - T * 1.5), 2, 2, "cellar")    # hidden cellar west of the potions dungeon
	_build_room(Vector3(T * 3.0, 0, -15 - T * 4.5), 3, 3, "annex")      # restricted shelves, east of the tower
	_build_doorways()
	_build_new_rooms()
	_build_furniture()
	_build_people()
	_build_exit()
	_build_floating_candles()
	for i in Story.PORTRAITS.size():
		var pt: Array = Story.PORTRAITS[i]
		var pn := Node3D.new()
		pn.position = [Vector3(-7.0, 2.2, -14.6), Vector3(0.0, 3.4, -14.6), Vector3(7.0, 2.2, -14.6)][i]
		pn.rotation.y = 0.0
		pn.set_script(load("res://world/painting.gd"))
		pn.setup(pt[0], pt[1], pt[2])
		add_child(pn)
	var lcat := CharacterBody3D.new()
	lcat.position = Vector3(3.0, 0, -22.5)
	lcat.set_script(load("res://world/cat.gd"))
	lcat.tint = Color(0.5, 0.45, 0.55)
	add_child(lcat)
	for cid in {"archivist": Vector3(-4.5, 0, -24.0), "stargazer": Vector3(4.0, 0, -34.0), "brewer": Vector3(-18.0, 0, -23.5), "founder_orders": Vector3(18.5, 0, -17.0)}:
		var ch := Node3D.new()
		ch.position = {"archivist": Vector3(-4.5, 0, -24.0), "stargazer": Vector3(4.0, 0, -34.0), "brewer": Vector3(-18.0, 0, -23.5), "founder_orders": Vector3(18.5, 0, -17.0)}[cid]
		ch.set_script(load("res://world/chest.gd"))
		ch.setup(cid)
		add_child(ch)
	var tt := Node3D.new()
	tt.position = Vector3(3.5, 0, 1.0)
	tt.set_script(load("res://world/landmark.gd"))
	tt.setup("Timetable", "08-11  Flamecraft — Professor Alder, Hall of Flame (east)\n11-14  Herbology — Professor Isolde, Greenhouse (west)\n14-17  Lore — Archivist Quill, Library (north)\n17-19  Evening Assembly — Headmistress Vance, Great Hall\n19-21  Potions — Master Corvin, Potions Dungeon (west of the library)\n21-24  Astronomy — Professor Lowe, Astronomy Tower (north of the library)\n\nTalk to the teacher in their room during the hour. Marks: %d (%s)" % [GameState.marks, Story.rank_for(GameState.marks)])
	add_child(tt)
	if GameState.spawn_at != Vector3.INF:
		player.global_position = GameState.spawn_at
		cam_rig.set_view(GameState.spawn_yaw, -0.42, 9.5)
		GameState.spawn_at = Vector3.INF
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
		if arg.begins_with("--cam="):
			var v := arg.get_slice("=", 1).split(",")
			player.global_position = Vector3(float(v[0]), 0.1, float(v[1]))
			cam_rig.set_view(float(v[2]), float(v[3]) if v.size() > 3 else -0.42, float(v[4]) if v.size() > 4 else 9.5)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in _candles.size():
		var c := _candles[i]
		c.position.y = 4.2 + sin(t * 0.8 + i * 1.3) * 0.35 + (i % 3) * 0.5
		c.rotation.y = t * 0.2 + i
	for i in torches.size():
		torches[i].light_energy = 1.3 + sin(t * 9.0 + i * 1.7) * 0.15
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
	env.background_color = Color(0.03, 0.025, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.38, 0.58)
	env.ambient_light_energy = 1.1
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.fog_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color(0.85, 0.75, 0.9)
	key.light_energy = 0.6
	key.rotation = Vector3(deg_to_rad(-60), deg_to_rad(30), 0)
	key.shadow_enabled = true
	add_child(key)


## A rectangular room centred at `c`, w × d tiles, with walls and corner columns.
func _build_room(c: Vector3, w: int, d: int, kind: String) -> void:
	var x0 := c.x - (w - 1) * T / 2.0
	var z0 := c.z - (d - 1) * T / 2.0
	for i in w:
		for j in d:
			_place(DUN + ("floor_wood_large.gltf.glb" if kind == "dorm" else "floor_tile_large.gltf.glb"), Vector3(x0 + i * T, 0, z0 + j * T), 0.0)
	var n_edge := c.z - d * T / 2.0
	var s_edge := c.z + d * T / 2.0
	var w_edge := c.x - w * T / 2.0
	var e_edge := c.x + w * T / 2.0
	for i in w:
		var x := x0 + i * T
		_wall(Vector3(x, 0, n_edge), 0.0, kind, i)
		_wall(Vector3(x, 0, s_edge), PI, kind, i + 10)
	for j in d:
		var z := z0 + j * T
		_wall(Vector3(w_edge, 0, z), PI / 2.0, kind, j + 20)
		_wall(Vector3(e_edge, 0, z), -PI / 2.0, kind, j + 30)
	for corner in [Vector3(w_edge, 0, n_edge), Vector3(e_edge, 0, n_edge), Vector3(w_edge, 0, s_edge), Vector3(e_edge, 0, s_edge)]:
		_place(DUN + "column.gltf.glb", corner, 0.0, 2.2)
	# Invisible collision box per wall tile (doorway tiles are left open)
	for i in w:
		var x := x0 + i * T
		for z in [n_edge, s_edge]:
			if not _is_doorway(Vector3(x, 0, z)):
				_wall_collider(Vector3(x, 0, z), Vector3(T + 0.3, 6, 0.6))
	for j in d:
		var z := z0 + j * T
		for x in [w_edge, e_edge]:
			if not _is_doorway(Vector3(x, 0, z)):
				_wall_collider(Vector3(x, 0, z), Vector3(0.6, 6, T + 0.3))


func _wall(pos: Vector3, rot: float, kind: String, idx: int) -> void:
	# Gaps for doorways are handled by _build_doorways (walls there are skipped).
	if _is_doorway(pos):
		return
	var model := "wall.gltf.glb"
	if kind == "tower":
		model = "wall_half.gltf.glb" if idx % 2 == 0 else "wall_archedwindow_open.gltf.glb"
	elif kind == "potions":
		model = "wall_shelves.gltf.glb" if idx % 3 == 1 else "wall.gltf.glb"
	elif idx % 3 == 1:
		model = "wall_archedwindow_open.gltf.glb" if kind in ["green", "dorm"] else "wall_arched.gltf.glb"
	var n := _place(DUN + model, pos, rot)
	n.position.y = 0.0
	if idx % 2 == 0:
		var torch := _place(DUN + "torch_mounted.gltf.glb", pos, rot, 0.9)
		torch.position += Vector3(sin(rot), 2.1, cos(rot)) * 0.45
		# Real lights only on a few torches (web renderer budget); the rest are decoration.
		if torches.size() < 9 and idx % 4 == 0 and kind in ["hall", "flame", "green"]:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.7, 0.4)
			l.omni_range = 9.0
			l.position = torch.position + Vector3(sin(rot), 0.4, cos(rot)) * 0.6
			add_child(l)
			torches.append(l)


const DOORS := [Vector3(2.5 * 3.6, 0, -4), Vector3(-2.5 * 3.6, 0, -4), Vector3(0, 0, 3.0), Vector3(0, 0, -15.0), Vector3(1.5 * 3.6, 0, -15 - 1.5 * 3.6), Vector3(-1.5 * 3.6, 0, -15 - 1.5 * 3.6), Vector3(0, 0, -15 - 3.0 * 3.6), Vector3(5.5 * 3.6, 0, -15 - 1.5 * 3.6), Vector3(-5.5 * 3.6, 0, -15 - 1.5 * 3.6 + 1.8), Vector3(1.5 * 3.6, 0, -15 - 4.5 * 3.6)]

func _is_doorway(pos: Vector3) -> bool:
	for d in DOORS:
		if pos.distance_to(d) < 2.2:
			return true
	return false


func _build_doorways() -> void:
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(T * 2.5, 0, -4), PI / 2.0)
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(-T * 2.5, 0, -4), -PI / 2.0)
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(0, 0, T * 2.5 - 6), PI)
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(0, 0, -15), 0.0)
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(T * 1.5, 0, -15 - T * 1.5), PI / 2.0)
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(-T * 1.5, 0, -15 - T * 1.5), -PI / 2.0)
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(0, 0, -15 - T * 3.0), 0.0)
	_place(DUN + "wall_doorway_sides.gltf.glb", Vector3(T * 5.5, 0, -15 - T * 1.5), PI / 2.0)
	# Carpet runner from the entrance to the Headmistress
	var rug := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(2.2, 0.03, 14.0)
	rug.mesh = b
	rug.position = Vector3(0, 0.04, -5.0)
	rug.material_override = _mat(Color(0.45, 0.12, 0.2), 0.95)
	add_child(rug)


func _build_furniture() -> void:
	# Great hall: banners, long tables, candles
	for x in [-6.5, 6.5]:
		for z in [-12.0, -8.0, -4.0, 0.0]:
			_place(DUN + "banner_patternA_blue.gltf.glb", Vector3(x, 1.0, z), 0.0, 0.8)
	_place(DUN + "table_long_tablecloth.gltf.glb", Vector3(-4.5, 0, -6), 0.0, 0.9)
	_place(DUN + "table_long_tablecloth.gltf.glb", Vector3(4.5, 0, -6), 0.0, 0.9)
	for z in [-7.5, -6.0, -4.5]:
		_place(DUN + "chair.gltf.glb", Vector3(-5.8, 0, z), PI / 2.0, 0.9)
		_place(DUN + "chair.gltf.glb", Vector3(5.8, 0, z), -PI / 2.0, 0.9)
	_place(DUN + "candle_triple.gltf.glb", Vector3(-4.5, 0.9, -6), 0.0, 0.8)
	_place(DUN + "candle_triple.gltf.glb", Vector3(4.5, 0.9, -6), 0.0, 0.8)
	_collider_box(Vector3(-4.5, 0.5, -6), Vector3(2.0, 1.0, 3.8))
	_collider_box(Vector3(4.5, 0.5, -6), Vector3(2.0, 1.0, 3.8))
	# Headmistress dais
	var dais := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(6.0, 0.3, 3.0)
	dais.mesh = db
	dais.position = Vector3(0, 0.15, -12.6)
	dais.material_override = _mat(Color(0.3, 0.28, 0.4), 0.9)
	add_child(dais)
	_place(DUN + "shelf_large.gltf.glb", Vector3(-3.5, 1.2, -14.5), 0.0, 0.9)
	_place(DUN + "shelf_large.gltf.glb", Vector3(3.5, 1.2, -14.5), 0.0, 0.9)
	# Library: shelves along the walls, five tomes, reading table
	var lz := -15.0 - T * 1.5
	for x in [-4.0, 0.0, 4.0]:
		_place(DUN + "shelf_large.gltf.glb", Vector3(x, 1.0, lz - 4.8), 0.0, 0.9)
		_place(DUN + "shelf_large.gltf.glb", Vector3(x, 2.2, lz - 4.8), 0.0, 0.9)
	_place(DUN + "table_medium_decorated_A.gltf.glb", Vector3(3.0, 0, lz + 1.0), 0.2, 0.8)
	_place(DUN + "candle_lit.gltf.glb", Vector3(-3.2, 0, lz + 2.0), 0.0, 0.8)
	_collider_box(Vector3(3.0, 0.5, lz + 1.0), Vector3(1.8, 1.0, 1.8))
	var ids := []
	for id in Story.BOOKS:
		if not Story.BOOKS[id].get("restricted", false):
			ids.append(id)
	for i in ids.size():
		var bk := Node3D.new()
		bk.position = Vector3(-4.0 + i * 2.0, 0.95, lz - 4.3)
		bk.set_script(load("res://world/book.gd"))
		bk.setup(ids[i])
		add_child(bk)
	var ll := OmniLight3D.new()
	ll.light_color = Color(0.75, 0.8, 1.0)
	ll.omni_range = 10.0
	ll.light_energy = 1.2
	ll.position = Vector3(0, 3.0, lz)
	add_child(ll)
	# Hall of Flame: brazier (practice target) + crates
	var brazier := _brazier(Vector3(T * 4 + 3.0, 0, -4))
	_place(DUN + "crates_stacked.gltf.glb", Vector3(T * 4 + 3.5, 0, -8.5), 0.4, 0.8)
	_place(DUN + "chest.glb", Vector3(T * 4 - 3.5, 0, -8.5), 0.8, 0.8)
	# Greenhouse: three practice beds
	for i in 3:
		var plot := HerbPlotScript.new()
		plot.setup(["whisperleaf", "emberroot", "moonpetal"][i], "academy_%d" % i)
		plot.position = Vector3(-T * 4 - 3.0 + i * 3.0, 0.1, -7.5)
		add_child(plot)
	var fenplant := Node3D.new()
	fenplant.position = Vector3(-T * 4 - 5.0, 0, -0.5)
	fenplant.set_script(load("res://world/fen_plant.gd"))
	add_child(fenplant)
	_place(DUN + "table_medium_decorated_A.gltf.glb", Vector3(-T * 4 + 3.5, 0, -0.5), 0.3, 0.8)
	_place(DUN + "bottle_A_green.gltf.glb", Vector3(-T * 4 + 3.3, 0.75, -0.6), 0.0, 0.6)
	_collider_box(Vector3(-T * 4 + 3.5, 0.5, -0.5), Vector3(1.8, 1.0, 1.8))
	_collider_box(brazier.position + Vector3(0, 0.5, 0), Vector3(1.2, 1.0, 1.2))


func _brazier(at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = at
	root.add_to_group("dark_lantern")
	root.set_script(load("res://world/dark_lantern.gd"))
	root.setup("academy_brazier")
	add_child(root)
	return root


func _build_people() -> void:
	for id in Story.NPCS:
		if Story.NPCS[id].get("scene", "village") == "academy" and not Story.NPCS[id].get("hidden", false):
			var v := VillagerScript.new()
			v.setup(id)
			add_child(v)


func _build_exit() -> void:
	var door := Node3D.new()
	door.position = Vector3(0, 0, T * 2.5 - 6 + 0.2)
	door.set_script(load("res://world/exit_door.gd"))
	add_child(door)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.7, 1.0)
	l.omni_range = 6.0
	l.light_energy = 1.0
	l.position = door.position + Vector3(0, 2.5, 0)
	add_child(l)


# ---------------------------------------------------------------- helpers

func _place(path: String, pos: Vector3, rot_y: float, s: float = SCALE) -> Node3D:
	var n: Node3D = load(path).instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * s
	add_child(n)
	return n


func _wall_collider(center: Vector3, size: Vector3) -> void:
	_collider_box(center + Vector3(0, size.y / 2.0, 0), size)


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


# ---------------------------------------------------------------- common room, potions dungeon, astronomy tower

func _build_new_rooms() -> void:
	var lz := -15.0 - T * 1.5
	# --- Common room (east): four beds, four Order banners, hearth, order board
	var dc := Vector3(T * 3.5, 0, lz)
	var i := 0
	for id in Story.ORDERS:
		var o: Dictionary = Story.ORDERS[id]
		var bx: float = dc.x - 4.5 + i * 3.0
		_place(DUN + "bed_decorated.gltf.glb", Vector3(bx, 0, lz - 3.8), 0.0, 0.85)
		_collider_box(Vector3(bx, 0.4, lz - 3.8), Vector3(1.6, 0.8, 2.6))
		_place(DUN + "banner_shield_%s.gltf.glb" % o["banner"], Vector3(bx, 1.4, lz - 5.1), 0.0, 0.9)
		_place(DUN + "trunk_small_A.gltf.glb", Vector3(bx + 0.9, 0, lz - 2.2), 0.3, 0.8)
		var bed := Node3D.new()
		bed.position = Vector3(bx, 0, lz - 2.6)
		bed.set_script(load("res://world/bed.gd"))
		bed.order_id = id
		add_child(bed)
		i += 1
	var hearth := _brazier(Vector3(dc.x + 6.2, 0, lz + 2.5))
	hearth.get_node("Tag").visible = false
	_collider_box(hearth.position + Vector3(0, 0.5, 0), Vector3(1.2, 1.0, 1.2))
	_place(DUN + "table_medium_tablecloth_decorated_B.gltf.glb", Vector3(dc.x, 0, lz + 2.5), 0.0, 0.85)
	_collider_box(Vector3(dc.x, 0.5, lz + 2.5), Vector3(2.4, 1.0, 1.4))
	for k in 3:
		_place(DUN + "stool.gltf.glb", Vector3(dc.x - 1.4 + k * 1.4, 0, lz + 3.9), 0.0, 0.85)
	_place(DUN + "shelves.gltf.glb", Vector3(dc.x - 6.6, 0, lz + 3.0), PI / 2.0, 0.85)
	var rug := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(8.0, 0.03, 4.0)
	rug.mesh = rb
	rug.position = Vector3(dc.x, 0.04, lz + 1.5)
	rug.material_override = _mat(Color(0.45, 0.18, 0.2), 1.0)
	add_child(rug)
	var board := Node3D.new()
	board.position = Vector3(dc.x + 6.4, 0, lz - 3.5)
	board.set_script(load("res://world/order_board.gd"))
	add_child(board)
	var cl := OmniLight3D.new()
	cl.light_color = Color(1.0, 0.75, 0.5)
	cl.omni_range = 11.0
	cl.light_energy = 1.1
	cl.position = Vector3(dc.x, 3.2, lz)
	add_child(cl)
	# --- Headmistress's study (east of the common room)
	var sc := Vector3(T * 7.0, 0, lz)
	_place(DUN + "table_long_decorated_A.gltf.glb", Vector3(sc.x, 0, lz - 2.5), 0.0, 0.85)
	_collider_box(Vector3(sc.x, 0.5, lz - 2.5), Vector3(3.6, 1.0, 1.4))
	_place(DUN + "chair.gltf.glb", Vector3(sc.x, 0, lz - 4.0), PI, 0.85)
	_place(DUN + "shelf_large.gltf.glb", Vector3(sc.x + 4.8, 1.0, lz - 1.0), -PI / 2.0, 0.9)
	_place(DUN + "shelf_large.gltf.glb", Vector3(sc.x + 4.8, 2.2, lz - 1.0), -PI / 2.0, 0.9)
	_place(DUN + "shelf_large.gltf.glb", Vector3(sc.x - 4.8, 1.0, lz + 1.0), PI / 2.0, 0.9)
	_place(DUN + "candle_triple.gltf.glb", Vector3(sc.x - 1.2, 0.95, lz - 2.5), 0.0, 0.8)
	_place(DUN + "banner_patternA_blue.gltf.glb", Vector3(sc.x, 1.0, lz - 5.2), 0.0, 0.8)
	_place(DUN + "chest_gold.glb", Vector3(sc.x + 3.5, 0, lz + 3.5), 0.6, 0.8)
	_place(DUN + "coin_stack_medium.gltf.glb", Vector3(sc.x + 1.3, 0.95, lz - 2.5), 0.0, 0.8)
	var rug2 := MeshInstance3D.new()
	var rb2 := BoxMesh.new()
	rb2.size = Vector3(5.0, 0.03, 5.0)
	rug2.mesh = rb2
	rug2.position = Vector3(sc.x, 0.04, lz + 0.5)
	rug2.material_override = _mat(Color(0.2, 0.22, 0.45), 1.0)
	add_child(rug2)
	var letter := Node3D.new()
	letter.position = Vector3(sc.x, 0.95, lz - 2.2)
	letter.set_script(load("res://world/letter.gd"))
	add_child(letter)
	var sl2 := OmniLight3D.new()
	sl2.light_color = Color(1.0, 0.8, 0.55)
	sl2.omni_range = 10.0
	sl2.light_energy = 1.0
	sl2.position = Vector3(sc.x, 3.0, lz)
	add_child(sl2)
	# --- Restricted shelves (annex east of the tower): three true books behind a gated door
	var ac := Vector3(T * 3.0, 0, -15.0 - T * 4.5)
	var gate := Node3D.new()
	gate.position = Vector3(T * 1.5, 0, ac.z)
	gate.set_script(load("res://world/annex_door.gd"))
	add_child(gate)
	for x in [-3.0, 0.0, 3.0]:
		_place(DUN + "shelf_large.gltf.glb", Vector3(ac.x + x, 1.0, ac.z - 4.8), 0.0, 0.9)
		_place(DUN + "shelf_large.gltf.glb", Vector3(ac.x + x, 2.2, ac.z - 4.8), 0.0, 0.9)
	var rids := []
	for id in Story.BOOKS:
		if Story.BOOKS[id].get("restricted", false):
			rids.append(id)
	for ri in rids.size():
		var rbook := Node3D.new()
		rbook.position = Vector3(ac.x - 3.0 + ri * 3.0, 0.95, ac.z - 4.3)
		rbook.set_script(load("res://world/book.gd"))
		rbook.setup(rids[ri])
		add_child(rbook)
	_place(DUN + "table_medium_decorated_A.gltf.glb", Vector3(ac.x, 0, ac.z + 2.0), 0.0, 0.8)
	_collider_box(Vector3(ac.x, 0.5, ac.z + 2.0), Vector3(1.8, 1.0, 1.8))
	_place(DUN + "candle_triple.gltf.glb", Vector3(ac.x, 0.9, ac.z + 2.0), 0.0, 0.8)
	var notes := Node3D.new()
	notes.position = Vector3(ac.x + 3.5, 0.0, ac.z + 3.0)
	notes.set_script(load("res://world/notes.gd"))
	add_child(notes)
	var al2 := OmniLight3D.new()
	al2.light_color = Color(0.9, 0.5, 0.4)
	al2.omni_range = 9.0
	al2.light_energy = 0.9
	al2.position = Vector3(ac.x, 2.8, ac.z)
	add_child(al2)
	# --- Hidden cellar: a sliding shelf in the dungeon's west wall, Mirabel's old bottle inside
	var cc := Vector3(-T * 6.5, 0, lz)
	var secret := Node3D.new()
	secret.position = Vector3(-T * 5.5, 0, lz + 1.8)
	secret.set_script(load("res://world/secret_shelf.gd"))
	add_child(secret)
	_place(DUN + "barrel_small_stack.gltf.glb", cc + Vector3(-2.0, 0, -2.0), 0.3, 0.8)
	_place(DUN + "crates_stacked.gltf.glb", cc + Vector3(1.8, 0, -2.2), 0.0, 0.7)
	_place(DUN + "table_small_decorated_B.gltf.glb", cc + Vector3(0.0, 0, 1.5), 0.0, 0.8)
	_collider_box(cc + Vector3(0.0, 0.5, 1.5), Vector3(1.2, 1.0, 1.2))
	var bottle := Node3D.new()
	bottle.position = cc + Vector3(0.0, 0.78, 1.5)
	bottle.set_script(load("res://world/old_bottle.gd"))
	add_child(bottle)
	var cl2 := OmniLight3D.new()
	cl2.light_color = Color(0.9, 0.7, 0.4)
	cl2.omni_range = 7.0
	cl2.light_energy = 0.7
	cl2.position = cc + Vector3(0, 2.4, 0)
	add_child(cl2)
	# --- Potions dungeon (west): class cauldron, bottle shelves, kegs, Corvin's desk
	var pc := Vector3(-T * 3.5, 0, lz)
	var caul := Node3D.new()
	caul.position = Vector3(pc.x, 0, lz + 1.0)
	caul.set_script(load("res://world/cauldron.gd"))
	add_child(caul)
	_collider_box(caul.position + Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.4))
	for k in 3:
		_place(DUN + "shelf_small_candles.gltf.glb", Vector3(pc.x - 6.6, 1.0 + k * 1.1, lz - 3.5 + k * 1.5), PI / 2.0, 0.85)
	_place(DUN + "shelves.gltf.glb", Vector3(pc.x + 2.0, 0, lz - 5.0), 0.0, 0.85)
	_place(DUN + "shelves.gltf.glb", Vector3(pc.x - 2.0, 0, lz - 5.0), 0.0, 0.85)
	for k in 6:
		var bm: String = ["bottle_A_green.gltf.glb", "bottle_B_brown.gltf.glb", "bottle_C_brown.gltf.glb", "bottle_A_labeled_green.gltf.glb", "bottle_B_green.gltf.glb", "bottle_A_labeled_brown.gltf.glb"][k]
		_place(DUN + bm, Vector3(pc.x - 2.8 + k * 1.1, 1.05, lz - 5.0), 0.0, 0.7)
	_place(DUN + "keg_decorated.gltf.glb", Vector3(pc.x + 5.5, 0, lz + 3.5), 0.4, 0.85)
	_place(DUN + "barrel_small_stack.gltf.glb", Vector3(pc.x + 5.8, 0, lz - 3.0), 0.0, 0.85)
	_place(DUN + "table_small_decorated_A.gltf.glb", Vector3(pc.x - 4.5, 0, lz + 3.5), 0.2, 0.85)
	_collider_box(Vector3(pc.x - 4.5, 0.5, lz + 3.5), Vector3(1.4, 1.0, 1.4))
	var gl2 := OmniLight3D.new()
	gl2.light_color = Color(0.55, 1.0, 0.6)
	gl2.omni_range = 10.0
	gl2.light_energy = 1.2
	gl2.position = Vector3(pc.x, 2.6, lz)
	add_child(gl2)
	# --- Astronomy tower (north): open to the sky, telescope, star-dome with the three constellations
	var tc := Vector3(0, 0, -15.0 - T * 4.5)
	var scope := Node3D.new()
	scope.position = tc + Vector3(-2.0, 0, -1.0)
	scope.set_script(load("res://world/telescope.gd"))
	add_child(scope)
	_collider_box(scope.position + Vector3(0, 0.6, 0), Vector3(1.2, 1.2, 1.2))
	_place(DUN + "table_small_decorated_B.gltf.glb", Vector3(tc.x + 4.0, 0, tc.z + 3.0), 0.0, 0.85)
	_collider_box(Vector3(tc.x + 4.0, 0.5, tc.z + 3.0), Vector3(1.4, 1.0, 1.4))
	_place(DUN + "candle_thin_lit.gltf.glb", Vector3(tc.x + 4.0, 0.8, tc.z + 3.0), 0.0, 0.7)
	var sky := Node3D.new()
	sky.position = tc + Vector3(0, 6.5, 0)
	add_child(sky)
	var ci := 0
	for id in Story.CONSTELLATIONS:
		var cst: Dictionary = Story.CONSTELLATIONS[id]
		var off: Vector3 = [Vector3(-4.5, 0, -2.0), Vector3(5.0, -1.0, 1.0), Vector3(0.0, 2.0, 3.5)][ci]
		for st in cst["stars"]:
			var m := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.12
			sm.height = 0.24
			m.mesh = sm
			var mm := StandardMaterial3D.new()
			mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mm.albedo_color = Color(1.0, 0.95, 0.8)
			m.material_override = mm
			m.position = off + Vector3(st.x, st.y * 0.4, st.y)
			sky.add_child(m)
		ci += 1
	for k in 60:
		var m2 := MeshInstance3D.new()
		var sm2 := SphereMesh.new()
		sm2.radius = 0.05
		sm2.height = 0.1
		m2.mesh = sm2
		var mm2 := StandardMaterial3D.new()
		mm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mm2.albedo_color = Color(0.8, 0.85, 1.0)
		m2.material_override = mm2
		m2.position = Vector3(randf_range(-9, 9), randf_range(-3, 3), randf_range(-9, 9))
		sky.add_child(m2)
	var sl := OmniLight3D.new()
	sl.light_color = Color(0.6, 0.65, 1.0)
	sl.omni_range = 12.0
	sl.light_energy = 0.9
	sl.position = tc + Vector3(0, 3.0, 0)
	add_child(sl)


## Floating candles over the great hall (no real lights; emissive flames only).
func _build_floating_candles() -> void:
	var wax := StandardMaterial3D.new()
	wax.albedo_color = Color(0.95, 0.9, 0.78)
	var flame := StandardMaterial3D.new()
	flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.albedo_color = Color(1.0, 0.8, 0.35)
	flame.emission_enabled = true
	flame.emission = Color(1.0, 0.6, 0.2)
	flame.emission_energy_multiplier = 2.0
	var g := RandomNumberGenerator.new()
	g.seed = 4
	for i in 26:
		var root := Node3D.new()
		var body := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.06
		cm.height = g.randf_range(0.3, 0.6)
		body.mesh = cm
		body.material_override = wax
		root.add_child(body)
		var f := MeshInstance3D.new()
		var fm := SphereMesh.new()
		fm.radius = 0.06
		fm.height = 0.16
		f.mesh = fm
		f.material_override = flame
		f.position.y = cm.height / 2.0 + 0.08
		root.add_child(f)
		root.position = Vector3(g.randf_range(-7.5, 7.5), 4.5, g.randf_range(-13.5, 1.5))
		add_child(root)
		_candles.append(root)
	var hl := OmniLight3D.new()
	hl.light_color = Color(1.0, 0.8, 0.5)
	hl.omni_range = 16.0
	hl.light_energy = 0.9
	hl.position = Vector3(0, 5.0, -6.0)
	add_child(hl)
