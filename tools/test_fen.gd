extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var fp = get_tree().get_nodes_in_group("interactable").filter(func(n): return n.has_method("_refresh") and n.get_script().resource_path.find("fen_plant") >= 0)[0]
	var d: Dictionary = fp.build_dialogue(); print("locked: ", d["pages"][0][1].substr(0, 30))
	GameState.friendship["fen"] = 8; GameState.friendship["isolde"] = 4
	d = fp.build_dialogue(); print("pages=", d["pages"].size(), " bloom=", fp._bloom.visible, " ember=", GameState.ember)
	get_tree().quit()
