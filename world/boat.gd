extends Node3D
## Hatch's boat at the dock / on Heron Isle: rows between the two.

var at_isle := false
const DOCK := Vector3(36.0, 0.1, 9.0)
const ISLE := Vector3(63.0, 0.1, 16.5)

func _ready() -> void:
	add_to_group("interactable")
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.26, 0.16)
	var hull := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(1.4, 0.5, 3.2)
	hull.mesh = hm
	hull.material_override = wood
	hull.position.y = 0.25
	add_child(hull)
	var bow := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(1.4, 0.5, 1.0)
	bow.mesh = pm
	bow.material_override = wood
	bow.position = Vector3(0, 0.25, 2.1)
	bow.rotation.x = PI / 2.0
	add_child(bow)
	var tag := Label3D.new()
	tag.text = "Hatch's boat"
	tag.font_size = 34
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.2
	add_child(tag)

func get_prompt() -> String:
	return "[F] Row to Heron Isle" if not at_isle else "[F] Row back to the dock"

func build_dialogue() -> Dictionary:
	return {"pages": [["Hatch's boat", "It leaks. It has always leaked.  %s" % ("Row out to Heron Isle?" if not at_isle else "Row back to the dock?")]], "choices": [{"label": "Row", "enabled": true, "call": "row", "arg": null}, {"label": "Stay", "enabled": true, "call": "noop", "arg": null}]}

func row(_a) -> void:
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	at_isle = not at_isle
	position = (ISLE + Vector3(-2.5, 0, 1.5)) if at_isle else (Vector3(43.0, 0.0, 12.0))
	pl.global_position = ISLE if at_isle else DOCK
	GameState.say("You row across Lake Mirren. The boat leaks, as promised." if at_isle else "Back to the dock.")

func noop(_a) -> void:
	pass

func interact() -> void:
	pass
