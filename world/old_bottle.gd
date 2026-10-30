extends Node3D
## Mirabel's unlabelled Warmth Tonic from the morning after the Quiet Night.

func _ready() -> void:
	add_to_group("interactable")
	var b: Node3D = load("res://assets/kaykit/dungeon/bottle_B_brown.gltf.glb").instantiate()
	b.scale = Vector3.ONE * 0.7
	add_child(b)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.omni_range = 2.5
	l.light_energy = 0.8
	l.position.y = 0.3
	add_child(l)

func get_prompt() -> String:
	return "[F] An unlabelled bottle"

func build_dialogue() -> Dictionary:
	if GameState.quests_done.has("old_bottle"):
		return {"pages": [["Mirabel's bottle", "Half full. It will stay that way; some things are for keeping."]]}
	GameState.quests_done["old_bottle"] = true
	GameState.add_ember(3)
	GameState.add_friend("corvin", 2)
	GameState.add_friend("mirabel", 2)
	GameState.add_marks(2, "The unlabelled bottle")
	GameState.mark_dirty()
	return {"pages": [["Mirabel's bottle", "Brown glass, no label, half full. It is warm. It has been warm for nine years."], ["Mirabel's bottle", "This is the Warmth Tonic Mirabel brewed the morning after the Quiet, the one that relit Gorrin's forge. Corvin kept it. Not on the top shelf; here, where nobody would ask.\n\n(+3 Ember, +2 Marks — Corvin and Mirabel will both want to know you found it)"]]}

func interact() -> void:
	pass
