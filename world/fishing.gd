extends Node3D
## Fishing spot on the Lake Mirren dock. F casts; when the float dips ("!"), press F within a second.

var _state := "idle"   # idle, waiting, bite, done
var moon_bonus := 0.0   # extra Moonfish chance at night (Heron Isle)
var _t := 0.0
var _float: MeshInstance3D
var _tag: Label3D
var _line: MeshInstance3D


func _ready() -> void:
	add_to_group("interactable")
	_tag = Label3D.new()
	_tag.text = "Fishing spot"
	_tag.font_size = 36
	_tag.pixel_size = 0.006
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.outline_size = 10
	_tag.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	_tag.modulate = Color(0.75, 0.9, 1.0)
	_tag.position.y = 2.4
	add_child(_tag)
	_float = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	_float.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.3, 0.3)
	_float.material_override = m
	_float.position = Vector3(0, 0.1, 4.0)
	_float.visible = false
	add_child(_float)


func get_prompt() -> String:
	match _state:
		"idle": return "[F] Cast a line"
		"waiting": return "…waiting for a bite"
		"bite": return "[F] NOW!"
	return "[F] Cast a line"


func get_action_anim() -> String:
	return "Spellcast_Shoot" if _state == "idle" else "PickUp"


func interact() -> void:
	match _state:
		"idle":
			_state = "waiting"
			_t = randf_range(2.5, 6.0)
			_float.visible = true
			_float.position.y = 0.1
			_tag.text = "…"
		"waiting":
			_state = "idle"
			_float.visible = false
			_tag.text = "Fishing spot"
			GameState.say("Too early. The float had not moved.")
		"bite":
			_catch()


func _catch() -> void:
	_state = "idle"
	_float.visible = false
	_tag.text = "Fishing spot"
	var r := randf()
	var id := "minnow"
	if GameState.is_night() and r < 0.3 + moon_bonus:
		id = "moonfish"
	elif r < 0.55:
		id = "perch"
	GameState.add_item(id, 1)
	GameState.fish_caught += 1
	GameState.mark_dirty()
	var msg := "Caught a %s!  (%d fish in all)" % [GameState.ITEM_NAMES[id], GameState.fish_caught]
	if GameState.fish_caught in [1, 10, 25]:
		GameState.add_marks(1, "Angler")
	if id == "moonfish":
		GameState.add_ember(1)
		msg += "  A Moonfish — Tamsin pays well."
	GameState.say(msg)


func _process(delta: float) -> void:
	if _state == "waiting":
		_t -= delta
		_float.position.y = 0.1 + sin(Time.get_ticks_msec() / 300.0) * 0.04
		if _t <= 0.0:
			_state = "bite"
			_t = 1.1
			_float.position.y = -0.25
			_tag.text = "!"
			GameState.say("A bite!  Press F!")
	elif _state == "bite":
		_t -= delta
		if _t <= 0.0:
			_state = "idle"
			_float.visible = false
			_tag.text = "Fishing spot"
			GameState.say("It got away.")
