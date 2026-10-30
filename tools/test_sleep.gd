extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	GameState._ensure_daily(); GameState.coins += 12; GameState.add_marks(2, "test")
	var bed = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("sleep"))[0]
	bed.sleep(null)
	await get_tree().process_frame; await get_tree().process_frame
	print("summary: ", hud._dlg_text.text.replace("\n", " | "))
	get_tree().quit()
