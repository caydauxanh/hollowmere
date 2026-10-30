extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var p: CharacterBody3D = v.get_node("Player")
	var boat = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("row"))[0]
	boat.row(null)
	await get_tree().physics_frame
	print("at isle pos=", p.global_position)
	# walk around isle
	for i in 120:
		p.velocity = Vector3(3, -1, 0); p.move_and_slide(); await get_tree().physics_frame
	print("walked east to x=", p.global_position.x, " y=", p.global_position.y, " (water wall expected near 71)")
	boat.row(null)
	await get_tree().physics_frame
	print("back pos=", p.global_position)
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	print("nell=", by.has("nell"), " marrow=", by.has("marrow"), " sheep=", get_tree().get_nodes_in_group("interactable").filter(func(n): return n.get("pen_center") != null).size())
	get_tree().quit()
