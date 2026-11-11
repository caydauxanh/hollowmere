extends Node
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD"); hud._close_dialogue()
	GameState.intro_seen = false
	var p = v.get_node("Player")
	# 1) compass target at start: a villager with a request or the notice board
	hud._compass_t = 0.0; hud._update_compass()
	print("compass start target=", hud._compass_target.round(), " visible=", hud._compass.visible)
	# 2) intro: play through with taps
	var intro := CanvasLayer.new()
	intro.set_script(load("res://ui/intro.gd"))
	v.add_child(intro)
	var hours := []
	for i in 7:
		await get_tree().create_timer(1.6).timeout
		if not is_instance_valid(intro): break
		hours.append(GameState.forced_hour)
		print(" shot ", intro._i, " locked=", GameState.ui_locked, " cine=", v.get_node("CameraRig").cine_point.round())
		intro._t = 1.0
		intro._next()
	await get_tree().create_timer(1.5).timeout
	print("after intro: valid=", is_instance_valid(intro), " locked=", GameState.ui_locked, " hour=", GameState.forced_hour, " hudvis=", hud.visible, " dlg=", hud._dlg_open, " cine=", v.get_node("CameraRig").cine_point)
	hud._close_dialogue()
	# 3) stick analog
	p.stick_mag = 0.5
	Input.action_press("down", 0.5)
	for i in 50: await get_tree().physics_frame
	var v_half := Vector2(p.velocity.x, p.velocity.z).length()
	p.stick_mag = 1.0
	Input.action_press("down", 1.0)
	for i in 50: await get_tree().physics_frame
	var v_full := Vector2(p.velocity.x, p.velocity.z).length()
	Input.action_release("down"); p.stick_mag = -1.0
	print("stick half speed=%.2f full=%.2f" % [v_half, v_full])
	# 4) compass through story states
	GameState.gate_open = true; hud._compass_t = 0.0; hud._update_compass(); print("gate open, unsorted -> ", hud._compass_target.round())
	GameState.order = "emberwing"; GameState.forced_hour = 3.0
	for r in Story.todays_requests(): GameState.quests_done[r["id"]] = true
	hud._compass_t = 0.0; hud._update_compass(); print("need kindle -> ", hud._compass_target.round())
	GameState.spells["kindle"] = true; hud._compass_t = 0.0; hud._update_compass(); print("ch2 lantern -> ", hud._compass_target.round())
	GameState.chapter2_done = true; GameState.chapter3_done = true; GameState.chapter4_done = true
	hud._compass_t = 0.0; hud._update_compass(); print("ch5 -> ", hud._compass_target.round())
	GameState.chapter5_done = true; hud._compass_t = 0.0; hud._update_compass(); print("ch6 boat -> ", hud._compass_target.round())
	get_tree().quit()
