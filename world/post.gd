class_name PostFX
extends CanvasLayer
## Final picture pass over the 3D view (under the HUD): split-tone grade (cool shadows, warm lights),
## a gentle contrast curve, vignette and film grain. One full-screen pass, cheap enough for phones.

const CODE := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float night = 0.0;
uniform float strength = 1.0;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	// split tone: shadows lean teal-blue, highlights lean lantern-warm (stronger at night)
	vec3 sh = mix(vec3(0.93, 0.98, 1.07), vec3(0.80, 0.93, 1.16), night);
	vec3 hi = mix(vec3(1.05, 1.0, 0.93), vec3(1.12, 1.0, 0.84), night);
	vec3 g = c * mix(sh, hi, smoothstep(0.06, 0.62, l));
	// filmic S-curve
	g = mix(g, g * g * (3.0 - 2.0 * g), 0.32 + 0.18 * night);
	// pull the muddiest saturation back a little, keep vivid things vivid
	float l2 = dot(g, vec3(0.299, 0.587, 0.114));
	g = mix(vec3(l2), g, 0.94);
	// vignette
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.12, 1.0);
	float v = smoothstep(0.38, 0.98, length(d));
	g *= 1.0 - v * (0.42 + 0.25 * night);
	// grain
	float n = fract(sin(dot(FRAGCOORD.xy + fract(TIME) * 61.0, vec2(12.9898, 78.233))) * 43758.5453);
	g += (n - 0.5) * (0.035 + 0.03 * night);
	COLOR = vec4(mix(c, g, strength), 1.0);
}
"""
var _mat: ShaderMaterial


func _ready() -> void:
	layer = 0
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = CODE
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	r.material = _mat
	add_child(r)


func set_night(n: float) -> void:
	_mat.set_shader_parameter("night", n)
