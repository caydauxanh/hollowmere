extends Node
## Flood-fill walkability on a 2 m grid (physics point probes at knee height) and report which interactables are reachable from the spawn.
const STEP := 2.0
const R := 112
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	var space := v.get_viewport().world_3d.direct_space_state
	var n := int(R * 2 / STEP) + 1
	print("grid ", n)
	var blocked := PackedByteArray(); blocked.resize(n * n)
	var q := PhysicsPointQueryParameters3D.new()
	for i in n:
		for j in n:
			q.position = Vector3(-R + i * STEP, 0.7, -R + j * STEP)
			var hits := space.intersect_point(q, 1)
			blocked[i * n + j] = 1 if hits.size() > 0 else 0
		if i % 20 == 0: print("row ", i)
	# deck/ramps are walkable at a different height: probe them at y=1.9 too (if clear there, treat as open)
	for i in n:
		for j in n:
			if blocked[i * n + j] == 1:
				q.position = Vector3(-R + i * STEP, 1.9, -R + j * STEP)
				var hits := space.intersect_point(q, 2)
				var only_deck := hits.size() == 0
				var pos := Vector3(-R + i * STEP, 0, -R + j * STEP)
				if only_deck and pos.distance_to(Vector3(-40, 0, 31)) < 9.0:
					blocked[i * n + j] = 0
	var seen := PackedByteArray(); seen.resize(n * n)
	var start := Vector2i(int((0 + R) / STEP), int((10 + R) / STEP))
	var stack := [start]
	seen[start.x * n + start.y] = 1
	var count := 0
	while stack.size() > 0:
		var c: Vector2i = stack.pop_back()
		count += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: Vector2i = c + d
			if nx.x < 0 or nx.y < 0 or nx.x >= n or nx.y >= n: continue
			var k := nx.x * n + nx.y
			if seen[k] == 1 or blocked[k] == 1: continue
			seen[k] = 1
			stack.append(nx)
	print("walkable cells reachable: ", count, " of ", n * n)
	var unreachable := []
	var total := 0
	for it in get_tree().get_nodes_in_group("interactable"):
		var p: Vector3 = (it as Node3D).global_position
		total += 1
		var ok := false
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var gi: int = int(round((p.x + R) / STEP)) + dx
				var gj: int = int(round((p.z + R) / STEP)) + dz
				if gi >= 0 and gj >= 0 and gi < n and gj < n and seen[gi * n + gj] == 1:
					ok = true
		if not ok:
			var label: String = it.get_prompt() if it.has_method("get_prompt") else it.name
			unreachable.append("%s @%s" % [label, p.round()])
	print("interactables: ", total, "  unreachable: ", unreachable.size())
	for u in unreachable:
		print("  X ", u)
	get_tree().quit()
