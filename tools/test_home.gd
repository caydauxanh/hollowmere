extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var p: CharacterBody3D = v.get_node("Player")
	print("scene=", v.name, " at ", p.global_position)
	for i in 200:
		var to: Vector3 = Vector3(-4.0, 0, -5.0) - p.global_position; to.y = 0
		if to.length() < 0.8: break
		p.velocity = to.normalized() * 4.0 + Vector3(0, -1, 0); p.move_and_slide(); await get_tree().physics_frame
	print("walked to hearth: ", p.global_position)
	var items := 0
	for n in get_tree().get_nodes_in_group("interactable"): items += 1
	print("interactables=", items)
	get_tree().quit()
