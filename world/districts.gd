extends Node3D
## Builds the four districts of Hollowmere around the old square:
## Hearth Row (homes, west), Lantern Market (east), Festival Green (south), Trial Field (north-west).
## Uses the village's helpers (_place, _collider, _mat, _night_light, _signpost, _cyl).

const HEX := "res://assets/kaykit/hex/"
const HAL := "res://assets/kaykit/halloween/"
const B := 5.0

var v: Node3D   # the village


func build(village: Node3D) -> void:
	v = village
	_hearth_row(Story.DISTRICTS["hearth"]["pos"])
	_market(Story.DISTRICTS["market"]["pos"])
	_festival_green(Story.DISTRICTS["green"]["pos"])
	_trial_field(Story.DISTRICTS["trial"]["pos"])
	for id in Story.DISTRICTS:
		var d: Dictionary = Story.DISTRICTS[id]
		var mark := Node3D.new()
		mark.position = d["pos"] + Vector3(0, 0, 3.5)
		mark.set_script(load("res://world/landmark.gd"))
		mark.setup(d["name"], d["text"])
		v.add_child(mark)
	v._signpost(Vector3(-16, 0, -1), "Hearth Row")
	v._signpost(Vector3(16, 0, -6), "Lantern Market")
	v._signpost(Vector3(1, 0, 18), "Festival Green")
	v._signpost(Vector3(-14, 0, -22), "Trial Field")


func _house(model: String, pos: Vector3, face_to: Vector3, s: float = B) -> Node3D:
	var h: Node3D = v._place(HEX + model, pos, s, atan2(face_to.x - pos.x, face_to.z - pos.z))
	v._collider(h, Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
	return h


func _fence_line(a: Vector3, b: Vector3, gate_at: int = -1) -> void:
	var n := int(a.distance_to(b) / 2.4)
	var dir := (b - a) / float(n)
	for i in n:
		var model := "buildings/neutral/fence_wood_straight_gate.gltf" if i == gate_at else "buildings/neutral/fence_wood_straight.gltf"
		var f: Node3D = v._place(HEX + model, a + dir * (i + 0.5), B * 0.5, atan2(dir.x, dir.z) + PI / 2.0)
		if i != gate_at:
			v._collider(f, Vector3(0, 0.3, 0), Vector3(1.0, 0.6, 0.2))


func _lamp(pos: Vector3) -> void:
	v._place(HAL + "lantern_standing.gltf", pos, 1.0, 0.0)
	var l: OmniLight3D = v._night_light(Color(1.0, 0.78, 0.45), 1.5, 8.0)
	l.position = pos + Vector3(0, 0.9, 0)
	v.add_child(l)


# ---------------------------------------------------------------- Hearth Row

func _hearth_row(c: Vector3) -> void:
	var models := ["buildings/red/building_home_A_red.gltf", "buildings/yellow/building_home_B_yellow.gltf", "buildings/red/building_home_B_red.gltf", "buildings/yellow/building_home_A_yellow.gltf", "buildings/red/building_home_A_red.gltf"]
	var spots := [Vector3(-9, 0, -7), Vector3(0, 0, -9), Vector3(9, 0, -7), Vector3(-8, 0, 6), Vector3(8, 0, 6)]
	for i in 5:
		var pos: Vector3 = c + spots[i]
		var h := _house(models[i], pos, c)
		var dir := (c - pos).normalized()
		var side := dir.rotated(Vector3.UP, PI / 2.0)
		if i % 2 == 0:
			v._place(HAL + "pumpkin_orange_small.gltf", pos + dir * 2.8 + side * 1.6, 0.6, randf() * TAU)
		else:
			v._place(HEX + "decoration/props/crate_B_small.gltf", pos + dir * 2.8 + side * 1.6, B * 0.7, randf() * TAU)
	var well := _house("buildings/yellow/building_well_yellow.gltf", c, c + Vector3(0, 0, 5), B * 0.85)
	v._place(HAL + "bench_decorated.gltf", c + Vector3(-3.5, 0, 2.5), 1.0, PI / 2.0)
	v._place(HAL + "bench_decorated.gltf", c + Vector3(3.5, 0, 2.5), 1.0, -PI / 2.0)
	# Washing lines between posts
	for k in 2:
		var a: Vector3 = c + Vector3(-12 + k * 20, 0, 0)
		var b: Vector3 = a + Vector3(0, 0, 5)
		for q in [a, b]:
			var post: MeshInstance3D = v._cyl(0.06, 0.06, 2.2, v._mat(Color(0.45, 0.3, 0.18), 0.9))
			post.position = q + Vector3(0, 1.1, 0)
			v.add_child(post)
		var line: MeshInstance3D = v._cyl(0.012, 0.012, 5.0, v._mat(Color(0.9, 0.9, 0.9), 1.0))
		line.position = (a + b) * 0.5 + Vector3(0, 2.1, 0)
		line.rotation.x = PI / 2.0
		v.add_child(line)
		for j in 4:
			var cloth := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.05, 0.7, 0.6)
			cloth.mesh = cm
			cloth.position = a + Vector3(0, 1.75, 0.8 + j * 1.1)
			cloth.material_override = v._mat([Color(0.9, 0.5, 0.5), Color(0.6, 0.7, 1.0), Color(1.0, 0.95, 0.7), Color(0.6, 0.9, 0.7)][j], 1.0)
			v.add_child(cloth)
	_fence_line(c + Vector3(-15, 0, -12), c + Vector3(15, 0, -12))
	_fence_line(c + Vector3(-15, 0, 11), c + Vector3(15, 0, 11), 6)
	_lamp(c + Vector3(-5, 0, -2))
	_lamp(c + Vector3(5, 0, -2))
	for pos in [Vector3(-15, 0, -3), Vector3(15, 0, 2), Vector3(-13, 0, 12), Vector3(13, 0, 12)]:
		v._tree("oak", c + pos, 1.1)


# ---------------------------------------------------------------- Lantern Market

func _market(c: Vector3) -> void:
	_house("buildings/red/building_market_red.gltf", c + Vector3(-5, 0, -4), c)          # Tamsin
	_house("buildings/yellow/building_market_yellow.gltf", c + Vector3(3, 0, -7), c)      # decor stall
	_house("buildings/green/building_market_green.gltf", c + Vector3(-2, 0, 7), c)
	_house("buildings/red/building_blacksmith_red.gltf", c + Vector3(7, 0, 5), c)        # Gorrin
	var forge: OmniLight3D = v._night_light(Color(1.0, 0.5, 0.2), 2.2, 7.0)
	forge.position = c + Vector3(6, 1.2, 3)
	v.add_child(forge)
	v._place(HEX + "decoration/props/tent.gltf", c + Vector3(-9, 0, 3), B, deg_to_rad(80))
	for i in 3:
		v._place(HEX + "decoration/props/crate_A_big.gltf", c + Vector3(-7 + i * 1.1, 0, -1.5), B * 0.7, randf() * 0.5)
	v._place(HEX + "decoration/props/sack.gltf", c + Vector3(-3.5, 0, -2), B * 0.8, 0.3)
	v._place(HEX + "decoration/props/sack.gltf", c + Vector3(-2.7, 0, -2.6), B * 0.8, 1.3)
	v._place(HEX + "decoration/props/wheelbarrow.gltf", c + Vector3(1, 0, -3.5), B * 0.8, deg_to_rad(200))
	v._place(HEX + "decoration/props/resource_lumber.gltf", c + Vector3(9, 0, 1), B * 0.8, 0.2)
	v._place(HEX + "decoration/props/bucket_water.gltf", c + Vector3(5, 0, 2), B * 0.8, 0.0)
	for i in 3:
		v._place(HEX + "decoration/props/flag_%s.gltf" % ["red", "yellow", "green"][i], c + Vector3(-6 + i * 6, 0, -10), B, 0.0)
	var market := Node3D.new()   # decorations stall (moved here from the square)
	market.position = c + Vector3(3, 0, -4.2)
	market.set_script(load("res://world/market.gd"))
	v.add_child(market)
	_lamp(c + Vector3(-1, 0, 1))
	_lamp(c + Vector3(11, 0, -4))
	_bunting(c + Vector3(-9, 3.2, -9), c + Vector3(9, 3.2, -9))
	_bunting(c + Vector3(-9, 3.2, -9), c + Vector3(-9, 3.2, 8))


# ---------------------------------------------------------------- Festival Green

func _festival_green(c: Vector3) -> void:
	# Maypole with ribbons
	var pole: MeshInstance3D = v._cyl(0.12, 0.14, 7.0, v._mat(Color(0.85, 0.8, 0.7), 0.9))
	pole.position = c + Vector3(0, 3.5, 0)
	v.add_child(pole)
	v._collider(pole, Vector3(0, 0, 0), Vector3(0.4, 1.0, 0.4))
	for i in 8:
		var a := i * TAU / 8.0
		var rib := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.08, 7.6, 0.01)
		rib.mesh = rm
		var end := c + Vector3(cos(a) * 3.2, 0.5, sin(a) * 3.2)
		var top := c + Vector3(0, 7.0, 0)
		rib.position = (top + end) * 0.5
		rib.basis = Basis.looking_at((end - top).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, -PI / 2.0)
		rib.material_override = v._mat([Color(1.0, 0.4, 0.4), Color(1.0, 0.85, 0.3), Color(0.4, 0.8, 1.0), Color(0.6, 1.0, 0.6)][i % 4], 1.0)
		v.add_child(rib)
	# Bonfire ring
	var fire := c + Vector3(-9, 0, 4)
	for i in 8:
		var a := i * TAU / 8.0
		v._place(HEX + "decoration/nature/rock_single_%s.gltf" % ["A", "B", "C"][i % 3], fire + Vector3(cos(a) * 1.6, 0, sin(a) * 1.6), B * 0.5, a)
	var logs: Node3D = v._place(HEX + "decoration/props/resource_lumber.gltf", fire, B * 0.6, 0.4)
	var fl: OmniLight3D = v._night_light(Color(1.0, 0.55, 0.25), 2.5, 10.0)
	fl.position = fire + Vector3(0, 1.0, 0)
	v.add_child(fl)
	var fp: GPUParticles3D = v._particles(Color(1.0, 0.6, 0.3), 24, 1.2, 0.05)
	fp.position = fire + Vector3(0, 0.5, 0)
	v.add_child(fp)
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		v._place(HAL + "bench_decorated.gltf", fire + Vector3(cos(a) * 3.6, 0, sin(a) * 3.6), 1.0, -a - PI / 2.0)
	# Lily pond with stepping stones
	var pc := c + Vector3(11, 0, 5)
	var pond := WaterBody.make(Vector2(12, 9), 12, true)
	pond.position = pc + Vector3(0, 0.08, 0)
	v.add_child(pond)
	v._water_collider(pc, Vector3(10, 2, 7))
	for i in 5:
		v._place(HEX + "decoration/nature/waterlily_%s.gltf" % ["A", "B"][i % 2], pc + Vector3(-4 + i * 2.0, 0.02, (i % 2) * 2.0 - 1.0), B, randf() * TAU)
	for i in 6:
		var st: MeshInstance3D = v._cyl(0.55, 0.6, 1.4, v._mat(Color(0.6, 0.6, 0.62), 0.95))
		st.position = pc + Vector3(-4.5 + i * 1.8, 0.1, sin(i * 1.3) * 1.2)
		v.add_child(st)
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 0.6
		cs.height = 1.6
		col.shape = cs
		body.add_child(col)
		body.position = st.position
		v.add_child(body)
	for i in 10:
		var a := i * TAU / 10.0
		v._place(HEX + "decoration/nature/waterplant_%s.gltf" % ["A", "B"][i % 2], pc + Vector3(cos(a) * 6.3, 0, sin(a) * 4.8), B, randf() * TAU)
	if GameState.chapter7_done:
		var ss := Node3D.new()
		ss.position = c + Vector3(-3, 0, 3)
		ss.set_script(load("res://world/star_stone.gd"))
		v.add_child(ss)
	var ct := Node3D.new()
	ct.position = c + Vector3(-10, 0, -4)
	ct.set_script(load("res://world/contest.gd"))
	v.add_child(ct)
	# Broom course
	var bc := Node3D.new()
	bc.position = c + Vector3(-6, 0, -10)
	bc.set_script(load("res://world/broom_course.gd"))
	v.add_child(bc)
	# Spark Targets
	var tg := Node3D.new()
	tg.position = c + Vector3(6, 0, -8)
	tg.set_script(load("res://world/targets.gd"))
	v.add_child(tg)
	for i in 5:
		v._place(HAL + "pumpkin_orange_small.gltf", c + Vector3(-14 + i * 1.2, 0, -8 + sin(i) * 0.6), 0.7, randf() * TAU)
	_lamp(c + Vector3(-4, 0, -4))
	_lamp(c + Vector3(5, 0, 9))
	for k in 6:
		var a := k * TAU / 6.0
		_bunting(c + Vector3(0, 6.8, 0), c + Vector3(cos(a) * 11.0, 3.0, sin(a) * 11.0))
		var post: MeshInstance3D = v._cyl(0.06, 0.07, 3.0, v._mat(Color(0.45, 0.3, 0.18), 0.9))
		post.position = c + Vector3(cos(a) * 11.0, 1.5, sin(a) * 11.0)
		v.add_child(post)


# ---------------------------------------------------------------- Trial Field

func _trial_field(c: Vector3) -> void:
	_fence_line(c + Vector3(-11, 0, -8), c + Vector3(11, 0, -8))
	_fence_line(c + Vector3(-11, 0, 8), c + Vector3(11, 0, 8), 4)
	_fence_line(c + Vector3(-11, 0, -8), c + Vector3(-11, 0, 8))
	_fence_line(c + Vector3(11, 0, -8), c + Vector3(11, 0, 8))
	for i in 3:
		var d := Node3D.new()
		d.position = c + Vector3(-6 + i * 6, 0, -5)
		d.set_script(load("res://world/dark_lantern.gd"))
		d.setup("trial_%d" % i, true)
		v.add_child(d)
	for i in 3:
		var plot := HerbPlot.new()
		plot.setup(["whisperleaf", "emberroot", "moonpetal"][i], "trial_%d" % i)
		plot.position = c + Vector3(-6 + i * 6, 0.1, 4)
		v.add_child(plot)
	var rack: Node3D = v._place(HEX + "decoration/props/weaponrack.gltf", c + Vector3(-9.5, 0, 0), B * 0.8, PI / 2.0)
	v._collider(rack, Vector3(0, 0.3, 0), Vector3(0.3, 0.6, 1.0))
	for i in 2:
		var t: Node3D = v._place(HEX + "decoration/props/target.gltf", c + Vector3(9.5, 0, -3 + i * 6), B, -PI / 2.0)
		v._collider(t, Vector3(0, 0.3, 0), Vector3(0.3, 0.6, 0.6))
	v._place(HEX + "decoration/props/flag_blue.gltf", c + Vector3(-11, 0, -8), B, 0.0)
	v._place(HEX + "decoration/props/flag_blue.gltf", c + Vector3(11, 0, -8), B, 0.0)
	var duel := Node3D.new()
	duel.position = c + Vector3(0, 0, -1.5)
	duel.set_script(load("res://world/duel.gd"))
	v.add_child(duel)
	_lamp(c + Vector3(-3, 0, 1))


## A line of little triangular flags between two points.
func _bunting(a: Vector3, b: Vector3) -> void:
	var line: MeshInstance3D = v._cyl(0.012, 0.012, a.distance_to(b), v._mat(Color(0.85, 0.8, 0.7), 1.0))
	line.position = (a + b) * 0.5
	line.basis = Basis.looking_at((b - a).normalized(), Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT) * Basis(Vector3.RIGHT, -PI / 2.0)
	v.add_child(line)
	var n := int(a.distance_to(b) / 0.9)
	for i in n:
		var t := (i + 0.5) / float(n)
		var p := a.lerp(b, t) + Vector3(0, -0.22 - sin(t * PI) * 0.35, 0)
		var f := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.34, 0.4, 0.02)
		f.mesh = pm
		f.position = p
		var side := (b - a).cross(Vector3.UP).normalized()
		if side.length() < 0.1:
			side = Vector3.RIGHT
		f.basis = Basis.looking_at(side, Vector3.UP) * Basis(Vector3.RIGHT, PI)
		f.material_override = v._mat([Color(1.0, 0.4, 0.4), Color(1.0, 0.85, 0.3), Color(0.4, 0.75, 1.0), Color(0.5, 0.95, 0.6), Color(1.0, 0.6, 0.9)][i % 5], 1.0)
		v.add_child(f)
