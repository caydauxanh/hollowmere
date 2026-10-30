extends Node3D
## Market stall: buy decorations that appear in the village.

func _ready() -> void:
	add_to_group("interactable")
	var tag := Label3D.new()
	tag.text = "Market"
	tag.font_size = 40
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 10
	tag.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	tag.position.y = 2.6
	add_child(tag)


func get_prompt() -> String:
	return "[F] Browse the market"


func build_dialogue() -> Dictionary:
	var choices := []
	for id in Story.DECOR:
		var d: Dictionary = Story.DECOR[id]
		var owned: bool = GameState.decor.has(id)
		choices.append({"label": "%s — %s" % [d["name"], "owned" if owned else "%d coins" % d["price"]], "enabled": not owned and GameState.coins >= d["price"], "call": "buy", "arg": id})
	for id in Story.HOME_DECOR:
		var d: Dictionary = Story.HOME_DECOR[id]
		var owned: bool = GameState.home_decor.has(id)
		choices.append({"label": "For the cottage: %s — %s" % [d["name"], "owned" if owned else "%d coins" % d["price"]], "enabled": not owned and GameState.coins >= d["price"], "call": "buy_home", "arg": id})
	return {"pages": [["Market", "Wren's cousin runs the stall on good days. Today the sign just says: TAKE WHAT YOU PAY FOR.\n\nVillage decorations appear outside; cottage furniture appears in your apothecary.\n\nCoins: %d" % GameState.coins]], "choices": choices}


func buy_home(id: String) -> void:
	var d: Dictionary = Story.HOME_DECOR[id]
	if GameState.home_decor.has(id) or GameState.coins < d["price"]:
		return
	GameState.coins -= d["price"]
	GameState.home_decor[id] = true
	GameState.add_ember(1)
	GameState.mark_dirty()
	GameState.say("Bought: %s. It is waiting in your cottage.  +1 Ember" % d["name"])


func buy(id: String) -> void:
	var d: Dictionary = Story.DECOR[id]
	if GameState.decor.has(id) or GameState.coins < d["price"]:
		return
	GameState.coins -= d["price"]
	GameState.decor[id] = true
	GameState.add_ember(1)
	GameState.say("Bought: %s.  It appears in the village.  +1 Ember" % d["name"])
	get_parent().call_deferred("_place_decor", id)


func interact() -> void:
	pass
