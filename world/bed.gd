extends Node3D
## Your bed in the common room: sleep until 6:30 (moves the clock forward).

var order_id := ""
var _glow: OmniLight3D

func _ready() -> void:
	add_to_group("interactable")
	_glow = OmniLight3D.new()
	_glow.light_color = Story.ORDERS[order_id]["color"]
	_glow.light_energy = 0.0
	_glow.omni_range = 6.0
	_glow.position = Vector3(0, 2.2, -1.2)
	add_child(_glow)

func _process(_d: float) -> void:
	_glow.light_energy = 1.6 if GameState.order == order_id else 0.0

func get_prompt() -> String:
	return "[F] Sleep until morning" if GameState.order == order_id else "[F] %s bed" % Story.ORDERS[order_id]["name"]

func build_dialogue() -> Dictionary:
	var o: Dictionary = Story.ORDERS[order_id]
	if GameState.order != order_id:
		return {"pages": [["%s bed" % o["name"], "The %s banner hangs over this one. Not yours." % o["banner"]]]}
	return {"pages": [["Your bed", "The %s banner glows softly over your pillow.  Sleep until morning?" % o["name"]]], "choices": [{"label": "Sleep", "enabled": true, "call": "sleep", "arg": null}, {"label": "Not yet", "enabled": true, "call": "noop", "arg": null}]}

func sleep(_a) -> void:
	var summary := GameState.day_summary()
	GameState.sleep_until_morning()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.call_deferred("open_dialogue", self, {"pages": [["The day's ledger", summary + "\n\nYou sleep. Morning comes to the valley."]]})
	GameState.say("You sleep. Morning comes to Ashenvale.")

func noop(_a) -> void:
	pass

func interact() -> void:
	pass
