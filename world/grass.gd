class_name Grass
extends MultiMeshInstance3D
## Dense meadow grass: one tile of blades that wraps around the camera (the vertex shader re-centres
## every blade), so there is always thick grass near the player and none is wasted far away.
## Blades sway, bend away from the player, take light from the sun and every lantern,
## and are masked off roads, water and paving by a small top-down texture.

const TILE := 46.0
const CODE := """
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;
uniform vec3 center;
uniform vec3 player_pos;
uniform float tile = 46.0;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec3 base_col : source_color = vec3(0.10, 0.22, 0.10);
uniform vec3 tip_col : source_color = vec3(0.46, 0.62, 0.26);
uniform vec3 dry_col : source_color = vec3(0.66, 0.60, 0.30);
varying float vh;
varying float vrand;
void vertex() {
	vec3 ip = MODEL_MATRIX[3].xyz;
	vec3 lv = VERTEX - ip;
	vec2 rel = mod(ip.xz - center.xz + tile * 0.5, tile) - tile * 0.5;
	vec3 root = vec3(center.x + rel.x, 0.0, center.z + rel.y);
	float mask = texture(mask_tex, root.xz / 256.0 + 0.5).r;
	float edge = 1.0 - smoothstep(tile * 0.36, tile * 0.5, length(rel));
	vh = UV.y;
	vrand = INSTANCE_CUSTOM.x;
	float k = mask * edge;
	// wind: a slow roll plus a quick shiver, stronger toward the tip
	float w = sin(TIME * 1.5 + root.x * 0.31 + root.z * 0.23) * 0.13 + sin(TIME * 3.4 + root.x * 1.3 + vrand * 6.0) * 0.04;
	lv.x += w * vh * vh;
	lv.z += w * 0.6 * vh * vh;
	// bend away from the player
	vec2 pd = root.xz - player_pos.xz;
	float pk = (1.0 - smoothstep(0.25, 1.25, length(pd))) * step(player_pos.y, 1.5);
	lv.xz += normalize(pd + vec2(0.001)) * pk * 0.45 * vh;
	lv.y *= 1.0 - pk * 0.55;
	VERTEX = root + lv * k;
	NORMAL = normalize(vec3(lv.x * 0.6, 1.0, lv.z * 0.6));
}
void fragment() {
	vec3 tip = mix(tip_col, dry_col, smoothstep(0.55, 0.95, vrand));
	ALBEDO = mix(base_col, tip, vh);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
"""

var _mat: ShaderMaterial


static func _blade() -> ArrayMesh:
	# A tuft: three tapered, slightly curved blades fanned around the root (5 vertices each).
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var base := [Vector3(-0.04, 0, 0), Vector3(0.04, 0, 0), Vector3(-0.028, 0.5, 0.05), Vector3(0.028, 0.5, 0.05), Vector3(0.0, 1.0, 0.16)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(0, 0.5), Vector2(1, 0.5), Vector2(0.5, 1)]
	for k in 3:
		var rot := Basis(Vector3.UP, k * TAU / 3.0 + 0.4)
		var off := rot * Vector3(0, 0, 0.07)
		var hk: float = [1.0, 0.78, 0.6][k]
		var o := v.size()
		for i in 5:
			var p: Vector3 = base[i]
			v.append(rot * Vector3(p.x, p.y * hk, p.z) + off)
			uv.append(Vector2(uvs[i].x, uvs[i].y * hk))
		for t in [0, 1, 2, 1, 3, 2, 2, 3, 4]:
			idx.append(o + t)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


func setup(count: int, mask: Texture2D, tint: Color) -> void:
	name = "Grass"
	var sh := Shader.new()
	sh.code = CODE
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_mat.set_shader_parameter("mask_tex", mask)
	_mat.set_shader_parameter("tile", TILE)
	set_tint(tint)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _blade()
	mm.instance_count = count
	var g := RandomNumberGenerator.new()
	g.seed = 21
	for i in count:
		var h := g.randf_range(0.32, 0.62)
		if g.randf() < 0.07:
			h = g.randf_range(0.7, 1.0)   # the odd tall tuft
		var b := Basis.from_euler(Vector3(g.randf_range(-0.25, 0.25), g.randf() * TAU, 0)).scaled(Vector3(g.randf_range(0.9, 1.8), h, 1.0))
		mm.set_instance_transform(i, Transform3D(b, Vector3(g.randf() * TILE, 0.0, g.randf() * TILE)))
		mm.set_instance_custom_data(i, Color(g.randf(), g.randf(), 0, 0))
	multimesh = mm
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-400, -2, -400), Vector3(800, 6, 800))


func set_tint(t: Color) -> void:
	_mat.set_shader_parameter("base_col", Color(0.17, 0.33, 0.15) * t)
	_mat.set_shader_parameter("tip_col", Color(0.52, 0.72, 0.3) * t)
	_mat.set_shader_parameter("dry_col", Color(0.74, 0.68, 0.34) * t)


func follow(center: Vector3, player: Vector3) -> void:
	_mat.set_shader_parameter("center", center)
	_mat.set_shader_parameter("player_pos", player)
