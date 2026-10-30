class_name WaterBody
extends MeshInstance3D
## Animated low-poly water (lake or river segment). Gentle ripples in the vertex shader.

const SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 shallow : source_color = vec4(0.35, 0.7, 0.85, 0.75);
uniform vec4 deep : source_color = vec4(0.12, 0.3, 0.55, 0.9);
uniform float oval = 0.0;   // 1 = clip to a wobbly ellipse (lake), 0 = full rectangle (river)
void vertex() {
	float w = sin(VERTEX.x * 0.9 + TIME * 1.3) * 0.06 + cos(VERTEX.z * 1.1 + TIME * 0.9) * 0.06;
	VERTEX.y += w;
}
void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float ang = atan(UV.y - 0.5, UV.x - 0.5);
	float edge = 1.0 + 0.08 * sin(ang * 5.0) + 0.05 * cos(ang * 3.0 + 1.2);
	if (oval > 0.5 && r > edge) { discard; }
	vec4 c = mix(deep, shallow, smoothstep(0.3, 1.0, r));
	float sparkle = pow(max(0.0, sin(UV.x * 90.0 + TIME * 2.0) * sin(UV.y * 70.0 - TIME * 1.7)), 24.0);
	ALBEDO = c.rgb + sparkle * 0.25;
	ALPHA = c.a;
	ROUGHNESS = 0.15;
	SPECULAR = 0.6;
}
"""

static func make(size: Vector2, subdiv: int = 24, oval: bool = false) -> WaterBody:
	var w := WaterBody.new()
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = subdiv
	pm.subdivide_depth = subdiv
	w.mesh = pm
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("oval", 1.0 if oval else 0.0)
	w.material_override = m
	w.position.y = -0.12
	return w
