extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var p = v.get_node("Player")
	GameState.broom = true; p.set_flying(true)
	var sl: Node3D = null
	for n in v.get_children():
		if n.get("lantern_id") != null and str(n.lantern_id).begins_with("sky_"): sl = n; break
	p.global_position = sl.global_position
	await get_tree().create_timer(0.2).timeout
	print("sky=", GameState.sky_lanterns.size(), " coins=", GameState.coins)
	get_tree().quit()
