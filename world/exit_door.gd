extends Node3D
## Academy entrance: walk back down to Hollowmere.

func _ready() -> void:
	add_to_group("interactable")
	var tag := Label3D.new()
	tag.text = "To Hollowmere"
	tag.font_size = 36
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 10
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.6
	add_child(tag)


func get_prompt() -> String:
	return "[F] Leave the Academy"


func interact() -> void:
	GameState.save_game()
	GameState.spawn_at = Vector3(2.0, 0.1, -10.5)
	GameState.spawn_yaw = 180.0
	get_tree().call_deferred("change_scene_to_file", "res://world/village.tscn")
