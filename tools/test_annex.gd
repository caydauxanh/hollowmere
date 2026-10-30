extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var p: CharacterBody3D = v.get_node("Player")
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.chapter3_done = true
	by["quill"].build_dialogue(); var d: Dictionary = by["quill"].build_dialogue()
	print("quill low ember: ", d["pages"][0][1].substr(0, 40))
	GameState.ember = 30
	d = by["quill"].build_dialogue(); print("quill: ", d["pages"][0][1].substr(0, 40), " annex=", GameState.quests_done.has("annex"))
	var g = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("_unlock"))[0]
	d = g.build_dialogue(); print("gate: ", d["pages"][0][1].substr(0, 30))
	await get_tree().physics_frame
	p.global_position = Vector3(3.0, 0.1, -31.2)
	for i in 150: p.velocity = Vector3(4, -1, 0); p.move_and_slide(); await get_tree().physics_frame
	print("walked into annex x=", p.global_position.x)
	var rb = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.get("book_id") != null and str(n.book_id).begins_with("r_"))
	print("restricted books=", rb.size())
	for b in rb: b.build_dialogue()
	print("marks=", GameState.marks, " public read=", Story.public_books_read(), "/", Story.public_books_total())
	get_tree().quit()
