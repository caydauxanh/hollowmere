extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	print("meshes=", v.find_children("*", "MeshInstance3D", true, false).size(), " omni=", v.find_children("*", "OmniLight3D", true, false).size(), " particles=", v.find_children("*", "GPUParticles3D", true, false).size(), " labels=", v.find_children("*", "Label3D", true, false).size(), " bodies=", v.find_children("*", "StaticBody3D", true, false).size())
	get_tree().quit()
