extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	by["bramble"].build_dialogue()
	var d: Dictionary = by["bramble"].build_dialogue()
	print("choices=", d.get("choices", []).size())
	by["bramble"].ask("quiet")
	await get_tree().process_frame; await get_tree().process_frame
	print("ask: ", hud._dlg_text.text.substr(0, 40), " friend=", GameState.friendship.get("bramble"))
	get_tree().quit()
