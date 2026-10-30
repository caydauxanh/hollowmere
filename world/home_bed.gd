extends Node3D
## Your own bed at the apothecary: sleep until morning.

func _ready() -> void:
	add_to_group("interactable")

func get_prompt() -> String:
	return "[F] Sleep until morning"

func build_dialogue() -> Dictionary:
	return {"pages": [["Your bed", "The quilt smells of Whisperleaf. Sleep until 6:30?"]], "choices": [{"label": "Sleep", "enabled": true, "call": "sleep", "arg": null}, {"label": "Not yet", "enabled": true, "call": "noop", "arg": null}]}

func sleep(_a) -> void:
	var summary := GameState.day_summary()
	GameState.sleep_until_morning()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.call_deferred("open_dialogue", self, {"pages": [["The day's ledger", summary + "\n\nYou sleep. Morning comes to the valley."]]})
	GameState.say("You sleep. Morning light through the window.")

func noop(_a) -> void:
	pass

func interact() -> void:
	pass
