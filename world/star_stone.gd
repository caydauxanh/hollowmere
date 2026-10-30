extends Node3D
## The small star, come to rest on Festival Green after Chapter 7. Touch it once a day for Ember.

var _l: OmniLight3D
var _m: MeshInstance3D

func _ready() -> void:
	add_to_group("interactable")
	_m = MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(1.2, 1.8, 1.2)
	_m.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.6)
	mat.emission_energy_multiplier = 2.0
	_m.material_override = mat
	_m.position.y = 1.4
	add_child(_m)
	_l = OmniLight3D.new()
	_l.light_color = Color(1.0, 0.9, 0.7)
	_l.omni_range = 12.0
	_l.light_energy = 2.0
	_l.position.y = 2.0
	add_child(_l)
	var p := GPUParticles3D.new()
	p.amount = 30
	p.lifetime = 2.5
	var ppm := ParticleProcessMaterial.new()
	ppm.direction = Vector3.UP
	ppm.spread = 60.0
	ppm.initial_velocity_min = 0.3
	ppm.initial_velocity_max = 0.9
	ppm.gravity = Vector3.ZERO
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ppm.emission_sphere_radius = 1.2
	p.process_material = ppm
	p.draw_pass_1 = HerbPlot._spark_mesh(Color(1.0, 0.9, 0.6), 0.05)
	p.position.y = 1.2
	add_child(p)
	var tag := Label3D.new()
	tag.text = "Star Stone"
	tag.font_size = 36
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 10
	tag.outline_modulate = Color(0.1, 0.05, 0.0, 0.9)
	tag.modulate = Color(1.0, 0.95, 0.75)
	tag.position.y = 3.0
	add_child(tag)

func _process(delta: float) -> void:
	_m.rotation.y += delta * 0.6
	_m.position.y = 1.4 + sin(Time.get_ticks_msec() / 700.0) * 0.1

func get_prompt() -> String:
	return "[F] Touch the Star Stone"

func build_dialogue() -> Dictionary:
	if GameState.star_stone_day == Story.today_key():
		return {"pages": [["Star Stone", "Warm. It hums very quietly, like something content. Come back tomorrow."]]}
	GameState.star_stone_day = Story.today_key()
	GameState.add_ember(2)
	GameState.mark_dirty()
	return {"pages": [["Star Stone", "Warm. The hum climbs your arm and settles somewhere behind your ribs.  +2 Ember"]]}

func interact() -> void:
	pass
