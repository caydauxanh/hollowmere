extends Node3D
## Saturday pumpkin contest table on Festival Green.

func _ready() -> void:
	add_to_group("interactable")
	var t: Node3D = load("res://assets/kaykit/dungeon/table_medium_tablecloth.gltf.glb").instantiate()
	t.scale = Vector3.ONE * 0.85
	add_child(t)
	var tag := Label3D.new()
	tag.text = "Judging table"
	tag.font_size = 30
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.2
	add_child(tag)

func get_prompt() -> String:
	return "[F] Pumpkin contest"

func build_dialogue() -> Dictionary:
	if Story.todays_event().get("id", "") != "market":
		return {"pages": [["Judging table", "The pumpkin contest is on Saturdays (Market Day). Grow one behind your cottage."]]}
	if GameState.contest_day == Story.today_key():
		return {"pages": [["Judging table", "Already judged today. Nell's entry is still sulking in the corner."]]}
	var have: int = GameState.inventory.get("pumpkin", 0)
	return {"pages": [["Judging table", "Mirabel judges, Nell argues, Pip eats the losers. Enter a harvested pumpkin? Your best: %d lb." % GameState.pumpkin_best]], "choices": [{"label": "Enter my best pumpkin", "enabled": have > 0 and GameState.pumpkin_best > 0, "call": "enter", "arg": null}, {"label": "Just watching", "enabled": true, "call": "noop", "arg": null}]}

func enter(_a) -> void:
	if not GameState.take_item("pumpkin", 1):
		return
	GameState.contest_day = Story.today_key()
	var w := GameState.pumpkin_best
	var rival := 20 + (Story.today_key().hash() % 40)
	var msg := ""
	if w >= rival:
		GameState.coins += 30
		GameState.add_ember(3)
		GameState.add_marks(2, "Pumpkin champion")
		msg = "%d lb against Nell's %d. First prize! Pip is already eating hers.  (+30 coins, +3 Ember)" % [w, rival]
	else:
		GameState.coins += 8
		GameState.add_ember(1)
		msg = "%d lb against Nell's %d. Second. Mirabel says 'next year' in a tone.  (+8 coins, +1 Ember)" % [w, rival]
	GameState.mark_dirty()
	GameState.say(msg)

func noop(_a) -> void:
	pass

func interact() -> void:
	pass
