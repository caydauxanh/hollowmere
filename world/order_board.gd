extends Node3D
## The Order points board in the common room.

func _ready() -> void:
	add_to_group("interactable")
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.1, 1.6, 2.2)
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.2, 0.3)
	m.material_override = mat
	m.position.y = 1.4
	add_child(m)
	var tag := Label3D.new()
	tag.text = "Order Points"
	tag.font_size = 34
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.5
	add_child(tag)

func get_prompt() -> String:
	return "[F] Read the Order board"

func build_dialogue() -> Dictionary:
	var pts := GameState.order_board()
	var lines := []
	var best := ""
	var bv := -1
	for id in Story.ORDERS:
		lines.append("%s — %d" % [Story.ORDERS[id]["name"], pts[id]])
		if pts[id] > bv:
			bv = pts[id]
			best = id
	var mine := ("Your Order: %s. Every Mark you earn is a point for them." % Story.ORDERS[GameState.order]["name"]) if GameState.order != "" else "You have not been sorted yet. Speak to the Headmistress."
	return {"pages": [["Order Points", "\n".join(lines) + "\n\nLeading: %s.  %s" % [Story.ORDERS[best]["name"], mine]]]}

func interact() -> void:
	pass
