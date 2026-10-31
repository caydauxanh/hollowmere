extends Node
## Academy: students and teachers reach their rooms through the doors (NavGrid inside the castle).
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var v := get_tree().current_scene
	var nav := NavGrid.get_for(get_tree())
	while not nav.built:
		await get_tree().process_frame
	print("academy grid %dx%d step %.1f" % [nav.nx, nav.nz, nav.step])
	var fails := 0
	for hour in [8.5, 11.5, 14.5, 17.5, 19.5, 21.5]:
		GameState.forced_hour = hour
		v.player.global_position = Vector3(0, 0.1, -10)
		await get_tree().create_timer(40.0).timeout
		var late := 0
		for n in get_tree().get_nodes_in_group("villager"):
			if not n.visible:
				continue
			var d: float = n._post_eff.distance_to(n.global_position) if n._post_eff != Vector3.INF else 0.0
			if d > 1.5 and not n._strolling:
				late += 1
				print("  X %s at %.1f: %.1f m from post %s, walking=%s replans=%d" % [n.npc_id, hour, d, n._target_pos.round(), n.is_walking(), n._replans])
		print("hour %.1f: late %d" % [hour, late])
		fails += late
	print("RESULT navacad ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	get_tree().quit()
