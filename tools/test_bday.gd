extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	print("today=", Story.today_key(), " birthdays=", Story.birthday_today())
	var hud = get_tree().current_scene.get_node("HUD"); hud._close_dialogue()
	hud._show_villager_info("wren")
	print(hud._dlg_text.text.replace("\n", " | "))
	get_tree().quit()
