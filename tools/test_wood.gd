extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.forced_hour = 12.0
	await get_tree().process_frame
	print("wennet visible by day=", by["wennet"].visible, " avail=", by["wennet"].is_available())
	GameState.forced_hour = 23.0
	await get_tree().process_frame
	print("wennet visible by night=", by["wennet"].visible)
	by["wennet"].build_dialogue()
	var d: Dictionary = by["wennet"].build_dialogue()
	print("quest: ", d["pages"][0][1].substr(0, 40))
	GameState.add_item("nightcap", 2); GameState.add_item("moonpetal", 1)
	d = by["wennet"].build_dialogue()
	print("recipe unlocked=", GameState.recipes_unlocked.has("shade"), " shade=", GameState.inventory["shade"])
	var plots = get_tree().get_nodes_in_group("interactable").filter(func(n): return n is HerbPlot and n.herb_id == "nightcap")
	print("nightcap beds=", plots.size(), " prompt=", plots[0].get_prompt())
	get_tree().quit()
