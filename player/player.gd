class_name Player
extends CharacterBody3D
## Pháp sư tập sự (model KayKit Mage, CC0).
## Di chuyển mượt theo hướng camera, animation tự chuyển theo trạng thái.

const MODEL := preload("res://assets/kaykit/chars/Mage.glb")
const STAFF := preload("res://assets/kaykit/chars/props/staff.gltf")
const MODEL_SCALE := 0.62          # Mage gốc cao 3m → ~1.85m

@export var walk_speed := 3.2
@export var run_speed := 6.0
@export var accel := 16.0
@export var decel := 24.0
@export var jump_velocity := 6.5
@export var turn_speed := 11.0

const COYOTE := 0.12        # may still jump this long after stepping off an edge
const JUMP_BUFFER := 0.15   # a jump pressed this early before landing still fires
var _coyote_t := 0.0
var _jump_buf := 0.0
var _lean := 0.0
var _path: Array[Vector3] = []
var _wp := 0
var _nav: NavGrid

var gravity: float = 18.0
var _anim: AnimationPlayer
var _skin: Node3D
var _busy_until := 0.0
var _current_anim := ""
var _was_on_floor := true
var _step_timer := 0.0
var _foot: AudioStreamPlayer3D
var _land: AudioStreamPlayer3D
var _dust: GPUParticles3D
var glow: OmniLight3D
var flying := false
var _broom: Node3D
var _trail: GPUParticles3D
var _star: Node3D
var _scarf: MeshInstance3D

signal interacted

## Click-to-move target (set by HUD when the player clicks the ground). Routed through the NavGrid
## so a tap on the far side of a house walks around it.
## Set by the HUD while the touch stick is held (0..1); -1 when not in use.
var stick_mag := -1.0
var move_target := Vector3.INF:
	set(v):
		move_target = v
		_path = []
		_wp = 0
		if v != Vector3.INF:
			if _nav == null and is_inside_tree():
				_nav = NavGrid.get_for(get_tree())
			_path = _nav.find_path(global_position, v) if _nav and _nav.built else [v]
			if _path.is_empty():
				_path = [v]


func _ready() -> void:
	add_to_group("player")
	_skin = MODEL.instantiate()
	_skin.scale = Vector3.ONE * MODEL_SCALE
	add_child(_skin)
	_anim = _skin.get_node("AnimationPlayer")
	for mi in _skin.find_children("*", "MeshInstance3D", true, false):
		for i in mi.get_surface_override_material_count():
			var base: Material = mi.mesh.surface_get_material(i) if mi.mesh else null
			var m: StandardMaterial3D = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
			m.rim_enabled = true
			m.rim = 0.5
			m.rim_tint = 0.6
			mi.set_surface_override_material(i, m)
	for a in ["Idle", "Walking_A", "Running_A", "Jump_Idle"]:
		_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	# Gậy phép trong tay phải
	var slot: Node3D = _skin.find_child("handslot_r", true, false)
	if slot:
		var staff: Node3D = STAFF.instantiate()
		slot.add_child(staff)
	# Ánh sáng nhỏ ở đầu gậy, để nhân vật luôn nổi trong đêm
	glow = OmniLight3D.new()
	glow.light_color = Color(0.7, 0.85, 1.0)
	glow.light_energy = 0.8
	glow.omni_range = 3.5
	glow.position = Vector3(0, 1.6, 0)
	add_child(glow)
	_play("Idle")

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.9
	add_child(col)
	collision_mask = 1 | 2            # scenery and walkers (villagers, cats, sheep)
	floor_snap_length = 0.45          # stay glued to ramps and small bumps instead of hopping
	floor_constant_speed = true       # slopes do not slow you down
	floor_max_angle = deg_to_rad(50.0)
	wall_min_slide_angle = deg_to_rad(8.0)   # brushing a wall at a shallow angle slides along it

	_foot = _audio(["res://assets/sounds/footstep_concrete_000.ogg", "res://assets/sounds/footstep_concrete_001.ogg", "res://assets/sounds/footstep_concrete_002.ogg"], -6.0)
	_land = _audio(["res://assets/sounds/land.ogg"], -4.0)
	_dust = _make_dust()
	add_child(_dust)
	_scarf = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.16
	tm.outer_radius = 0.27
	_scarf.mesh = tm
	var scm := StandardMaterial3D.new()
	scm.albedo_color = Color.WHITE
	_scarf.material_override = scm
	_scarf.position = Vector3(0, 1.32, 0)
	_scarf.visible = false
	add_child(_scarf)
	_star = Node3D.new()
	var sm := MeshInstance3D.new()
	var ss := SphereMesh.new()
	ss.radius = 0.12
	ss.height = 0.24
	sm.mesh = ss
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.95, 0.75)
	sm.material_override = smat
	_star.add_child(sm)
	var sl := OmniLight3D.new()
	sl.light_color = Color(1.0, 0.9, 0.7)
	sl.omni_range = 3.0
	sl.light_energy = 0.8
	_star.add_child(sl)
	_star.visible = false
	add_child(_star)
	_broom = _make_broom()
	_broom.visible = false
	add_child(_broom)


func _physics_process(delta: float) -> void:
	var g := GameState.glimmer_active()
	glow.light_color = Story.CRYSTALS.get(GameState.staff_color, Story.CRYSTALS["blue"])["color"]
	_star.visible = GameState.chapter4_done
	_scarf.visible = GameState.order != ""
	if _scarf.visible:
		(_scarf.material_override as StandardMaterial3D).albedo_color = Story.ORDERS[GameState.order]["color"]
		_scarf.rotation.y = _skin.rotation.y
	if _star.visible:
		var tt := Time.get_ticks_msec() / 1000.0
		_star.position = Vector3(cos(tt * 1.4) * 0.9, 1.9 + sin(tt * 2.1) * 0.25, sin(tt * 1.4) * 0.9)
	glow.light_energy = move_toward(glow.light_energy, 3.2 if g else 0.8, delta * 4.0)
	glow.omni_range = move_toward(glow.omni_range, 12.0 if g else 3.5, delta * 12.0)
	var cam := get_viewport().get_camera_3d()
	var input := Input.get_vector("left", "right", "up", "down", 0.15) if not GameState.ui_locked else Vector2.ZERO
	var dir := Vector3.ZERO
	if cam and input != Vector2.ZERO:
		var f := -cam.global_basis.z
		f.y = 0.0
		f = f.normalized()
		var r := cam.global_basis.x
		r.y = 0.0
		r = r.normalized()
		dir = (r * input.x - f * input.y).normalized()
		move_target = Vector3.INF
	elif move_target != Vector3.INF:
		if _wp >= _path.size():
			move_target = Vector3.INF
		else:
			# Cut corners: head for the farthest of the next waypoints that is in plain view.
			if _nav and _nav.built and Engine.get_physics_frames() % 20 == 0:
				for i in range(mini(_path.size() - 1, _wp + 3), _wp, -1):
					if _nav.line_clear(global_position, _path[i]):
						_wp = i
						break
			var to := _path[_wp] - global_position
			to.y = 0.0
			var last := _wp == _path.size() - 1
			if to.length() < (0.4 if last else 0.7):
				_wp += 1
				if _wp >= _path.size():
					move_target = Vector3.INF
			else:
				dir = to.normalized()

	var busy := Time.get_ticks_msec() / 1000.0 < _busy_until
	# Touch stick: a gentle push strolls, a full push runs. Keyboard: Shift runs.
	var running: bool = Input.is_action_pressed("run") or stick_mag > 0.9
	var speed := run_speed if running else walk_speed
	if stick_mag > 0.0 and not running:
		speed *= clampf(stick_mag / 0.9, 0.45, 1.0)
	if GameState.haste_active():
		speed *= 1.35
	if busy:
		dir = Vector3.ZERO
	if flying:
		_fly(delta, dir)
		return

	# Walk-to-tap: slow down smoothly for the last metre so you stop on the spot, not past it.
	if dir != Vector3.ZERO and move_target != Vector3.INF and _wp == _path.size() - 1:
		var left := (move_target - global_position)
		left.y = 0.0
		speed = minf(speed, maxf(1.2, left.length() * 2.5))
	var target := dir * speed
	# Frame-rate independent smoothing: quick to get going, a touch quicker to stop.
	var planar_v := Vector2(velocity.x, velocity.z)
	var want := Vector2(target.x, target.z)
	var rate := accel if dir != Vector3.ZERO else decel
	# Reversing direction: brake first, so turns feel planted rather than skating.
	if dir != Vector3.ZERO and planar_v.length() > 0.5 and planar_v.normalized().dot(want.normalized()) < -0.2:
		rate = decel * 1.5
	planar_v = planar_v.lerp(want, 1.0 - exp(-rate / 3.0 * delta))
	velocity.x = planar_v.x
	velocity.z = planar_v.y

	_coyote_t = COYOTE if is_on_floor() else maxf(_coyote_t - delta, 0.0)
	if Input.is_action_just_pressed("jump") and not busy:
		_jump_buf = JUMP_BUFFER
	else:
		_jump_buf = maxf(_jump_buf - delta, 0.0)
	if not is_on_floor():
		# Hold to go higher, let go for a short hop; fall a little faster than you rise.
		var g_mul := 1.0 if (velocity.y > 0.0 and Input.is_action_pressed("jump")) else 1.6
		velocity.y -= gravity * g_mul * delta
	if _jump_buf > 0.0 and _coyote_t > 0.0 and not busy:
		velocity.y = jump_velocity
		_jump_buf = 0.0
		_coyote_t = 0.0
		_play("Jump_Idle", 0.1)

	move_and_slide()

	# Quay mặt theo hướng đi, nghiêng người nhẹ khi vào cua
	var yaw_before := _skin.rotation.y
	if dir.length() > 0.1:
		var yaw := atan2(dir.x, dir.z)
		var k := 1.0 - exp(-turn_speed * delta)
		_skin.rotation.y = lerp_angle(_skin.rotation.y, yaw, k)
	var yaw_rate := angle_difference(yaw_before, _skin.rotation.y) / maxf(delta, 0.001)
	var speed_frac := clampf(planar_v.length() / run_speed, 0.0, 1.0)
	_lean = lerpf(_lean, clampf(-yaw_rate * 0.035 * speed_frac, -0.18, 0.18), 1.0 - exp(-8.0 * delta))
	_skin.rotation.z = _lean

	# Animation
	var planar := Vector2(velocity.x, velocity.z).length()
	if not busy:
		if not is_on_floor():
			_play("Jump_Idle", 0.2)
		elif planar > 0.25:
			var run_anim := planar > walk_speed + 0.8
			_play("Running_A" if run_anim else "Walking_A", 0.22)
			_anim.speed_scale = clampf(planar / (run_speed if run_anim else walk_speed), 0.6, 1.25)
		else:
			_play("Idle", 0.35)
			_anim.speed_scale = 1.0

	# Tiếng bước chân + bụi
	if is_on_floor() and planar > 0.5:
		_step_timer -= delta * planar
		if _step_timer <= 0.0:
			_step_timer = 1.6
			_foot.pitch_scale = randf_range(0.9, 1.1)
			_foot.play()
	_dust.emitting = is_on_floor() and planar > walk_speed + 0.5
	if is_on_floor() and not _was_on_floor:
		_land.play()
		_dust.restart()
	_was_on_floor = is_on_floor()


## Broom flight: WASD moves, Space (JUMP) climbs, Shift (RUN) descends. Capped at 28 m.
func _fly(delta: float, dir: Vector3) -> void:
	var target := dir * 11.0
	velocity.x = move_toward(velocity.x, target.x, 18.0 * delta)
	velocity.z = move_toward(velocity.z, target.z, 18.0 * delta)
	var vy := 0.0
	if Input.is_action_pressed("jump") and global_position.y < 28.0:
		vy = 6.0
	elif Input.is_action_pressed("run"):
		vy = -6.0
	velocity.y = move_toward(velocity.y, vy, 20.0 * delta)
	move_and_slide()
	if dir.length() > 0.1:
		var yaw := atan2(dir.x, dir.z)
		_skin.rotation.y = lerp_angle(_skin.rotation.y, yaw, turn_speed * delta)
	_skin.rotation.x = lerp(_skin.rotation.x, -0.35 * clampf(Vector2(velocity.x, velocity.z).length() / 11.0, 0.0, 1.0), 6.0 * delta)
	_play("Jump_Idle", 0.2)
	_trail.emitting = Vector2(velocity.x, velocity.z).length() > 2.0
	if is_on_floor() and Input.is_action_pressed("run"):
		set_flying(false)


func set_flying(on: bool) -> void:
	if on and not GameState.broom:
		return
	flying = on
	_broom.visible = on
	_trail.emitting = false
	var rig := get_parent().get_node_or_null("CameraRig")
	if rig:
		rig.distance = 13.5 if on else 9.5
	if on:
		velocity.y = 4.0
		GameState.say("You mount the broom.  Space / JUMP climbs, Shift / DOWN descends. Land and hold DOWN to dismount.")
	else:
		_skin.rotation.x = 0.0
		_play("Idle", 0.2)


func _make_broom() -> Node3D:
	var root := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.3, 0.18)
	var shaft := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.05
	c.bottom_radius = 0.06
	c.height = 2.2
	shaft.mesh = c
	shaft.material_override = wood
	shaft.rotation.x = PI / 2.0
	shaft.position = Vector3(0, 0.75, 0.1)
	root.add_child(shaft)
	var brush := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.12
	bc.bottom_radius = 0.26
	bc.height = 0.7
	brush.mesh = bc
	var straw := StandardMaterial3D.new()
	straw.albedo_color = Color(0.85, 0.7, 0.35)
	brush.material_override = straw
	brush.rotation.x = -PI / 2.0
	brush.position = Vector3(0, 0.75, -1.2)
	root.add_child(brush)
	_trail = GPUParticles3D.new()
	_trail.amount = 30
	_trail.lifetime = 0.8
	_trail.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0, -1)
	pm.spread = 20.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(0, -0.5, 0)
	pm.scale_min = 0.4
	pm.scale_max = 1.0
	_trail.process_material = pm
	_trail.draw_pass_1 = HerbPlot._spark_mesh(Color(0.8, 0.9, 1.0), 0.06)
	_trail.position = Vector3(0, 0.75, -1.4)
	root.add_child(_trail)
	return root


## Cast a spell: animation + a burst of coloured sparks from the staff.
func cast(color: Color) -> void:
	do_action("Spellcast_Shoot")
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 0.95
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.0
	pm.gravity = Vector3(0, -3, 0)
	p.process_material = pm
	p.draw_pass_1 = HerbPlot._spark_mesh(color, 0.05)
	p.position = Vector3(0, 1.4, 0)
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Chơi animation một lần (hái, pha thuốc...) rồi quay lại Idle.
func do_action(anim_name: String) -> void:
	_play(anim_name, 0.1)
	_busy_until = Time.get_ticks_msec() / 1000.0 + _anim.get_animation(anim_name).length * 0.85
	_anim.speed_scale = 1.0


func _play(anim_name: String, blend: float = 0.2) -> void:
	if _current_anim == anim_name:
		return
	_current_anim = anim_name
	_anim.play(anim_name, blend)


func _audio(paths: Array, db: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	var rnd := AudioStreamRandomizer.new()
	for s in paths:
		rnd.add_stream(-1, load(s))
	rnd.random_pitch = 1.1
	p.stream = rnd
	p.volume_db = db
	p.position.y = 0.3
	add_child(p)
	return p


func _make_dust() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 12
	p.lifetime = 0.7
	p.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 35.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 1.0
	pm.gravity = Vector3(0, 0.3, 0)
	pm.scale_min = 0.4
	pm.scale_max = 1.0
	pm.color = Color(0.85, 0.8, 0.7, 0.5)
	p.process_material = pm
	var m := SphereMesh.new()
	m.radius = 0.08
	m.height = 0.16
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	m.material = mat
	p.draw_pass_1 = m
	p.position.y = 0.1
	return p
