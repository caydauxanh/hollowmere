extends Node
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var hud = get_tree().current_scene.get_node("HUD"); hud._close_dialogue(); hud._toggle_map()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[1].get_slice("=", 1))
	get_tree().quit()
