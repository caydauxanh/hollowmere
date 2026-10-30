extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.forced_hour = 16.5
	by["ivy"].build_dialogue()
	var d: Dictionary = by["ivy"].build_dialogue(); print("ivy ask: ", d["pages"][0][1].substr(0, 30))
	GameState.shrine_smelled = true
	d = by["ivy"].build_dialogue(); print("ivy done: ", d["pages"][0][1].substr(0, 30), " favours=", GameState.favours.keys(), " marks=", GameState.marks)
	var notes = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.get_script().resource_path.find("notes.gd") >= 0)
	print("notes=", notes.size()); notes[0].interact()
	by["lark"].build_dialogue(); d = by["lark"].build_dialogue(); print("lark: ", d["pages"][0][1].substr(0, 30))
	get_tree().quit()
