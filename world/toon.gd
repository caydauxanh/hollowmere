class_name Toon
## Replaces imported StandardMaterial3D materials with a cel-shaded ShaderMaterial (2-band light + rim).

const CODE := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 albedo : source_color = vec4(1.0);
uniform float use_tex = 1.0;
uniform float rim_strength = 0.18;
global uniform float focus_dist;
varying float vdist;
varying float up_facing;
varying float world_y;
void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	vdist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	up_facing = (MODEL_MATRIX * vec4(NORMAL, 0.0)).y;
}
void fragment() {
	// Walls and roofs between the camera and the player open a dithered window (floors never do).
	float centre = length((SCREEN_UV - vec2(0.5, 0.48)) * vec2(1.7, 1.0));
	float occl = clamp((focus_dist - 1.2 - vdist) / 1.5, 0.0, 1.0) * clamp((0.30 - centre) / 0.08, 0.0, 1.0) * (1.0 - step(0.75, up_facing) * step(world_y, 0.45));
	// anything crowding the lens (closer than about half-way to the player) clears out, floors excepted
	float floorish = step(0.75, up_facing) * step(world_y, 0.45);
	float near = mix(clamp((vdist - focus_dist * 0.40) / (focus_dist * 0.05 + 0.01), 0.0, 1.0), 1.0, floorish);
	float keep = min(near, 1.0 - occl);
	if (keep < 0.999) {
		float dith = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (keep < dith) { discard; }
	}
	vec4 c = albedo;
	if (use_tex > 0.5) { c *= texture(albedo_tex, UV); }
	ALBEDO = c.rgb;
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
static var _cache := {}


static func apply(root: Node) -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODE
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.material_override != null:
			continue
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.get_surface_override_material(i)
			if m == null:
				m = mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D:
				var sm: StandardMaterial3D = m
				if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or sm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or sm.emission_enabled:
					continue
				mi.set_surface_override_material(i, _convert(sm))


static func _convert(sm: StandardMaterial3D) -> ShaderMaterial:
	var key: Material = sm   # the material itself is the key (keeps it alive, so ids are never reused)
	if _cache.has(key):
		return _cache[key]
	var out := ShaderMaterial.new()
	out.shader = _shader
	out.set_shader_parameter("albedo", sm.albedo_color)
	if sm.albedo_texture:
		out.set_shader_parameter("albedo_tex", sm.albedo_texture)
		out.set_shader_parameter("use_tex", 1.0)
	else:
		out.set_shader_parameter("use_tex", 0.0)
	_cache[key] = out
	return out
