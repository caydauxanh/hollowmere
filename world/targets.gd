extends Node3D
## Spark Targets (Festival Green): a timed Kindle minigame. Targets rise one at a time;
## cast Kindle (1) within 5 m of the raised target to score. 30 seconds, best score saved.

const ROUND := 30.0
var _targets: Array[Node3D] = []
var _live := -1
var _score := 0
var _time := 0.0
var _running := false
var _tag: Label3D
var _hint: Label3D


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("spark_targets")
	_tag = Label3D.new()
	_tag.text = "Spark Targets"
	_tag.font_size = 40
	_tag.pixel_size = 0.006
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.outline_size = 10
	_tag.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	_tag.modulate = Color(1.0, 0.85, 0.5)
	_tag.position.y = 2.6
	add_child(_tag)
	_hint = Label3D.new()
	_hint.font_size = 30
	_hint.pixel_size = 0.006
	_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint.no_depth_test = true
	_hint.outline_size = 8
	_hint.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	_hint.position.y = 2.1
	add_child(_hint)
	for i in 5:
		var a := -0.9 + i * 0.45
		var t: Node3D = load("res://assets/kaykit/hex/decoration/props/target.gltf").instantiate()
		t.scale = Vector3.ONE * 5.0
		t.position = Vector3(sin(a) * 7.0, -1.4, -cos(a) * 7.0)
		t.rotation.y = a + PI
		add_child(t)
		_targets.append(t)
	_hint.text = "best %d" % GameState.best_targets


func get_prompt() -> String:
	return "[F] Spark Targets — start a round" if not _running else "[F] round running…"


func build_dialogue() -> Dictionary:
	if not GameState.spells.has("kindle"):
		return {"pages": [["Spark Targets", "Gorrin's targets rise one at a time; you knock them down with Kindle. You have not learned Kindle yet — Professor Alder teaches it at the Academy."]]}
	if _running:
		return {"pages": [["Spark Targets", "Round running! %d hit, %.0f s left." % [_score, _time]]]}
	return {"pages": [["Spark Targets", "30 seconds. A target pops up; stand near it and cast Kindle (1). Each hit is 2 coins; beat your best for a Mark.\n\nBest so far: %d" % GameState.best_targets]], "choices": [{"label": "Start!", "enabled": true, "call": "start", "arg": null}]}


func start(_a) -> void:
	_running = true
	_score = 0
	_time = ROUND
	_raise(randi() % 5)


func _raise(i: int) -> void:
	_live = i
	for k in _targets.size():
		var tw := create_tween()
		tw.tween_property(_targets[k], "position:y", 0.0 if k == i else -1.4, 0.25)


## Called by HUD.cast_spell when Kindle is cast. Returns true if a target was hit.
func kindle_at(p: Vector3) -> bool:
	if not _running or _live < 0:
		return false
	if _targets[_live].global_position.distance_to(p) < 5.5:
		_score += 1
		GameState.say("Hit!  %d" % _score)
		_raise((_live + 1 + randi() % 4) % 5)
		return true
	return false


func _process(delta: float) -> void:
	if not _running:
		return
	_time -= delta
	_hint.text = "%d hit · %.0f s" % [_score, maxf(_time, 0.0)]
	if _time <= 0.0:
		_running = false
		_raise(-1)
		GameState.coins += _score * 2
		var msg := "Round over: %d hits, +%d coins." % [_score, _score * 2]
		if _score > GameState.best_targets:
			GameState.best_targets = _score
			msg += "  New best!"
			GameState.add_marks(1, "Spark Targets record")
		GameState.mark_dirty()
		GameState.say(msg)
		_hint.text = "best %d" % GameState.best_targets


func interact() -> void:
	pass
