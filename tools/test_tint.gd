extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var n := 0; var tinted := 0
	for mi in v.find_children("*", "MeshInstance3D", true, false):
		var path := mi.get_path().get_concatenated_names().to_lower()
		if "tree" in path:
			n += 1
			var m = mi.get_surface_override_material(0)
			if m is StandardMaterial3D and m.albedo_color.r > 1.05: tinted += 1
			if n == 1: print("sample mat: ", m, " ", (m.albedo_color if m is StandardMaterial3D else "n/a"), " mesh mat=", mi.mesh.surface_get_material(0) if mi.mesh else null)
	print("tree meshes=", n, " tinted=", tinted)
	get_tree().quit()
