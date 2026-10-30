extends Node3D
## A cup on the cottage table: drink one of your own potions for a small, temporary effect.

func _ready() -> void:
	add_to_group("interactable")
	var c: Node3D = load("res://assets/kaykit/dungeon/plate_small.gltf.glb").instantiate()
	c.scale = Vector3.ONE * 0.6
	add_child(c)

func get_prompt() -> String:
	return "[F] Drink a potion"

func build_dialogue() -> Dictionary:
	var choices := []
	var effects := {"potion": "Starlight: your staff shines bright for ten minutes.", "tonic": "Warmth: you run faster for ten minutes.", "draught": "Dream: sleep until morning, with a dream.", "elixir": "Ember: +2 village Ember, now.", "shade": "Shade: see star shards without Glimmer for ten minutes.", "glow": "Glowbrew: every dark lantern within sight lights at once."}
	for id in effects:
		var have: int = GameState.inventory.get(id, 0)
		choices.append({"label": "%s (%d) — %s" % [GameState.ITEM_NAMES[id], have, effects[id]], "enabled": have > 0, "call": "drink", "arg": id})
	choices.append({"label": "Not thirsty", "enabled": true, "call": "noop", "arg": null})
	return {"pages": [["The cup", "A chipped cup Mirabel left behind. Potions are for giving, mostly; but one now and then is allowed."]], "choices": choices}

func drink(id: String) -> void:
	if not GameState.take_item(id, 1):
		return
	var until := Time.get_ticks_msec() / 1000.0 + 600.0
	match id:
		"potion":
			GameState.glimmer_until = until
			GameState.say("Starlight. Your staff blazes.")
		"tonic":
			GameState.haste_until = until
			GameState.say("Warmth spreads to your feet. You feel quick.")
		"draught":
			GameState.sleep_until_morning()
			GameState.say(["You dream of a lantern on a hill, and someone waving.", "You dream the lake is a sky and the fish are stars.", "You dream Pip is Headmistress. It is fine. Everyone is fine."][randi() % 3])
		"elixir":
			GameState.add_ember(2)
			GameState.say("Bottled warmth, uncorked. The village feels it. +2 Ember")
		"glow":
			var n := 0
			for l in get_tree().get_nodes_in_group("dark_lantern"):
				if l.has_method("kindle") and not l.is_lit() and not str(l.lantern_id) in ["watchtower", "isle"]:
					if l.kindle():
						n += 1
			GameState.say("Glowbrew. Light pours out of you. %d lanterns answer." % n if n > 0 else "Glowbrew. Nothing here was dark; the cottage glows anyway.")
		"shade":
			GameState.shade_until = until
			GameState.say("Shade Draught. The dark gets friendlier; shards glint without Glimmer.")

func noop(_a) -> void:
	pass

func interact() -> void:
	pass
