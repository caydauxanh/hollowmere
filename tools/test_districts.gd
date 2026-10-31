extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD")
	var p: Node3D = v.get_node("Player")
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	print("npcs: ", by.keys())
	# schedule: 10:00 wren should head to market (30,-11)
	GameState.forced_hour = 10.0
	p.global_position = Vector3(30, 0.1, -8)
	await get_tree().create_timer(0.5).timeout
	print("wren target 10h: ", by["wren"]._target_pos, " walking=", by["wren"].is_walking())
	GameState.forced_hour = 20.0
	p.global_position = Vector3(-34, 0.1, -5)
	await get_tree().create_timer(0.5).timeout
	print("wren target 20h: ", by["wren"]._target_pos, " pos=", by["wren"].position)
	# shop
	GameState.forced_hour = 10.0
	GameState.coins = 20
	var d: Dictionary = by["tamsin"].build_dialogue()   # intro first
	d = by["tamsin"].build_dialogue()
	print("tamsin choices: ", d.get("choices", []).size(), " first=", d.get("choices", [{}])[0].get("label", ""))
	by["tamsin"].shop_buy("emberroot")
	GameState.add_item("potion", 1)
	by["tamsin"].shop_sell("potion")
	print("coins after buy/sell: ", GameState.coins, " emberroot=", GameState.inventory["emberroot"], " potion=", GameState.inventory["potion"])
	# trial brazier
	GameState.spells["kindle"] = true
	var tr: Node3D = null
	for n in get_tree().get_nodes_in_group("dark_lantern"):
		if n.lantern_id == "trial_0": tr = n
	p.global_position = tr.global_position + Vector3(1, 0.1, 0)
	hud.cast_spell("kindle")
	print("marks after trial kindle: ", GameState.marks, " lit=", tr.is_lit())
	# targets
	var tg = get_tree().get_first_node_in_group("spark_targets")
	tg.start(null)
	var hits := 0
	for i in 6:
		p.global_position = tg._targets[tg._live].global_position + Vector3(0, 0.1, 1)
		if tg.kindle_at(p.global_position): hits += 1
	tg._time = 0.01
	await get_tree().create_timer(0.3).timeout
	print("targets hits=", hits, " best=", GameState.best_targets, " coins=", GameState.coins, " marks=", GameState.marks)
	# landmarks
	var lm := 0
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.get("title") != null: lm += 1
	print("landmarks: ", lm)
	get_tree().quit()
