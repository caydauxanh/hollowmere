class_name Walker
extends CharacterBody3D
## Base for everything that walks on its own (villagers, cats, sheep).
## Physics body with a capsule, so it never passes through houses, fences, trees or the player.
## Paths come from the scene's NavGrid; movement is smoothed (acceleration, turning), with
## string-pulling so corners are cut naturally, a little separation from other walkers, and
## stuck recovery (sidestep → forget the bad edge and re-plan → last resort: nudge).

@export var walk_speed := 2.0
@export var accel := 7.0
@export var turn_speed := 7.0
@export var body_radius := 0.38
@export var body_height := 1.7

var skin: Node3D                 # the visible model; turned to face the way we walk
var _path: Array[Vector3] = []
var _wp := 0
var _goal := Vector3.INF
var _moving := false
var _speed_now := 0.0
var _stuck_t := 0.0
var _last_d := 1e9
var _sidestep := 0.0
var _side := 1.0
var _skip_t := 0.0
var _replans := 0
var _nav: NavGrid
var _col: CollisionShape3D
var _pending_goal := Vector3.INF
var _replan_cd := 0.0


func _enter_tree() -> void:
	collision_layer = 2
	collision_mask = 1 | 2
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50.0)
	wall_min_slide_angle = deg_to_rad(5.0)
	if _col == null:
		_col = CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = body_radius
		cap.height = body_height
		_col.shape = cap
		_col.position.y = body_height * 0.5 + 0.02
		add_child(_col)
	add_to_group("walker")


func _grid() -> NavGrid:
	if _nav == null and is_inside_tree():
		_nav = NavGrid.get_for(get_tree())
	return _nav


## Walk to `p` by the shortest route. `arrived` is true once we are within `stop_dist`.
func go_to(p: Vector3) -> void:
	if _goal != Vector3.INF and _goal.distance_to(p) < 0.3:
		return
	# A goal that only moved a little (following someone): slide the last waypoint, keep the route.
	var nudge := _goal != Vector3.INF and _goal.distance_to(p) < 2.5 and not _path.is_empty()
	_goal = p
	if nudge or (_replan_cd > 0.0 and not _path.is_empty()):
		_path[_path.size() - 1] = p
		return
	_replans = 0
	_replan_cd = 0.4
	_grid()
	if _nav == null or not _nav.built:
		_path = [p]
		_wp = 0
		if _nav:
			_pending_goal = p
			_nav.when_ready(_replan)
		return
	_replan()


func _replan() -> void:
	if _goal == Vector3.INF:
		return
	_pending_goal = Vector3.INF
	var pth := _nav.find_path(global_position, _goal) if _nav else []
	if pth.is_empty():
		pth = [_goal]
	_path = pth
	_wp = 0
	_stuck_t = 0.0
	_last_d = 1e9


func stop() -> void:
	_goal = Vector3.INF
	_path = []
	_wp = 0


func is_walking() -> bool:
	return _moving


func distance_to_goal() -> float:
	if _goal == Vector3.INF:
		return 0.0
	var d := _goal - global_position
	d.y = 0.0
	return d.length()


## Show or hide, and stop colliding while hidden (an invisible villager should never block the player).
func set_shown(on: bool) -> void:
	if on == visible:
		return
	visible = on
	if _col:
		_col.disabled = not on
	if on and global_position.y < -0.3:
		global_position.y = 0.0
	velocity = Vector3.ZERO


## Place somewhere instantly (far from the player, scene start).
func teleport(p: Vector3) -> void:
	global_position = p
	velocity = Vector3.ZERO
	stop()


func _physics_process(delta: float) -> void:
	if not visible:
		velocity = Vector3.ZERO   # hidden: no collider, so no gravity either (or we would sink through the floor)
		return
	var dir := Vector3.ZERO
	var want_speed := 0.0
	_replan_cd -= delta
	_grid()
	if _goal != Vector3.INF and _wp < _path.size():
		_skip_t -= delta
		if _skip_t <= 0.0 and _nav and _nav.built:
			_skip_t = 0.35
			# String pulling: aim at the farthest of the next few waypoints we can see.
			for i in range(mini(_path.size() - 1, _wp + 3), _wp, -1):
				if _nav.line_clear(global_position, _path[i]):
					_wp = i
					_last_d = 1e9
					break
		var target := _path[_wp]
		var to := target - global_position
		to.y = 0.0
		var d := to.length()
		var last := _wp == _path.size() - 1
		var stop_dist := 0.35 if last else 0.6
		if d <= stop_dist:
			_wp += 1
			if _wp >= _path.size():
				stop()
			_last_d = 1e9
			_stuck_t = 0.0
		else:
			dir = to / d
			want_speed = walk_speed
			if last and d < 1.4:
				want_speed = walk_speed * maxf(0.45, d / 1.4)   # ease into the stop
			# Stuck watch: no progress toward the waypoint for a while.
			if d < _last_d - 0.05:
				_last_d = d
				_stuck_t = 0.0
			else:
				_stuck_t += delta
			if _sidestep > 0.0:
				_sidestep -= delta
				dir = (dir * 0.3 + Vector3(-dir.z, 0, dir.x) * _side).normalized()
			elif _stuck_t > 1.2:
				_stuck_t = 0.0
				_last_d = 1e9
				_replans += 1
				if _replans <= 2:
					_sidestep = 0.6
					_side = 1.0 if randf() < 0.5 else -1.0
				elif _replans <= 4 and _nav and _nav.built:
					if _wp > 0:
						_nav.forget_edge(_path[_wp - 1], _path[_wp])
					else:
						_nav.forget_edge(global_position, _path[_wp])
					_replan()
				elif distance_to_goal() < 2.5:
					stop()   # close enough; the spot itself is taken
				else:
					_replans = 2
					_replan()
	# Separation: drift away from other walkers that are very close.
	if want_speed > 0.0:
		for other in get_tree().get_nodes_in_group("walker"):
			if other == self or not (other as Node3D).visible:
				continue
			var away: Vector3 = global_position - (other as Node3D).global_position
			away.y = 0.0
			var l := away.length()
			if l < 1.3 and l > 0.001:
				dir += away / l * (1.3 - l) * 0.9
		if dir.length() > 0.001:
			dir = dir.normalized()
	# Smooth speed and heading.
	_speed_now = move_toward(_speed_now, want_speed, accel * delta)
	var planar := Vector2(velocity.x, velocity.z)
	var desired := Vector2(dir.x, dir.z) * _speed_now if dir != Vector3.ZERO else Vector2.ZERO
	var k := 1.0 - exp(-accel * delta)
	planar = planar.lerp(desired, k)
	velocity.x = planar.x
	velocity.z = planar.y
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	var moving := planar.length() > 0.15 and want_speed > 0.0
	if moving and skin:
		skin.rotation.y = lerp_angle(skin.rotation.y, atan2(planar.x, planar.y), turn_speed * delta)
	if moving != _moving:
		_moving = moving
		_on_moving_changed(moving)
	_on_walk(delta, planar.length())


## Hooks for subclasses (animation, bobbing).
func _on_moving_changed(_moving_now: bool) -> void:
	pass


func _on_walk(_delta: float, _speed: float) -> void:
	pass
