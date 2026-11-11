extends Node3D
## Làng phù thủy Hollowmere — bản dựng lại với bộ model KayKit (CC0).
## Hướng nghệ thuật: trung cổ cổ tích, mái xanh lam, đèn lồng ấm, hoàng hôn tím.
## Cảnh dựng bằng code để dễ chỉnh từ xa. Ngày/đêm theo giờ thật, T để tua nhanh.

const HEX := "res://assets/kaykit/hex/"
const HAL := "res://assets/kaykit/halloween/"
const DUN := "res://assets/kaykit/dungeon/"
const HerbPlotScript := preload("res://world/herb_plot.gd")
const CauldronScript := preload("res://world/cauldron.gd")
const VillagerScript := preload("res://world/npc.gd")
const BoardScript := preload("res://world/notice_board.gd")
const GateScript := preload("res://world/gate.gd")

const B := 5.0        # scale cho nhà/cây bộ hexagon (gốc rất nhỏ)

@onready var player: CharacterBody3D = $Player
@onready var cam_rig: Node3D = $CameraRig

var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var fireflies: GPUParticles3D
var night_lights: Array[OmniLight3D] = []
var clouds: Array[Node3D] = []
var rng := RandomNumberGenerator.new()

var _shot_path := ""
var _shot_frames := 0


func apply_quality() -> void:
	var low := GameState.quality == "low"
	sun.directional_shadow_max_distance = 26.0 if low else 40.0
	if grass:
		grass.multimesh.visible_instance_count = 5500 if low else 9000
	env.glow_enabled = not low
	if player and player.get("lantern") != null:
		player.lantern.shadow_enabled = not low
	var fl := get_node_or_null("Flowers")
	if fl:
		fl.visible = true
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	if weather_particles:
		weather_particles.amount_ratio = 0.5 if low else 1.0


func _ready() -> void:
	add_to_group("quality")
	rng.seed = 7
	_build_environment()
	_build_ground()
	_build_plaza()
	_build_tower(Vector3(-13, 0, -12))
	_build_academy(Vector3(4, 0, -34))
	_build_garden(Vector3(-4.5, 0, -7))
	_build_houses()
	_build_paths()
	_build_lanterns()
	_build_nature()
	_build_fireflies()
	_build_grass()
	_build_flowers()
	_build_butterflies()
	_build_night_sky()
	_build_people()
	_build_chapter3()
	_build_overworld()
	var districts := Node3D.new()
	districts.set_script(load("res://world/districts.gd"))
	add_child(districts)
	districts.build(self)
	var patrol := Node3D.new()
	patrol.set_script(load("res://world/patrol.gd"))
	add_child(patrol)
	for sid in Story.SHARDS:
		var sh := Node3D.new()
		sh.position = Story.SHARDS[sid]
		sh.set_script(load("res://world/shard.gd"))
		sh.setup(sid)
		add_child(sh)
	for cid in {"ashen": Vector3(-16.0, 0, -9.0), "first_keeper": Vector3(-22.0, 0, -27.0), "thornquist_elder": Vector3(-1.0, 0, -4.5), "ferryman": Vector3(-61.0, 0, 49.0), "shepherd": Vector3(24.0, 0, -33.0), "lanternwright": Vector3(38.0, 0, -12.5), "heron_hermit": Vector3(68.5, 0, 11.0), "watchman": Vector3(60.0, 0, -58.5)}:
		var ch := Node3D.new()
		ch.position = {"ashen": Vector3(-16.0, 0, -9.0), "first_keeper": Vector3(-22.0, 0, -27.0), "thornquist_elder": Vector3(-1.0, 0, -4.5), "ferryman": Vector3(-61.0, 0, 49.0), "shepherd": Vector3(24.0, 0, -33.0), "lanternwright": Vector3(38.0, 0, -12.5), "heron_hermit": Vector3(68.5, 0, 11.0), "watchman": Vector3(60.0, 0, -58.5)}[cid]
		ch.set_script(load("res://world/chest.gd"))
		ch.setup(cid)
		add_child(ch)
	for cinfo in [[Vector3(-14.0, 0, 9.5), Color(0.9, 0.6, 0.3)], [Vector3(26.0, 0, -5.0), Color(0.25, 0.22, 0.25)], [Vector3(-37.0, 0, 0.0), Color(0.85, 0.85, 0.8)]]:
		var cat := CharacterBody3D.new()
		cat.position = cinfo[0]
		cat.set_script(load("res://world/cat.gd"))
		cat.tint = cinfo[1]
		cat.companion = cinfo[1] == Color(0.9, 0.6, 0.3)
		add_child(cat)
	for lid in Story.SKY_LANTERNS:
		var sl := Node3D.new()
		sl.position = Story.SKY_LANTERNS[lid]
		sl.set_script(load("res://world/sky_lantern.gd"))
		sl.setup(lid)
		add_child(sl)
	for bd in Story.BROKEN:
		var br := Node3D.new()
		br.position = bd["pos"]
		br.set_script(load("res://world/broken.gd"))
		br.setup(bd)
		add_child(br)
	_build_bounds()
	_build_season_and_weather()
	if not OS.get_cmdline_user_args().has("--flat"):
		Toon.apply(self)
	_apply_visibility_ranges()
	_update_daylight()
	apply_quality()
	if GameState.spawn_at != Vector3.INF:
		player.global_position = GameState.spawn_at
		cam_rig.set_view(GameState.spawn_yaw, -0.42, 9.5)
		GameState.spawn_at = Vector3.INF
	elif not GameState.title_shown and not OS.get_cmdline_user_args().has("--fresh"):
		GameState.title_shown = true
		GameState.ui_locked = true
		var t := CanvasLayer.new()
		t.set_script(load("res://ui/title.gd"))
		add_child(t)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.get_slice("=", 1)
			process_mode = Node.PROCESS_MODE_ALWAYS
		if arg.begins_with("--cam="):
			var v := arg.get_slice("=", 1).split(",")
			player.global_position = Vector3(float(v[0]), 0.1, float(v[1]))
			cam_rig.set_view(float(v[2]), float(v[3]) if v.size() > 3 else -0.38, float(v[4]) if v.size() > 4 else 7.5)


var _sweep := -1.0
var _all_lights: Array[OmniLight3D] = []
var _light_t := 0.0

## Only lights near the player render (the GL renderer pays per light per object).
func _cull_lights(delta: float) -> void:
	_light_t -= delta
	if _light_t > 0.0:
		return
	_light_t = 0.4
	if _all_lights.is_empty():
		for n in find_children("*", "OmniLight3D", true, false):
			_all_lights.append(n)
	var limit := 36.0 if GameState.quality == "low" else 55.0
	var pp := player.global_position
	for l in _all_lights:
		if is_instance_valid(l):
			var d := l.global_position.distance_to(pp)
			l.visible = d < limit or (l.get_parent() == player)

## Opening sweep: start high above the Academy, glide down to the apprentice.
func start_sweep() -> void:
	_sweep = 0.0
	cam_rig.set_view(180.0, -0.55, 34.0)
	cam_rig.global_position = Vector3(4, 14, -34)


func _process(delta: float) -> void:
	if _sweep >= 0.0:
		_sweep += delta
		var t := clampf(_sweep / 5.0, 0.0, 1.0)
		var e := t * t * (3.0 - 2.0 * t)
		cam_rig.distance = lerpf(34.0, 9.5, e)
		cam_rig.pitch = lerpf(-0.55, -0.42, e)
		cam_rig.yaw = lerp_angle(PI, 0.0, e)
		cam_rig.follow_speed = lerpf(0.6, 9.0, e)
		if t >= 1.0:
			_sweep = -1.0
			cam_rig.follow_speed = 9.0
	_update_wisps(Time.get_ticks_msec() / 1000.0)
	_cull_lights(delta)
	_update_daylight()
	for c in clouds:
		c.position.x += delta * 0.5
		if c.position.x > 70.0:
			c.position.x = -70.0
	if _shot_path != "":
		_shot_frames += 1
		if _shot_frames == 100:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("time_fast"):
		GameState.time_scale = 720.0 if GameState.time_scale == 1.0 else 1.0
		GameState.say("Fast-forward ON (1 day = 2 min)" if GameState.time_scale > 1.0 else "Back to real time")


# ---------------------------------------------------------------- ánh sáng & trời

func _build_environment() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sun_angle_max = 25.0
	sky_mat.sun_curve = 0.2
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	env.glow_enabled = true    # switched off again by apply_quality() on "low"
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_enabled = true
	env.fog_density = 0.0025
	env.fog_sky_affect = 0.25
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	post = PostFX.new()
	add_child(post)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias = 0.03
	add_child(sun)

	moon = DirectionalLight3D.new()
	moon.light_color = Color(0.5, 0.6, 1.0)
	moon.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-150), 0)
	add_child(moon)


func _update_daylight() -> void:
	var h := GameState.hour_of_day()
	var f := h / 24.0
	var elev := sin((f - 0.25) * TAU)
	var day := smoothstep(-0.12, 0.3, elev)
	var dusk := clampf(1.0 - absf(elev) * 3.0, 0.0, 1.0)

	sun.rotation = Vector3(-(f - 0.25) * TAU, deg_to_rad(40), 0)
	sun.light_energy = day * 0.75
	sun.light_color = Color(1.0, 0.92, 0.8).lerp(Color(1.0, 0.5, 0.25), dusk)
	sun.visible = day > 0.02
	moon.light_energy = (1.0 - day) * 0.42
	moon.light_color = Color(0.56, 0.7, 0.95)
	moon.visible = day < 0.98

	var top := Color(0.06, 0.06, 0.2).lerp(Color(0.3, 0.5, 0.9), day).lerp(Color(0.3, 0.2, 0.55), dusk * 0.7)
	var hor := Color(0.18, 0.14, 0.35).lerp(Color(0.75, 0.82, 0.92), day).lerp(Color(1.0, 0.5, 0.4), dusk * 0.85)
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor
	sky_mat.ground_bottom_color = top.darkened(0.5)
	env.fog_light_color = hor.lerp(Color(0.45, 0.35, 0.6), 0.3)
	env.ambient_light_color = Color(0.13, 0.19, 0.4).lerp(Color(0.5, 0.55, 0.7), day)
	env.ambient_light_energy = lerpf(0.62, 0.45, day)
	env.tonemap_exposure = lerpf(1.05, 0.85, day)
	env.fog_density = lerpf(0.0075, 0.0025, day) * (1.0 + dusk * 0.6)
	if env.glow_enabled:
		env.glow_intensity = lerpf(1.0, 0.4, day)
	if post:
		post.set_night(1.0 - day)
	if player and player.get("lantern") != null:
		var fl := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * 9.0) * 0.05 + sin(Time.get_ticks_msec() / 1000.0 * 23.0) * 0.03
		player.lantern.light_energy = (1.0 - day) * 4.2 * fl
		player.lantern.visible = day < 0.9
	if grass:
		var cam3 := get_viewport().get_camera_3d()
		var cpos: Vector3 = player.global_position if cam3 == null else player.global_position.lerp(cam3.global_position, 0.25)
		grass.follow(Vector3(cpos.x, 0, cpos.z), player.global_position)

	var night := 1.0 - day
	for l in night_lights:
		var flick := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * 7.0 + l.get_meta("seed", 0.0)) * 0.08
		l.light_energy = lerpf(0.05, l.get_meta("base_energy", 1.5) * 1.5, night) * flick * float(l.get_meta("warm", 1.0))
	fireflies.emitting = night > 0.4


# ---------------------------------------------------------------- đất & quảng trường

func _build_ground() -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = WorldBoundaryShape3D.new()
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	mesh.mesh = plane
	# Meadow ground: mottled turf, dry patches, muddy hollows and standing water that catches the light.
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.noise = noise
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	var gsh := Shader.new()
	gsh.code = """
shader_type spatial;
uniform vec3 tint : source_color = vec3(0.34, 0.52, 0.32);
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;
uniform float wet_amount = 0.4;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n1 = texture(noise_tex, wp.xz * 0.013).r;
	float n2 = texture(noise_tex, wp.xz * 0.051 + vec2(3.7, 1.9)).r;
	float n3 = texture(noise_tex, wp.xz * 0.23 + vec2(7.1, 4.3)).r;
	vec3 g = tint * mix(0.55, 0.92, n1) * mix(0.9, 1.06, n3);
	g = mix(g, g * vec3(1.18, 1.06, 0.72), smoothstep(0.5, 0.72, n2));
	float hollow = smoothstep(0.56, 0.7, n1 * 0.55 + n2 * 0.45);
	float wet = hollow * wet_amount;
	float puddle = smoothstep(0.34, 0.42, wet + (n3 - 0.5) * 0.1);
	vec3 col = mix(g, vec3(0.15, 0.12, 0.09), clamp(wet * 1.6, 0.0, 0.85));
	col = mix(col, vec3(0.03, 0.045, 0.06), puddle * 0.9);
	ALBEDO = col;
	ROUGHNESS = mix(0.97, 0.08, puddle);
	SPECULAR = mix(0.15, 0.9, puddle);
	METALLIC = puddle * 0.25;
}
"""
	ground_mat = ShaderMaterial.new()
	ground_mat.shader = gsh
	ground_mat.set_shader_parameter("noise_tex", nt)
	mesh.material_override = ground_mat
	body.add_child(mesh)
	add_child(body)


func _build_plaza() -> void:
	var disc := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 7.0
	c.bottom_radius = 7.0
	c.height = 0.12
	c.radial_segments = 8    # bát giác, hợp với phong cách low-poly
	disc.mesh = c
	disc.position.y = 0.06
	disc.rotation.y = PI / 8.0
	var cobble := _mat(Color(0.55, 0.52, 0.6), 0.95)
	var cn := FastNoiseLite.new()
	cn.noise_type = FastNoiseLite.TYPE_CELLULAR
	cn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	cn.frequency = 0.09
	cn.seed = 9
	var ct := NoiseTexture2D.new()
	ct.noise = cn
	ct.width = 256
	ct.height = 256
	ct.color_ramp = Gradient.new()
	ct.color_ramp.set_color(0, Color(0.45, 0.42, 0.5))
	ct.color_ramp.set_color(1, Color(1.0, 1.0, 1.0))
	cobble.albedo_texture = ct
	cobble.uv1_scale = Vector3(3.0, 3.0, 3.0)
	cobble.uv1_triplanar = true
	disc.material_override = cobble
	add_child(disc)
	# Eight-pointed star mosaic around the shrine
	for k in 8:
		var ray := MeshInstance3D.new()
		var rm := PrismMesh.new()
		rm.size = Vector3(1.2, 3.2, 0.05)
		ray.mesh = rm
		ray.rotation = Vector3(-PI / 2.0, k * PI / 4.0, 0)
		ray.position = Vector3(sin(k * PI / 4.0) * 2.4, 0.13, cos(k * PI / 4.0) * 2.4)
		ray.rotation.y = k * PI / 4.0
		ray.material_override = _mat(Color(0.85, 0.78, 0.6), 0.8)
		add_child(ray)
	var ring := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 7.4
	rc.bottom_radius = 7.4
	rc.height = 0.08
	rc.radial_segments = 8
	ring.mesh = rc
	ring.position.y = 0.04
	ring.rotation.y = PI / 8.0
	ring.material_override = _mat(Color(0.36, 0.34, 0.42), 0.9)
	add_child(ring)

	# Đền thờ nến ở giữa: trái tim phép thuật của làng
	var shrine := _place(HAL + "shrine_candles.gltf", Vector3(0, 0.12, 0), 2.6, 0.0)
	_collider(shrine, Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 1.0))
	var sh_i := Node3D.new()
	sh_i.position = Vector3(0, 0.12, 2.2)
	sh_i.set_script(load("res://world/shrine.gd"))
	add_child(sh_i)
	var l := _night_light(Color(1.0, 0.7, 0.4), 3.0, 10.0)
	l.position = Vector3(0, 3.5, 0)
	add_child(l)
	var p := _particles(Color(0.75, 0.6, 1.0), 60, 5.0, 0.035)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 2.5
	pm.emission_ring_inner_radius = 1.0
	pm.emission_ring_height = 0.5
	pm.emission_ring_axis = Vector3.UP
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.8
	pm.orbit_velocity_min = 0.04
	pm.orbit_velocity_max = 0.08
	p.position.y = 1.0
	add_child(p)

	# Ghế đá, bí ngô, thùng quanh quảng trường
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4.0
		var pos := Vector3(cos(a) * 5.2, 0.12, sin(a) * 5.2)
		var bench := _place(HAL + "bench.gltf", pos, 1.0, -a + PI / 2.0)
		_collider(bench, Vector3(0, 0.25, 0), Vector3(2.0, 0.5, 0.75))
	_place(HAL + "pumpkin_orange_jackolantern.gltf", Vector3(4.2, 0.12, -4.0), 0.7, 0.6)
	_place(HAL + "pumpkin_orange_small.gltf", Vector3(5.0, 0.12, -3.2), 0.7, 1.2)
	_place(HAL + "pumpkin_yellow.gltf", Vector3(-4.6, 0.12, 4.0), 0.7, 2.0)
	var pl := _night_light(Color(1.0, 0.55, 0.15), 1.2, 4.0)
	pl.position = Vector3(4.2, 0.8, -4.0)
	add_child(pl)


# ---------------------------------------------------------------- tháp & học viện

func _build_tower(at: Vector3) -> void:
	var t := _place(HEX + "buildings/blue/building_tower_B_blue.gltf", at, B * 1.15, deg_to_rad(35))
	_collider(t, Vector3(0, 1.0, 0), Vector3(1.0, 2.0, 1.1))
	# Tháp phụ hai bên
	var t2 := _place(HEX + "buildings/blue/building_tower_A_blue.gltf", at + Vector3(5.5, 0, 2.5), B * 0.8, deg_to_rad(-20))
	_collider(t2, Vector3(0, 1.0, 0), Vector3(1.0, 2.0, 1.1))
	# Cây chết + lồng đèn treo cho không khí
	var dt1 := _place(HAL + "tree_dead_large.gltf", at + Vector3(-5.0, 0, 4.0), 0.9, 1.0)
	_collider(dt1, Vector3(0, 1.0, 0), Vector3(0.5, 2.0, 0.5))
	var dt2 := _place(HAL + "tree_dead_medium.gltf", at + Vector3(6.0, 0, -4.0), 0.9, 2.2)
	_collider(dt2, Vector3(0, 1.0, 0), Vector3(0.4, 2.0, 0.4))
	var hang := _place(HAL + "post_lantern.gltf", at + Vector3(2.8, 0, 5.5), 1.0, deg_to_rad(200))
	var hl := _night_light(Color(1.0, 0.75, 0.45), 1.6, 7.0)
	hl.position = at + Vector3(2.0, 2.8, 5.0)
	add_child(hl)
	# Ánh sáng cửa sổ tháp
	var wl := _night_light(Color(0.75, 0.55, 1.0), 2.5, 12.0)
	wl.position = at + Vector3(0, 9.0, 3.0)
	add_child(wl)
	# Hạt tím bay quanh đỉnh
	var p := _particles(Color(0.7, 0.45, 1.0), 50, 6.0, 0.045)
	var pm: ParticleProcessMaterial = p.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = 4.5
	pm.emission_ring_inner_radius = 3.0
	pm.emission_ring_height = 5.0
	pm.emission_ring_axis = Vector3.UP
	pm.orbit_velocity_min = 0.03
	pm.orbit_velocity_max = 0.06
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.3
	p.position = at + Vector3(0, 9.5, 0)
	add_child(p)


func _build_academy(at: Vector3) -> void:
	# Lâu đài xa xa: học viện phép thuật, bóng dáng phía chân trời
	var c := _place(HEX + "buildings/blue/building_castle_blue.gltf", at, B * 1.3, deg_to_rad(10))
	_collider(c, Vector3(0, 1.5, 0), Vector3(2.0, 3.0, 2.2))
	var al := _night_light(Color(1.0, 0.8, 0.5), 3.0, 18.0)
	al.position = at + Vector3(0, 10, 3)
	add_child(al)
	_place(HEX + "buildings/blue/building_church_blue.gltf", at + Vector3(14, 0, 4), B, deg_to_rad(-25))
	# Towers and banners around the keep
	for off in [Vector3(-11, 0, -4), Vector3(11, 0, -6), Vector3(-7, 0, -13), Vector3(8, 0, -14)]:
		var tw := _place(HEX + "buildings/blue/building_tower_A_blue.gltf", at + off, B * 1.1, rng.randf() * TAU)
		_collider(tw, Vector3(0, 0.6, 0), Vector3(0.9, 1.2, 0.9))
		var tl := _night_light(Color(1.0, 0.8, 0.5), 1.6, 9.0)
		tl.position = at + off + Vector3(0, 5.5, 0)
		add_child(tl)
	for off in [Vector3(-5, 0, 7.5), Vector3(5, 0, 7.5)]:
		_place(HEX + "decoration/props/flag_blue.gltf", at + off, B * 1.2, 0.0)
	_place(HEX + "buildings/blue/building_tower_B_blue.gltf", at + Vector3(0, 0, -16), B * 1.4, 0.2)
	_place(HEX + "buildings/neutral/wall_straight.gltf", at + Vector3(-9, 0, 7), B, deg_to_rad(90))
	_place(HEX + "buildings/neutral/wall_straight.gltf", at + Vector3(9, 0, 7), B, deg_to_rad(90))


# ---------------------------------------------------------------- vườn thảo dược

func _build_garden(at: Vector3) -> void:
	var herbs := ["moonpetal", "emberroot", "whisperleaf"]
	for i in herbs.size():
		var plot := HerbPlotScript.new()
		plot.setup(herbs[i], "plot_%d" % i)
		plot.position = at + Vector3(i * 3.4 - 3.4, 0, 0)
		add_child(plot)
	# Extra beds bought from Tamsin (garden level 1 and 2)
	for lvl in range(1, GameState.garden_level + 1):
		for i in herbs.size():
			var extra := HerbPlotScript.new()
			extra.setup(herbs[(i + lvl) % 3], "plot_%d_%d" % [lvl, i])
			extra.position = at + Vector3(i * 3.4 - 3.4, 0, 3.2 * lvl + 2.0)
			add_child(extra)
	var pk := Node3D.new()
	pk.position = at + Vector3(-15.5, 0, 5.5)
	pk.set_script(load("res://world/pumpkin.gd"))
	add_child(pk)
	if GameState.sunbell_bed:
		var sb := HerbPlotScript.new()
		sb.setup("sunbell", "plot_sunbell")
		sb.position = at + Vector3(-7.0, 0, -4.5)
		add_child(sb)
	# Hàng rào gỗ thấp sau vườn
	for i in 4:
		_place(HAL + "fence.gltf", at + Vector3(i * 3.0 - 4.5, 0, -1.6), 0.5, 0.0)
	var cauldron := CauldronScript.new()
	cauldron.position = at + Vector3(-7.0, 0, 2.5)
	add_child(cauldron)
	_collider(cauldron, Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.4))
	# Bàn pha chế với lọ thuốc và nến
	var table := _place(DUN + "table_medium_decorated_A.gltf.glb", at + Vector3(-9.6, 0, 1.0), 0.85, deg_to_rad(20))
	_collider(table, Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 2.0))
	_place(DUN + "bottle_A_labeled_green.gltf.glb", at + Vector3(-9.3, 0.8, 0.7), 0.6, 0.3)
	_place(DUN + "bottle_B_brown.gltf.glb", at + Vector3(-9.9, 0.8, 1.3), 0.6, 1.0)
	_place(DUN + "candle_lit.gltf.glb", at + Vector3(-9.0, 0.8, 1.5), 0.6, 0.0)
	var cl := _night_light(Color(1.0, 0.7, 0.35), 1.0, 4.0)
	cl.position = at + Vector3(-9.2, 1.6, 1.2)
	add_child(cl)
	_place(DUN + "barrel_large.gltf.glb", at + Vector3(-11.5, 0, 3.5), 0.75, 0.4)
	# The apothecary cottage itself (your home), door facing the garden
	var cottage := _place(HEX + "buildings/green/building_home_B_green.gltf", at + Vector3(-14.0, 0, 1.5), B, deg_to_rad(90))
	_collider(cottage, Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
	var owl := Node3D.new()
	owl.position = at + Vector3(-11.0, 0.0, -0.6)
	owl.set_script(load("res://world/owl.gd"))
	add_child(owl)
	var perch := _cyl(0.05, 0.06, 1.6, _mat(Color(0.4, 0.28, 0.18), 0.9))
	perch.position = at + Vector3(-11.0, 0.8, -0.6)
	add_child(perch)
	owl.position.y = 1.6
	var ent := Node3D.new()
	ent.position = at + Vector3(-11.2, 0, 1.5)
	ent.set_script(load("res://world/home_entrance.gd"))
	add_child(ent)
	_place(DUN + "chest.glb", at + Vector3(-11.3, 0, 0.0), 0.7, deg_to_rad(60))


# ---------------------------------------------------------------- nhà cửa & đường

func _build_houses() -> void:
	var spots := [
		["buildings/blue/building_home_A_blue.gltf", Vector3(13, 0, -10), B],
		["buildings/blue/building_home_B_blue.gltf", Vector3(19, 0, 9.5), B],
		["buildings/blue/building_tavern_blue.gltf", Vector3(-16, 0, 7), B],
		["buildings/blue/building_market_blue.gltf", Vector3(3, 0, -18), B],
		["buildings/blue/building_home_A_blue.gltf", Vector3(-9, 0, 16), B],
		["buildings/blue/building_well_blue.gltf", Vector3(9, 0, 12), B * 0.9],
		["buildings/blue/building_windmill_blue.gltf", Vector3(24, 0, -4), B],
	]
	for s in spots:
		var pos: Vector3 = s[1]
		var face := atan2(-pos.x, -pos.z)
		var h := _place(HEX + s[0], pos, s[2], face)
		_collider(h, Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
		var dir := Vector3(-pos.x, 0, -pos.z).normalized()
		if spots.find(s) < 4:
			var lamp := _night_light(Color(1.0, 0.78, 0.5), 1.8, 8.0)
			lamp.position = pos + dir * 3.2 + Vector3(0, 2.4, 0)
			add_child(lamp)
		# Bí ngô hoặc thùng cạnh cửa
		var side := dir.rotated(Vector3.UP, PI / 2.0)
		if rng.randf() < 0.6:
			_place(HAL + "pumpkin_orange_small.gltf", pos + dir * 2.6 + side * 1.6, 0.6, rng.randf() * TAU)
		else:
			_place(HEX + "decoration/props/barrel.gltf", pos + dir * 2.6 + side * 1.6, B * 0.7, rng.randf() * TAU)


func _build_paths() -> void:
	var dirt := _mat(Color(0.56, 0.47, 0.36), 1.0)
	var targets := [Vector3(-13, 0, -12), Vector3(13, 0, -10), Vector3(16, 0, 3), Vector3(-16, 0, 7), Vector3(3, 0, -18), Vector3(-9, 0, 16), Vector3(9, 0, 12), Vector3(-4.5, 0, -7)]
	for t in targets:
		var dir: Vector3 = (t as Vector3).normalized()
		var length: float = (t as Vector3).length() - 7.5
		var path := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.7, 0.05, length)
		path.mesh = b
		path.material_override = dirt
		var mid: Vector3 = dir * (7.5 + length * 0.5)
		path.position = Vector3(mid.x, 0.025, mid.z)
		path.rotation.y = atan2(dir.x, dir.z)
		add_child(path)
	# Đường mòn lên học viện
	var road := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(2.2, 0.05, 20.0)
	road.mesh = rb
	road.material_override = dirt
	road.position = Vector3(3.2, 0.025, -22.0)
	road.rotation.y = atan2(3.2, 18.0) * -1.0
	add_child(road)
	var arch := _place(HAL + "arch.gltf", Vector3(2.0, 0, -13.5), 0.9, deg_to_rad(-10))
	_collider(arch, Vector3(-1.8, 1.5, 0), Vector3(0.6, 3.0, 0.6))
	_collider(arch, Vector3(1.8, 1.5, 0), Vector3(0.6, 3.0, 0.6))


func _build_lanterns() -> void:
	for i in 8:
		var a := i * TAU / 8.0 + PI / 8.0
		var pos := Vector3(cos(a) * 8.6, 0, sin(a) * 8.6)
		var lantern := _place(HAL + "lantern_standing.gltf", pos, 1.1, -a)
		_collider(lantern, Vector3(0, 0.45, 0), Vector3(0.5, 0.9, 0.5))
		if i % 2 == 0:
			var l := _night_light(Color(1.0, 0.75, 0.45), 1.3, 6.0)
			l.position = pos + Vector3(0, 0.9, 0)
			add_child(l)
	for pos in [Vector3(-6, 0, 9), Vector3(10, 0, -3), Vector3(-9, 0, -4), Vector3(4, 0, 9)]:
		var post := _place(HAL + "post_lantern.gltf", pos, 1.0, atan2(-pos.x, -pos.z) + PI)
		_collider(post, Vector3(0, 1.5, 0), Vector3(0.4, 3.0, 0.4))
		var l := _night_light(Color(1.0, 0.75, 0.45), 1.6, 7.0)
		l.position = pos + Vector3(0, 2.8, 0) + Vector3(-pos.x, 0, -pos.z).normalized() * 1.2
		add_child(l)


# ---------------------------------------------------------------- people & story props

func _build_people() -> void:
	for id in Story.NPCS:
		if Story.NPCS[id].get("scene", "village") != "village":
			continue
		var v := VillagerScript.new()
		v.setup(id)
		add_child(v)
	# Lanterns that went dark in the Quiet (Chapter 2: light them with Kindle)
	var spots := [Vector3(-7.5, 0, 14.5), Vector3(18.5, 0, 9.0), Vector3(-20.5, 0, -8.0), Vector3(12.5, 0, -16.0)]
	for i in spots.size():
		var d := Node3D.new()
		d.position = spots[i]
		d.set_script(load("res://world/dark_lantern.gd"))
		d.setup("village_%d" % i)
		add_child(d)
	var board := BoardScript.new()
	board.position = Vector3(6.4, 0.12, -3.6)
	board.rotation.y = deg_to_rad(-120)
	add_child(board)
	var gate := GateScript.new()
	gate.position = Vector3(2.0, 0, -13.5)
	add_child(gate)
	var tt := Node3D.new()
	tt.position = Vector3(-1.5, 0, -11.5)
	tt.set_script(load("res://world/landmark.gd"))
	tt.setup("Academy timetable", "08-11  Flamecraft — Professor Alder, Hall of Flame\n11-14  Herbology — Professor Isolde, Greenhouse\n14-17  Lore — Archivist Quill, Library\n17-19  Evening Assembly — Headmistress Vance, Great Hall\n19-21  Potions — Master Corvin, Potions Dungeon (west of the library)\n21-24  Astronomy — Professor Lowe, Astronomy Tower (north of the library)\n\nEach lesson earns up to 3 Marks once a day. Marks raise your rank.")
	add_child(tt)


# ---------------------------------------------------------------- chapter 3, seasons, weather

var ground_mat: ShaderMaterial
var post: PostFX
var weather_particles: GPUParticles3D

func _build_chapter3() -> void:
	for id in Story.LOST_PAGES:
		var pg := Node3D.new()
		pg.position = Story.LOST_PAGES[id]["pos"]
		pg.set_script(load("res://world/lost_page.gd"))
		pg.setup(id)
		add_child(pg)
	for id in GameState.decor:
		_place_decor(id)


func _place_decor(id: String) -> void:
	var d: Dictionary = Story.DECOR[id]
	var n := _place("res://assets/kaykit/" + d["model"], d["pos"], d["scale"], 0.4)
	n.name = "decor_" + id
	var p := _particles(Color(1.0, 0.9, 0.5), 20, 1.5, 0.03)
	p.one_shot = true
	p.explosiveness = 0.9
	var pm: ParticleProcessMaterial = p.process_material
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.5
	pm.spread = 80.0
	p.position = d["pos"] + Vector3(0, 1, 0)
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _build_season_and_weather() -> void:
	var season := Story.season()
	var weather := Story.weather()
	# Ground colour follows the season
	var ground_colors := {"winter": Color(0.82, 0.85, 0.9), "spring": Color(0.42, 0.62, 0.36), "summer": Color(0.34, 0.56, 0.3), "autumn": Color(0.4, 0.5, 0.3)}
	ground_mat.set_shader_parameter("tint", ground_colors[season])
	if grass:
		grass.set_tint({"winter": Color(1.5, 1.6, 1.9), "spring": Color(1.0, 1.08, 1.0), "summer": Color(1, 1, 1), "autumn": Color(1.45, 1.0, 0.6)}.get(season, Color(1, 1, 1)))
	ground_mat.set_shader_parameter("wet_amount", 0.75 if weather in ["rain", "storm", "drizzle"] else 0.42)
	# Season touches: tinted tree leaves in autumn, frost on grass in winter, blossom in spring
	var leaf_tint: Color = {"winter": Color(0.8, 0.85, 0.9), "spring": Color(1.0, 1.0, 1.0), "summer": Color(1.0, 1.0, 1.0), "autumn": Color(1.25, 1.0, 0.7)}[season]
	if season != "summer" and season != "spring":
		for mi in find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var par := m.get_parent()
			var pname := str(par.name).to_lower() if par else ""
			var gname := str(par.get_parent().name).to_lower() if par and par.get_parent() else ""
			var path := m.get_path().get_concatenated_names().to_lower()
			if "tree" in path or "hills" in path or "mountain" in path:
				for i in m.get_surface_override_material_count():
					var base: Material = m.get_surface_override_material(i)
					if base == null and m.mesh:
						base = m.mesh.surface_get_material(i)
					if base is StandardMaterial3D:
						var dup: StandardMaterial3D = base.duplicate()
						dup.albedo_color = dup.albedo_color * leaf_tint
						m.set_surface_override_material(i, dup)
	if weather == "rain" or weather == "misty":
		# puddles on the roads
		for i in 14:
			var rd: Array = ROADS[i % ROADS.size()]
			var pos: Vector3 = (rd[0] as Vector3).lerp(rd[1], rng.randf())
			var pd := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = rng.randf_range(0.8, 1.6)
			pm.bottom_radius = pm.top_radius
			pm.height = 0.02
			pm.radial_segments = 10
			pd.mesh = pm
			pd.position = pos + Vector3(rng.randf_range(-2, 2), 0.03, rng.randf_range(-2, 2))
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.45, 0.55, 0.7, 0.75)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.05
			mat.metallic = 0.3
			pd.material_override = mat
			add_child(pd)
	if weather == "rain" and GameState.hour_of_day() >= 15.0 and GameState.hour_of_day() < 18.0:
		_build_rainbow()
	if season == "winter":
		for i in 30:
			var a := rng.randf() * TAU
			var r := rng.randf_range(12.0, 70.0)
			var pos := Vector3(cos(a) * r, 0, sin(a) * r)
			if _on_road(pos) or pos.distance_to(Vector3(58, 0, 14)) < 26.0:
				continue
			var sn := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = rng.randf_range(0.6, 1.4)
			sm.height = sm.radius * 1.2
			sn.mesh = sm
			sn.position = pos + Vector3(0, -sm.radius * 0.3, 0)
			sn.material_override = _mat(Color(0.95, 0.97, 1.0), 1.0)
			add_child(sn)
	if season == "spring":
		for i in 90:
			var a := rng.randf() * TAU
			var r := rng.randf_range(10.0, 60.0)
			var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
			if _on_road(pos) or pos.length() < 13.0:
				continue
			var bl := MeshInstance3D.new()
			var bm := SphereMesh.new()
			bm.radius = 0.2
			bm.height = 0.3
			bm.radial_segments = 6
			bm.rings = 3
			bl.mesh = bm
			bl.material_override = _mat([Color(1.0, 0.75, 0.85), Color(1.0, 1.0, 1.0), Color(1.0, 0.9, 0.6)][i % 3], 0.9)
			bl.position = pos + Vector3(0, 0.25, 0)
			add_child(bl)
	if weather == "clear":
		return
	weather_particles = GPUParticles3D.new()
	weather_particles.amount = 400 if weather != "misty" else 60
	weather_particles.lifetime = 4.0 if weather == "snow" else 1.5
	weather_particles.visibility_aabb = AABB(Vector3(-50, -5, -50), Vector3(100, 40, 100))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(35, 1, 35)
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 5.0
	if weather == "snow":
		pm.initial_velocity_min = 1.0
		pm.initial_velocity_max = 2.0
		pm.gravity = Vector3(0.3, -0.5, 0)
		pm.turbulence_enabled = true
		weather_particles.draw_pass_1 = HerbPlot._spark_mesh(Color(1, 1, 1), 0.05)
		weather_particles.position.y = 16.0
	elif weather == "rain":
		pm.initial_velocity_min = 14.0
		pm.initial_velocity_max = 18.0
		pm.gravity = Vector3(0, -20, 0)
		var q := QuadMesh.new()
		q.size = Vector2(0.03, 0.5)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.7, 0.8, 1.0, 0.45)
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		q.material = m
		weather_particles.draw_pass_1 = q
		weather_particles.position.y = 18.0
		env.fog_density = 0.006
	else:   # misty
		pm.initial_velocity_min = 0.1
		pm.initial_velocity_max = 0.3
		pm.gravity = Vector3.ZERO
		pm.emission_box_extents = Vector3(35, 2, 35)
		weather_particles.draw_pass_1 = HerbPlot._spark_mesh(Color(0.85, 0.85, 0.95), 0.9)
		var mm: StandardMaterial3D = weather_particles.draw_pass_1.material
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.emission_enabled = false
		mm.albedo_color = Color(0.85, 0.85, 0.95, 0.07)
		weather_particles.position.y = 1.5
		env.fog_density = 0.009
	weather_particles.process_material = pm
	add_child(weather_particles)


# ---------------------------------------------------------------- overworld: lake, river, Fernmoor, ruins

const ROADS := [[Vector3(8, 0, 0), Vector3(36, 0, 10.5)], [Vector3(-8, 0, 6), Vector3(-56, 0, 44)], [Vector3(10, 0, -12), Vector3(52, 0, -52)]]

func _in_district(p: Vector3) -> bool:
	for id in Story.DISTRICTS:
		if (Story.DISTRICTS[id]["pos"] as Vector3).distance_to(p) < 19.0:
			return true
	return false


## Where villagers may route (NavGrid): the valley from Fernmoor to Ashford and the Watchtower.
func nav_bounds() -> Rect2:
	return Rect2(-80.0, -70.0, 156.0, 130.0)


## Path cost for the NavGrid: roads, the square and the district greens are cheap, so villagers
## keep to the lanes when there is one and only cut across grass when it is clearly shorter.
func nav_cost(p: Vector3) -> float:
	if _on_road(p, 4.0) or p.length() < 17.0 or _in_district(p):
		return 1.0
	return 1.8


const RIVER_PTS := [Vector3(38, 0, 26), Vector3(24, 0, 38), Vector3(6, 0, 46), Vector3(-14, 0, 46), Vector3(-30, 0, 38), Vector3(-50, 0, 24), Vector3(-64, 0, 10)]

func _on_road(p: Vector3, width: float = 7.0) -> bool:
	for rd in ROADS:
		var a: Vector3 = rd[0]
		var b: Vector3 = rd[1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (a + ab * t).distance_to(p) < width:
			return true
	return false


func _build_overworld() -> void:
	var dirt := _mat(Color(0.56, 0.47, 0.36), 1.0)
	for rd in ROADS:
		_road(rd[0], rd[1], dirt)
	# --- Lake Mirren (east) with dock, reeds and lilies
	var lake_c := Vector3(58, 0, 14)
	var lake := WaterBody.make(Vector2(48, 38), 28, true)
	lake.position = lake_c + Vector3(0, 0.08, 0)
	add_child(lake)
	# water colliders leave a gap for Heron Isle (x 61..71, z 9..20) and for the dock (x 36..47, z 10.6..13.4)
	_water_collider(Vector3(49.5, 0, 4.8), Vector3(23, 2, 11.6))
	_water_collider(Vector3(49.5, 0, 21.2), Vector3(23, 2, 15.6))
	_water_collider(Vector3(54, 0, 12), Vector3(14, 2, 2.8))
	_water_collider(Vector3(74.5, 0, 14), Vector3(7, 2, 30))
	_water_collider(Vector3(66, 0, 4), Vector3(10, 2, 10))
	_water_collider(Vector3(66, 0, 24.5), Vector3(10, 2, 9))
	_build_isle(Vector3(66, 0, 14))
	for i in 26:
		var a := i * TAU / 26.0
		var pos := lake_c + Vector3(cos(a) * 22.0, 0, sin(a) * 17.0)
		if absf(pos.z - 12.0) < 3.0 and pos.x < 48.0:
			continue   # keep the dock clear of reeds
		_place(HEX + "decoration/nature/waterplant_%s.gltf" % ["A", "B"][i % 2], pos, B * rng.randf_range(0.8, 1.2), rng.randf() * TAU)
	for i in 8:
		_place(HEX + "decoration/nature/waterlily_%s.gltf" % ["A", "B"][i % 2], lake_c + Vector3(rng.randf_range(-14, 14), 0.02, rng.randf_range(-10, 10)), B, rng.randf() * TAU)
	# dock: a long wooden pier from the shore (x 37) out over the water (x 47), sloping up 0.3 m so it is walkable
	var dock := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(10.0, 0.22, 2.4)
	dock.mesh = db
	dock.position = Vector3(42.0, 0.12, 12)
	dock.rotation.z = atan2(0.3, 10.0)
	dock.material_override = _mat(Color(0.5, 0.35, 0.22), 0.85)
	add_child(dock)
	var deck := StaticBody3D.new()
	deck.name = "col_dock"
	var dcol := CollisionShape3D.new()
	var dbs := BoxShape3D.new()
	dbs.size = Vector3(10.4, 0.22, 2.4)
	dcol.shape = dbs
	deck.add_child(dcol)
	add_child(deck)
	deck.global_transform = dock.global_transform
	for side in [-1.0, 1.0]:
		var rail := StaticBody3D.new()
		rail.name = "col_dock_rail"
		var rc := CollisionShape3D.new()
		var rb := BoxShape3D.new()
		rb.size = Vector3(10.0, 1.0, 0.2)
		rc.shape = rb
		rail.add_child(rc)
		rail.position = Vector3(42.5, 0.6, 12 + side * 1.3)
		add_child(rail)
	var endw := StaticBody3D.new()
	endw.name = "col_dock_end"
	var ec := CollisionShape3D.new()
	var eb := BoxShape3D.new()
	eb.size = Vector3(0.2, 1.0, 2.8)
	ec.shape = eb
	endw.add_child(ec)
	endw.position = Vector3(47.1, 0.6, 12)
	add_child(endw)
	for i in 6:
		var post := _cyl(0.1, 0.1, 1.1, _mat(Color(0.4, 0.28, 0.18), 0.9))
		post.position = Vector3(38.5 + (i / 2) * 4.0, 0.55, 12 + (-1.25 if i % 2 == 0 else 1.25))
		add_child(post)
	for i in 2:
		var railm := _cyl(0.04, 0.04, 9.6, _mat(Color(0.45, 0.32, 0.2), 0.9))
		railm.position = Vector3(42.5, 1.0, 12 + (-1.25 if i == 0 else 1.25))
		railm.rotation.z = PI / 2.0
		add_child(railm)
	var boat := Node3D.new()
	boat.position = Vector3(47.5, 0.0, 14.5)
	boat.rotation.y = deg_to_rad(-30)
	boat.set_script(load("res://world/boat.gd"))
	add_child(boat)
	var fsp := Node3D.new()
	fsp.position = Vector3(46.0, 0.45, 12.0)
	fsp.rotation.y = deg_to_rad(-90)
	fsp.set_script(load("res://world/fishing.gd"))
	add_child(fsp)
	var dock_l := _place(HAL + "lantern_standing.gltf", Vector3(37.5, 0.0, 14.2), 1.0, 0.0)
	var dl := _night_light(Color(1.0, 0.78, 0.45), 1.5, 8.0)
	dl.position = dock_l.position + Vector3(0, 0.9, 0)
	add_child(dl)
	_signpost(Vector3(36, 0, 9), "Lake Mirren")
	# --- River Wend: from the lake, winding south-west, with a stone bridge on the Fernmoor road
	var pts := RIVER_PTS
	for i in pts.size() - 1:
		_river_segment(pts[i], pts[i + 1])
	var bridge := _place(HEX + "buildings/neutral/building_bridge_A.gltf", Vector3(-40, 0.1, 31), B * 1.2, atan2(-48.0, 38.0))
	_bridge_deck(Vector3(-40, 0, 31), atan2(-48.0, 38.0), 1.35, 7.0, 4.6)
	# --- Fernmoor (second village, south-west): green roofs, a well, Hatch the ferryman
	var fm := Vector3(-58, 0, 46)
	_village_patch(fm)
	_build_ashford(Vector3(36, 0, -36))
	_build_hollow_wood(Vector3(-62, 0, -62))
	_signpost(Vector3(-42, 0, 34), "Fernmoor")
	# --- Watchtower ruins (north-east hill)
	var ru := Vector3(56, 0, -56)
	var hill := _place(HEX + "decoration/nature/hill_single_A.gltf", ru + Vector3(0, -0.6, 0), B * 3.0, 0.3)
	var tw := _place(HEX + "buildings/blue/building_tower_base_blue.gltf", ru + Vector3(0, 0.4, 0), B * 1.3, 0.6)
	_collider(tw, Vector3(0, 0.6, 0), Vector3(1.0, 1.2, 1.0))
	_place(HEX + "buildings/neutral/building_destroyed.gltf", ru + Vector3(7, 0.3, 3), B, 1.0)
	_place(HEX + "buildings/neutral/building_destroyed.gltf", ru + Vector3(-6, 0.3, -7), B, 2.4)
	# Chapter 5: the Watchtower's own brazier, dark since the Quiet Night
	var wb := Node3D.new()
	wb.position = ru + Vector3(3.5, 0.4, -2.0)
	wb.set_script(load("res://world/dark_lantern.gd"))
	wb.setup("watchtower")
	add_child(wb)
	for i in 6:
		_place(HAL + "tree_dead_%s.gltf" % ["large", "medium"][i % 2], ru + Vector3(cos(i * 1.1) * 11.0, 0, sin(i * 1.1) * 11.0), 0.9, i * 0.7)
	var rl := _night_light(Color(0.55, 0.7, 1.0), 2.0, 14.0)
	rl.position = ru + Vector3(0, 7, 0)
	add_child(rl)
	_signpost(Vector3(30, 0, -32), "Old Watchtower")
	var mark := Node3D.new()
	mark.position = ru + Vector3(0, 0.4, 4)
	mark.set_script(load("res://world/landmark.gd"))
	mark.setup("Old Watchtower", "Burnt timbers and a tower base. Someone kept a fire here not long ago; the ash is still warm.\n\n(A later chapter begins here.)")
	add_child(mark)
	# scatter more woods between places
	for i in 90:
		var a := rng.randf() * TAU
		var r := rng.randf_range(46.0, 78.0)
		var pos := Vector3(cos(a) * r, -0.05, sin(a) * r)
		if _on_road(pos) or pos.distance_to(lake_c) < 30.0 or pos.distance_to(fm) < 22.0 or pos.distance_to(ru) < 18.0:
			continue
		_grove(pos, 2 + (i % 3), 3.2)


func _village_patch(c: Vector3) -> void:
	var spots := [["building_home_A_green.gltf", Vector3(-7, 0, -6), 20.0], ["building_home_B_green.gltf", Vector3(8, 0, 4), -60.0], ["building_tavern_green.gltf", Vector3(-9, 0, 8), 60.0], ["building_lumbermill_green.gltf", Vector3(12, 0, 12), -120.0]]
	for sp in spots:
		var h := _place(HEX + "buildings/green/" + sp[0], c + sp[1], B, deg_to_rad(sp[2]))
		_collider(h, Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
		var lamp := _night_light(Color(1.0, 0.78, 0.5), 1.5, 8.0)
		lamp.position = c + sp[1] + Vector3(0, 2.4, 0) + (c - (c + sp[1])).normalized() * 3.0
		add_child(lamp)
	var well := _place(HEX + "buildings/green/building_well_green.gltf", c, B * 0.9, 0.0)
	_collider(well, Vector3(0, 0.4, 0), Vector3(0.6, 0.8, 0.6))
	for i in 3:
		_place(HAL + "lantern_standing.gltf", c + Vector3(cos(i * 2.1) * 4.0, 0, sin(i * 2.1) * 4.0), 1.0, 0.0)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 5.5
	cm.bottom_radius = 5.5
	cm.height = 0.08
	cm.radial_segments = 8
	disc.mesh = cm
	disc.position = c + Vector3(0, 0.04, 0)
	disc.material_override = _mat(Color(0.55, 0.5, 0.42), 0.9)
	add_child(disc)


func _road(a: Vector3, b: Vector3, m: Material) -> void:
	var dir := (b - a)
	var path := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.0, 0.05, dir.length())
	path.mesh = bm
	path.material_override = m
	path.position = (a + b) * 0.5 + Vector3(0, 0.025, 0)
	path.rotation.y = atan2(dir.x, dir.z)
	add_child(path)


func _river_segment(a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var w := WaterBody.make(Vector2(7.0, dir.length() + 3.0), 10)
	w.position = (a + b) * 0.5 + Vector3(0, 0.08, 0)
	w.rotation.y = atan2(dir.x, dir.z)
	add_child(w)
	var bank := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(9.5, 0.04, dir.length() + 3.0)
	bank.mesh = bm
	bank.position = (a + b) * 0.5 + Vector3(0, 0.03, 0)
	bank.rotation.y = atan2(dir.x, dir.z)
	bank.material_override = _mat(Color(0.5, 0.45, 0.35), 1.0)
	add_child(bank)
	# Water is a wall, except directly under the bridge deck (the deck has its own walkable collider)
	var yaw := atan2(dir.x, dir.z)
	var n := dir.normalized()
	var bridge_c := Vector3(-40, 0, 31)
	var t_b := (bridge_c - a).dot(n)
	var half := 4.6
	var spans := []
	if t_b > 0.0 and t_b < dir.length():
		if t_b - half > 0.5:
			spans.append([0.0, t_b - half])
		if t_b + half < dir.length() - 0.5:
			spans.append([t_b + half, dir.length()])
	else:
		spans.append([0.0, dir.length()])
	for sp in spans:
		var body := StaticBody3D.new()
		body.name = "col_river"
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(7.0, 4.0, sp[1] - sp[0])
		col.shape = bs
		body.add_child(col)
		add_child(body)
		body.global_transform = Transform3D(Basis.from_euler(Vector3(0, yaw, 0)), a + n * ((sp[0] + sp[1]) * 0.5) + Vector3(0, 0.5, 0))


## Walkable bridge: flat deck at `top`, a ramp at each end, low rails along both sides.
func _bridge_deck(c: Vector3, yaw: float, top: float, deck_len: float, width: float) -> void:
	var basis := Basis.from_euler(Vector3(0, yaw, 0))
	var deck := StaticBody3D.new()
	deck.name = "col_bridge_deck"
	var dc := CollisionShape3D.new()
	var db := BoxShape3D.new()
	db.size = Vector3(width, 0.5, deck_len)
	dc.shape = db
	deck.add_child(dc)
	add_child(deck)
	deck.global_transform = Transform3D(basis, c + Vector3(0, top - 0.25, 0))
	var ramp_len := 5.0
	for side in [-1.0, 1.0]:
		var ramp := StaticBody3D.new()
		ramp.name = "col_bridge_ramp"
		var rc := CollisionShape3D.new()
		var rb := BoxShape3D.new()
		var slope := atan2(top, ramp_len)
		rb.size = Vector3(width, 0.3, sqrt(ramp_len * ramp_len + top * top) + 0.6)
		rc.shape = rb
		ramp.add_child(rc)
		add_child(ramp)
		var centre := c + basis * Vector3(0, top * 0.5 - 0.2, side * (deck_len * 0.5 + ramp_len * 0.5))
		ramp.global_transform = Transform3D(basis * Basis.from_euler(Vector3(side * slope, 0, 0)), centre)
		# Visible ramp (packed earth) so the step up reads on screen
		var rm := MeshInstance3D.new()
		var rbm := BoxMesh.new()
		rbm.size = Vector3(width, 0.3, rb.size.z)
		rm.mesh = rbm
		rm.material_override = _mat(Color(0.52, 0.42, 0.3), 1.0)
		add_child(rm)
		rm.global_transform = ramp.global_transform.translated_local(Vector3(0, -0.06, 0))
	for side in [-1.0, 1.0]:
		var rail := StaticBody3D.new()
		rail.name = "col_bridge_rail"
		var rc2 := CollisionShape3D.new()
		var rb2 := BoxShape3D.new()
		rb2.size = Vector3(0.3, 1.2, deck_len + ramp_len * 2.0)
		rc2.shape = rb2
		rail.add_child(rc2)
		add_child(rail)
		rail.global_transform = Transform3D(basis, c + basis * Vector3(side * (width * 0.5 + 0.1), top + 0.3, 0))


func _water_collider(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	body.add_child(col)
	body.name = "col_water"
	bs.size.y = 6.0
	body.position = center + Vector3(0, 1.0, 0)
	add_child(body)


func _signpost(at: Vector3, text: String) -> void:
	var post := _cyl(0.07, 0.08, 2.0, _mat(Color(0.45, 0.3, 0.18), 0.9))
	post.position = at + Vector3(0, 1.0, 0)
	add_child(post)
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 0.4, 0.08)
	board.mesh = bm
	board.position = at + Vector3(0, 1.8, 0)
	board.material_override = _mat(Color(0.6, 0.42, 0.25), 0.8)
	add_child(board)
	var tag := Label3D.new()
	tag.text = "→ " + text
	tag.font_size = 34
	tag.pixel_size = 0.006
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 8
	tag.outline_modulate = Color(0.1, 0.05, 0.0, 0.9)
	tag.position = at + Vector3(0, 2.4, 0)
	add_child(tag)


# ---------------------------------------------------------------- thiên nhiên

## A small grove: n trees of mixed kinds around `c`, plus a shrub or two.
func _grove(c: Vector3, n: int, spread: float) -> void:
	for k in n:
		var a := k * TAU / float(n) + rng.randf() * 1.2
		var d := rng.randf_range(spread * 0.4, spread)
		var kind := "oak"
		var roll := rng.randf()
		if roll < 0.3:
			kind = "pine"
		elif roll < 0.45:
			kind = "birch"
		elif roll < 0.52:
			kind = "autumn"
		_tree(kind, c + Vector3(cos(a) * d, 0, sin(a) * d), rng.randf_range(0.85, 1.35))
	if rng.randf() < 0.6:
		_tree("shrub", c + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), rng.randf_range(0.8, 1.3))


func _build_nature() -> void:
	# Rừng vòng ngoài: cụm cây lớn
	var clusters := ["decoration/nature/trees_A_large.gltf", "decoration/nature/trees_B_large.gltf", "decoration/nature/trees_A_medium.gltf"]
	for i in 60:
		var a := rng.randf() * TAU
		var r := rng.randf_range(33.0, 46.0)
		var pos := Vector3(cos(a) * r, -0.05, sin(a) * r)
		if pos.z < -24.0 and absf(pos.x - 4.0) < 16.0:
			continue   # chừa chỗ cho học viện
		if _on_road(pos) or _in_district(pos):
			continue
		_grove(pos, 2 + (i % 2), 2.6)
	# Cây đơn rải trong làng
	for pos in [Vector3(7, 0, -14), Vector3(-20, 0, -2), Vector3(21, 0, 6), Vector3(-13, 0, 12), Vector3(14, 0, 16), Vector3(-12, 0, 24), Vector3(20, 0, -14), Vector3(-22, 0, -10)]:
		_tree("oak" if rng.randf() < 0.7 else "birch", pos, rng.randf_range(0.95, 1.25))
		if rng.randf() < 0.5:
			_tree("shrub", pos + Vector3(rng.randf_range(-2.5, 2.5), 0, rng.randf_range(-2.5, 2.5)), rng.randf_range(0.8, 1.2))
	# Thông cam mùa thu làm điểm nhấn màu
	for pos in [Vector3(-7, 0, -17), Vector3(19, 0, -9), Vector3(-24, 0, 9), Vector3(12, 0, 19)]:
		var pt := _place(HAL + "tree_pine_orange_large.gltf", pos, rng.randf_range(0.7, 0.95), rng.randf() * TAU)
		_collider(pt, Vector3(0, 2.0, 0), Vector3(1.4, 4.0, 1.4))
	# Đồi và núi phía xa
	for i in 14:
		var a := i * TAU / 14.0 + 0.3
		var r := 108.0 + (i % 3) * 8.0
		var m := "decoration/nature/mountain_%s_grass_trees.gltf" % ["A", "B", "C"][i % 3]
		var mt := _place(HEX + m, Vector3(cos(a) * r, -0.5, sin(a) * r), B * rng.randf_range(2.2, 3.2), rng.randf() * TAU)
		_collider(mt, Vector3(0, 1.0, 0), Vector3(1.6, 2.0, 1.6))
	for i in 10:
		var a := rng.randf() * TAU
		var r := rng.randf_range(80.0, 100.0)
		var hp := Vector3(cos(a) * r, -0.2, sin(a) * r)
		var too_close := false
		for poi in [Vector3(-62, 0, -62), Vector3(-58, 0, 46), Vector3(56, 0, -56), Vector3(36, 0, -36), Vector3(66, 0, 14)]:
			if hp.distance_to(poi) < 34.0:
				too_close = true
		if too_close:
			continue
		var hl := _place(HEX + "decoration/nature/hills_%s_trees.gltf" % ["A", "B", "C"][i % 3], hp, B * 1.8, rng.randf() * TAU)
		_collider(hl, Vector3(0, 0.6, 0), Vector3(1.5, 1.2, 1.5))
	# Pines on the outer slopes (between the woods and the hills)
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(60.0, 92.0)
		var pp := Vector3(cos(a) * r, 0, sin(a) * r)
		if _on_road(pp) or pp.distance_to(Vector3(58, 0, 14)) < 30.0 or pp.distance_to(Vector3(-58, 0, 46)) < 24.0 or pp.distance_to(Vector3(56, 0, -56)) < 20.0 or _in_district(pp):
			continue
		_tree("pine" if rng.randf() < 0.8 else "autumn", pp, rng.randf_range(0.9, 1.5))
	# Đá
	for i in 30:
		var a := rng.randf() * TAU
		var r := rng.randf_range(9.0, 30.0)
		var rp := Vector3(cos(a) * r, 0, sin(a) * r)
		if _in_district(rp):
			continue
		_place(HEX + "decoration/nature/rock_single_%s.gltf" % ["A", "B", "C", "D", "E"][i % 5], rp, B * rng.randf_range(0.35, 0.8), rng.randf() * TAU)
	# Mây
	for i in 8:
		var cm := "decoration/nature/cloud_big.gltf" if i % 2 == 0 else "decoration/nature/cloud_small.gltf"
		var c := _place(HEX + cm, Vector3(rng.randf_range(-70, 70), rng.randf_range(26, 38), rng.randf_range(-60, 30)), B * rng.randf_range(1.5, 2.5), rng.randf() * TAU)
		clouds.append(c)


func _build_fireflies() -> void:
	fireflies = _particles(Color(0.85, 1.0, 0.45), 60, 6.0, 0.045)
	fireflies.visibility_aabb = AABB(Vector3(-45, -2, -45), Vector3(90, 10, 90))
	var pm: ParticleProcessMaterial = fireflies.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(30, 1.5, 30)
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.4
	pm.spread = 180.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 2.0
	fireflies.position.y = 1.5
	add_child(fireflies)


func _build_bounds() -> void:
	for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(1, 60, 240) if d.x != 0 else Vector3(240, 60, 1)
		col.shape = b
		body.add_child(col)
		body.name = "col_bounds"
		body.position = d * 118.0 + Vector3(0, 30, 0)
		add_child(body)


# ---------------------------------------------------------------- tiện ích

func _place(path: String, pos: Vector3, s: float, rot_y: float) -> Node3D:
	var n: Node3D = load(path).instantiate()
	n.position = pos
	n.scale = Vector3.ONE * s
	n.rotation.y = rot_y
	add_child(n)
	if _is_solid(path):
		_auto_collider(n, path)
	return n


## One hex-pack fence piece centred on `p`, running along `dir`. The KayKit fence mesh sits on the edge
## of a hex tile (one unit from its origin, along local -X, length along local Z), so the node is placed
## one scaled unit to the side and turned so local Z follows `dir`; the automatic collider then matches
## the picture exactly. A gate piece has its door leaf hidden, leaving an open gateway between posts.
func _fence_piece(p: Vector3, dir: Vector3, gate: bool = false) -> Node3D:
	var s := B * 0.5
	var yaw := atan2(dir.x, dir.z)
	var node_pos := p + Vector3(cos(yaw), 0, -sin(yaw)) * s
	var f := _place(HEX + ("buildings/neutral/fence_wood_straight_gate.gltf" if gate else "buildings/neutral/fence_wood_straight.gltf"), node_pos, s, yaw)
	if gate:
		for d in f.find_children("*door*", "", true, false):
			(d as Node3D).visible = false
	return f


## Everything you can bump into gets a collider automatically (buildings, walls, fences, rocks, crates…).
## Walkable or tiny things are skipped: tiles, paths, flags, clouds, water plants, small decor.
const WALKABLE_HINTS := ["floor", "path_", "hex_", "flag_", "cloud", "waterlily", "waterplant", "pumpkin", "candle", "bottle", "coin", "plate", "bone", "skull", "lantern_hanging", "arch", "bridge", "fence_gate", "straight_gate", "ribcage", "mountain", "hills", "hill_single", "banner", "sack", "plaque", "key", "grass"]

func _is_solid(path: String) -> bool:
	var f := path.get_file().to_lower()
	for h in WALKABLE_HINTS:
		if h in f:
			return false
	return true


func _auto_collider(n: Node3D, path: String) -> void:
	var inv := n.global_transform.affine_inverse()
	var aabb := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (inv * (mi as MeshInstance3D).global_transform) * (mi as MeshInstance3D).get_aabb()
		aabb = a if first else aabb.merge(a)
		first = false
	if first:
		return
	var world_size := aabb.size * n.scale
	if world_size.y < 0.45 or (world_size.x < 0.35 and world_size.z < 0.35):
		return   # too small to matter (a cup, a candle)
	var f := path.get_file().to_lower()
	var shrink := 0.78 if "building" in f else 0.88
	var size := Vector3(aabb.size.x * shrink, aabb.size.y, aabb.size.z * shrink)
	var centre := aabb.get_center()
	centre.y = aabb.position.y + aabb.size.y * 0.5
	_collider(n, centre, size)


## Hộp va chạm theo toạ độ gốc của model (đã nhân scale của node cha).
## Collision box given in the model's local units; placed in world space (physics ignores scaled parents).
## Plant a hand-built tree (see trees.gd). Collider lives inside the tree node (unscaled parent, so it scales with it).
func _tree(kind: String, pos: Vector3, s: float = 1.0, rot: float = -1.0) -> Node3D:
	var t := Trees.make(kind, rng, s)
	t.position = pos
	t.rotation.y = rng.randf() * TAU if rot < 0.0 else rot
	add_child(t)
	return t


func _collider(parent: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size * parent.scale
	col.shape = b
	body.add_child(col)
	body.name = "col_" + parent.name
	add_child(body)
	body.global_transform = Transform3D(Basis.from_euler(Vector3(0, parent.rotation.y, 0)), parent.global_position + Basis.from_euler(Vector3(0, parent.rotation.y, 0)) * (center * parent.scale))


func _particles(color: Color, amount: int, life: float, radius: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.gravity = Vector3.ZERO
	p.process_material = pm
	p.draw_pass_1 = HerbPlot._spark_mesh(color, radius)
	return p


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _night_light(c: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.omni_range = rng_m
	l.omni_attenuation = 1.2
	l.set_meta("base_energy", energy)
	l.set_meta("seed", rng.randf() * TAU)
	night_lights.append(l)
	return l


func _cyl(top: float, bottom: float, height: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = 12
	mi.mesh = c
	mi.material_override = m
	return mi


# ---------------------------------------------------------------- grass, stars, wisps

var _moon_disc: MeshInstance3D
var _fireworks: Array[GPUParticles3D] = []
var _fw_timer := 0.0
var _flocks: Array[Node3D] = []
var _stars: MultiMeshInstance3D
var _wisps: Array[Node3D] = []

var grass: Grass

func _seg_dist(p: Vector2, a: Vector3, b: Vector3) -> float:
	var a2 := Vector2(a.x, a.z)
	var ab := Vector2(b.x, b.z) - a2
	var t := clampf((p - a2).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return (a2 + ab * t).distance_to(p)


## Top-down mask (1 texel = 1.33 m over +-128 m): white where grass may grow.
func _grass_mask() -> ImageTexture:
	var n := 192
	var img := Image.create(n, n, false, Image.FORMAT_L8)
	var segs := []   # [a, b, half-width]
	for rd in ROADS:
		segs.append([rd[0], rd[1], 2.0])
	for t in [Vector3(-13, 0, -12), Vector3(13, 0, -10), Vector3(16, 0, 3), Vector3(-16, 0, 7), Vector3(3, 0, -18), Vector3(-9, 0, 16), Vector3(9, 0, 12), Vector3(-4.5, 0, -7)]:
		segs.append([Vector3.ZERO, t, 1.6])
	segs.append([Vector3(0, 0, -12), Vector3(6.4, 0, -32), 1.9])
	for i in RIVER_PTS.size() - 1:
		segs.append([RIVER_PTS[i], RIVER_PTS[i + 1], 5.0])
	segs.append([Vector3(36, 0, 12), Vector3(48, 0, 12), 2.2])   # dock
	for j in n:
		for i in n:
			var p := Vector2((float(i) + 0.5) / n * 256.0 - 128.0, (float(j) + 0.5) / n * 256.0 - 128.0)
			var ok := true
			if p.length() < 14.5 or p.length() > 112.0:
				ok = false
			elif Vector2((p.x - 58.0) / 25.5, (p.y - 14.0) / 20.5).length() < 1.0:
				ok = false   # Lake Mirren
			elif p.distance_to(Vector2(13, 33)) < 7.5:
				ok = false   # lily pond
			elif absf(p.x - 4.0) < 15.0 and p.y < -24.0 and p.y > -45.0:
				ok = false   # Academy forecourt
			else:
				for sg in segs:
					if _seg_dist(p, sg[0], sg[1]) < sg[2]:
						ok = false
						break
			img.set_pixel(i, j, Color(1, 1, 1) if ok else Color(0, 0, 0))
	return ImageTexture.create_from_image(img)


func _build_grass() -> void:
	grass = Grass.new()
	grass.setup(9000, _grass_mask(), Color(1, 1, 1))
	add_child(grass)


func _build_night_sky() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.97, 0.9)
	sm.material = m
	mm.mesh = sm
	mm.instance_count = 320
	var g := RandomNumberGenerator.new()
	g.seed = 5
	for i in 320:
		var a := g.randf() * TAU
		var e := g.randf_range(0.12, 1.4)
		var r := 230.0
		var pos := Vector3(cos(a) * cos(e) * r, sin(e) * r, sin(a) * cos(e) * r)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * g.randf_range(0.5, 1.4)), pos))
	for f in 2:
		var flock := Node3D.new()
		for i in 6:
			var bird := MeshInstance3D.new()
			var pm2 := PrismMesh.new()
			pm2.size = Vector3(0.9, 0.08, 0.5)
			bird.mesh = pm2
			var bm2 := StandardMaterial3D.new()
			bm2.albedo_color = Color(0.15, 0.12, 0.2)
			bird.material_override = bm2
			bird.position = Vector3(-i * 0.9 if i % 2 == 0 else i * 0.9, i * 0.15, -absf(i) * 1.1)
			flock.add_child(bird)
		add_child(flock)
		_flocks.append(flock)
	_moon_disc = MeshInstance3D.new()
	var md := SphereMesh.new()
	md.radius = 9.0
	md.height = 18.0
	_moon_disc.mesh = md
	var mdm := StandardMaterial3D.new()
	mdm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mdm.albedo_color = Color(0.95, 0.95, 0.85)
	_moon_disc.material_override = mdm
	add_child(_moon_disc)
	for i in 3:
		var fw := _particles([Color(1.0, 0.5, 0.4), Color(0.5, 0.8, 1.0), Color(1.0, 0.9, 0.4)][i], 90, 1.6, 0.07)
		fw.one_shot = true
		fw.explosiveness = 1.0
		fw.emitting = false
		var pm: ParticleProcessMaterial = fw.process_material
		pm.spread = 180.0
		pm.initial_velocity_min = 6.0
		pm.initial_velocity_max = 10.0
		pm.gravity = Vector3(0, -3, 0)
		fw.position = Vector3(2, 18, 28) + Vector3(i * 6 - 6, i * 2, 0)
		add_child(fw)
		_fireworks.append(fw)
	_stars = MultiMeshInstance3D.new()
	_stars.multimesh = mm
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_stars)
	# Wisps: three slow lights that wander the square after dark
	for i in 3:
		var w := Node3D.new()
		var l := OmniLight3D.new()
		l.light_color = [Color(0.6, 0.9, 1.0), Color(0.9, 0.7, 1.0), Color(0.7, 1.0, 0.8)][i]
		l.omni_range = 5.0
		l.light_energy = 1.2
		w.add_child(l)
		var orb := MeshInstance3D.new()
		var om := SphereMesh.new()
		om.radius = 0.18
		om.height = 0.36
		orb.mesh = om
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = l.light_color
		orb.material_override = mat
		w.add_child(orb)
		var pt := _particles(l.light_color, 12, 1.2, 0.04)
		w.add_child(pt)
		add_child(w)
		_wisps.append(w)


func _update_wisps(t: float) -> void:
	var night := GameState.is_night()
	# Village warmth scales with the Ember: lanterns glow brighter, fireflies thicken
	var warmth := clampf(GameState.ember / 40.0, 0.0, 1.0)
	if fireflies:
		fireflies.amount_ratio = 0.4 + 0.6 * warmth
	if Engine.get_process_frames() % 20 == 0:
		for l in night_lights:
			if is_instance_valid(l) and l.has_meta("base_energy"):
				l.set_meta("warm", 0.85 + 0.45 * warmth)
	if _stars:
		_stars.visible = night
	if _moon_disc:
		var h := GameState.hour_of_day()
		var f := h / 24.0
		var ang := -(f - 0.25) * TAU + PI   # opposite the sun
		_moon_disc.position = Vector3(cos(deg_to_rad(40)) * 190.0, sin(ang) * 190.0, -sin(deg_to_rad(40)) * 190.0).rotated(Vector3.UP, 0.0)
		_moon_disc.position = Vector3(cos(ang) * 60.0, sin(ang) * 190.0, -150.0)
		_moon_disc.visible = night and sin(ang) > 0.05
	for b in _butterflies:
		b.emitting = not night
	for i in _flocks.size():
		var fl := _flocks[i]
		fl.visible = not night
		var ph := t * 0.06 + i * 3.0
		var r := 55.0 + i * 20.0
		fl.position = Vector3(cos(ph) * r, 22.0 + sin(t * 0.5 + i) * 2.0, sin(ph) * r * 0.7)
		fl.rotation.y = -ph + PI / 2.0
		for b in fl.get_children():
			(b as Node3D).rotation.z = sin(t * 7.0 + b.get_index()) * 0.5
	# Fireworks over Festival Green every evening at eight
	var hh := GameState.hour_of_day()
	if hh >= 20.0 and hh < 20.25:
		_fw_timer -= get_process_delta_time()
		if _fw_timer <= 0.0:
			_fw_timer = randf_range(0.8, 1.6)
			var fw := _fireworks[randi() % _fireworks.size()]
			fw.position = Vector3(randf_range(-10, 14), randf_range(14, 22), randf_range(22, 34))
			fw.restart()
			fw.emitting = true
	for i in _wisps.size():
		var w := _wisps[i]
		w.visible = night
		if night:
			var ph := t * 0.25 + i * 2.1
			w.position = Vector3(cos(ph) * (9.0 + i * 4.0) + sin(ph * 2.3) * 2.0, 1.6 + sin(t * 1.3 + i) * 0.5, sin(ph * 0.8) * (8.0 + i * 3.0))


func _build_isle(c: Vector3) -> void:
	var isle := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 5.2
	cm.bottom_radius = 6.0
	cm.height = 1.0
	cm.radial_segments = 14
	isle.mesh = cm
	isle.position = c + Vector3(0, -0.5, 0)
	isle.material_override = _mat(Color(0.36, 0.55, 0.33), 1.0)
	add_child(isle)
	var sand := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 6.4
	sm.bottom_radius = 6.6
	sm.height = 0.3
	sm.radial_segments = 14
	sand.mesh = sm
	sand.position = c + Vector3(0, -0.45, 0)
	sand.material_override = _mat(Color(0.78, 0.72, 0.55), 1.0)
	add_child(sand)
	var hut := _place(HEX + "buildings/green/building_home_A_green.gltf", c + Vector3(1.5, 0.0, -2.0), B * 0.9, deg_to_rad(200))
	_collider(hut, Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
	_tree("birch", c + Vector3(-3.0, 0, -2.5), 1.1)
	_place(HAL + "shrine.gltf", c + Vector3(-2.5, 0.0, 2.5), 1.6, deg_to_rad(120))
	var dl := Node3D.new()
	dl.position = c + Vector3(3.0, 0.0, 2.5)
	dl.set_script(load("res://world/dark_lantern.gd"))
	dl.setup("isle")
	add_child(dl)
	for i in 10:
		var a := i * TAU / 10.0
		_place(HEX + "decoration/nature/waterplant_%s.gltf" % ["A", "B"][i % 2], c + Vector3(cos(a) * 6.8, 0, sin(a) * 6.8), B, rng.randf() * TAU)
	var lm := Node3D.new()
	lm.position = c + Vector3(0, 0.0, 4.0)
	lm.set_script(load("res://world/landmark.gd"))
	lm.setup("Heron Isle", Story.DISTRICTS["isle"]["text"])
	add_child(lm)
	var ifs := Node3D.new()
	ifs.position = c + Vector3(-5.0, 0.0, 1.0)
	ifs.rotation.y = deg_to_rad(90)
	ifs.set_script(load("res://world/fishing.gd"))
	ifs.moon_bonus = 0.3
	add_child(ifs)


func _build_ashford(c: Vector3) -> void:
	var spots := [["buildings/yellow/building_home_A_yellow.gltf", Vector3(-7, 0, -5), 40.0], ["buildings/yellow/building_home_B_yellow.gltf", Vector3(9, 0, 2.3), -30.0], ["buildings/yellow/building_tavern_yellow.gltf", Vector3(8, 0, 9), -100.0], ["buildings/yellow/building_windmill_yellow.gltf", Vector3(-10.5, 0, -2.4), 90.0]]
	for sp in spots:
		var h := _place(HEX + sp[0], c + sp[1], B, deg_to_rad(sp[2]))
		_collider(h, Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
	# Sheep pen: a ring of fence pieces with one opening (i == 3) to lead the stubborn sheep home through
	var pc := c + Vector3(-9.7, 0, -10.1)
	for i in 14:
		if i == 3:
			continue
		var a := i * TAU / 14.0
		_fence_piece(pc + Vector3(cos(a), 0, sin(a)) * 6.5, Vector3(-sin(a), 0, cos(a)))
	for i in 6:
		var sh := CharacterBody3D.new()
		sh.set_script(load("res://world/sheep.gd"))
		sh.pen_center = pc
		sh.pen_radius = 5.0
		sh.is_lost_candidate = i == 0
		var a := rng.randf() * TAU
		sh.position = pc + Vector3(cos(a), 0, sin(a)) * rng.randf_range(1.0, 4.5)
		add_child(sh)
	var l := _place(HAL + "lantern_standing.gltf", c + Vector3(2.4, 0, 2.6), 1.0, 0.0)
	var nl := _night_light(Color(1.0, 0.78, 0.45), 1.5, 8.0)
	nl.position = l.position + Vector3(0, 0.9, 0)
	add_child(nl)
	_signpost(Vector3(21, 0, -19.5), "Ashford")


func _build_hollow_wood(c: Vector3) -> void:
	var dark := _mat(Color(0.2, 0.18, 0.22), 1.0)
	var floor_m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 24.0
	cm.bottom_radius = 24.0
	cm.height = 0.1
	cm.radial_segments = 18
	floor_m.mesh = cm
	floor_m.position = c + Vector3(0, 0.02, 0)
	floor_m.material_override = _mat(Color(0.22, 0.24, 0.2), 1.0)
	add_child(floor_m)
	for i in 34:
		var a := rng.randf() * TAU
		var r := rng.randf_range(5.0, 23.0)
		var pos := c + Vector3(cos(a) * r, 0, sin(a) * r)
		var near_bed := false
		for k in 3:
			if pos.distance_to(c + Vector3(-6 + k * 6, 0, 4)) < 4.0:
				near_bed = true
		if near_bed or pos.distance_to(c + Vector3(0, 0, -9)) < 5.0:
			continue
		var tm: String = ["tree_dead_large.gltf", "tree_dead_medium.gltf", "tree_dead_large_decorated.gltf"][i % 3]
		var t := _place(HAL + tm, pos, rng.randf_range(1.1, 1.7), rng.randf() * TAU)
		_collider(t, Vector3(0, 1.0, 0), Vector3(0.5, 2.0, 0.5))
	for i in 9:
		var a := rng.randf() * TAU
		var r := rng.randf_range(4.0, 18.0)
		_place(HAL + ["grave_A.gltf", "gravemarker_A.gltf", "gravestone.gltf"][i % 3], c + Vector3(cos(a) * r, 0, sin(a) * r), 1.0, rng.randf() * TAU)
	_place(HAL + "crypt.gltf", c + Vector3(0, 0, -9), 1.4, 0.0)
	_collider(_place(HAL + "arch_gate.gltf", c + Vector3(14, 0, 12), 1.5, deg_to_rad(-45)), Vector3(-1.4, 1.0, 0), Vector3(0.5, 2.0, 0.5))
	# Nightcap beds among the roots
	for i in 3:
		var plot := HerbPlotScript.new()
		plot.setup("nightcap", "wood_%d" % i)
		plot.position = c + Vector3(-6 + i * 6, 0.1, 4)
		add_child(plot)
	# Mist: slow pale particles, and a cold light
	var mist := _particles(Color(0.75, 0.8, 0.9), 26, 7.0, 1.6)
	var pm: ParticleProcessMaterial = mist.process_material
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(20, 0.5, 20)
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.3
	var mm: StandardMaterial3D = mist.draw_pass_1.material
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.emission_enabled = false
	mm.albedo_color = Color(0.75, 0.8, 0.9, 0.07)
	mist.position = c + Vector3(0, 1.0, 0)
	mist.visibility_aabb = AABB(Vector3(-25, -2, -25), Vector3(50, 8, 50))
	add_child(mist)
	var cl := _night_light(Color(0.55, 0.7, 1.0), 1.4, 16.0)
	cl.position = c + Vector3(0, 3.0, 0)
	add_child(cl)
	var lm := Node3D.new()
	lm.position = c + Vector3(8, 0, 8)
	lm.set_script(load("res://world/landmark.gd"))
	lm.setup("The Hollow Wood", Story.DISTRICTS["wood"]["text"])
	add_child(lm)
	var ch := Node3D.new()
	ch.position = c + Vector3(2.5, 0, -6.5)
	ch.set_script(load("res://world/chest.gd"))
	ch.setup("watchman_wife")
	add_child(ch)
	_signpost(Vector3(-40, 0, -44), "The Hollow Wood")
	var wr := Node3D.new()
	wr.position = c + Vector3(12, 0, 14)
	wr.set_script(load("res://world/broom_course.gd"))
	wr.course_name = "Wood Run"
	wr.best_key = "best_broom2"
	wr.RINGS = [Vector3(-6, 4, -6), Vector3(-14, 7, -12), Vector3(-22, 5, -20), Vector3(-16, 9, -30), Vector3(-4, 12, -28), Vector3(4, 8, -18), Vector3(-2, 5, -10), Vector3(-10, 3, -2)]
	add_child(wr)


func _build_flowers() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var head := SphereMesh.new()
	head.radius = 0.12
	head.height = 0.2
	head.radial_segments = 6
	head.rings = 3
	var fm := StandardMaterial3D.new()
	fm.vertex_color_use_as_albedo = true
	fm.roughness = 0.9
	head.material = fm
	mm.mesh = head
	var spots := [Vector3(-35, 0, -9), Vector3(2, 0, 28), Vector3(0, 0, 0), Vector3(-58, 0, 46), Vector3(36, 0, -36), Vector3(31, 0, -9), Vector3(-4.5, 0, -7), Vector3(44, 0, 12)]
	var n := 520
	mm.instance_count = n
	var g := RandomNumberGenerator.new()
	g.seed = 23
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 5:
		tries += 1
		var c: Vector3 = spots[g.randi() % spots.size()]
		var a := g.randf() * TAU
		var r := g.randf_range(4.0, 15.0)
		var pos := c + Vector3(cos(a) * r, 0, sin(a) * r)
		if _on_road(pos, 5.0) or pos.length() < 13.5 or pos.distance_to(Vector3(58, 0, 14)) < 24.0:
			continue
		var t := Transform3D(Basis().scaled(Vector3.ONE * g.randf_range(0.7, 1.3)), pos + Vector3(0, 0.3, 0))
		mm.set_instance_transform(placed, t)
		mm.set_instance_color(placed, [Color(1.0, 0.55, 0.7), Color(1.0, 0.9, 0.4), Color(0.95, 0.95, 1.0), Color(0.7, 0.6, 1.0)][g.randi() % 4])
		placed += 1
	mm.visible_instance_count = placed
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.name = "Flowers"
	add_child(mmi)
	# stems: thin green prisms under each head
	var mm2 := MultiMesh.new()
	mm2.transform_format = MultiMesh.TRANSFORM_3D
	var stem := PrismMesh.new()
	stem.size = Vector3(0.06, 0.3, 0.06)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.3, 0.55, 0.3)
	stem.material = sm
	mm2.mesh = stem
	mm2.instance_count = placed
	for i in placed:
		var t := mm.get_instance_transform(i)
		mm2.set_instance_transform(i, Transform3D(Basis(), t.origin - Vector3(0, 0.15, 0)))
	var mmi2 := MultiMeshInstance3D.new()
	mmi2.multimesh = mm2
	mmi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi2)


var _butterflies: Array[GPUParticles3D] = []

func _build_butterflies() -> void:
	for c in [Vector3(-4.5, 1.0, -7), Vector3(2, 1.0, 28), Vector3(-35, 1.0, -9)]:
		var p := GPUParticles3D.new()
		p.amount = 10
		p.lifetime = 6.0
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(6, 0.5, 6)
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 180.0
		pm.initial_velocity_min = 0.4
		pm.initial_velocity_max = 0.9
		pm.gravity = Vector3.ZERO
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = 1.5
		pm.turbulence_noise_scale = 2.0
		pm.scale_min = 0.6
		pm.scale_max = 1.0
		p.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.22, 0.16)
		var qm := StandardMaterial3D.new()
		qm.albedo_color = Color(1.0, 0.75, 0.3)
		qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		qm.cull_mode = BaseMaterial3D.CULL_DISABLED
		q.material = qm
		p.draw_pass_1 = q
		p.position = c
		p.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 6, 16))
		add_child(p)
		_butterflies.append(p)


## Small props stop rendering far away (the GL renderer pays per draw call).
func _apply_visibility_ranges() -> void:
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var aabb := m.get_aabb()
		var size: float = (aabb.size * m.global_transform.basis.get_scale()).length()
		if size < 2.5:
			m.visibility_range_end = 55.0
			m.visibility_range_end_margin = 6.0
		elif size < 7.0:
			m.visibility_range_end = 95.0
			m.visibility_range_end_margin = 8.0


func _build_rainbow() -> void:
	var cols := [Color(1.0, 0.3, 0.3), Color(1.0, 0.65, 0.2), Color(1.0, 0.95, 0.3), Color(0.4, 0.9, 0.4), Color(0.4, 0.6, 1.0), Color(0.6, 0.4, 0.9)]
	for i in cols.size():
		var arc := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 60.0 - i * 1.6
		tm.outer_radius = 61.4 - i * 1.6
		tm.rings = 48
		tm.ring_segments = 6
		arc.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(cols[i].r, cols[i].g, cols[i].b, 0.35)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		arc.material_override = m
		arc.position = Vector3(30, -8, -90)
		arc.rotation.x = PI / 2.0
		arc.rotation.y = deg_to_rad(20)
		add_child(arc)
