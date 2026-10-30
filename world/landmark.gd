extends Node3D
## A point of interest with a short description (ruins, shrines, viewpoints).

var title := ""
var text := ""

func setup(t: String, body: String) -> void:
	title = t
	text = body

func _ready() -> void:
	add_to_group("interactable")
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.3
	s.height = 0.6
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.7, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.2
	m.material_override = mat
	m.position.y = 0.6
	add_child(m)

func get_prompt() -> String:
	return "[F] Look around: %s" % title

func build_dialogue() -> Dictionary:
	return {"pages": [[title, text]]}

func interact() -> void:
	pass
