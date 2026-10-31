extends Node3D
## Camera góc nhìn thứ ba, xoay bằng chuột, có độ trễ mềm khi đi theo nhân vật.

@export var target_path: NodePath
@export var distance := 9.5
@export var min_pitch := -0.9
@export var max_pitch := 0.15
@export var follow_speed := 9.0

var yaw := 0.0
var pitch := -0.42
var _lead := Vector3.ZERO
var _arm: SpringArm3D
var _cam: Camera3D
var _target: Node3D


func _ready() -> void:
	_target = get_node(target_path)
	_arm = SpringArm3D.new()
	_arm.spring_length = distance
	_arm.collision_mask = 0   # scenery never pushes the camera into the player
	_arm.margin = 0.3
	if _target is CollisionObject3D:
		_arm.add_excluded_object(_target.get_rid())
	add_child(_arm)
	_cam = Camera3D.new()
	_cam.fov = 52.0
	_cam.current = true
	_arm.add_child(_cam)
	global_position = _target.global_position + Vector3(0, 1.4, 0)
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - 0.8, 5.0, 18.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + 0.8, 5.0, 18.0)


var _touches := {}
var _pinch_d := 0.0

## Pinch to zoom on touch screens (two fingers).
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch_d = 0.0
	elif event is InputEventScreenDrag and _touches.has(event.index):
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var k := _touches.keys()
			var d: float = (_touches[k[0]] as Vector2).distance_to(_touches[k[1]])
			if _pinch_d > 0.0:
				distance = clampf(distance - (d - _pinch_d) * 0.03, 5.0, 18.0)
			_pinch_d = d


func _process(delta: float) -> void:
	var pan := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	yaw -= pan.x * 2.0 * delta
	pitch = clampf(pitch - pan.y * 1.2 * delta, min_pitch, max_pitch)
	var vel: Vector3 = _target.velocity if _target is CharacterBody3D else Vector3.ZERO
	var planar := Vector3(vel.x, 0, vel.z)
	# Look a little ahead of the way you are moving; eased so it never jerks when you stop.
	_lead = _lead.lerp(planar * 0.14, 1.0 - exp(-3.0 * delta))
	var goal := _target.global_position + Vector3(0, 1.4, 0) + _lead
	# Vertical follow is softer than horizontal: jumps and small steps do not bob the camera.
	var kh := 1.0 - exp(-follow_speed * delta)
	var kv := 1.0 - exp(-follow_speed * 0.55 * delta)
	var p := global_position
	p.x = lerpf(p.x, goal.x, kh)
	p.z = lerpf(p.z, goal.z, kh)
	p.y = lerpf(p.y, goal.y, kv)
	global_position = p
	_arm.spring_length = lerpf(_arm.spring_length, distance, 1.0 - exp(-8.0 * delta))
	if _cam:
		# A touch wider when running, so speed reads on screen.
		var speed_frac := clampf(planar.length() / 6.0, 0.0, 1.0)
		_cam.fov = lerpf(_cam.fov, 52.0 + 5.0 * speed_frac * speed_frac, 1.0 - exp(-4.0 * delta))
		RenderingServer.global_shader_parameter_set("focus_dist", _cam.global_position.distance_to(_target.global_position + Vector3(0, 1.0, 0)))
	_apply()


func _apply() -> void:
	rotation = Vector3(pitch, yaw, 0)


func set_view(yaw_deg: float, pitch_rad: float = -0.52, dist: float = 10.5) -> void:
	yaw = deg_to_rad(yaw_deg)
	pitch = pitch_rad
	distance = dist
	_arm.spring_length = dist
	global_position = _target.global_position + Vector3(0, 1.4, 0)
	_apply()
