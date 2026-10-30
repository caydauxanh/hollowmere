extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var p = v.get_node("Player")
	var cats = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.get("companion") != null)
	var oc = cats.filter(func(c): return c.companion)[0]
	GameState.cat_pets = 14
	oc.interact()
	await get_tree().process_frame; await get_tree().process_frame
	print("dlg=", hud._dlg_open, " choices=", hud._dlg_choices.get_child_count())
	oc.name_cat("Biscuit"); hud._close_dialogue()
	p.global_position = Vector3(30, 0.1, 30)
	await get_tree().create_timer(0.5).timeout
	print("cat near=", oc.position.distance_to(p.global_position), " prompt=", oc.get_prompt())
	get_tree().quit()
