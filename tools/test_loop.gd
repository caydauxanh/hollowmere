extends Node
## Kiểm thử nhanh vòng chơi: hái 3 loại cây rồi pha thuốc.
func _ready():
	await get_tree().create_timer(0.5).timeout
	var v = get_tree().current_scene
	var hud = v.get_node("HUD")
	var gs = get_node("/root/GameState")
	gs.forced_hour = 22.0
	for plot in get_tree().get_nodes_in_group("interactable"):
		v.player.global_position = plot.global_position + Vector3(0, 0.2, 1.2)
		await get_tree().create_timer(0.3).timeout
		print("near ", plot.name, ": ", hud._prompt.text)
		var ev := InputEventAction.new(); ev.action = "interact"; ev.pressed = true
		Input.parse_input_event(ev)
		await get_tree().create_timer(0.3).timeout
		print("  inv=", gs.inventory)
	print("RESULT potion=", gs.inventory["potion"])
	get_tree().quit()
