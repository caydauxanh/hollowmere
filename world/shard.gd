extends Node3D
## A star shard: invisible until Glimmer is active after dark; walk into it to collect.

var shard_id := ""
var _m: MeshInstance3D
var _l: OmniLight3D

func setup(id: String) -> void:
	shard_id = id

func _ready() -> void:
	if GameState.shards.has(shard_id):
		queue_free()
		return
	_m = MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.5, 0.8, 0.5)
	_m.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.85, 1.0)
	mat.emission_energy_multiplier = 2.5
	_m.material_override = mat
	_m.position.y = 0.9
	add_child(_m)
	_l = OmniLight3D.new()
	_l.light_color = Color(0.7, 0.85, 1.0)
	_l.omni_range = 5.0
	_l.light_energy = 1.5
	_l.position.y = 1.0
	add_child(_l)
	visible = false

func _process(delta: float) -> void:
	var show := GameState.glimmer_active() and GameState.is_night()
	visible = show
	if not show:
		return
	_m.rotation.y += delta * 2.0
	_m.position.y = 0.9 + sin(Time.get_ticks_msec() / 400.0) * 0.15
	var pl := get_tree().get_first_node_in_group("player")
	if pl and (pl as Node3D).global_position.distance_to(global_position) < 1.4:
		GameState.shards[shard_id] = true
		GameState.coins += 6
		GameState.add_ember(1)
		GameState.add_marks(1, "Star shard  (%d / %d)" % [GameState.shards.size(), Story.SHARDS.size()])
		queue_free()
