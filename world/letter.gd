extends Node3D
## The letter Wren carried up the hill on the Quiet Night. Readable once the Watchtower burns.

func _ready() -> void:
	add_to_group("interactable")
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.35, 0.02, 0.25)
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.9, 0.78)
	m.material_override = mat
	add_child(m)
	var seal := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.05
	sm.bottom_radius = 0.05
	sm.height = 0.02
	seal.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.7, 0.15, 0.15)
	seal.material_override = smat
	seal.position = Vector3(0.08, 0.02, 0.0)
	add_child(seal)

func get_prompt() -> String:
	return "[F] The unopened letter"

func build_dialogue() -> Dictionary:
	if not GameState.chapter5_done:
		return {"pages": [["The unopened letter", "A letter addressed to the Headmistress, sealed in red wax, nine years old. Oriel has not opened it. Neither will you."]]}
	if not GameState.quests_done.has("letter_read"):
		GameState.quests_done["letter_read"] = true
		GameState.add_ember(3)
		GameState.add_marks(2, "The Quiet Night letter")
		GameState.mark_dirty()
	return {"pages": [["The unopened letter", "The seal is broken now. Oriel opened it the night the Watchtower burned, and left it here for you."], ["From the Last Watchman", "Headmistress,\n\nThe fire is going out and I cannot say why. I have tried everything I know. If this reaches you, the lanterns below will be next.\n\nI am going up. Not down. Someone has to see what the Wheel is doing."], ["From the Last Watchman", "Tell whoever relights it: it was never a curse. It was a watch-fire with nobody left to watch it.\n\nKeep the Ember. Keep the school. Set a chair for Marrow; he will come down eventually.\n\n— the Watchman"]]}

func interact() -> void:
	pass
