extends Node3D
## A readable tome on a library shelf.

var book_id := ""
var _glow: OmniLight3D


func setup(id: String) -> void:
	book_id = id


func _ready() -> void:
	add_to_group("interactable")
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.28, 0.4, 0.08)
	m.mesh = b
	var mat := StandardMaterial3D.new()
	var hues := {"founding": Color(0.7, 0.2, 0.2), "quiet": Color(0.2, 0.25, 0.6), "herbal": Color(0.25, 0.55, 0.3), "kindle": Color(0.9, 0.5, 0.2), "ember": Color(0.6, 0.45, 0.15)}
	mat.albedo_color = hues.get(book_id, Color(0.5, 0.4, 0.3))
	mat.roughness = 0.6
	m.material_override = mat
	m.position.y = 0.2
	add_child(m)
	var tag := Label3D.new()
	tag.text = Story.BOOKS[book_id]["title"]
	tag.font_size = 26
	tag.pixel_size = 0.005
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 0.75
	add_child(tag)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(0.8, 0.85, 1.0)
	_glow.omni_range = 1.5
	_glow.light_energy = 0.0 if GameState.books_read.has(book_id) else 0.8
	_glow.position.y = 0.5
	add_child(_glow)


func get_prompt() -> String:
	return "[F] Read \"%s\"" % Story.BOOKS[book_id]["title"]


func build_dialogue() -> Dictionary:
	var pages := []
	for pg in Story.BOOKS[book_id]["pages"]:
		pages.append([Story.BOOKS[book_id]["title"], pg])
	GameState.practical("lore", "reading in class")
	if not GameState.books_read.has(book_id):
		GameState.books_read[book_id] = true
		GameState.mark_dirty()
		_glow.light_energy = 0.0
		if Story.BOOKS[book_id].get("restricted", false):
			GameState.add_marks(2, "Restricted reading")
			GameState.add_ember(2)
			var all_r := true
			for id in Story.BOOKS:
				if Story.BOOKS[id].get("restricted", false) and not GameState.books_read.has(id):
					all_r = false
			pages.append(["", "You close the book, carefully. (+2 Marks, +2 Ember)" + ("\n\nAll three restricted books. You know, now, what the valley sent the small star for." if all_r else "")])
		else:
			pages.append(["", "You close the book. (%d / %d read)" % [Story.public_books_read(), Story.public_books_total()]])
	return {"pages": pages}


func interact() -> void:
	pass
