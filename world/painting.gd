extends Node3D
## A talking portrait on the great hall wall. The bust is rendered live by the Portraits autoload.

var pid := ""
var title := ""
var lines: Array = []

func setup(p: String, t: String, l: Array) -> void:
	pid = p
	title = t
	lines = l

func _ready() -> void:
	add_to_group("interactable")
	var frame := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(1.5, 1.85, 0.12)
	frame.mesh = fb
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.55, 0.4, 0.15)
	fm.metallic = 0.4
	frame.material_override = fm
	add_child(frame)
	var canvas := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.25, 1.6)
	canvas.mesh = qm
	var cm := StandardMaterial3D.new()
	cm.albedo_texture = Portraits.get_portrait(pid)
	cm.albedo_color = Color(0.85, 0.8, 0.7)
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	canvas.material_override = cm
	canvas.position.z = 0.07
	add_child(canvas)
	var back := MeshInstance3D.new()
	var bq := QuadMesh.new()
	bq.size = Vector2(1.25, 1.6)
	back.mesh = bq
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.3, 0.22, 0.3)
	back.material_override = bm
	back.position.z = 0.065
	add_child(back)
	var tag := Label3D.new()
	tag.text = title
	tag.font_size = 24
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 1.15
	add_child(tag)

func get_prompt() -> String:
	return "[F] Talk to the portrait"

func build_dialogue() -> Dictionary:
	var key := "portrait_" + pid
	var first := not GameState.quests_done.has(key)
	if first:
		GameState.quests_done[key] = true
		GameState.add_ember(1)
		GameState.mark_dirty()
	var line: String = lines[randi() % lines.size()]
	return {"pages": [[title, line + ("\n\n(The portrait is pleased to be spoken to. +1 Ember)" if first else "")]]}

func interact() -> void:
	pass
