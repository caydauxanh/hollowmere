extends Node3D
## A shelf that is actually a door. It slides open once you have heard Corvin's or Mirabel's story.

var _model: Node3D
var _body: StaticBody3D
var _open := false

func _ready() -> void:
	add_to_group("interactable")
	_model = load("res://assets/kaykit/dungeon/shelves.gltf.glb").instantiate()
	_model.scale = Vector3.ONE * 0.85
	_model.rotation.y = PI / 2.0
	add_child(_model)
	_body = StaticBody3D.new()
	var col := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(0.6, 4.0, 3.6)
	col.shape = b
	col.position.y = 2.0
	_body.add_child(col)
	add_child(_body)
	if GameState.quests_done.has("cellar_open"):
		_slide(false)

func get_prompt() -> String:
	return "[F] An odd shelf" if not _open else ""

func build_dialogue() -> Dictionary:
	if _open:
		return {"pages": [["Open passage", "The shelf stands aside. Cold air from the cellar."]]}
	if GameState.memories_heard.has("corvin") or GameState.memories_heard.has("mirabel"):
		GameState.quests_done["cellar_open"] = true
		GameState.add_ember(1)
		GameState.mark_dirty()
		_slide(true)
		return {"pages": [["An odd shelf", "You push where the dust is thinnest. The whole shelf swings inward on a hinge nobody oiled for nine years. A cellar."]]}
	return {"pages": [["An odd shelf", "The dust on this shelf is thinner on one side, as if someone leans on it. It does not move for you. Not yet. (Someone here knows what is behind it.)"]]}

func _slide(animate: bool) -> void:
	_open = true
	_body.queue_free()
	if animate:
		var tw := create_tween()
		tw.tween_property(_model, "position", Vector3(0, 0, -3.2), 1.2).set_trans(Tween.TRANS_SINE)
	else:
		_model.position = Vector3(0, 0, -3.2)

func interact() -> void:
	pass
