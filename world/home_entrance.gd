extends Node3D
## The apothecary cottage door in the village: go inside.

func _ready() -> void:
	add_to_group("interactable")
	var tag := Label3D.new()
	tag.text = "The Apothecary (your cottage)"
	tag.font_size = 30
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.6
	add_child(tag)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.5)
	l.omni_range = 5.0
	l.light_energy = 0.8
	l.position.y = 2.0
	add_child(l)

func get_prompt() -> String:
	return "[F] Go inside"

func interact() -> void:
	GameState.save_game()
	GameState.spawn_at = Vector3(0, 0.1, 0.5)
	GameState.spawn_yaw = 0.0
	get_tree().call_deferred("change_scene_to_file", "res://world/home.tscn")
