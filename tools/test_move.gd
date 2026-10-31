extends Node
## Player movement feel + tap-to-walk routing. Run: --headless -- --fresh --hour=12
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD")
	hud._close_dialogue()
	GameState.ui_locked = false
	var p: CharacterBody3D = v.get_node("Player")
	var nav := NavGrid.get_for(get_tree())
	while not nav.built:
		await get_tree().process_frame
	var fails := 0
	# 1. Acceleration: time from rest to 90 % walk speed, and stop distance.
	p.global_position = Vector3(0, 0.1, 8)
	p.velocity = Vector3.ZERO
	await get_tree().physics_frame
	Input.action_press("up")
	var t := 0.0
	var reached := -1.0
	for i in 120:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if reached < 0.0 and Vector2(p.velocity.x, p.velocity.z).length() >= p.walk_speed * 0.9:
			reached = t
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	Input.action_release("up")
	var stop_from := p.global_position
	for i in 60:
		await get_tree().physics_frame
	var stop_d := stop_from.distance_to(p.global_position)
	print("walk: 90%% speed after %.2f s, cruise %.2f m/s, stop distance %.2f m" % [reached, speed, stop_d])
	if reached < 0.0 or reached > 0.6 or stop_d > 1.0:
		fails += 1
	# 2. Run, along a lane that is clear for 30 m (camera looks down -Z, so "up" walks toward -Z).
	var lane := Vector3.INF
	for x in range(-40, 41, 2):
		for z0 in [48.0, 40.0, 30.0, 20.0, 10.0, 0.0, -10.0, -20.0]:
			if nav.line_clear(Vector3(x, 0, z0), Vector3(x, 0, z0 - 22.0)) and nav._surface_y(Vector3(x, 0, z0)) == 0.0:
				lane = Vector3(x, 0.1, z0)
				break
		if lane != Vector3.INF:
			break
	print("run lane from ", lane)
	p.global_position = lane
	p.velocity = Vector3.ZERO
	await get_tree().physics_frame
	Input.action_press("up")
	Input.action_press("run")
	for i in 90:
		await get_tree().physics_frame
	var rs := Vector2(p.velocity.x, p.velocity.z).length()
	Input.action_release("run")
	Input.action_release("up")
	print("run cruise %.2f m/s" % rs)
	if rs < p.run_speed * 0.9:
		fails += 1
	for i in 60:
		await get_tree().physics_frame
	# 3. Jump height and landing.
	var y0 := p.global_position.y
	Input.action_press("jump")
	var top := y0
	for i in 90:
		await get_tree().physics_frame
		top = maxf(top, p.global_position.y)
		if i == 20:
			Input.action_release("jump")
	print("jump height %.2f m, landed y=%.2f" % [top - y0, p.global_position.y])
	if top - y0 < 0.8 or absf(p.global_position.y - y0) > 0.1:
		fails += 1
	# 4. Tap-to-walk routed around the church: from the square to behind it.
	var from := Vector3(0, 0.1, 8)
	var to := Vector3(18, 0, -36)   # north of the church at (18,-30)
	p.global_position = from
	p.velocity = Vector3.ZERO
	await get_tree().physics_frame
	p.move_target = to
	print("tap path waypoints: ", p._path.size())
	var arrived := false
	var frames := 0
	while frames < 60 * 40:
		await get_tree().physics_frame
		frames += 1
		if p.move_target == Vector3.INF:
			arrived = true
			break
	var d := Vector2(p.global_position.x - to.x, p.global_position.z - to.z).length()
	print("tap walk: arrived=%s in %.1f s, %.2f m from target" % [arrived, frames / 60.0, d])
	if not arrived or d > 1.0:
		fails += 1
	# 5. Villagers are solid: walking into one stops you (Tamsin at the market, 8-18h).
	GameState.forced_hour = 12.0
	await get_tree().create_timer(1.0).timeout
	var tam: Node3D = null
	for n in get_tree().get_nodes_in_group("villager"):
		if n.npc_id == "tamsin":
			tam = n
	var tp := tam.global_position
	p.global_position = tp + Vector3(3.0, 0.1, 0)
	p.velocity = Vector3.ZERO
	p.set_physics_process(false)
	for i in 90:
		p.velocity = Vector3(-3.0, -1.0, 0)
		p.move_and_slide()
		await get_tree().physics_frame
	p.set_physics_process(true)
	var gap := p.global_position.distance_to(tam.global_position)
	print("pushed into Tamsin: gap %.2f m -> %s" % [gap, "SOLID" if gap > 0.55 else "PASSED THROUGH"])
	if gap <= 0.55:
		fails += 1
	print("RESULT move ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	get_tree().quit()
