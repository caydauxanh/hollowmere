extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var pk = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("harvest"))[0]
	print(pk.get_prompt())
	GameState.add_item("pumpkin_seed", 1)
	pk.plant(null)
	print("days=", GameState.pumpkin_days(), " prompt=", pk.get_prompt())
	GameState.time_offset += 3 * 86400.0
	pk._refresh()
	print("after 3 days=", GameState.pumpkin_days(), " ", pk.get_prompt())
	pk.harvest(null)
	print("pumpkin=", GameState.inventory["pumpkin"], " best=", GameState.pumpkin_best, " coins=", GameState.coins)
	get_tree().quit()
