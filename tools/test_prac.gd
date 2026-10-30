extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var p = v.get_node("Player")
	GameState.spells["kindle"] = true; GameState.spells["verdant"] = true
	GameState.forced_hour = 9.0
	var br: Node3D = null
	for n in get_tree().get_nodes_in_group("dark_lantern"):
		if n.lantern_id == "academy_brazier": br = n
	p.global_position = br.global_position + Vector3(1, 0, 0)
	await get_tree().physics_frame
	hud.cast_spell("kindle")
	print("flame practical marks=", GameState.marks, " lit=", br.is_lit())
	GameState.forced_hour = 12.0
	var plot = get_tree().get_nodes_in_group("interactable").filter(func(n): return n is HerbPlot and n.plot_key == "academy_0")[0]
	GameState.plots[plot.plot_key]["planted_at"] = GameState.now()
	plot.verdant()
	print("herb practical marks=", GameState.marks)
	GameState.forced_hour = 15.0
	var bk = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.get("book_id") != null)[0]
	bk.build_dialogue()
	print("lore practical marks=", GameState.marks)
	GameState.forced_hour = 20.0
	GameState.add_item("emberroot", 2)
	var c = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("brew"))[0]
	c.brew("tonic")
	print("potions practical marks=", GameState.marks)
	GameState.forced_hour = 22.0
	var sc = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("observe"))[0]
	sc.observe("bearer")
	print("astronomy practical marks=", GameState.marks, " done=", GameState.lessons_done.keys())
	get_tree().quit()
