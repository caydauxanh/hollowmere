extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	GameState.forced_hour = 20.0
	await get_tree().create_timer(0.3).timeout
	var vis := []
	for n in v.find_children("*", "Villager", true, false):
		if n.visible: vis.append(n.npc_id)
	print(v.name, " 20h visible: ", vis)
	GameState.forced_hour = 12.0
	await get_tree().create_timer(0.3).timeout
	vis = []
	for n in v.find_children("*", "Villager", true, false):
		if n.visible: vis.append(n.npc_id)
	print(v.name, " 12h visible: ", vis)
	get_tree().quit()
