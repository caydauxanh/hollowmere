extends Node3D
## Your pumpkin patch behind the cottage. Plant a seed, water daily (Verdant works too), enter the Saturday contest.

var _m: Node3D

func _ready() -> void:
	add_to_group("interactable")
	_refresh()

func _refresh() -> void:
	if _m:
		_m.queue_free()
		_m = null
	var d := GameState.pumpkin_days()
	if d < 0:
		var soil := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 1.0
		sm.bottom_radius = 1.0
		sm.height = 0.1
		soil.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.25, 0.18)
		soil.material_override = mat
		_m = soil
	else:
		var model := "pumpkin_orange_small.gltf" if d < 2 else ("pumpkin_orange.gltf" if d < 5 else "pumpkin_orange_jackolantern.gltf")
		_m = load("res://assets/kaykit/halloween/" + model).instantiate()
		_m.scale = Vector3.ONE * clampf(0.5 + d * 0.18, 0.5, 1.8)
	add_child(_m)

func get_prompt() -> String:
	var d := GameState.pumpkin_days()
	if d < 0:
		return "[F] Empty pumpkin patch"
	return "[F] Your pumpkin (%d day%s, ~%d lb)" % [d, "s" if d != 1 else "", _weight()]

func _weight() -> int:
	return maxi(0, GameState.pumpkin_days()) * 9 + 4

func build_dialogue() -> Dictionary:
	var d := GameState.pumpkin_days()
	if d < 0:
		return {"pages": [["Pumpkin patch", "Bare earth behind the apothecary. Tamsin sells pumpkin seed (6 coins) at the market."]], "choices": [{"label": "Plant a seed (needs one)", "enabled": GameState.inventory.get("pumpkin_seed", 0) > 0, "call": "plant", "arg": null}, {"label": "Leave it", "enabled": true, "call": "noop", "arg": null}]}
	var choices := [{"label": "Harvest now (%d lb)" % _weight(), "enabled": true, "call": "harvest", "arg": null}, {"label": "Let it grow", "enabled": true, "call": "noop", "arg": null}]
	return {"pages": [["Your pumpkin", "Day %d. About %d pounds. It grows a little every real day; the Saturday contest on Festival Green judges by weight.\nBest so far: %d lb." % [d, _weight(), GameState.pumpkin_best]]], "choices": choices}

func plant(_a) -> void:
	if not GameState.take_item("pumpkin_seed", 1):
		return
	GameState.pumpkin_planted = Story.today_key()
	GameState.mark_dirty()
	_refresh()
	GameState.say("Planted. Come back tomorrow; it grows while you are away.")

func harvest(_a) -> void:
	var w := _weight()
	GameState.pumpkin_best = maxi(GameState.pumpkin_best, w)
	GameState.pumpkin_planted = ""
	GameState.add_item("pumpkin", 1)
	GameState.coins += w / 2
	GameState.add_ember(1)
	GameState.mark_dirty()
	_refresh()
	GameState.say("Harvested a %d lb pumpkin. (+%d coins, +1 Ember) Tamsin buys them; Pip wants one." % [w, w / 2])

func noop(_a) -> void:
	pass

func interact() -> void:
	pass
