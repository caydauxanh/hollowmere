extends Node3D
## Vạc pha thuốc: mỗi loại thảo dược 1 cây → 1 lọ Thuốc Ánh Sao.


var _brew_light: OmniLight3D
var _surface_mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("interactable")
	var pot := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.75
	cyl.bottom_radius = 0.55
	cyl.height = 0.9
	pot.mesh = cyl
	pot.position.y = 0.6
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.12, 0.11, 0.14)
	iron.metallic = 0.6
	iron.roughness = 0.45
	pot.material_override = iron
	add_child(pot)
	# Ba chân
	for i in 3:
		var leg := MeshInstance3D.new()
		var lc := CylinderMesh.new()
		lc.top_radius = 0.06
		lc.bottom_radius = 0.06
		lc.height = 0.3
		leg.mesh = lc
		var a := i * TAU / 3.0
		leg.position = Vector3(cos(a) * 0.45, 0.15, sin(a) * 0.45)
		leg.material_override = iron
		add_child(leg)
	# Mặt nước thuốc
	var surface := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.68
	disc.bottom_radius = 0.68
	disc.height = 0.02
	surface.mesh = disc
	surface.position.y = 0.98
	_surface_mat = StandardMaterial3D.new()
	_surface_mat.albedo_color = Color(0.4, 1.0, 0.6)
	_surface_mat.emission_enabled = true
	_surface_mat.emission = Color(0.3, 1.0, 0.5)
	_surface_mat.emission_energy_multiplier = 2.0
	surface.material_override = _surface_mat
	add_child(surface)

	_brew_light = OmniLight3D.new()
	_brew_light.light_color = Color(0.4, 1.0, 0.6)
	_brew_light.omni_range = 4.0
	_brew_light.light_energy = 1.0
	_brew_light.position.y = 1.4
	add_child(_brew_light)

	var bubbles := GPUParticles3D.new()
	bubbles.amount = 16
	bubbles.lifetime = 1.6
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.5
	pm.direction = Vector3.UP
	pm.spread = 10.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3.ZERO
	bubbles.process_material = pm
	bubbles.draw_pass_1 = HerbPlot._spark_mesh(Color(0.5, 1.0, 0.7))
	bubbles.position.y = 1.0
	add_child(bubbles)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	_brew_light.light_energy = 1.0 + sin(t * 3.0) * 0.25


func get_prompt() -> String:
	return "[F] Open the cauldron"


func can_brew(id: String) -> bool:
	for k in Story.RECIPES[id]["needs"]:
		if GameState.inventory.get(k, 0) < Story.RECIPES[id]["needs"][k]:
			return false
	return true


## Dialogue with one choice per recipe.
func build_dialogue() -> Dictionary:
	var choices := []
	for id in Story.RECIPES:
		var r: Dictionary = Story.RECIPES[id]
		if r.get("locked", false) and not GameState.recipes_unlocked.has(id):
			continue
		var parts := []
		for k in r["needs"]:
			parts.append("%d %s" % [r["needs"][k], GameState.ITEM_NAMES[k]])
		choices.append({"label": "%s  (%s)" % [r["name"], ", ".join(parts)], "enabled": can_brew(id), "recipe": id})
	return {"pages": [["Cauldron", "The brew bubbles green. What will you make?"]], "choices": choices}


func brew(id: String) -> void:
	if not can_brew(id):
		GameState.say("Not enough ingredients.")
		return
	for k in Story.RECIPES[id]["needs"]:
		GameState.take_item(k, Story.RECIPES[id]["needs"][k])
	GameState.add_item(id)
	GameState._brewed = true
	var gain := 3 if id == "elixir" else 1
	GameState.add_ember(gain)
	GameState.say("You brewed a %s!  +%d Ember" % [Story.RECIPES[id]["name"], gain])
	if get_tree().current_scene.name == "Academy":
		GameState.practical("potions", "brewing in the dungeon")
	var tw := create_tween()
	tw.tween_property(_brew_light, "light_energy", 6.0, 0.15)
	tw.tween_property(_brew_light, "light_energy", 1.0, 0.8)


func get_action_anim() -> String:
	return "Spellcast_Raise"


func interact() -> void:
	pass
