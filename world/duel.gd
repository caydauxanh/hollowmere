extends Node3D
## Duelling Club: Sir Pellam calls a spell; cast the matching one (1-4) within the time. Eight calls.

var _running := false
var _round := 0
var _score := 0
var _want := ""
var _t := 0.0
var _tag: Label3D
var _hint: Label3D
const ROUNDS := 8


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("duel")
	_tag = Label3D.new()
	_tag.text = "Duelling Club"
	_tag.font_size = 40
	_tag.pixel_size = 0.006
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.outline_size = 10
	_tag.outline_modulate = Color(0.05, 0.03, 0.1, 0.9)
	_tag.modulate = Color(1.0, 0.75, 0.6)
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
	_hint.text = "best %d / %d" % [GameState.best_duel, ROUNDS]
	add_child(_hint)
	var m: Node3D = load("res://assets/kaykit/hex/decoration/props/weaponrack.gltf").instantiate()
	m.scale = Vector3.ONE * 4.0
	add_child(m)


func get_prompt() -> String:
	return "[F] Duelling Club" if not _running else "[F] duel running…"


func build_dialogue() -> Dictionary:
	var known := []
	for id in Story.SPELLS:
		if GameState.spells.has(id):
			known.append(id)
	if known.size() < 2:
		return {"pages": [["Duelling Club", "Sir Pellam's drill: he calls a spell, you cast it. You need at least two spells first — the Academy teaches them."]]}
	var h := GameState.hour_of_day()
	if h < 14.0 or h >= 16.0:
		return {"pages": [["Duelling Club", "Sir Pellam drills here from two until four in the afternoon. Best: %d / %d." % [GameState.best_duel, ROUNDS]]]}
	return {"pages": [["Sir Pellam", "Eight calls. I name a spell, you cast it before I finish counting. Wrong spell, no point. Ready, apprentice?"]], "choices": [{"label": "Begin!", "enabled": true, "call": "start", "arg": null}]}


func start(_a) -> void:
	_running = true
	_round = 0
	_score = 0
	_next()


func _next() -> void:
	var known := []
	for id in Story.SPELLS:
		if GameState.spells.has(id):
			known.append(id)
	_want = known[randi() % known.size()]
	_t = 2.2
	GameState.say("Pellam: \"%s!\"  (press %d)" % [Story.SPELLS[_want]["name"].to_upper(), Story.SPELLS[_want]["key"]])


## Called by HUD when any spell is cast.
func on_cast(id: String) -> void:
	if not _running:
		return
	if id == _want:
		_score += 1
		GameState.say("Good!  %d / %d" % [_score, ROUNDS])
	else:
		GameState.say("Wrong spell.")
	_advance()


func _advance() -> void:
	_round += 1
	if _round >= ROUNDS:
		_finish()
	else:
		_next()


func _process(delta: float) -> void:
	if not _running:
		return
	_t -= delta
	_hint.text = "round %d/%d · %.1f" % [_round + 1, ROUNDS, maxf(_t, 0.0)]
	if _t <= 0.0:
		GameState.say("Too slow.")
		_advance()


func _finish() -> void:
	_running = false
	GameState.coins += _score * 2
	var msg := "Drill over: %d of %d.  +%d coins" % [_score, ROUNDS, _score * 2]
	if _score > GameState.best_duel:
		GameState.best_duel = _score
		msg += "  New best!"
		GameState.add_marks(1, "Duelling Club")
	if _score == ROUNDS:
		GameState.add_ember(2)
		msg += "  Perfect — +2 Ember"
	GameState.mark_dirty()
	GameState.say(msg)
	_hint.text = "best %d / %d" % [GameState.best_duel, ROUNDS]


func interact() -> void:
	pass
