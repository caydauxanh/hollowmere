extends Node3D
## The tavern's tally board: who is in tonight, and a round of drinks for Ember.

func _ready() -> void:
	add_to_group("interactable")
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.1, 1.2, 1.6)
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.18, 0.16)
	m.material_override = mat
	m.position.y = 1.5
	add_child(m)
	var tag := Label3D.new()
	tag.text = "Tally board"
	tag.font_size = 28
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.4
	add_child(tag)

func get_prompt() -> String:
	return "[F] Tally board"

func build_dialogue() -> Dictionary:
	var here := []
	for n in get_tree().get_nodes_in_group("villager"):
		if n.visible:
			here.append(n.data["name"])
	var key := "%s/round" % Story.today_key()
	var choices := []
	if not GameState.quests_done.has(key):
		choices.append({"label": "Buy a round for the house — 12 coins", "enabled": GameState.coins >= 12, "call": "round", "arg": null})
	choices.append({"label": "Just looking", "enabled": true, "call": "noop", "arg": null})
	return {"pages": [["Tally board", "Tonight: %s\\n\\nTamsin keeps the tab. Bramble keeps the fire. A round for the house warms everyone." % (", ".join(here) if not here.is_empty() else "nobody yet; the regulars come after six")]], "choices": choices}

func round(_a) -> void:
	if GameState.coins < 12:
		return
	GameState.coins -= 12
	GameState.quests_done["%s/round" % Story.today_key()] = true
	var n := 0
	for v in get_tree().get_nodes_in_group("villager"):
		if v.visible:
			GameState.add_friend(v.npc_id, 1)
			n += 1
			v.cheer()
	GameState.add_ember(2)
	GameState.mark_dirty()
	GameState.say("A round for the house! %d villagers raise a cup.  +2 Ember" % n)

func noop(_a) -> void:
	pass

func interact() -> void:
	pass
