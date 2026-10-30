class_name Toon
## Replaces imported StandardMaterial3D materials with a cel-shaded ShaderMaterial (2-band light + rim).

const CODE := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 albedo : source_color = vec4(1.0);
uniform float use_tex = 1.0;
uniform float rim_strength = 0.18;
void fragment() {
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
