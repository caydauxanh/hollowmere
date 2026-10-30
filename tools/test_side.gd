extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var p = v.get_node("Player")
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.forced_hour = 10.0
	by["pip"].build_dialogue()
	var d: Dictionary = by["pip"].build_dialogue(); print("pip: ", d["pages"][0][1].substr(0, 20), " choices=", d.get("choices", []).size())
	by["pip"].go_hide(null)
	await get_tree().create_timer(0.5).timeout
	print("pip hiding at ", by["pip"].position, " hiding=", by["pip"]._hiding)
	d = by["pip"].build_dialogue(); print("found: ", d["pages"][0][1].substr(0, 10), " coins=", GameState.coins)
	by["nell"].build_dialogue()
	d = by["nell"].build_dialogue(); print("nell: ", d["pages"][0][1].substr(0, 30))
	var sh = get_tree().get_first_node_in_group("lost_sheep")
	print("sheep lost at ", sh.position)
	sh.interact(); print("following=", sh._following)
	p.global_position = sh.pen_center + Vector3(2, 0.1, 0); sh.position = sh.pen_center + Vector3(3, 0, 0)
	await get_tree().create_timer(0.3).timeout
	print("home: lost=", sh._lost, " coins=", GameState.coins, " marks=", GameState.marks)
	get_tree().quit()
