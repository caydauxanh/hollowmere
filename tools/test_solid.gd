extends Node
var _p: CharacterBody3D
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var v := get_tree().current_scene
	_p = v.find_child("Player", true, false)
	_p.set_physics_process(false)
	# [name, position of thing, approach from +x]
	var cases := [["church", Vector3(18, 0, -30)], ["acad wall W", Vector3(-5, 0, -27)], ["ruin house", Vector3(63, 0, -53)], ["crypt", Vector3(0, 0, 0)], ["tent market", Vector3(22, 0, -6)], ["crate market", Vector3(24, 0, -10.5)], ["barrel garden", Vector3(-16, 0, -3.5)], ["rock", Vector3(0,0,0)]]
	# find a rock and the crypt by scanning children
	for n in v.get_children():
		var nm := str(n.name).to_lower()
		if "rock_single" in nm and cases[7][1] == Vector3.ZERO: cases[7][1] = (n as Node3D).global_position
		if "crypt" in nm: cases[3][1] = (n as Node3D).global_position
	for c in cases:
		if c[1] == Vector3.ZERO: continue
		await _push(c[1] + Vector3(5, 0, 0), Vector3(-4, 0, 0), 120)
		var d: float = _p.global_position.x - c[1].x
		print("%s @%s dx=%.2f -> %s" % [c[0], c[1].round(), d, "BLOCKED" if d > 0.3 else "PASSED"])
	# walkability: roads & plaza & doors must stay open: walk along road to lake
	await _push(Vector3(10, 0, 0.5), Vector3(4, 0, 1.5).normalized() * 4.0, 300)
	print("road to lake reached x=%.1f -> %s" % [_p.global_position.x, "OPEN" if _p.global_position.x > 28.0 else "BLOCKED(bad)"])
	await _push(Vector3(2, 0, -6), Vector3(0, 0, -4), 120)
	print("gate approach z=%.1f -> %s" % [_p.global_position.z, "OPEN" if _p.global_position.z < -11.5 else "BLOCKED(bad)"])
	get_tree().quit()
func _push(start: Vector3, vel: Vector3, frames: int) -> void:
	_p.global_position = Vector3(start.x, 1.0, start.z); _p.velocity = Vector3.ZERO
	await get_tree().create_timer(0.3).timeout
	for i in frames:
		_p.velocity = Vector3(vel.x, _p.velocity.y - 0.3, vel.z); _p.move_and_slide(); await get_tree().physics_frame
