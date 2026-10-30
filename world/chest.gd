extends Node3D
## A small chest holding a Founders' Card.

var card_id := ""
var _m: Node3D

func setup(id: String) -> void:
	card_id = id

func _ready() -> void:
	add_to_group("interactable")
	_m = load("res://assets/kaykit/dungeon/chest.glb").instantiate()
	_m.scale = Vector3.ONE * 0.7
	add_child(_m)
	if GameState.cards.has(card_id):
		_m.rotation.x = 0.0
	var tag := Label3D.new()
	tag.text = "chest" if not GameState.cards.has(card_id) else "empty chest"
	tag.name = "Tag"
	tag.font_size = 26
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.modulate = Color(1.0, 0.9, 0.6, 0.85)
	tag.outline_size = 8
	tag.outline_modulate = Color(0.1, 0.05, 0.0, 0.9)
	tag.position.y = 1.3
	add_child(tag)

func get_prompt() -> String:
	return "[F] Open the chest" if not GameState.cards.has(card_id) else "[F] An empty chest"

func get_action_anim() -> String:
	return "PickUp"

func build_dialogue() -> Dictionary:
	var c: Dictionary = Story.CARDS[card_id]
	if GameState.cards.has(card_id):
		return {"pages": [["Empty chest", "You already took the card from this one: %s." % c["name"]]]}
	GameState.cards[card_id] = true
	GameState.coins += 5
	GameState.add_ember(1)
	GameState.add_marks(1, "Founders' Card %d / %d" % [GameState.cards.size(), Story.CARDS.size()])
	get_node("Tag").text = "empty chest"
	var extra := ""
	if GameState.cards.size() == Story.CARDS.size():
		GameState.coins += 60
		GameState.add_ember(5)
		extra = "\n\nThat is all twelve. Quill will want to see them. (+60 coins, +5 Ember)"
	return {"pages": [["Founders' Card: " + c["name"], c["text"] + "\n\n(+5 coins, +1 Ember)" + extra]]}

func interact() -> void:
	pass
