extends Node3D
func _ready() -> void:
	add_to_group("interactable")
	var tag := Label3D.new()
	tag.text = "To Hearth Row"
	tag.font_size = 32
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0, 0, 0.1, 0.9)
	tag.position.y = 2.4
	add_child(tag)
func get_prompt() -> String:
	return "[F] Go outside"
func interact() -> void:
	GameState.save_game()
	GameState.spawn_at = Vector3(-46.0, 0.1, 1.5)
	GameState.spawn_yaw = 0.0
	get_tree().call_deferred("change_scene_to_file", "res://world/village.tscn")
