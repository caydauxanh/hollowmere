extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	var n := 0
	var errs := 0
	for h in [6.0, 10.0, 15.0, 18.0, 20.0, 23.0]:
		GameState.forced_hour = h
		for it in get_tree().get_nodes_in_group("interactable"):
			if not is_instance_valid(it): continue
			if it.has_method("build_dialogue"):
				var d = it.build_dialogue()
				n += 1
				if typeof(d) != TYPE_DICTIONARY or not d.has("pages"):
					errs += 1; print("BAD dialogue from ", it.name, " ", it.get_script().resource_path)
				else:
					hud.open_dialogue(it, d)
					for k in d["pages"].size() + 1:
						hud.advance_dialogue(); hud.advance_dialogue()
					hud._close_dialogue()
			elif it.has_method("interact") and not it.has_method("row") and it.get_script().resource_path.find("door") < 0 and it.get_script().resource_path.find("entrance") < 0 and it.get_script().resource_path.find("gate") < 0:
				it.interact(); n += 1
			if it.has_method("get_prompt"): it.get_prompt()
	# journal, cards, map
	hud._toggle_journal(); hud._toggle_journal(); hud._toggle_cards(); hud._toggle_cards(); hud._toggle_map(); hud._toggle_map()
	print("scene=", v.name, " interactions=", n, " bad=", errs)
	get_tree().quit()
