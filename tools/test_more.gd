extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var p = v.get_node("Player")
	var f = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("_catch"))[0]
	f.interact(); f._t = 0.01
	await get_tree().create_timer(0.1).timeout
	print("fish state=", f._state)
	f.interact()
	print("fish=", GameState.inventory["minnow"] + GameState.inventory["perch"] + GameState.inventory["moonfish"], " caught=", GameState.fish_caught, " marks=", GameState.marks)
	var d = get_tree().get_first_node_in_group("duel")
	GameState.spells["kindle"] = true; GameState.spells["verdant"] = true
	GameState.forced_hour = 15.0
	var dd: Dictionary = d.build_dialogue()
	print("duel choices=", dd.get("choices", []).size())
	d.start(null)
	for i in 8:
		hud.cast_spell(d._want)
		await get_tree().process_frame
	print("duel running=", d._running, " best=", GameState.best_duel, " coins=", GameState.coins)
	GameState.chapter4_done = true
	await get_tree().process_frame
	print("star visible=", p._star.visible)
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.broom = true; GameState.coins = 50
	by["gorrin"].build_dialogue(); var g: Dictionary = by["gorrin"].build_dialogue()
	print("crystal choices=", g.get("choices", []).size())
	by["gorrin"].fit_crystal("ember")
	print("staff=", GameState.staff_color, " coins=", GameState.coins)
	get_tree().quit()
