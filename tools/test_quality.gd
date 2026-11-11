extends Node
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var v := get_tree().current_scene
	for q in ["low", "high", "low"]:
		GameState.quality = q
		get_tree().call_group("quality", "apply_quality")
		await get_tree().process_frame
		print("QUAL ", q, " grass=", v.grass.multimesh.visible_instance_count, " glow=", v.env.glow_enabled, " lantern_shadow=", v.player.lantern.shadow_enabled)
	GameState.forced_hour = 23.0
	await get_tree().create_timer(0.3).timeout
	print("QUAL night lantern energy=%.2f visible=%s" % [v.player.lantern.light_energy, v.player.lantern.visible])
	get_tree().quit()
