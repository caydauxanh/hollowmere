extends Node3D
## A paper lantern drifting high over a landmark. Fly through it on the broom.

var lantern_id := ""
var _base := Vector3.ZERO
var _l: OmniLight3D

func setup(id: String) -> void:
	lantern_id = id

func _ready() -> void:
	if GameState.sky_lanterns.has(lantern_id):
		queue_free()
		return
	_base = position
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.6
	cm.height = 1.1
	cm.radial_segments = 8
	m.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.3)
	mat.emission_energy_multiplier = 1.5
	m.material_override = mat
	add_child(m)
	_l = OmniLight3D.new()
	_l.light_color = Color(1.0, 0.7, 0.4)
	_l.omni_range = 6.0
	_l.light_energy = 1.0
	add_child(_l)
	var p := GPUParticles3D.new()
	p.amount = 8
	p.lifetime = 1.5
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3.ZERO
	p.process_material = pm
	p.draw_pass_1 = HerbPlot._spark_mesh(Color(1.0, 0.8, 0.4), 0.04)
	add_child(p)

func _process(_d: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	position = _base + Vector3(sin(t * 0.3) * 1.5, sin(t * 0.7) * 0.8, cos(t * 0.25) * 1.5)
	rotation.y += _d * 0.5
	var pl := get_tree().get_first_node_in_group("player")
	if pl and (pl as Node3D).global_position.distance_to(global_position) < 2.6:
		GameState.sky_lanterns[lantern_id] = true
		GameState.coins += 8
		GameState.add_ember(1)
		GameState.add_marks(1, "Sky lantern  (%d / %d)" % [GameState.sky_lanterns.size(), Story.SKY_LANTERNS.size()])
		if GameState.sky_lanterns.size() == Story.SKY_LANTERNS.size():
			GameState.coins += 50
			GameState.add_ember(4)
			GameState.say("All ten sky lanterns! Gorrin would be proud. (+50 coins, +4 Ember)")
		GameState.mark_dirty()
		queue_free()
