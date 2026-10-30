extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var p = v.get_node("Player")
	GameState.spells["kindle"] = true
	var il: Node3D = null
	for n in get_tree().get_nodes_in_group("dark_lantern"):
		if n.lantern_id == "isle": il = n
	p.global_position = il.global_position + Vector3(1, 0, 0)
	await get_tree().physics_frame
	GameState.forced_hour = 23.0
	hud.cast_spell("kindle")
	print("ch6 w/o ch5: ", GameState.chapter6_done)
	GameState.chapter5_done = true
	hud.cast_spell("kindle")
	print("ch6: ", GameState.chapter6_done, " lit=", il.is_lit())
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	by["marrow"].build_dialogue(); var d: Dictionary = by["marrow"].build_dialogue()
	print("marrow: ", d["pages"][-1][1].substr(0, 40), " marks=", GameState.marks)
	GameState.forced_hour = 10.0; GameState.coins = 100
	by["tamsin"].build_dialogue(); d = by["tamsin"].build_dialogue()
	print("tamsin choices=", d["choices"].size(), " last=", d["choices"][-1]["label"])
	get_tree().quit()
