extends Node3D
## The shrine candle in the square: the one flame that never went out. Completes the ring of fires.

func _ready() -> void:
	add_to_group("interactable")

func get_prompt() -> String:
	return "[F] The shrine candle"

func build_dialogue() -> Dictionary:
	var wt := GameState.lanterns_lit.has("watchtower")
	var isle := GameState.lanterns_lit.has("isle")
	if wt and isle and GameState.is_night() and not GameState.quests_done.has("ring"):
		GameState.quests_done["ring"] = true
		GameState.add_ember(10)
		GameState.add_marks(5, "The ring of fires")
		GameState.mark_dirty()
		return {"pages": [["The shrine candle", "Watchtower. Isle. Shrine. For the first time in nine years all three burn at once, and the candle's flame stands straight up, tall as a hand, the way the old book said it would."], ["The shrine candle", "Somewhere above, a wheel that was stuck comes free.\n\n(+10 Ember, +5 Marks — the ring of fires is whole)"]]}
	if not GameState.shrine_smelled:
		GameState.shrine_smelled = true
		GameState.mark_dirty()
	var lines := ["Ashen Vale's lantern, nine hundred years on. It has never gone out. Mirabel stopped asking why.", "It smells, faintly, of Whisperleaf and iron."]
	if not wt:
		lines.append("The flame leans north-east, toward the Watchtower, as if listening for something.")
	elif not isle:
		lines.append("The flame leans east, toward the lake.")
	elif not GameState.is_night():
		lines.append("The flame stands very still. Come back after dark.")
	else:
		lines.append("The ring is whole. The flame stands tall.")
	return {"pages": [["The shrine candle", "\n\n".join(lines)]]}

func interact() -> void:
	pass
