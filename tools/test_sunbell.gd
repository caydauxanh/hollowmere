extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.chapter3_done = true; GameState.friendship["isolde"] = 4; GameState.forced_hour = 16.0
	by["isolde"].build_dialogue()
	var d: Dictionary = by["isolde"].build_dialogue(); print("isolde: ", d["pages"][0][1].substr(0, 30), " bed=", GameState.sunbell_bed, " glow=", GameState.recipes_unlocked.has("glow"))
	get_tree().quit()
