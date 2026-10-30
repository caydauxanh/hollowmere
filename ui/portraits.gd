extends Node
## Renders character busts to textures at runtime (SubViewport), so dialogue and cards
## get portraits in the game's own style. Autoload name: Portraits.

var _cache := {}
var _vps := {}


## Returns a ViewportTexture for the npc (or "player"). Renders lazily; the texture updates when ready.
func get_portrait(id: String) -> Texture2D:
	if _cache.has(id):
		# Re-render one frame on each request (cheap; portraits are static between requests).
		_vps[id].render_target_update_mode = SubViewport.UPDATE_ONCE
		return _cache[id]
	var model := "Mage"
	var tint = null
	if id != "player" and Story.NPCS.has(id):
		model = Story.NPCS[id]["model"]
		tint = Story.NPCS[id].get("tint", null)
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 320)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vps[id] = vp
	get_tree().create_timer(1.0).timeout.connect(func(): vp.render_target_update_mode = SubViewport.UPDATE_ONCE)
	vp.own_world_3d = true
	add_child(vp)
	var root := Node3D.new()
	vp.add_child(root)
	var skin: Node3D = load("res://assets/kaykit/chars/%s.glb" % model).instantiate()
	skin.rotation.y = deg_to_rad(20)
	root.add_child(skin)
	if tint != null:
		for mi in skin.find_children("*", "MeshInstance3D", true, false):
			for i in mi.get_surface_override_material_count():
				var base: Material = mi.mesh.surface_get_material(i) if mi.mesh else null
				var m: StandardMaterial3D = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
				m.albedo_color = tint
				mi.set_surface_override_material(i, m)
	var ap: AnimationPlayer = skin.get_node_or_null("AnimationPlayer")
	if ap:
		ap.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		ap.play("Idle")
	var cam := Camera3D.new()
	cam.fov = 28.0
	cam.position = Vector3(0.0, 2.25, 4.6)
	cam.look_at_from_position(cam.position, Vector3(0, 2.05, 0))
	root.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35), deg_to_rad(35), 0)
	key.light_energy = 1.3
	key.light_color = Color(1.0, 0.95, 0.88)
	root.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation = Vector3(deg_to_rad(-10), deg_to_rad(-150), 0)
	rim.light_energy = 0.8
	rim.light_color = Color(0.6, 0.7, 1.0)
	root.add_child(rim)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.65)
	e.ambient_light_energy = 0.9
	env.environment = e
	root.add_child(env)
	var tex := vp.get_texture()
	_cache[id] = tex
	return tex
