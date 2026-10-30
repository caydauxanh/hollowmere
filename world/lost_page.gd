extends Node3D
## A glowing catalogue page blown out of the Academy library.

var page_id := ""


func setup(id: String) -> void:
	page_id = id


func _ready() -> void:
	if GameState.pages_found.has(page_id):
		queue_free()
		return
	add_to_group("interactable")
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.65)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.97, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.85, 1.0)
	mat.emission_energy_multiplier = 1.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.material_override = mat
	m.position.y = 0.7
	add_child(m)
	var l := OmniLight3D.new()
	l.light_color = Color(0.8, 0.85, 1.0)
	l.omni_range = 3.0
	l.light_energy = 1.0
	l.position.y = 1.0
	add_child(l)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	position.y = sin(t * 2.0 + page_id.hash() % 7) * 0.12
	rotation.y += _delta * 0.8


func get_prompt() -> String:
	return "[F] Pick up the glowing page"


func interact() -> void:
	GameState.pages_found[page_id] = true
	GameState.mark_dirty()
	GameState.say("A page of Quill's catalogue.  (%d / %d)" % [GameState.pages_found.size(), Story.PAGES_TOTAL])
	queue_free()
