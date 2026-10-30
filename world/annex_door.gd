extends Node3D
## Gate to the Restricted Shelves. Quill unlocks it once the Ember is bright.

var _model: Node3D
var _body: StaticBody3D
var _open := false

func _ready() -> void:
	add_to_group("interactable")
	_model = load("res://assets/kaykit/dungeon/wall_gated.gltf.glb").instantiate()
	_model.scale = Vector3.ONE * 0.9
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
	if GameState.quests_done.has("annex"):
		_unlock(false)

func get_prompt() -> String:
	return "[F] Gated door" if not _open else ""

func build_dialogue() -> Dictionary:
	if _open:
		return {"pages": [["Restricted Shelves", "The gate stands open. Three books, and a great deal of quiet."]]}
	if GameState.quests_done.has("annex"):
		_unlock(true)
		return {"pages": [["Gated door", "The lock turns at your touch. Quill's doing."]]}
	return {"pages": [["Gated door", "Iron bars, a lock with no keyhole. A plate reads: RESTRICTED. ASK THE ARCHIVIST."]]}

func _unlock(animate: bool) -> void:
	_open = true
	_body.queue_free()
	if animate:
		var tw := create_tween()
		tw.tween_property(_model, "position", Vector3(0, 4.2, 0), 1.0).set_trans(Tween.TRANS_SINE)
	else:
		_model.position = Vector3(0, 4.2, 0)

func interact() -> void:
	pass
