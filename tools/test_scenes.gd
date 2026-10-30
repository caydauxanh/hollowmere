extends Node
var _steps := ["res://world/academy.tscn", "res://world/village.tscn", "res://world/home.tscn", "res://world/village.tscn", "res://world/academy.tscn", "res://world/village.tscn"]
var _i := 0
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	_next()
func _next() -> void:
	if _i >= _steps.size():
		var v := get_tree().current_scene
		print("final scene=", v.name, " npcs=", v.find_children("*", "Villager", true, false).size())
		get_tree().quit()
		return
	var path: String = _steps[_i]; _i += 1
	GameState.spawn_at = Vector3(0, 0.1, 1.0)
	get_tree().change_scene_to_file(path)
	await get_tree().create_timer(2.0).timeout
	print("loaded ", get_tree().current_scene.name)
	_next()
