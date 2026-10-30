extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	print("dilly=", by.has("dilly"))
	by["dilly"].build_dialogue()
	GameState.add_item("perch", 1); GameState.add_item("whisperleaf", 1)
	var d: Dictionary = by["dilly"].build_dialogue()
	print("pie=", GameState.inventory["pie"], " unlocked=", GameState.recipes_unlocked.has("pie"))
	by["pip"].build_dialogue()
	by["pip"].give("pie")
	print("pip friend=", GameState.friendship.get("pip"))
	get_tree().quit()
