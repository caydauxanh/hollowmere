class_name Villager
extends Walker
## A villager: KayKit character with idle animation, name tag, daily request and dialogue.
## Walks its daily schedule along real routes (NavGrid), strolls a little around its post,
## turns to face you when you come close, and never passes through walls or people.

const SCALE := 0.62

var npc_id := ""
var data := {}
var _anim: AnimationPlayer
var _skin: Node3D
var _tag: Label3D
var _bubble: Label3D
var _sleep := false
var _target_pos := Vector3.INF
var _target_face := 0.0
var _lesson := ""
var _q := 0
var _correct := 0
var _gesture_t := 5.0
var _hiding := false
var _stroll_t := 6.0
var _strolling := false
var _retry_t := 3.0
var _post_eff := Vector3.INF   # where we actually stand: the post, or the nearest clear spot beside it
var _post_ok := false
var _away_from_post := false


func setup(id: String) -> void:
	npc_id = id
	data = Story.NPCS[id]


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("villager")
	position = data["pos"]
	_skin = load("res://assets/kaykit/chars/%s.glb" % data["model"]).instantiate()
	_skin.scale = Vector3.ONE * float(data.get("scale", SCALE))
	_skin.rotation.y = deg_to_rad(data["face"])
	add_child(_skin)
	skin = _skin
	walk_speed = 2.0
	for mi in _skin.find_children("*", "MeshInstance3D", true, false):
		for i in mi.get_surface_override_material_count():
			var base: Material = mi.mesh.surface_get_material(i) if mi.mesh else null
			var m: StandardMaterial3D = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
			if data.has("tint"):
				m.albedo_color = data["tint"]
			if data.get("ghost", false):
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.albedo_color.a = 0.55
				m.emission_enabled = true
				m.emission = Color(0.5, 0.7, 0.9)
				m.emission_energy_multiplier = 0.6
			m.rim_enabled = true
			m.rim = 0.5
			m.rim_tint = 0.6
			mi.set_surface_override_material(i, m)
	_anim = _skin.get_node("AnimationPlayer")
	_anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
	_anim.get_animation("Walking_A").loop_mode = Animation.LOOP_LINEAR
	_anim.play("Idle")
	_anim.seek(randf() * 1.0)
	_stroll_t = randf_range(4.0, 14.0)

	_tag = Label3D.new()
	_tag.text = data["name"]
	_tag.font_size = 44
	_tag.pixel_size = 0.006
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.modulate = data["color"]
	_tag.outline_size = 10
	_tag.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	_tag.position.y = 2.25
	add_child(_tag)

	_bubble = Label3D.new()
	_bubble.text = "!"
	_bubble.font_size = 72
	_bubble.pixel_size = 0.006
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.modulate = Color(1.0, 0.85, 0.3)
	_bubble.outline_size = 12
	_bubble.outline_modulate = Color(0.3, 0.15, 0.0)
	_bubble.position.y = 2.75
	add_child(_bubble)
	if data.get("ghost", false):
		collision_layer = 0   # a ghost is not solid


func _process(_delta: float) -> void:
	if _anim == null:
		return
	var h := GameState.hour_of_day()
	var asleep: bool = (h >= 21.5 or h < 6.5) and data.get("scene", "village") == "village" and not data.get("night_only", false)
	if data.get("night_owl", false) and h >= 21.5 and h < 24.0:
		asleep = false
	if data.get("night_only", false):
		asleep = not GameState.is_night()
	if asleep != _sleep:
		_sleep = asleep
		set_shown(not asleep)
	_follow_schedule(h, _delta)
	var near := true
	var plr := get_tree().get_first_node_in_group("player")
	if plr:
		near = (plr as Node3D).global_position.distance_to(global_position) < 16.0
	_tag.visible = near
	_bubble.visible = near and not Story.request_for(npc_id).is_empty()
	var t := Time.get_ticks_msec() / 1000.0
	_bubble.position.y = 2.75 + sin(t * 3.0) * 0.08


## Daily schedule: [start, end, pos, face] entries in Story; walk there, otherwise stand at home pos.
func _follow_schedule(h: float, delta: float) -> void:
	if _hiding:
		return
	var want: Vector3 = data["pos"]
	var face: float = data["face"]
	var my_scene: String = get_tree().current_scene.name.to_lower()
	var home_scene: String = data.get("scene", "village")
	var elsewhere := false
	for e in data.get("schedule", []):
		if h >= e[0] and h < e[1] and e.size() > 4:
			# This slot is in another scene (e.g. the tavern)
			if str(e[4]) == my_scene:
				want = e[2]
				face = e[3]
				elsewhere = false
			else:
				elsewhere = true
			break
	if my_scene != home_scene and not (my_scene == "tavern" and _in_tavern_slot(h)):
		set_shown(false)
		return
	if elsewhere:
		set_shown(false)
		return
	if not _sleep:
		set_shown(true)
	if Story.todays_event().get("id", "") == "lantern" and h >= 19.0 and h < 21.0 and data.get("scene", "village") == "village" and npc_id != "hatch" and npc_id != "marrow":
		var k := npc_id.hash() % 7
		want = Vector3(2.0 + cos(k * 0.9) * 8.0, 0, 28.0 + sin(k * 0.9) * 6.0)
		face = 180.0
	for e in data.get("schedule", []):
		if h >= e[0] and h < e[1] and e.size() <= 4:
			want = e[2]
			face = e[3]
			break
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	var pd: float = pl.global_position.distance_to(global_position) if pl else 1e9
	if want != _target_pos:
		_target_pos = want
		_target_face = face
		_strolling = false
		_post_eff = _resolve_post(want)
		_post_ok = _nav != null and _nav.built
		_head_for_post(pl == null or pd > 45.0 or not visible)
		return
	if not _post_ok and _grid() and _nav.built:
		# The grid came up after the post was set: move to the standable spot if it differs.
		_post_ok = true
		var e := _resolve_post(_target_pos)
		if e.distance_to(_post_eff) > 0.2:
			_post_eff = e
			_head_for_post(pl == null or pd > 45.0 or not visible)
			return
	if is_walking():
		return
	# Standing. In a conversation: hold still.
	if GameState.ui_locked:
		return
	var at_post := _post_eff.distance_to(global_position) < 0.9
	# Did not make it (no route, spot taken): appear there once nobody is looking, else try again later.
	if not at_post and not _strolling and _post_eff.distance_to(global_position) > 5.0:
		if pd > 45.0:
			teleport(_post_eff)
		else:
			_retry_t -= delta
			if _retry_t <= 0.0:
				_retry_t = 8.0
				go_to(_post_eff)
		return
	# Turn to face the player when they come close, otherwise face the post's direction.
	if pl and pd < 4.5:
		var to_p: Vector3 = pl.global_position - global_position
		to_p.y = 0.0
		_skin.rotation.y = lerp_angle(_skin.rotation.y, atan2(to_p.x, to_p.z), 5.0 * delta)
		_stroll_t = maxf(_stroll_t, 3.0)
	elif at_post and not _strolling:
		_skin.rotation.y = lerp_angle(_skin.rotation.y, deg_to_rad(_target_face), 4.0 * delta)
	# A little life: every so often stroll a few steps near the post, then come back.
	_stroll_t -= delta
	if _stroll_t <= 0.0:
		if _strolling or not at_post:
			_strolling = false
			walk_speed = 1.3
			go_to(_post_eff)
			_stroll_t = randf_range(10.0, 24.0)
		elif _goal == Vector3.INF and pd < 40.0 and _nav and _nav.built:
			var a := randf() * TAU
			var p := _post_eff + Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 4.0)
			var sy := _nav._surface_y(p)
			if sy != NavGrid.BLOCKED and absf(sy - global_position.y) < 0.3 and _nav.line_clear(global_position, p):
				_strolling = true
				walk_speed = 1.1
				go_to(p)
			_stroll_t = randf_range(5.0, 12.0)
		else:
			_stroll_t = randf_range(4.0, 10.0)
	if not _strolling:
		_gesture_t -= delta
		if _gesture_t <= 0.0:
			_gesture_t = randf_range(6.0, 16.0)
			if _anim.current_animation == "Idle" and _anim.has_animation("Interact"):
				_anim.play("Interact", 0.3)
				_anim.animation_finished.connect(func(_n): _anim.play("Idle", 0.3), CONNECT_ONE_SHOT)


func _head_for_post(instant: bool) -> void:
	if instant:
		teleport(_post_eff)
	else:
		go_to(_post_eff)


## Posts were placed by hand and some sit inside a building's collision box (a doorway, a counter).
## A solid body cannot stand there, so pick the nearest clear spot within a couple of metres.
func _resolve_post(p: Vector3) -> Vector3:
	if _grid() == null or not _nav.built:
		return p
	if _standable(p):
		return p
	var best := p
	var bd := 1e9
	for ri: float in [0.7, 1.3, 1.9, 2.5, 3.2]:
		for k in 12:
			var a := k * TAU / 12.0
			var q := p + Vector3(cos(a), 0, sin(a)) * ri
			if _standable(q):
				var d := q.distance_to(p)
				if d < bd:
					bd = d
					best = q
		if bd < 1e9:
			break
	return best


func _standable(q: Vector3) -> bool:
	var sy := _nav._surface_y(q)
	if sy == NavGrid.BLOCKED or absf(sy) > 0.35:
		return false
	var sq := PhysicsShapeQueryParameters3D.new()
	var sp := CylinderShape3D.new()
	sp.radius = 0.5
	sp.height = 1.2
	sq.shape = sp
	sq.collision_mask = 1
	sq.transform = Transform3D(Basis.IDENTITY, Vector3(q.x, sy + 0.75, q.z))
	return _nav._space.intersect_shape(sq, 1).is_empty()


func _on_moving_changed(moving: bool) -> void:
	if moving:
		_anim.play("Walking_A", 0.25)
	else:
		_anim.speed_scale = 1.0
		_anim.play("Idle", 0.35)
		walk_speed = 2.0


func _on_walk(_delta: float, speed: float) -> void:
	if _moving:
		_anim.speed_scale = clampf(speed / 2.0, 0.55, 1.25)


func _in_tavern_slot(h: float) -> bool:
	for e in data.get("schedule", []):
		if h >= e[0] and h < e[1] and e.size() > 4 and str(e[4]) == "tavern":
			return true
	return false


func is_available() -> bool:
	return not _sleep


func get_prompt() -> String:
	return "[F] Talk to %s" % data["name"]


func get_action_anim() -> String:
	return "Interact"


func cheer() -> void:
	_anim.play("Cheer", 0.2)
	await _anim.animation_finished
	_anim.play("Idle", 0.3)


## Builds the dialogue for this moment: intro, request/deliver, or chat.
func build_dialogue() -> Dictionary:
	var name: String = data["name"]
	if not GameState.met.has(npc_id):
		GameState.met[npc_id] = true
		GameState.add_friend(npc_id, 1)
		var pages := []
		for line in data["intro"]:
			pages.append([name, line])
		_teach()
		return {"pages": pages}
	_teach()
	if data.get("shop", false):
		return _shop_dialogue()
	if npc_id == "gorrin" and GameState.broom:
		var ch := []
		for cid in Story.CRYSTALS:
			var c: Dictionary = Story.CRYSTALS[cid]
			var have: bool = GameState.staff_color == cid
			ch.append({"label": "%s — %s" % [c["name"], "fitted" if have else ("%d coins" % c["price"] if c["price"] > 0 else "free")], "enabled": not have and GameState.coins >= c["price"], "call": "fit_crystal", "arg": cid})
		return {"pages": [[name, "Staff crystals. Change the colour of your light; does nothing else, looks grand.  (Coins: %d)" % GameState.coins]], "choices": ch}
	if npc_id == "gorrin" and not GameState.broom:
		return {"pages": [[name, "Ashwood broom. Bristles from the Fernmoor reeds, shaft from a tree that fell on the Quiet Night. It flies. Mostly up.\n\n60 coins, and I throw in the advice: land before you dismount.  (Coins: %d)" % GameState.coins]], "choices": [{"label": "Buy the broom — 60 coins", "enabled": GameState.coins >= 60, "call": "buy_broom", "arg": null}, {"label": "Not today", "enabled": true, "call": "noop", "arg": null}]}
	if Story.FAVOURS.has(npc_id) and not GameState.favours.has(npc_id) and GameState.met.has(npc_id):
		var fv: Dictionary = Story.FAVOURS[npc_id]
		var done := false
		match fv["check"]:
			"duel6": done = GameState.best_duel >= 6
			"notes": done = GameState.quests_done.has("lark_notes")
			"nightcap": done = GameState.inventory.get("nightcap", 0) >= 1
			"shrine": done = GameState.shrine_smelled
		if done:
			if fv["check"] == "nightcap":
				GameState.take_item("nightcap", 1)
				GameState.add_ember(1)
			else:
				GameState.coins += 10
			GameState.favours[npc_id] = true
			GameState.add_marks(2, "A favour for " + name)
			GameState.add_friend(npc_id, 3)
			GameState.mark_dirty()
			return {"pages": [[name, fv["reward"]]]}
		if not GameState.quests_done.has("favour_asked_" + npc_id):
			GameState.quests_done["favour_asked_" + npc_id] = true
			GameState.mark_dirty()
			return {"pages": [[name, fv["text"]]]}
	if GameState.order != "" and Story.ORDER_TASKS[GameState.order]["student"] == npc_id:
		var task: Dictionary = Story.ORDER_TASKS[GameState.order]
		var key := "%s/ordertask" % Story.today_key()
		if not GameState.quests_done.has(key):
			var prog := GameState.order_task_progress()
			if prog >= int(task["need"]):
				GameState.quests_done[key] = true
				GameState.coins += 15
				GameState.add_marks(3, "Order task for %s" % Story.ORDERS[GameState.order]["name"])
				GameState.add_friend(npc_id, 2)
				GameState.mark_dirty()
				return {"pages": [[name, "Done already? %s will be insufferable at Assembly. Good.\n\n(+15 coins, +3 Marks for the Order)" % Story.ORDERS[GameState.order]["name"]]]}
			return {"pages": [[name, "Today's task for %s: %s  (%d / %d)" % [Story.ORDERS[GameState.order]["name"], task["text"], prog, int(task["need"])]]]}
	if npc_id == "oriel" and GameState.order == "":
		return {"pages": [[name, "Before lessons, before anything: the Sorting. Four Orders, four questions, no wrong answers. Ready?"]], "choices": [{"label": "Begin the Sorting", "enabled": true, "call": "start_sorting", "arg": null}, {"label": "Not yet", "enabled": true, "call": "noop", "arg": null}]}
	# Headmistress: chapter quest check.
	if npc_id == "oriel" and not GameState.chapter2_done and GameState.village_lanterns_lit() >= Story.DARK_LANTERNS:
		GameState.chapter2_done = true
		GameState.coins += 30
		GameState.add_ember(5)
		GameState.add_friend(npc_id, 3)
		GameState.mark_dirty()
		return {"pages": [[name, "Every lantern. I watched them come back from the tower window, one by one."], [name, "Hollowmere is a village again. And you, apprentice, are a student of Ashenvale. The library opens next term.\n\n(+30 coins, +5 Ember — Chapter 2 complete)"]]}
	if npc_id == "oriel" and GameState.chapter5_done and not GameState.quests_done.has("epilogue"):
		GameState.quests_done["epilogue"] = true
		GameState.add_marks(5, "The Watchtower")
		GameState.add_friend(npc_id, 3)
		GameState.mark_dirty()
		return {"pages": [[name, "I saw it from the tower window. The Watchtower, lit, for the first time in nine years."], [name, "The Quiet Night was never a curse, apprentice. It was a watch-fire going out, and nobody left to climb the hill and relight it. You climbed."], [name, "Ashenvale is a school again. Hollowmere is a village again. Keep the lanterns; keep the Ember. There will be other dark nights. There will also be you.\n\n(+5 Marks — Chapter 5 complete)"]]}
	if npc_id == "pellam" and GameState.patrol_day != Story.today_key() and (GameState.hour_of_day() >= 21.5 or GameState.hour_of_day() < 2.0) and GameState.chapter2_done:
		var pt := get_tree().get_first_node_in_group("patrol")
		if pt and not pt._running:
			return {"pages": [[name, "Night Patrol, apprentice. Four posts: Hearth Row, the Market, the Green, the Trial Field. In order, three minutes. The broom is allowed. Pellam's rules."]], "choices": [{"label": "Begin the patrol", "enabled": true, "call": "patrol", "arg": null}, {"label": "Not tonight", "enabled": true, "call": "noop", "arg": null}]}
	if npc_id == "pip" and GameState.hide_day != Story.today_key() and GameState.hour_of_day() >= 9.0 and GameState.hour_of_day() < 14.0 and not _hiding:
		return {"pages": [[name, "Hide and seek! I hide, you count to ten, you find me. I'm REALLY good. I'm in the village somewhere. Go!"]], "choices": [{"label": "Count to ten", "enabled": true, "call": "go_hide", "arg": null}, {"label": "Later, Pip", "enabled": true, "call": "noop", "arg": null}]}
	if npc_id == "pip" and _hiding:
		_hiding = false
		GameState.hide_day = Story.today_key()
		GameState.coins += 6
		GameState.add_ember(1)
		GameState.add_friend(npc_id, 2)
		GameState.mark_dirty()
		_target_pos = Vector3.INF
		return {"pages": [[name, "FOUND ME. Okay. Okay okay. You're good. Again tomorrow.\n\n(+6 coins, +1 Ember)"]]}
	if npc_id == "nell" and GameState.sheep_day != Story.today_key() and not GameState.quests_done.has("sheep_" + Story.today_key()):
		GameState.quests_done["sheep_" + Story.today_key()] = true
		var sh := get_tree().get_first_node_in_group("lost_sheep")
		if sh:
			sh.wander_off()
		return {"pages": [[name, "One of them's got out again. The stubborn one. Named after you, as it happens. It'll be on the Watchtower road or down by the lake; pet it and it'll follow you home. Pen's at Ashford."]]}
	if npc_id == "isolde" and GameState.chapter3_done and not GameState.sunbell_bed and GameState.friend_level("isolde") >= 1:
		GameState.sunbell_bed = true
		GameState.recipes_unlocked["glow"] = true
		GameState.mark_dirty()
		return {"pages": [[name, "You have read the herbal, and you have been kind to my beds. So: Sunbell. A seed packet nobody has opened in nine years."], [name, "Plant it behind your apothecary; a bed will dig itself by morning. Two Sunbell and an Emberroot make Glowbrew. I have written it down for you. Do not drink it indoors.\n\n(New bed at the cottage, new recipe)"]]}
	if npc_id == "dilly" and not GameState.recipes_unlocked.has("pie"):
		if GameState.inventory.get("perch", 0) >= 1 and GameState.inventory.get("whisperleaf", 0) >= 1:
			GameState.take_item("perch", 1)
			GameState.take_item("whisperleaf", 1)
			GameState.recipes_unlocked["pie"] = true
			GameState.add_item("pie", 1)
			GameState.add_ember(2)
			GameState.add_friend(npc_id, 3)
			GameState.mark_dirty()
			return {"pages": [[name, "A perch and a Whisperleaf. Now watch: flake the fish, tear the leaf, an Emberroot for heat, and never, ever tell it a lie while it bakes."], [name, "Fernmoor Fish Pie. The recipe's yours; so is the first one. Give it to someone. That's what it's for.\n\n(+2 Ember, new recipe)"]]}
		return {"pages": [[name, "One Reed Perch, one Whisperleaf, and I'll teach you the pie. (%d / 1 perch, %d / 1 Whisperleaf)" % [GameState.inventory.get("perch", 0), GameState.inventory.get("whisperleaf", 0)]]]}
	if npc_id == "wennet" and not GameState.recipes_unlocked.has("shade"):
		if GameState.inventory.get("nightcap", 0) >= 2 and GameState.inventory.get("moonpetal", 0) >= 1:
			GameState.take_item("nightcap", 2)
			GameState.take_item("moonpetal", 1)
			GameState.recipes_unlocked["shade"] = true
			GameState.add_item("shade", 1)
			GameState.add_ember(3)
			GameState.add_friend(npc_id, 3)
			GameState.mark_dirty()
			return {"pages": [[name, "Two Nightcap, one Moonpetal. Yes. Now: stir with the left hand, and think of someone who is waiting for you."], [name, "Shade Draught. We drank it on the long watches so the dark would not get in. The recipe is yours; the first bottle too.\n\n(+3 Ember, new recipe)"]]}
		return {"pages": [[name, "Two Nightcap and a Moonpetal, when you have them. The purple flowers, after dark. I can wait. I am good at it. (%d / 2 Nightcap, %d / 1 Moonpetal)" % [GameState.inventory.get("nightcap", 0), GameState.inventory.get("moonpetal", 0)]]]}
	if npc_id == "marrow" and GameState.chapter6_done and not GameState.quests_done.has("epilogue_isle"):
		GameState.quests_done["epilogue_isle"] = true
		GameState.add_marks(3, "The Lake's Heart")
		GameState.add_friend(npc_id, 3)
		GameState.mark_dirty()
		return {"pages": [[name, "You lit it. Nine years I sat beside that lantern and could not."], [name, "The lake glowed to the bottom. I saw the second shrine. It is fine. It was always fine; it was waiting, like the rest of us."], [name, "Tell Oriel to set a chair. I am coming down the hill at last.\n\n(+3 Marks — Chapter 6 complete)"]]}
	if npc_id == "quill" and not GameState.chapter3_done:
		var pages: int = GameState.pages_found.size()
		var books: int = Story.public_books_read()
		if pages >= Story.PAGES_TOTAL and books >= Story.public_books_total():
			GameState.chapter3_done = true
			GameState.recipes_unlocked["elixir"] = true
			GameState.coins += 40
			GameState.add_ember(6)
			GameState.add_friend(npc_id, 3)
			GameState.mark_dirty()
			return {"pages": [[name, "Three pages. Five books. The catalogue is whole for the first time in nine years."], [name, "Mirabel's margin note is right, you know. Ember Elixir. The cauldron will take it now; I have written the proportions into your journal.\n\n(+40 coins, +6 Ember, new recipe — Chapter 3 complete)"]]}
		return {"pages": [[name, "Pages: %d of %d.  Books read: %d of %d.  %s" % [pages, Story.PAGES_TOTAL, books, Story.public_books_total(), "Keep looking." if pages < Story.PAGES_TOTAL else "Now read."]]]}
	if npc_id == "quill" and GameState.chapter3_done and not GameState.quests_done.has("annex"):
		if GameState.ember >= 30:
			GameState.quests_done["annex"] = true
			GameState.mark_dirty()
			return {"pages": [[name, "The Ember is bright enough. There has always been a second room. The door is in the tower's east wall; it opens for you now."], [name, "Three books. Restricted, because they are true, and true things want careful readers. Read them in order if you can. Tell no one what the third one says until you have decided what it means."]]}
		return {"pages": [[name, "There is a second room. Ask me again when the village Ember is brighter — thirty, say. (%d now)" % GameState.ember]]}
	if npc_id == "oriel" and not GameState.chapter2_done:
		var lit: int = GameState.village_lanterns_lit()
		if lit > 0:
			return {"pages": [[name, "%d of %d lanterns. Keep going." % [lit, Story.DARK_LANTERNS]]]}
	if data.get("scene", "village") == "academy":
		var ld := _lesson_dialogue()
		if not ld.is_empty():
			return ld
	var req := Story.request_for(npc_id)
	if not req.is_empty():
		var have: int = GameState.inventory.get(req["item"], 0)
		if have >= req["amount"]:
			return {"pages": [[name, "Is that... yes! Thank you, apprentice."]], "deliver": req}
		return {"pages": [[name, req["line"]], [name, "I'll be right here. (%s %d/%d)" % [Story.item_name(req["item"]), have, req["amount"]]]]}
	var lvl := GameState.friend_level(npc_id)
	if lvl >= 2 and Story.MEMORIES.has(npc_id) and not GameState.memories_heard.has(npc_id):
		GameState.memories_heard[npc_id] = true
		GameState.add_ember(2)
		GameState.add_marks(1, "A friend's story")
		GameState.mark_dirty()
		return {"pages": [[name, "Can I tell you something I have not told anyone?"], [name, Story.MEMORIES[npc_id]], [name, "There. Now you know. (+2 Ember)"]]}
	var pool: Array = data["chat"].duplicate()
	if lvl >= 1:
		pool.append(data["friend"][mini(lvl - 1, 2)])
	if lvl >= 2:
		pool.append(data["friend"][2])
	var out := {"pages": [[name, pool[randi() % pool.size()]]]}
	var choices := []
	if Story.ASK.has(npc_id):
		choices.append({"label": "Ask about the Quiet Night", "enabled": true, "call": "ask", "arg": "quiet"})
		choices.append({"label": "Ask about their work", "enabled": true, "call": "ask", "arg": "work"})
	if GameState.gifts_given.get(npc_id, "") != Story.today_key():
		for item in GameState.inventory:
			if GameState.inventory[item] > 0 and item in ["potion", "tonic", "draught", "elixir", "minnow", "perch", "moonfish", "moonpetal", "emberroot", "whisperleaf", "oil", "broth", "nightcap", "shade", "pie", "sunbell", "glow", "pumpkin"]:
				choices.append({"label": "Give %s" % GameState.ITEM_NAMES[item], "enabled": true, "call": "give", "arg": item})
	if not choices.is_empty():
		choices.append({"label": "Just chatting", "enabled": true, "call": "noop", "arg": null})
		out["choices"] = choices
	return out


func ask(topic: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and Story.ASK.has(npc_id):
		if not GameState.quests_done.has("ask_%s_%s" % [npc_id, topic]):
			GameState.quests_done["ask_%s_%s" % [npc_id, topic]] = true
			GameState.add_friend(npc_id, 1)
			GameState.mark_dirty()
		hud.call_deferred("open_dialogue", self, {"pages": [[data["name"], Story.ASK[npc_id][topic]]]})


## Teachers grant their spell once.
func _teach() -> void:
	if data.has("teaches") and not GameState.spells.has(data["teaches"]):
		GameState.spells[data["teaches"]] = true
		GameState.spells_changed.emit()
		GameState.mark_dirty()
		GameState.say("You learned %s!  Press %d to cast." % [Story.SPELLS[data["teaches"]]["name"], Story.SPELLS[data["teaches"]]["key"]])


func deliver(req: Dictionary) -> void:
	GameState.take_item(req["item"], req["amount"])
	GameState.quests_done[req["id"]] = true
	var reward := 8 if req["amount"] == 1 else 6
	GameState.coins += reward
	GameState.add_ember(2)
	GameState.add_friend(npc_id, 2)
	if req.get("homework", false):
		GameState.add_marks(2, "Homework for " + data["name"])
	GameState.say("+%d coins   +2 Ember   %s likes you more" % [reward, data["name"]])
	cheer()


# ---------------------------------------------------------------- shop (Tamsin)

func _shop_dialogue() -> Dictionary:
	var h := GameState.hour_of_day()
	var name: String = data["name"]
	if h < 8.0 or h >= 18.0:
		return {"pages": [[name, "Stall's shut. Eight to six, like the sign says."]]}
	var choices := []
	for id in Story.SHOP_BUY:
		var price: int = Story.SHOP_BUY[id]
		choices.append({"label": "Buy %s — %d coins" % [Story.item_name(id), price], "enabled": GameState.coins >= price, "call": "shop_buy", "arg": id})
	for id in Story.SHOP_SELL:
		var have: int = GameState.inventory.get(id, 0)
		choices.append({"label": "Sell %s — %d coins (have %d)" % [Story.item_name(id), Story.SHOP_SELL[id], have], "enabled": have > 0, "call": "shop_sell", "arg": id})
	if GameState.garden_level < 2:
		var price := 40 + GameState.garden_level * 40
		choices.append({"label": "Garden expansion: +3 beds behind the apothecary — %d coins" % price, "enabled": GameState.coins >= price, "call": "buy_garden", "arg": null})
	return {"pages": [[name, "Herbs in, potions out. What'll it be?\n\nCoins: %d" % GameState.coins]], "choices": choices}


func shop_buy(id: String) -> void:
	var price: int = Story.SHOP_BUY[id]
	if GameState.coins < price:
		return
	GameState.coins -= price
	GameState.add_item(id, 1)
	GameState.say("Bought 1 %s for %d coins." % [Story.item_name(id), price])


func shop_sell(id: String) -> void:
	if not GameState.take_item(id, 1):
		return
	var price: int = Story.SHOP_SELL[id]
	if Story.todays_event().get("id", "") == "market":
		price = int(price * 1.5)
	GameState.coins += price
	GameState.add_ember(1)
	GameState.add_friend(npc_id, 1)
	GameState.mark_dirty()
	GameState.say("Sold %s for %d coins.  +1 Ember%s" % [Story.item_name(id), price, "  (Market Day!)" if price != Story.SHOP_SELL[id] else ""])


# ---------------------------------------------------------------- lessons (Academy)

func _my_lesson() -> String:
	for id in Story.LESSONS:
		if Story.LESSONS[id]["teacher"] == npc_id:
			return id
	return ""


func _lesson_dialogue() -> Dictionary:
	var id := _my_lesson()
	if id == "":
		return {}
	var L: Dictionary = Story.LESSONS[id]
	var name: String = data["name"]
	var key := "%s/%s" % [Story.today_key(), id]
	var h := GameState.hour_of_day()
	var in_window: bool = h >= L["start"] and h < L["end"]
	if not in_window:
		if randf() < 0.5:
			return {"pages": [[name, "%s is at %02d:00-%02d:00 in the %s. The timetable is on the board by the door; use Time +6h if you cannot wait." % [L["name"], int(L["start"]), int(L["end"]), L["room"]]]]}
		return {}
	if GameState.lessons_done.has(key):
		var pk := key + "/practical"
		if not GameState.lessons_done.has(pk) and id != "assembly":
			var tip: String = {"flame": "Now the practical: Kindle the brazier here before the hour ends.", "herb": "Now the practical: cast Verdant on one of the greenhouse beds.", "lore": "Now the practical: read any book on these shelves before the hour ends.", "potions": "Now the practical: brew anything in the class cauldron.", "astronomy": "Now the practical: look through the telescope and find a constellation."}[id]
			return {"pages": [[name, tip]]}
		return {}
	if id == "assembly":
		var today := 0
		for k in GameState.lessons_done:
			if str(k).begins_with(Story.today_key()):
				today += int(GameState.lessons_done[k])
		GameState.lessons_done[key] = 1
		GameState.coins += 5 + today * 2
		GameState.add_marks(1, "Evening Assembly")
		return {"pages": [[name, "Assembly. Stand straight, apprentice."], [name, "Today you earned %d Marks in lessons. Rank: %s.  The village lanterns are %d of %d.\n\n(+%d coins for attendance)" % [today, Story.rank_for(GameState.marks), GameState.village_lanterns_lit(), Story.DARK_LANTERNS, 5 + today * 2]]]}
	return {"pages": [[name, "%s. Three questions, three Marks. Ready?" % L["name"]]], "choices": [{"label": "Begin the lesson", "enabled": true, "call": "start_lesson", "arg": id}, {"label": "Not yet", "enabled": true, "call": "noop", "arg": null}]}


func noop(_a) -> void:
	pass


func start_lesson(id: String) -> void:
	_lesson = id
	_q = 0
	_correct = 0
	call_deferred("_ask")


func _ask() -> void:
	var L: Dictionary = Story.LESSONS[_lesson]
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	if _q >= L["quiz"].size():
		var key := "%s/%s" % [Story.today_key(), _lesson]
		GameState.lessons_done[key] = _correct
		if _correct > 0:
			GameState.add_marks(_correct, L["name"])
		if _correct == L["quiz"].size():
			GameState.add_ember(1)
			if _lesson == "potions" and not GameState.recipes_unlocked.has("oil"):
				GameState.recipes_unlocked["oil"] = true
				GameState.recipes_unlocked["broth"] = true
				GameState.say("Corvin writes two recipes into your journal: Lantern Oil and Heron Broth.")
		GameState.add_friend(npc_id, 1)
		GameState.mark_dirty()
		var verdict := "Full marks. Go and be insufferable about it." if _correct == 3 else ("Good enough. Read the books in the library." if _correct > 0 else "Nothing. Read. Then come back tomorrow.")
		hud.open_dialogue(self, {"pages": [[data["name"], "%d of %d.  %s" % [_correct, L["quiz"].size(), verdict]]]})
		cheer()
		return
	var q: Array = L["quiz"][_q]
	var choices := []
	for i in q[1].size():
		choices.append({"label": q[1][i], "enabled": true, "call": "answer", "arg": i})
	hud.open_dialogue(self, {"pages": [[data["name"], "Question %d.  %s" % [_q + 1, q[0]]]], "choices": choices})


func answer(i: int) -> void:
	var q: Array = Story.LESSONS[_lesson]["quiz"][_q]
	if i == q[2]:
		_correct += 1
		GameState.say("Correct.")
	else:
		GameState.say("No — %s." % q[1][q[2]])
	_q += 1
	call_deferred("_ask")


# ---------------------------------------------------------------- sorting ceremony

var _sort_q := 0
var _sort_tally := {}

func start_sorting(_a) -> void:
	_sort_q = 0
	_sort_tally = {}
	call_deferred("_sort_ask")


func _sort_ask() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	if _sort_q >= Story.SORTING.size():
		var best := ""
		var bv := -1
		for id in Story.ORDERS:
			var v: int = _sort_tally.get(id, 0)
			if v > bv:
				bv = v
				best = id
		GameState.order = best
		GameState.order_points[best] = int(GameState.order_points.get(best, 0)) + GameState.marks
		GameState.coins += 10
		GameState.add_ember(2)
		GameState.mark_dirty()
		var o: Dictionary = Story.ORDERS[best]
		hud.open_dialogue(self, {"pages": [[data["name"], "...%s." % o["name"].to_upper()], [data["name"], "%s — the Order of %s. '%s'\n\nYour bed is under the %s banner in the common room, east of the library. Every Mark you earn is a point for %s.\n\n(+10 coins, +2 Ember)" % [o["name"], o["virtue"], o["motto"], o["banner"], o["name"]]]]})
		cheer()
		return
	var q: Array = Story.SORTING[_sort_q]
	var choices := []
	for opt in q[1]:
		choices.append({"label": opt[0], "enabled": true, "call": "sort_answer", "arg": opt[1]})
	hud.open_dialogue(self, {"pages": [[data["name"], q[0]]], "choices": choices})


func sort_answer(order_id: String) -> void:
	_sort_tally[order_id] = int(_sort_tally.get(order_id, 0)) + 1
	_sort_q += 1
	call_deferred("_sort_ask")


func buy_broom(_a) -> void:
	if GameState.coins < 60 or GameState.broom:
		return
	GameState.coins -= 60
	GameState.broom = true
	GameState.add_ember(1)
	GameState.mark_dirty()
	GameState.say("You own an Ashwood broom!  Press B (or the Broom button) to fly. Try the ring course on Festival Green.")
	cheer()


func fit_crystal(cid: String) -> void:
	var c: Dictionary = Story.CRYSTALS[cid]
	if GameState.coins < c["price"]:
		return
	GameState.coins -= c["price"]
	GameState.staff_color = cid
	GameState.mark_dirty()
	GameState.say("%s fitted. Your staff glows %s." % [c["name"], cid])


func give(item: String) -> void:
	if not GameState.take_item(item, 1):
		return
	GameState.gifts_given[npc_id] = Story.today_key()
	var fav: bool = Story.FAVOURITES.get(npc_id, "") == item
	var student: bool = data.get("role", "").begins_with("Student")
	var pts := 3 if fav else (3 if item == "pie" and student else (2 if item in ["broth", "pie"] else 1))
	var bday := Story.birthday_today().has(npc_id)
	if bday:
		pts *= 3
		GameState.add_marks(2, "Birthday gift for " + data["name"])
	GameState.add_friend(npc_id, pts)
	GameState.add_ember(1)
	GameState.mark_dirty()
	if bday:
		GameState.say("%s: \"On my BIRTHDAY? Nobody— thank you.\"   friendship +%d, +1 Ember" % [data["name"], pts])
	elif fav:
		GameState.say("%s: \"%s! You remembered.\"   friendship +3, +1 Ember" % [data["name"], GameState.ITEM_NAMES[item]])
	else:
		GameState.say("%s thanks you for the %s.   friendship +%d, +1 Ember" % [data["name"], GameState.ITEM_NAMES[item], pts])
	cheer()


func buy_garden(_a) -> void:
	var price := 40 + GameState.garden_level * 40
	if GameState.coins < price or GameState.garden_level >= 2:
		return
	GameState.coins -= price
	GameState.garden_level += 1
	GameState.mark_dirty()
	GameState.save_game()
	GameState.say("Three new beds are being dug behind the apothecary. (They appear when you next enter the village.)")
	get_tree().call_deferred("reload_current_scene")


func go_hide(_a) -> void:
	_hiding = true
	var spots := [Vector3(-20.0, 0, 14.0), Vector3(24.0, 0, -9.0), Vector3(-9.0, 0, -17.0), Vector3(16.0, 0, 20.0), Vector3(-36.0, 0, 12.0), Vector3(30.0, 0, 6.0)]
	var p: Vector3 = spots[randi() % spots.size()]
	_target_pos = p
	_post_eff = _resolve_post(p)
	teleport(_post_eff)
	GameState.say("Ten! Pip is somewhere in the village. (Hint: look behind houses and trees.)")


func patrol(_a) -> void:
	var pt := get_tree().get_first_node_in_group("patrol")
	if pt:
		pt.start()
