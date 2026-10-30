class_name HerbPlot
extends Node3D
## Một luống thảo dược. Cây lớn theo thời gian thật (lưu lại khi tắt game).
## Đến gần và bấm F để hái khi cây đã nở.

const HERBS := {
	"moonpetal": {"color": Color(0.55, 0.75, 1.0), "leaf": Color(0.35, 0.55, 0.6), "grow": 300.0, "night_only": true},
	"emberroot": {"color": Color(1.0, 0.5, 0.2), "leaf": Color(0.45, 0.5, 0.25), "grow": 240.0, "night_only": false},
	"whisperleaf": {"color": Color(0.5, 1.0, 0.7), "leaf": Color(0.3, 0.6, 0.35), "grow": 180.0, "night_only": false},
	"nightcap": {"color": Color(0.7, 0.45, 1.0), "leaf": Color(0.3, 0.25, 0.4), "grow": 420.0, "night_only": true},
	"sunbell": {"color": Color(1.0, 0.85, 0.3), "leaf": Color(0.5, 0.6, 0.3), "grow": 600.0, "night_only": false},
}
const PLANTS_PER_PLOT := 5

var herb_id := "whisperleaf"
var plot_key := ""

var _plants: Array[Node3D] = []
var _blooms: Array[MeshInstance3D] = []
var _light: OmniLight3D
var _sparkles: GPUParticles3D
var _stage := -1


func setup(id: String, key: String) -> void:
	herb_id = id
	plot_key = key


func _ready() -> void:
	add_to_group("interactable")
	if not GameState.plots.has(plot_key):
		# Luống mới: cho nở sẵn để người chơi có cái hái ngay lần đầu.
		GameState.plots[plot_key] = {"planted_at": GameState.now() - HERBS[herb_id]["grow"]}
	_build()
	_update_stage(true)


func _build() -> void:
	var info: Dictionary = HERBS[herb_id]
	# Đất
	var soil := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.6, 0.25, 1.2)
	soil.mesh = box
	soil.position.y = 0.12
	soil.material_override = _mat(Color(0.33, 0.22, 0.15), 0.95)
	add_child(soil)
	# Viền gỗ
	for side in [-1, 1]:
		var rim := MeshInstance3D.new()
		var rb := BoxMesh.new()
		rb.size = Vector3(2.8, 0.32, 0.12)
		rim.mesh = rb
		rim.position = Vector3(0, 0.16, side * 0.66)
		rim.material_override = _mat(Color(0.55, 0.38, 0.24), 0.8)
		add_child(rim)

	var leaf_mat := _mat(info["leaf"], 0.7)
	var bloom_mat := StandardMaterial3D.new()
	bloom_mat.albedo_color = info["color"]
	bloom_mat.emission_enabled = true
	bloom_mat.emission = info["color"]
	bloom_mat.emission_energy_multiplier = 1.6
	bloom_mat.roughness = 0.3

	for i in PLANTS_PER_PLOT:
		var plant := Node3D.new()
		plant.position = Vector3(-1.0 + i * 0.5, 0.25, (0.18 if i % 2 == 0 else -0.18))
		plant.rotation.y = i * 1.3
		add_child(plant)
		var stem := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.04
		cyl.height = 0.6
		stem.mesh = cyl
		stem.position.y = 0.3
		stem.material_override = leaf_mat
		plant.add_child(stem)
		for l in 3:
			var leaf := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.14
			sph.height = 0.28
			leaf.mesh = sph
			leaf.scale = Vector3(1.0, 0.25, 0.55)
			leaf.position = Vector3(cos(l * TAU / 3.0) * 0.13, 0.12 + l * 0.08, sin(l * TAU / 3.0) * 0.13)
			leaf.rotation.y = -l * TAU / 3.0
			leaf.material_override = leaf_mat
			plant.add_child(leaf)
		var bloom := MeshInstance3D.new()
		var bs := SphereMesh.new()
		bs.radius = 0.11
		bs.height = 0.2
		bloom.mesh = bs
		bloom.position.y = 0.62
		bloom.material_override = bloom_mat
		plant.add_child(bloom)
		_plants.append(plant)
		_blooms.append(bloom)

	_light = OmniLight3D.new()
	_light.light_color = info["color"]
	_light.omni_range = 3.0
	_light.light_energy = 0.0
	_light.position.y = 1.0
	add_child(_light)

	_sparkles = GPUParticles3D.new()
	_sparkles.amount = 24
	_sparkles.lifetime = 2.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.2, 0.2, 0.4)
	pm.direction = Vector3.UP
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	_sparkles.process_material = pm
	_sparkles.draw_pass_1 = _spark_mesh(info["color"])
	_sparkles.position.y = 0.8
	add_child(_sparkles)


func _process(_delta: float) -> void:
	_update_stage(false)
	# Hoa nhún nhẹ cho có sức sống
	var t := Time.get_ticks_msec() / 1000.0
	for i in _plants.size():
		_plants[i].rotation.z = sin(t * 1.4 + i) * 0.05


func growth() -> float:
	var planted: float = GameState.plots[plot_key]["planted_at"]
	return clampf((GameState.now() - planted) / HERBS[herb_id]["grow"], 0.0, 1.0)


func is_ready() -> bool:
	return growth() >= 1.0


func _update_stage(force: bool) -> void:
	var g := growth()
	var stage := 0 if g < 0.4 else (1 if g < 1.0 else 2)
	var s := lerpf(0.35, 1.0, g)
	for p in _plants:
		p.scale = Vector3.ONE * s
	if stage == _stage and not force:
		return
	_stage = stage
	for b in _blooms:
		b.visible = stage == 2
	_light.light_energy = 1.2 if stage == 2 else 0.0
	_sparkles.emitting = stage == 2


## Gọi từ HUD để hiển thị gợi ý.
func get_prompt() -> String:
	var name: String = GameState.ITEM_NAMES[herb_id]
	if not is_ready():
		var left: float = (1.0 - growth()) * float(HERBS[herb_id]["grow"])
		return "%s is growing… about %d min left" % [name, ceili(left / 60.0)]
	if HERBS[herb_id]["night_only"] and not GameState.is_night():
		return "%s only blooms after dark" % name
	return "[F] Harvest %s" % name


## Verdant spell: jump ahead half a growth cycle, once per bed per day.
func verdant() -> bool:
	var day := Story.today_key()
	if GameState.verdant_used.get(plot_key, "") == day:
		GameState.say("This bed has had enough magic for today.")
		return false
	if is_ready():
		GameState.say("It is already in bloom.")
		return false
	GameState.plots[plot_key]["planted_at"] -= HERBS[herb_id]["grow"] * 0.5
	GameState.verdant_used[plot_key] = day
	GameState.mark_dirty()
	_update_stage(true)
	GameState.say("%s stretches toward the light." % GameState.ITEM_NAMES[herb_id])
	if plot_key.begins_with("trial_"):
		GameState.add_marks(1, "Trial Field: Verdant")
	if plot_key.begins_with("academy_"):
		GameState.practical("herb", "Verdant in the Greenhouse")
	return true


func get_action_anim() -> String:
	return "PickUp"


func interact() -> void:
	if not is_ready():
		return
	if HERBS[herb_id]["night_only"] and not GameState.is_night():
		GameState.say("%s is asleep. Come back after dark." % GameState.ITEM_NAMES[herb_id])
		return
	GameState.add_item(herb_id, PLANTS_PER_PLOT)
	GameState.plots[plot_key]["planted_at"] = GameState.now()
	GameState.mark_dirty()
	GameState.say("+%d %s" % [PLANTS_PER_PLOT, GameState.ITEM_NAMES[herb_id]])
	_burst()
	_update_stage(true)


func _burst() -> void:
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 60.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, -2, 0)
	p.process_material = pm
	p.draw_pass_1 = _spark_mesh(HERBS[herb_id]["color"])
	p.position.y = 0.8
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func _spark_mesh(color: Color, radius: float = 0.035) -> SphereMesh:
	var q := SphereMesh.new()
	q.radius = radius
	q.height = radius * 2.0
	q.radial_segments = 8
	q.rings = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color.lightened(0.3)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 3.0
	q.material = m
	return q


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
