extends Node3D
## A lantern that went dark in the Quiet. Kindle lights it (and keeps it lit).

var lantern_id := ""
var trial := false   # Trial Field brazier: resets daily, earns a Mark instead of Ember
var _light: OmniLight3D
var _glow: GPUParticles3D


func setup(id: String, is_trial: bool = false) -> void:
	lantern_id = id
	trial = is_trial


func _key() -> String:
	return lantern_id + ("@" + Story.today_key() if (trial or lantern_id == "academy_brazier") else "")


func _ready() -> void:
	add_to_group("dark_lantern")
	var m: Node3D = load("res://assets/kaykit/halloween/lantern_standing.gltf").instantiate()
	m.scale = Vector3.ONE * 1.1
	add_child(m)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.75, 0.4)
	_light.omni_range = 7.0
	_light.light_energy = 0.0
	_light.position.y = 0.9
	add_child(_light)
	_glow = GPUParticles3D.new()
	_glow.amount = 10
	_glow.lifetime = 1.5
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3.ZERO
	_glow.process_material = pm
	_glow.draw_pass_1 = HerbPlot._spark_mesh(Color(1.0, 0.8, 0.4), 0.03)
	_glow.position.y = 0.9
	_glow.emitting = false
	add_child(_glow)
	# Faint cold shimmer so the player can spot it
	var tag := Label3D.new()
	tag.text = "cold brazier" if trial else "dark lantern"
	tag.font_size = 30
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.modulate = Color(0.6, 0.65, 0.9, 0.8)
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.8)
	tag.position.y = 1.5
	tag.name = "Tag"
	add_child(tag)
	if GameState.lanterns_lit.has(_key()):
		_set_lit(true, false)


func is_lit() -> bool:
	return GameState.lanterns_lit.has(_key())


func _process(_d: float) -> void:
	if (trial or lantern_id == "academy_brazier") and _glow.emitting and not is_lit():
		_set_lit(false, false)   # a new day: the brazier is cold again


func kindle() -> bool:
	if is_lit():
		return false
	GameState.lanterns_lit[_key()] = true
	GameState.mark_dirty()
	_set_lit(true, true)
	if trial:
		GameState.add_marks(1, "Trial Field: Kindle")
		return true
	if lantern_id == "academy_brazier":
		GameState.practical("flame", "the Hall of Flame brazier")
	if lantern_id == "isle":
		if not GameState.chapter5_done or not GameState.is_night():
			GameState.lanterns_lit.erase(_key())
			_set_lit(false, false)
			GameState.say("The isle lantern sputters. It wants the Watchtower lit first, and the dark of night." if not GameState.chapter5_done else "The isle lantern only takes a flame after dark.")
			return true
		GameState.add_ember(5)
		GameState.coins += 40
		GameState.chapter6_done = true
		GameState.mark_dirty()
		GameState.say("Lake Mirren glows to its floor. Something shy turns over and sleeps on.  +5 Ember  +40 coins — Chapter 6: speak to Marrow.")
		return true
	if lantern_id == "watchtower":
		if not GameState.chapter4_done:
			GameState.lanterns_lit.erase(_key())
			_set_lit(false, false)
			GameState.say("The brazier flares and dies. Something above it is not ready. (Find all three constellations first.)")
			return true
		GameState.add_ember(4)
		GameState.coins += 30
		GameState.chapter5_done = true
		GameState.mark_dirty()
		GameState.say("The Watchtower burns again. Far above, Ashen's Wheel turns.  +4 Ember  +30 coins — Chapter 5: tell the Headmistress.")
		return true
	GameState.add_ember(1)
	GameState.say("The lantern wakes.  +1 Ember   (%d / %d)" % [GameState.village_lanterns_lit(), Story.DARK_LANTERNS])
	return true


func _set_lit(lit: bool, animate: bool) -> void:
	_glow.emitting = lit
	get_node("Tag").visible = not lit
	if animate:
		var tw := create_tween()
		tw.tween_property(_light, "light_energy", 3.5, 0.2)
		tw.tween_property(_light, "light_energy", 1.4, 0.8)
	else:
		_light.light_energy = 1.4 if lit else 0.0
