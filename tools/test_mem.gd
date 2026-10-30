extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.friendship["pip"] = 8
	by["pip"].build_dialogue()
	var d: Dictionary = by["pip"].build_dialogue()
	print("pip pages=", d["pages"].size(), " heard=", GameState.memories_heard.has("pip"), " first=", d["pages"][0][1].substr(0,30))
	GameState.recipes_unlocked["oil"] = true
	GameState.add_item("whisperleaf", 1); GameState.add_item("minnow", 1)
	var c = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("brew"))[0]
	print("can brew oil=", c.can_brew("oil"))
	c.brew("oil")
	print("oil=", GameState.inventory["oil"])
	get_tree().quit()
