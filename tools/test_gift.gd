extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.add_item("tonic", 1); GameState.add_item("minnow", 1)
	by["wren"].build_dialogue()
	var d: Dictionary = by["wren"].build_dialogue()
	print("wren choices=", d.get("choices", []).size())
	by["wren"].give("tonic")
	print("friend=", GameState.friendship.get("wren"), " tonic=", GameState.inventory["tonic"])
	d = by["wren"].build_dialogue()
	print("after gift choices=", d.get("choices", []).size())
	get_tree().quit()
