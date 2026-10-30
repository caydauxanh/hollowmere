extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var p = v.get_node("Player")
	var cam := get_viewport().get_camera_3d()
	# board at (6.4, .12, -3.6): project to screen and tap
	var sp := cam.unproject_position(Vector3(6.4, 0.1, -3.6))
	hud._click_to_move(sp)
	print("tap target=", hud._tap_target, " move_target=", p.move_target)
	for i in 300:
		await get_tree().physics_frame
		if hud._dlg_open: break
	print("dialogue opened=", hud._dlg_open, " name=", hud._dlg_name.text, " at ", p.global_position)
	get_tree().quit()
