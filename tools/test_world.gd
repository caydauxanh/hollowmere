extends Node
var _p: CharacterBody3D
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	_p = v.find_child("Player", true, false)
	_p.set_physics_process(false)
	var trees := []
	var all := get_tree().get_nodes_in_group("tree")
	for n in all:
		if not ("shrub" in str(n.name)) and trees.size() < 6:
			trees.append(n)
	print("trees: ", all.size())
	for t in trees:
		await _push(t.global_position + Vector3(3, 0, 0), Vector3(-4, 0, 0), 60)
		var d: float = _p.global_position.x - t.global_position.x
		print("%s @%s dx=%.2f -> %s" % [t.name, t.global_position.round(), d, "BLOCKED" if d > 0.25 else "PASSED"])
	# river bank (segment (6,46)-(-14,46) at z=46): walk south from z=40
	await _push(Vector3(-4, 0, 38), Vector3(0, 0, 4), 90)
	print("river from north: z=%.2f y=%.2f -> %s" % [_p.global_position.z, _p.global_position.y, "BLOCKED" if _p.global_position.z < 44.0 else "PASSED(bad)"])
	# bridge: walk along the Fernmoor road across the river (road dir (-48,38) normalized)
	var dir := Vector3(-48, 0, 38).normalized()
	var start := Vector3(-40, 0, 31) - dir * 12.0
	await _push(start, dir * 4.0, 700)
	var along := (_p.global_position - Vector3(-40, 0, 31)).dot(dir)
	var kc := _p.get_slide_collision_count()
	for i in kc:
		var col := _p.get_slide_collision(i)
		print("  hit: ", col.get_collider().name, " parent=", col.get_collider().get_parent().name, " at ", col.get_position().round(), " normal=", col.get_normal().round())
	print("bridge crossing: along=%.1f y=%.2f pos=%s -> %s" % [along, _p.global_position.y, _p.global_position.round(), "CROSSED" if along > 8.0 else "STUCK"])
	# make sure we went OVER: sample y when at bridge centre
	await _push(start, dir * 4.0, 60)
	var mid := _p.global_position
	for i in 200:
		_p.velocity = dir * 4.0 + Vector3(0, _p.velocity.y - 0.3, 0)
		_p.move_and_slide()
		await get_tree().physics_frame
		if absf((_p.global_position - Vector3(-40, 0, 31)).dot(dir)) < 0.6:
			mid = _p.global_position
			break
	print("at bridge centre y=%.2f -> %s" % [mid.y, "ON DECK" if mid.y > 1.0 else "UNDER (bad)"])
	get_tree().quit()

func _push(start: Vector3, vel: Vector3, frames: int) -> void:
	_p.global_position = Vector3(start.x, 1.0, start.z)
	_p.velocity = Vector3.ZERO
	await get_tree().create_timer(0.3).timeout
	for i in frames:
		_p.velocity = Vector3(vel.x, _p.velocity.y - 0.3, vel.z)
		_p.move_and_slide()
		await get_tree().physics_frame
