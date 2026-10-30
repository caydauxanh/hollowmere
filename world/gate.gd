extends Node3D
## The Academy gate on the hill road. Opens when the village Ember is high enough.

var _light: OmniLight3D
var _beam: MeshInstance3D
var _open := false

func _ready() -> void:
	add_to_group("interactable")
	_light = OmniLight3D.new()
	_light.light_color = Color(0.7, 0.6, 1.0)
	_light.omni_range = 9.0
	_light.light_energy = 0.3
	_light.position.y = 3.5
	add_child(_light)
	_beam = MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 1.6
	c.height = 14.0
	_beam.mesh = c
	_beam.position.y = 7.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.55, 1.0, 0.18)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam.material_override = m
	_beam.visible = false
	add_child(_beam)
	GameState.ember_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_open = GameState.gate_open or GameState.ember >= Story.EMBER_GATE
	if _open and not GameState.gate_open:
		GameState.gate_open = true
		GameState.mark_dirty()
		GameState.say("The Academy gate hums and opens…")
	_light.light_energy = 2.5 if _open else 0.3
	_beam.visible = _open


func _process(_delta: float) -> void:
	if _open:
		_beam.rotation.y += 0.01


func get_prompt() -> String:
	if _open:
		return "[F] The road to Ashenvale Academy"
	return "The gate is sealed. Ember %d / %d" % [GameState.ember, Story.EMBER_GATE]


func build_dialogue() -> Dictionary:
	if _open:
		return {"pages": [["Ashenvale Gate", "The gate stands open. Beyond it the road climbs into the mist, toward the Academy."]], "enter_academy": true}
	return {"pages": [["Ashenvale Gate", "Old runes glow faintly on the stone. They pulse in time with the shrine candles.\n\nWarm the village Ember to %d and the gate will answer." % Story.EMBER_GATE]]}


func interact() -> void:
	pass
