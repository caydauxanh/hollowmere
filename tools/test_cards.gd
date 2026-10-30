extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var chests = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.get("card_id") != null)
	print("chests=", chests.size())
	var d: Dictionary = chests[0].build_dialogue()
	print(d["pages"][0][0], " cards=", GameState.cards.size(), " marks=", GameState.marks)
	d = chests[0].build_dialogue()
	print(d["pages"][0][0])
	print("event today: ", Story.todays_event())
	GameState.order = "tidewatch"
	await get_tree().process_frame
	print("scarf=", v.get_node("Player")._scarf.visible)
	get_tree().quit()
