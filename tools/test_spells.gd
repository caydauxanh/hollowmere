extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var hud = v.get_node("HUD")
	var p: Node3D = v.get_node("Player")
	hud._close_dialogue()
	GameState.spells["glimmer"] = true; GameState.spells["mend"] = true; GameState.spells["kindle"] = true
	GameState.forced_hour = 22.0
	hud.cast_spell("glimmer")
	await get_tree().create_timer(0.3).timeout
	print("glimmer active=", GameState.glimmer_active(), " glow=", p.glow.light_energy)
	var sh: Node3D = null
	for n in v.get_children():
		if n.get("shard_id") != null: sh = n; break
	print("shard visible=", sh.visible)
	p.global_position = sh.global_position
	await get_tree().create_timer(0.3).timeout
	print("shards=", GameState.shards.size(), " coins=", GameState.coins, " marks=", GameState.marks)
	var br = get_tree().get_nodes_in_group("mendable")[0]
	p.global_position = br.global_position + Vector3(1, 0, 0)
	await get_tree().physics_frame
	hud.cast_spell("mend")
	print("mended=", GameState.mended.size(), " broken=", br.is_broken())
	var wt: Node3D = null
	for n in get_tree().get_nodes_in_group("dark_lantern"):
		if n.lantern_id == "watchtower": wt = n
	p.global_position = wt.global_position + Vector3(1, 0, 0)
	await get_tree().physics_frame
	hud.cast_spell("kindle")
	print("ch5 before ch4: ", GameState.chapter5_done, " lit=", wt.is_lit())
	GameState.chapter4_done = true
	hud.cast_spell("kindle")
	print("ch5 after ch4: ", GameState.chapter5_done, " lit=", wt.is_lit(), " ember=", GameState.ember)
	get_tree().quit()
