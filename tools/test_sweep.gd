extends Node
func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	var v := get_tree().current_scene
	v.start_sweep()
	await get_tree().create_timer(1.0).timeout
	print("sweep dist=", v.cam_rig.distance, " t=", v._sweep)
	await get_tree().create_timer(5.0).timeout
	print("after dist=", v.cam_rig.distance, " t=", v._sweep, " follow=", v.cam_rig.follow_speed)
	get_tree().quit()
