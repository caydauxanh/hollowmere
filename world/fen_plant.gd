extends Node3D
## Fen's secret in the greenhouse corner: Isolde's old blue Moonpetal root.

var _bloom: MeshInstance3D
var _l: OmniLight3D

func _ready() -> void:
	add_to_group("interactable")
	var pot := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.35
	pm.bottom_radius = 0.28
	pm.height = 0.4
	pot.mesh = pm
	var potm := StandardMaterial3D.new()
	potm.albedo_color = Color(0.55, 0.35, 0.25)
	pot.material_override = potm
	pot.position.y = 0.2
	add_child(pot)
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.03
	sm.bottom_radius = 0.04
	sm.height = 0.5
	stem.mesh = sm
	var stm := StandardMaterial3D.new()
	stm.albedo_color = Color(0.3, 0.5, 0.4)
	stem.material_override = stm
	stem.position.y = 0.65
	add_child(stem)
	_bloom = MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.16
	bm.height = 0.32
	_bloom.mesh = bm
	var blm := StandardMaterial3D.new()
	blm.albedo_color = Color(0.35, 0.5, 1.0)
	blm.emission_enabled = true
	blm.emission = Color(0.3, 0.5, 1.0)
	blm.emission_energy_multiplier = 1.5
	_bloom.material_override = blm
	_bloom.position.y = 0.95
	_bloom.visible = false
	add_child(_bloom)
	_l = OmniLight3D.new()
	_l.light_color = Color(0.4, 0.55, 1.0)
	_l.omni_range = 4.0
	_l.light_energy = 0.0
	_l.position.y = 1.0
	add_child(_l)
	_refresh()

func _refresh() -> void:
	var open := GameState.quests_done.has("fen_bloom")
	_bloom.visible = open
	_l.light_energy = 1.2 if open else 0.0

func get_prompt() -> String:
	return "[F] A pot in the corner"

func build_dialogue() -> Dictionary:
	if GameState.quests_done.has("fen_bloom"):
		return {"pages": [["Blue Moonpetal", "Isolde's root, Mirabel's cutting, forty years apart, and this one is open in daylight. Fen says it is because somebody finally looked at it."]]}
	if GameState.friend_level("fen") >= 2 and GameState.friend_level("isolde") >= 1:
		GameState.quests_done["fen_bloom"] = true
		GameState.add_ember(3)
		GameState.add_marks(2, "The blue Moonpetal")
		GameState.add_friend("fen", 2)
		GameState.add_friend("isolde", 2)
		GameState.mark_dirty()
		_refresh()
		return {"pages": [["A pot in the corner", "Fen is beside you before you touch it. 'It's fine. It's probably fine. Watch.'"], ["Blue Moonpetal", "The bud opens. In daylight. Blue as the lake. Behind you Isolde says nothing at all for a long moment, and then: 'Tell Mirabel the roses survived. Tell her the root did too.'\n\n(+3 Ember, +2 Marks)"]]}
	return {"pages": [["A pot in the corner", "A clay pot with one tight blue bud. Someone has been watering it very carefully and hiding it very badly. (Fen's secret; become close friends with Fen, and friends with Isolde.)"]]}

func interact() -> void:
	pass
