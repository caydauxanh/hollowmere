extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD")
	var p = v.get_node("Player")
	hud._close_dialogue()
	var by := {}
	for n in v.find_children("*", "Villager", true, false): by[n.npc_id] = n
	GameState.coins = 100
	by["gorrin"].build_dialogue()
	var d: Dictionary = by["gorrin"].build_dialogue()
	print("gorrin: choices=", d.get("choices", []).size())
	by["gorrin"].buy_broom(null)
	print("broom=", GameState.broom, " coins=", GameState.coins)
	var bc = get_tree().get_first_node_in_group("broom_course")
	p.global_position = bc.global_position + Vector3(2, 0.1, 0)
	bc.start(null)
	print("flying=", p.flying)
	Input.action_press("jump")
	for i in 90: await get_tree().physics_frame
	Input.action_release("jump")
	print("y after climb=", p.global_position.y)
	for i in bc.RINGS.size():
		p.global_position = bc._rings[i].global_position
		await get_tree().process_frame
		await get_tree().process_frame
	print("course running=", bc._running, " best=", GameState.best_broom, " best2=", GameState.best_broom2, " name=", bc.course_name, " coins=", GameState.coins)
	p.set_flying(false)
	for i in 120: await get_tree().physics_frame
	print("landed y=", p.global_position.y, " flying=", p.flying)
	get_tree().quit()
