extends Node3D
## The Astronomy Tower telescope: at night, find the three constellations (Chapter 4).

func _ready() -> void:
	add_to_group("interactable")
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.75, 0.6, 0.3)
	brass.metallic = 0.7
	brass.roughness = 0.35
	var tube := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.14
	c.bottom_radius = 0.2
	c.height = 2.2
	tube.mesh = c
	tube.material_override = brass
	tube.position = Vector3(0, 1.5, 0)
	tube.rotation.x = deg_to_rad(-50)
	add_child(tube)
	for i in 3:
		var leg := MeshInstance3D.new()
		var lc := CylinderMesh.new()
		lc.top_radius = 0.04
		lc.bottom_radius = 0.04
		lc.height = 1.3
		leg.mesh = lc
		leg.material_override = brass
		var a := i * TAU / 3.0
		leg.position = Vector3(cos(a) * 0.35, 0.65, sin(a) * 0.35)
		leg.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)
		add_child(leg)
	var tag := Label3D.new()
	tag.text = "Telescope"
	tag.font_size = 32
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.6
	add_child(tag)

func get_prompt() -> String:
	return "[F] Look through the telescope"

func build_dialogue() -> Dictionary:
	var h := GameState.hour_of_day()
	if h >= 5.5 and h < 20.0:
		return {"pages": [["Telescope", "Daylight. The sky over the tower is pale and empty. Come back after eight at night (or press Time +6h)."]]}
	var choices := []
	for id in Story.CONSTELLATIONS:
		var seen: bool = GameState.stars_seen.has(id)
		choices.append({"label": "%s%s" % [Story.CONSTELLATIONS[id]["name"], "  ✓" if seen else ""], "enabled": true, "call": "observe", "arg": id})
	if GameState.chapter6_done and not GameState.chapter7_done and (h >= 23.0 or h < 2.0):
		choices.append({"label": "✦ The small star (midnight)", "enabled": true, "call": "small_star", "arg": null})
	return {"pages": [["Telescope", "The brass is cold. Above the open tower the valley's own stars come out one by one.  Found: %d of 3." % GameState.stars_seen.size()]], "choices": choices}

func observe(id: String) -> void:
	var c: Dictionary = Story.CONSTELLATIONS[id]
	GameState.practical("astronomy", "observing in class")
	var first: bool = not GameState.stars_seen.has(id)
	GameState.stars_seen[id] = true
	GameState.mark_dirty()
	var hud := get_tree().get_first_node_in_group("hud")
	var extra := ""
	if first:
		GameState.add_marks(1, "Astronomy: " + c["name"])
	if GameState.stars_seen.size() >= 3 and not GameState.chapter4_done:
		GameState.chapter4_done = true
		GameState.coins += 40
		GameState.add_ember(6)
		GameState.mark_dirty()
		extra = "\n\nAll three. Seraphine's note in the almanac is right: the Wheel turns, and tonight it stands upright over the Watchtower.\n\n(+40 coins, +6 Ember — Chapter 4 complete)"
	if hud:
		hud.call_deferred("open_dialogue", self, {"pages": [[c["name"], c["text"] + extra]]})

func interact() -> void:
	pass


func small_star(_a) -> void:
	GameState.chapter7_done = true
	GameState.coins += 100
	GameState.add_ember(10)
	GameState.add_marks(10, "The Small Star")
	GameState.mark_dirty()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.call_deferred("open_dialogue", self, {"pages": [
			["The small star", "Just left of the Lantern-Bearer, the star Seraphine has measured every clear night for nine years is not a point any more. It is a lamp. It is coming down."],
			["The small star", "It passes the Watchtower, lit. It passes the isle, lit. It crosses the lake and the river and the four districts, each one answering with its lanterns, and comes to rest on Festival Green, where the whole village is standing with its faces turned up."],
			["Professor Seraphine Lowe", "I told you. Not to hurt us. Home."],
			["Headmistress Oriel Vance", "Chapter seven, apprentice. The Quiet Night is over. There will be other dark nights, and there will also be you.\n\n(+100 coins, +10 Ember, +10 Marks — a Star Stone now rests on Festival Green)"],
			["HOLLOWMERE", "a cozy valley below Ashenvale Academy\n\nmade with Godot 4, KayKit's CC0 character, hexagon, dungeon and halloween packs, and a great many lanterns.\n\nThank you for playing. The village keeps going — so do the lessons, the market, the sheep, and the cats."],
		]})
