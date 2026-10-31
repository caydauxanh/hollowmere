extends Node
## NavGrid + walkers: grid builds, routes cross the bridge, villagers reach their posts
## without ending up inside anything, nothing gets stuck. Run: --headless -- --fresh --hour=12
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var v := get_tree().current_scene
	var nav := NavGrid.get_for(get_tree())
	var t0 := Time.get_ticks_msec()
	while not nav.built:
		await get_tree().process_frame
	print("grid built in ", Time.get_ticks_msec() - t0, " ms: ", nav.nx, "x", nav.nz, " step ", nav.step)
	var open := 0
	for k in nav.ys.size():
		if nav.ys[k] != NavGrid.BLOCKED and nav.edges[k] != 0:
			open += 1
	print("open nodes: ", open, " / ", nav.ys.size())
	# Routes
	var fails := 0
	for pair in [[Vector3(0, 0, 10), Vector3(-54, 0, 40), "Fernmoor"], [Vector3(0, 0, 10), Vector3(33, 0, -14), "Ashford road"], [Vector3(0, 0, 10), Vector3(-30, 0, -29), "Trial Field"], [Vector3(0, 0, 10), Vector3(3, 0, 31), "Festival Green"], [Vector3(-54, 0, 40), Vector3(30, 0, -11), "Fernmoor→market"]]:
		var pth := nav.find_path(pair[0], pair[1])
		var ln := 0.0
		for i in range(1, pth.size()):
			ln += pth[i - 1].distance_to(pth[i])
		var via_bridge := false
		for p in pth:
			if p.distance_to(Vector3(-40, 0, 31)) < 6.0:
				via_bridge = true
		print("route %s: %d waypoints, %.0f m%s" % [pair[2], pth.size(), ln, "  (via bridge)" if via_bridge else ""])
		if pth.is_empty():
			fails += 1
			print("  X no route")
		if pair[2] == "Fernmoor" and not via_bridge:
			fails += 1
			print("  X Fernmoor route does not use the bridge")
	# Watch the villagers for a while (time passes: 12h → walks happen), then audit.
	var gs := get_node("/root/GameState")
	var space := v.get_viewport().world_3d.direct_space_state
	for hour in [12.5, 14.5, 17.5]:
		gs.forced_hour = hour
		# Keep the player near the square so no one is teleported.
		v.player.global_position = Vector3(0, 0.2, 8)
		await get_tree().create_timer(30.0).timeout
		var walking := 0
		var inside := 0
		var far := 0
		for n in get_tree().get_nodes_in_group("villager"):
			if not n.visible:
				continue
			if n.is_walking():
				walking += 1
				print("  still walking: %s  to go %.1f m  replans %d  wp %d/%d" % [n.npc_id, n.distance_to_goal(), n._replans, n._wp, n._path.size()])
				if n._replans >= 3:
					fails += 1
			var q := PhysicsPointQueryParameters3D.new()
			q.position = n.global_position + Vector3(0, 0.9, 0)
			q.collision_mask = 1
			if space.intersect_point(q, 1).size() > 0:
				inside += 1
				print("  X inside something: ", n.npc_id, " @", n.global_position.round())
			var d: float = n._target_pos.distance_to(n.global_position) if n._target_pos != Vector3.INF else 0.0
			if d > 6.0 and not n.is_walking():
				far += 1
				print("  X far from post and not walking: ", n.npc_id, " d=%.1f" % d)
		print("hour %.1f: still walking %d, inside colliders %d, far-from-post %d" % [hour, walking, inside, far])
		fails += inside + far
	# Sheep and cats must be solid walkers too.
	var animals := 0
	for n in get_tree().get_nodes_in_group("walker"):
		if n is Villager:
			continue
		animals += 1
		if not (n is CharacterBody3D):
			fails += 1
			print("  X animal is not a body: ", n)
	print("animals: ", animals)
	print("RESULT nav ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	get_tree().quit()
