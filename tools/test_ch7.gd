extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	GameState.chapter6_done = true; GameState.forced_hour = 23.5
	var scope = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("observe"))[0]
	var d: Dictionary = scope.build_dialogue()
	print("choices=", d["choices"].size(), " last=", d["choices"][-1]["label"])
	scope.small_star(null)
	await get_tree().process_frame; await get_tree().process_frame
	print("ch7=", GameState.chapter7_done, " dlg pages=", hud._dlg_pages.size(), " ember=", GameState.ember)
	get_tree().quit()
