extends Node3D
## Notice board by the shrine: lists today's villager requests.

func _ready() -> void:
	add_to_group("interactable")
	var post: Node3D = load("res://assets/kaykit/halloween/plaque.gltf").instantiate()
	post.scale = Vector3.ONE * 1.1
	add_child(post)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(1.4, 2.0, 0.5)
	col.shape = b
	col.position.y = 1.0
	body.add_child(col)
	add_child(body)
	var tag := Label3D.new()
	tag.text = "Notice Board"
	tag.font_size = 40
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 10
	tag.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	tag.position.y = 2.4
	add_child(tag)


func get_prompt() -> String:
	return "[F] Read the notice board"


func build_dialogue() -> Dictionary:
	var pages := [["Notice Board", "%s  ·  %s, %s" % [Story.today_key(), Story.season().capitalize(), Story.weather()]]]
	var bd := Story.birthday_today()
	if not bd.is_empty():
		var names := []
		for id in bd:
			names.append(Story.NPCS[id]["name"])
		pages.append(["Birthday", "Today is %s's birthday. A gift today counts for a great deal." % " and ".join(names)])
	var ev := Story.todays_event()
	if not ev.is_empty():
		pages.append(["★ " + ev["name"], ev["text"]])
	var letter := Story.todays_letter()
	if not letter.is_empty():
		GameState.last_letter_day = Story.today_key()
		if letter["gift"] == "coins":
			GameState.coins += letter["amount"]
		else:
			GameState.add_item(letter["gift"], letter["amount"])
		GameState.mark_dirty()
		var who: String = Story.NPCS[letter["from"]]["name"]
		pages.append(["Letter from %s" % who, "%s\n\n(Enclosed: %d %s)" % [letter["text"], letter["amount"], "coins" if letter["gift"] == "coins" else GameState.ITEM_NAMES[letter["gift"]]]])
	var any := false
	for r in Story.todays_requests():
		var done: bool = GameState.quests_done.has(r["id"])
		var who: String = Story.NPCS[r["npc"]]["name"]
		pages.append(["Notice Board", "%s %s: %d × %s\n%s" % ["✓" if done else "•", who, r["amount"], Story.item_name(r["item"]), "Delivered." if done else r["line"]]])
		any = true
	if not any:
		pages.append(["Notice Board", "Nothing today. Enjoy the quiet."])
	pages.append(["The Hollowmere Gazette", "• " + "\n\n• ".join(Story.todays_gazette())])
	pages.append(["Notice Board", "Village Ember: %d / %d   ·   Coins: %d" % [GameState.ember, Story.EMBER_GATE, GameState.coins]])
	return {"pages": pages}


func interact() -> void:
	pass
