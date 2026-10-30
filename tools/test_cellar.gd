extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var p: CharacterBody3D = v.get_node("Player")
	var sh = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("_slide"))[0]
	print("shelf at ", sh.global_position)
	var d: Dictionary = sh.build_dialogue(); print("closed: ", d["pages"][0][1].substr(0, 30))
	# try walking through before open
	p.global_position = Vector3(-18.0, 0.1, -18.6); p.velocity = Vector3.ZERO
	for i in 90: p.velocity = Vector3(-4, -1, 0); p.move_and_slide(); await get_tree().physics_frame
	print("blocked x=", p.global_position.x)
	GameState.memories_heard["corvin"] = true
	d = sh.build_dialogue(); print("open: ", d["pages"][0][1].substr(0, 30))
	await get_tree().physics_frame
	p.global_position = Vector3(-18.0, 0.1, -18.6)
	for i in 120: p.velocity = Vector3(-4, -1, 0); p.move_and_slide(); await get_tree().physics_frame
	print("after x=", p.global_position.x)
	var bt = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.get_script().resource_path.find("old_bottle") >= 0)[0]
	d = bt.build_dialogue(); print("bottle pages=", d["pages"].size(), " ember=", GameState.ember)
	get_tree().quit()
