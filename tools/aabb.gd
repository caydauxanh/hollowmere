extends SceneTree
func _init() -> void:
	for p in ["res://assets/kaykit/hex/buildings/neutral/building_bridge_A.gltf", "res://assets/kaykit/hex/decoration/nature/trees_A_medium.gltf", "res://assets/kaykit/hex/decoration/nature/tree_single_A.gltf", "res://assets/kaykit/halloween/tree_pine_orange_large.gltf", "res://assets/kaykit/hex/decoration/nature/hills_A_trees.gltf", "res://assets/kaykit/hex/decoration/nature/mountain_A_grass_trees.gltf"]:
		var n: Node3D = load(p).instantiate()
		root.add_child(n)
		var aabb := AABB()
		var first := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = mi.global_transform * mi.get_aabb()
			aabb = a if first else aabb.merge(a)
			first = false
		print(p.get_file(), " ", aabb)
		n.queue_free()
	quit()
