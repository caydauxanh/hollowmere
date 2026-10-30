extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.order = "moonquill"
	by["ivy"].build_dialogue()
	var d: Dictionary = by["ivy"].build_dialogue()
	print("ivy: ", d["pages"][0][1])
	GameState.lessons_done[Story.today_key() + "/lore/practical"] = 1
	GameState.lessons_done[Story.today_key() + "/flame/practical"] = 1
	d = by["ivy"].build_dialogue()
	print("ivy after: ", d["pages"][0][1].substr(0, 30), " marks=", GameState.marks)
	get_tree().quit()
