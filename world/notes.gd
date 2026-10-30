extends Node3D
## Lark's notes, left in the Restricted Shelves.

func _ready() -> void:
	if GameState.quests_done.has("lark_notes"):
		queue_free()
		return
	add_to_group("interactable")
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.3, 0.03, 0.22)
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.92, 0.8)
	m.material_override = mat
	m.position.y = 0.02
	add_child(m)
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.85, 1.0)
	l.omni_range = 2.0
	l.light_energy = 0.6
	l.position.y = 0.4
	add_child(l)

func get_prompt() -> String:
	return "[F] Someone's notes"

func get_action_anim() -> String:
	return "PickUp"

func interact() -> void:
	GameState.quests_done["lark_notes"] = true
	GameState.mark_dirty()
	GameState.say("A bundle of notes in a careful hand. 'L.' on the corner. Lark's.")
	queue_free()
