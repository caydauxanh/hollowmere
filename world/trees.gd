class_name Trees
## Hand-built stylised trees (oak, pine, birch, autumn pine, shrub): low-poly canopies with a
## cel-shaded, gently swaying leaf shader and a real trunk collider. Replaces the hex-pack tree tiles.

const CODE := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 albedo_top : source_color = vec4(1.0);
uniform float sway = 1.0;
uniform float height = 4.0;
uniform float rim_strength = 0.2;
global uniform float focus_dist;
varying float vh;
varying float vdist;
void vertex() {
	vh = clamp(VERTEX.y / height, 0.0, 1.0);
	vdist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * 1.1 + wp.x * 0.35 + wp.z * 0.25;
	float s = vh * vh * sway;
	VERTEX.x += sin(t) * 0.09 * s;
	VERTEX.z += cos(t * 0.83 + 1.3) * 0.07 * s;
}
void fragment() {
	// Leaves right in front of the camera dissolve (screen-door) so the view never goes dark inside a canopy.
	float fade = clamp((vdist - focus_dist * 0.40) / (focus_dist * 0.05 + 0.01), 0.0, 1.0);
	// ...and leaves between the camera and the player (near the screen centre) go see-through.
	float centre = length((SCREEN_UV - vec2(0.5)) * vec2(1.6, 1.0));
	float occl = clamp((focus_dist - 0.8 - vdist) / 1.5, 0.0, 1.0) * clamp((0.30 - centre) / 0.08, 0.0, 1.0);
	fade = min(fade, 1.0 - occl);
	float dith = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	if (fade < dith) { discard; }
	ALBEDO = mix(albedo.rgb, albedo_top.rgb, vh);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.02, 0.10, ndl) * 0.65 + smoothstep(0.35, 0.50, ndl) * 0.35;
	float a = ATTENUATION;
	DIFFUSE_LIGHT += band * a * LIGHT_COLOR * ALBEDO;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.5);
	DIFFUSE_LIGHT += rim * rim_strength * max(ndl, 0.0) * a * LIGHT_COLOR;
}
"""
static var _shader: Shader
static var tint := Color(1, 1, 1)   # seasonal leaf tint, set by the village before building
static var _count := 0


static func _mat(base: Color, top: Color, sway: float, height: float) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("albedo", base)
	m.set_shader_parameter("albedo_top", top)
	m.set_shader_parameter("sway", sway)
	m.set_shader_parameter("height", height)
	return m


static func _sphere(r: float, segs: int = 10, rings: int = 6) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = rings
	return s


static func _mesh(root: Node3D, mesh: Mesh, m: Material, pos: Vector3, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = scale
	root.add_child(mi)
	return mi


static func _trunk(root: Node3D, top_r: float, bot_r: float, h: float, color: Color) -> void:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bot_r
	c.height = h
	c.radial_segments = 8
	c.rings = 1
	_mesh(root, c, _mat(color.darkened(0.15), color, 0.0, h + 2.0), Vector3(0, h / 2.0 - 0.1, 0))
	# root flare
	var f := CylinderMesh.new()
	f.top_radius = bot_r * 0.9
	f.bottom_radius = bot_r * 1.6
	f.height = 0.35
	f.radial_segments = 8
	f.rings = 1
	_mesh(root, f, _mat(color.darkened(0.3), color.darkened(0.2), 0.0, 10.0), Vector3(0, 0.1, 0))


static func _collider(root: Node3D, r: float, h: float) -> void:
	var body := StaticBody3D.new()
	body.name = "col_tree"
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = r
	cs.height = h
	col.shape = cs
	col.position.y = h / 2.0
	body.add_child(col)
	root.add_child(body)


## kind: "oak" | "pine" | "birch" | "autumn" | "shrub"
static func make(kind: String, rng: RandomNumberGenerator, s: float = 1.0) -> Node3D:
	var root := Node3D.new()
	_count += 1
	root.name = "Tree_%s_%d" % [kind, _count]
	root.add_to_group("tree")
	var g := rng.randf_range(-0.06, 0.06)
	match kind:
		"oak":
			_trunk(root, 0.2, 0.34, 2.4, Color(0.4, 0.27, 0.16))
			var base := Color(0.22 + g, 0.46 + g, 0.2) * tint
			var top := Color(0.5 + g, 0.78 + g, 0.33) * tint
			var m := _mat(base, top, 1.0, 5.2)
			_mesh(root, _sphere(1.9), m, Vector3(0, 3.5, 0), Vector3(1.0, 0.85, 1.0))
			for i in 4:
				var a := i * TAU / 4.0 + rng.randf() * 0.8
				var rr := rng.randf_range(1.1, 1.45)
				_mesh(root, _sphere(rr), m, Vector3(cos(a) * 1.35, 3.0 + rng.randf_range(-0.2, 0.7), sin(a) * 1.35))
			_mesh(root, _sphere(1.15), m, Vector3(0.2, 4.7, -0.1))
			_collider(root, 0.42, 3.0)
		"birch":
			_trunk(root, 0.1, 0.17, 3.0, Color(0.9, 0.9, 0.85))
			var base := Color(0.5 + g, 0.68 + g, 0.25) * tint
			var top := Color(0.78 + g, 0.9 + g, 0.4) * tint
			var m := _mat(base, top, 1.3, 5.0)
			_mesh(root, _sphere(1.2), m, Vector3(0, 3.6, 0), Vector3(0.9, 1.15, 0.9))
			_mesh(root, _sphere(0.9), m, Vector3(0.7, 3.0, 0.3))
			_mesh(root, _sphere(0.85), m, Vector3(-0.6, 3.2, -0.4))
			_mesh(root, _sphere(0.7), m, Vector3(0.1, 4.6, 0.2))
			_collider(root, 0.25, 3.2)
		"pine", "autumn":
			_trunk(root, 0.14, 0.26, 1.8, Color(0.36, 0.24, 0.14))
			var base: Color
			var top: Color
			if kind == "pine":
				base = Color(0.1 + g, 0.34 + g, 0.24) * tint
				top = Color(0.3 + g, 0.62 + g, 0.4) * tint
			else:
				base = Color(0.7 + g, 0.3, 0.1) * tint
				top = Color(1.0, 0.62 + g, 0.2) * tint
			var m := _mat(base, top, 0.6, 6.0)
			var ys := [1.3, 2.6, 3.8, 4.9]
			var rs := [1.75, 1.4, 1.05, 0.65]
			for i in 4:
				var c := CylinderMesh.new()
				c.top_radius = 0.0
				c.bottom_radius = rs[i]
				c.height = 2.1 - i * 0.2
				c.radial_segments = 9
				c.rings = 1
				_mesh(root, c, m, Vector3(0, ys[i] + c.height / 2.0 - 0.6, 0))
			_collider(root, 0.35, 2.4)
		"shrub":
			var base := Color(0.25 + g, 0.5 + g, 0.22) * tint
			var top := Color(0.5 + g, 0.75 + g, 0.3) * tint
			var m := _mat(base, top, 1.4, 1.4)
			_mesh(root, _sphere(0.7, 8, 5), m, Vector3(0, 0.55, 0), Vector3(1.0, 0.8, 1.0))
			_mesh(root, _sphere(0.5, 8, 5), m, Vector3(0.55, 0.45, 0.2))
			_mesh(root, _sphere(0.45, 8, 5), m, Vector3(-0.45, 0.4, -0.3))
	root.scale = Vector3.ONE * s
	return root
