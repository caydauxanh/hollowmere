extends Node3D
## Something the Quiet Night broke. Mend (spell 4) swaps it for the whole version.

var data := {}
var _model: Node3D
var _tag: Label3D

func setup(d: Dictionary) -> void:
	data = d

func _ready() -> void:
	add_to_group("mendable")
	_swap(GameState.mended.has(data["id"]))

func _swap(fixed: bool) -> void:
	if _model:
		_model.queue_free()
	if _tag:
		_tag.queue_free()
		_tag = null
	_model = load("res://assets/kaykit/" + (data["fixed"] if fixed else data["broken"])).instantiate()
	_model.scale = Vector3.ONE * float(data.get("scale", 1.0))
	add_child(_model)
	if not fixed:
		_tag = Label3D.new()
		_tag.text = "broken"
		_tag.font_size = 28
		_tag.pixel_size = 0.006
		_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_tag.no_depth_test = true
		_tag.modulate = Color(1.0, 0.7, 0.85, 0.85)
		_tag.outline_size = 8
		_tag.outline_modulate = Color(0.1, 0.0, 0.05, 0.9)
		_tag.position.y = 1.6
		add_child(_tag)

func is_broken() -> bool:
	return not GameState.mended.has(data["id"])

func mend() -> bool:
	if not is_broken():
		return false
	GameState.mended[data["id"]] = true
	GameState.coins += 3
	GameState.add_ember(1)
	GameState.mark_dirty()
	_swap(true)
	GameState.say("Mended.  +3 coins  +1 Ember   (%d / %d repaired)" % [GameState.mended.size(), Story.BROKEN.size()])
	return true
