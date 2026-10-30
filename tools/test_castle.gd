extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD")
	var p: CharacterBody3D = v.get_node("Player")
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	print("npcs: ", by.keys())
	# walk test: from library (0,-20.4) east through door to common room (12.6,-20.4)
	var route := [[Vector3(0, 0.1, -20.4), Vector3(12.6, 0, -20.4), "library->common"], [Vector3(0, 0.1, -20.4), Vector3(-12.6, 0, -20.4), "library->potions"], [Vector3(2.5, 0.1, -20.4), Vector3(2.5, 0, -26.5), "library->tower-door"], [Vector3(0.5, 0.1, -26.5), Vector3(0.5, 0, -31.2), "door->tower"], [Vector3(4.5, 0.1, -9), Vector3(4.5, 0, -14.2), "hall->north"], [Vector3(0.5, 0.1, -14.2), Vector3(0.5, 0, -19.0), "north->library"], [Vector3(0, 0.1, -2.5), Vector3(7.5, 0, -4), "hall->east"], [Vector3(7.5, 0.1, -4), Vector3(14.4, 0, -4), "east->flame"], [Vector3(0, 0.1, 1), Vector3(0, 0, -6), "entrance->hall"], [Vector3(16.5, 0.1, -20.4), Vector3(25.2, 0, -20.4), "common->study"]]
	for r in route:
		p.global_position = r[0]
		p.velocity = Vector3.ZERO
		await get_tree().physics_frame
		for i in 400:
			var to: Vector3 = r[1] - p.global_position
			to.y = 0
			if to.length() < 0.6: break
			p.velocity = to.normalized() * 5.0 + Vector3(0, -1, 0)
			p.move_and_slide()
			await get_tree().physics_frame
		print(r[2], ": reached=", (r[1] - p.global_position).length() < 1.0, " at ", p.global_position)
	# sorting
	var o = by["oriel"]
	o.build_dialogue()
	var d: Dictionary = o.build_dialogue()
	print("oriel: ", d["pages"][0][1].substr(0, 30), " choices=", d.get("choices", []).size())
	o.start_sorting(null)
	await get_tree().process_frame; await get_tree().process_frame
	for i in 4:
		o.sort_answer("thornhollow")
		await get_tree().process_frame; await get_tree().process_frame
	print("order=", GameState.order, " dlg=", hud._dlg_text.text.substr(0, 60))
	hud._close_dialogue()
	# bed / telescope / board exist?
	print("beds: ", get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("sleep")).size())
	var scope = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("observe"))[0]
	GameState.forced_hour = 22.0
	d = scope.build_dialogue()
	print("scope choices: ", d["choices"].size())
	for id in Story.CONSTELLATIONS: scope.observe(id)
	await get_tree().process_frame
	print("stars=", GameState.stars_seen.size(), " ch4=", GameState.chapter4_done, " marks=", GameState.marks)
	# potions lesson at 20h
	GameState.forced_hour = 20.0
	by["corvin"].build_dialogue()
	d = by["corvin"].build_dialogue()
	print("corvin 20h: ", d["pages"][0][1].substr(0, 40), " choices=", d.get("choices", []).size())
	GameState.forced_hour = 10.0
	GameState.sleep_until_morning()
	print("after sleep hour=", GameState.hour_of_day())
	get_tree().quit()
