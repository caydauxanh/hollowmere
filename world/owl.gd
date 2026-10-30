extends Node3D
## The post owl on the apothecary roof. Brings the morning letter (the notice board shows it too).

var _body: Node3D
var _t := 0.0

func _ready() -> void:
	add_to_group("interactable")
	_body = Node3D.new()
	add_child(_body)
	var fe := StandardMaterial3D.new()
	fe.albedo_color = Color(0.55, 0.42, 0.3)
	var light := StandardMaterial3D.new()
	light.albedo_color = Color(0.9, 0.82, 0.65)
	var b := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.2
	bm.height = 0.62
	b.mesh = bm
	b.material_override = fe
	b.position.y = 0.31
	_body.add_child(b)
	var belly := MeshInstance3D.new()
	var bem := SphereMesh.new()
	bem.radius = 0.14
	bem.height = 0.3
	belly.mesh = bem
	belly.material_override = light
	belly.position = Vector3(0, 0.26, 0.1)
	_body.add_child(belly)
	for e in [-0.09, 0.09]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.06
		em.height = 0.12
		eye.mesh = em
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color(1.0, 0.85, 0.3)
		eye.material_override = emat
		eye.position = Vector3(e, 0.5, 0.15)
		_body.add_child(eye)
		var pupil := MeshInstance3D.new()
		var pm := SphereMesh.new()
		pm.radius = 0.028
		pm.height = 0.056
		pupil.mesh = pm
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.05, 0.05, 0.08)
		pupil.material_override = pmat
		pupil.position = Vector3(e, 0.5, 0.2)
		_body.add_child(pupil)
		var tuft := MeshInstance3D.new()
		var tm := PrismMesh.new()
		tm.size = Vector3(0.08, 0.12, 0.06)
		tuft.mesh = tm
		tuft.material_override = fe
		tuft.position = Vector3(e * 1.4, 0.64, 0.05)
		_body.add_child(tuft)
	var beak := MeshInstance3D.new()
	var km := PrismMesh.new()
	km.size = Vector3(0.06, 0.08, 0.06)
	beak.mesh = km
	beak.rotation.x = PI / 2.0
	var kmat := StandardMaterial3D.new()
	kmat.albedo_color = Color(0.9, 0.6, 0.2)
	beak.material_override = kmat
	beak.position = Vector3(0, 0.42, 0.2)
	_body.add_child(beak)
	var tag := Label3D.new()
	tag.text = "Post owl"
	tag.font_size = 28
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 1.1
	add_child(tag)

func _process(delta: float) -> void:
	_t += delta
	_body.rotation.y = sin(_t * 0.7) * 0.6
	_body.scale.y = 1.0 + sin(_t * 2.0) * 0.02

func get_prompt() -> String:
	return "[F] The post owl"

func build_dialogue() -> Dictionary:
	var choices := []
	if GameState.quests_done.get("owl_sent", "") != Story.today_key():
		choices.append({"label": "Send a letter (5 coins)", "enabled": GameState.coins >= 5, "call": "pick_recipient", "arg": null})
	var letter := Story.todays_letter()
	if letter.is_empty():
		var out := {"pages": [["Post owl", "Hoo. Nothing today. The owl looks at you as if that were your fault."]]}
		if not choices.is_empty():
			choices.append({"label": "Just a scratch", "enabled": true, "call": "noop", "arg": null})
			out["choices"] = choices
		return out
	GameState.last_letter_day = Story.today_key()
	if letter["gift"] == "coins":
		GameState.coins += letter["amount"]
	else:
		GameState.add_item(letter["gift"], letter["amount"])
	GameState.mark_dirty()
	var who: String = Story.NPCS[letter["from"]]["name"]
	return {"pages": [["Post owl", "Hoo. The owl holds out a leg with a letter tied to it, and accepts a scratch as payment."], ["Letter from %s" % who, "%s\n\n(Enclosed: %d %s)" % [letter["text"], letter["amount"], "coins" if letter["gift"] == "coins" else GameState.ITEM_NAMES[letter["gift"]]]]]}

func interact() -> void:
	pass


func pick_recipient(_a) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	var choices := []
	for id in Story.NPCS:
		var d: Dictionary = Story.NPCS[id]
		if d.get("hidden", false) or not GameState.met.has(id):
			continue
		choices.append({"label": "To %s" % d["name"], "enabled": true, "call": "send_to", "arg": id})
	if choices.is_empty():
		GameState.say("You have not met anyone to write to yet.")
		return
	choices.append({"label": "Never mind", "enabled": true, "call": "noop", "arg": null})
	hud.call_deferred("open_dialogue", self, {"pages": [["Post owl", "A short note, a scratch for the owl, and off it goes. Who to?"]], "choices": choices})


func send_to(id: String) -> void:
	if GameState.coins < 5:
		return
	GameState.coins -= 5
	GameState.quests_done["owl_sent"] = Story.today_key()
	GameState.add_friend(id, 2)
	GameState.add_ember(1)
	GameState.mark_dirty()
	var replies := ["%s writes back by evening: 'Got your note. Made my day.'", "%s sends the owl back with a pressed flower and no words.", "%s replies: 'You have terrible handwriting. Come by.'", "%s writes: 'Kept it. Keeping all of them.'"]
	GameState.say((replies[randi() % replies.size()]) % Story.NPCS[id]["name"] + "   friendship +2, +1 Ember")


func noop(_a) -> void:
	pass
