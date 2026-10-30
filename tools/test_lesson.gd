extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD")
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.forced_hour = 9.0
	var a = by["alder"]
	a.build_dialogue()
	var d: Dictionary = a.build_dialogue()
	print("alder 9h: ", d["pages"][0][1], " choices=", d.get("choices", []).size())
	a.start_lesson("flame")
	await get_tree().process_frame
	await get_tree().process_frame
	print("q1 open=", hud._dlg_open, " text=", hud._dlg_text.text)
	for i in 3:
		var q: Array = Story.LESSONS["flame"]["quiz"][a._q]
		a.answer(q[2] if i < 2 else (q[2] + 1) % 3)
		await get_tree().process_frame
		await get_tree().process_frame
	print("result: ", hud._dlg_text.text, " marks=", GameState.marks, " done=", GameState.lessons_done)
	hud._close_dialogue()
	d = a.build_dialogue()
	print("alder again: ", d["pages"][0][1].substr(0, 40))
	GameState.forced_hour = 15.0
	d = a.build_dialogue()
	print("alder 15h: ", d["pages"][0][1].substr(0, 60))
	GameState.forced_hour = 18.0
	by["oriel"].build_dialogue()
	d = by["oriel"].build_dialogue()
	print("oriel 18h: ", d["pages"][-1][1], " marks=", GameState.marks)
	get_tree().quit()
