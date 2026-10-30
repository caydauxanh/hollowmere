extends Node3D
## A shelf of small trophies that fills as you play.

func _ready() -> void:
	add_to_group("interactable")
	var shelf: Node3D = load("res://assets/kaykit/dungeon/shelf_small.gltf.glb").instantiate()
	shelf.scale = Vector3.ONE * 0.9
	add_child(shelf)
	var items := []
	if GameState.cards.size() >= 1: items.append(["dungeon/coin_stack_small.gltf.glb", 0.6])
	if GameState.fish_caught >= 10: items.append(["dungeon/plate_food_A.gltf.glb", 0.6])
	if GameState.best_duel >= 8: items.append(["dungeon/sword_shield_gold.gltf.glb", 0.4])
	if GameState.chapter4_done: items.append(["dungeon/candle_thin_lit.gltf.glb", 0.6])
	if GameState.chapter7_done: items.append(["dungeon/chest_gold.glb", 0.35])
	if GameState.broom: items.append(["dungeon/keyring.gltf.glb", 0.6])
	for i in items.size():
		var n: Node3D = load("res://assets/kaykit/" + items[i][0]).instantiate()
		n.scale = Vector3.ONE * items[i][1]
		n.position = Vector3(-0.8 + i * 0.35, 1.05 if i % 2 == 0 else 1.75, 0.0)
		add_child(n)
	var tag := Label3D.new()
	tag.text = "Trophies"
	tag.font_size = 28
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.4
	add_child(tag)

func get_prompt() -> String:
	return "[F] Look at the trophy shelf"

func build_dialogue() -> Dictionary:
	var lines := []
	lines.append("Founders' Cards: %d / %d" % [GameState.cards.size(), Story.CARDS.size()])
	lines.append("Fish caught: %d   ·   Duelling best: %d / 8   ·   Spark Targets best: %d" % [GameState.fish_caught, GameState.best_duel, GameState.best_targets])
	lines.append("Broom Course best: %s" % (("%.1f s" % GameState.best_broom) if GameState.best_broom > 0.0 else "—"))
	lines.append("Marks: %d (%s)   ·   Ember: %d   ·   Lanterns lit: %d" % [GameState.marks, Story.rank_for(GameState.marks), GameState.ember, GameState.lanterns_lit.size()])
	lines.append("Star shards: %d / %d   ·   Repairs: %d / %d   ·   Memories heard: %d" % [GameState.shards.size(), Story.SHARDS.size(), GameState.mended.size(), Story.BROKEN.size(), GameState.memories_heard.size()])
	return {"pages": [["Trophy shelf", "\n".join(lines)]]}

func interact() -> void:
	pass
