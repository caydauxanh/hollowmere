extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var p = v.get_node("Player")
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.chapter2_done = true; GameState.forced_hour = 22.5
	await get_tree().create_timer(0.3).timeout
	print("pellam visible=", by["pellam"].visible, " pos=", by["pellam"].position)
	by["pellam"].build_dialogue()
	var d: Dictionary = by["pellam"].build_dialogue(); print("pellam: ", d["pages"][0][1].substr(0, 20), " choices=", d.get("choices", []).size())
	by["pellam"].patrol(null)
	var pt = get_tree().get_first_node_in_group("patrol")
	for i in 4:
		p.global_position = pt.POSTS[i] + Vector3(0, 0.1, 1)
		await get_tree().process_frame; await get_tree().process_frame
	print("patrol running=", pt._running, " day=", GameState.patrol_day, " coins=", GameState.coins)
	get_tree().quit()
