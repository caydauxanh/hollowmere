extends Node
## Music and ambience (autoload "Sound"). Day/night crossfades; water near the lake; small SFX.

var _music_day: AudioStreamPlayer
var _music_night: AudioStreamPlayer
var _music_academy: AudioStreamPlayer
var _amb_day: AudioStreamPlayer
var _amb_night: AudioStreamPlayer
var _water: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var muted := false
const CFG := "user://sound.cfg"


func _ready() -> void:
	_music_day = _player("res://assets/audio/music_day.ogg", -12.0)
	_music_night = _player("res://assets/audio/music_night.ogg", -14.0)
	_music_academy = _player("res://assets/audio/music_academy.ogg", -40.0)
	_amb_day = _player("res://assets/audio/amb_day.ogg", -10.0)
	_amb_night = _player("res://assets/audio/amb_night.ogg", -12.0)
	_water = _player("res://assets/audio/amb_water.ogg", -40.0)
	_rain = _player("res://assets/audio/amb_rain.ogg", -40.0)
	_sfx = AudioStreamPlayer.new()
	_sfx.volume_db = -8.0
	add_child(_sfx)
	if FileAccess.file_exists(CFG):
		muted = FileAccess.get_file_as_string(CFG).strip_edges() == "muted"
	_apply_mute()


func _player(path: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		st.loop = true
	p.stream = st
	p.volume_db = db
	p.autoplay = true
	add_child(p)
	p.play()
	return p


func toggle_mute() -> void:
	muted = not muted
	_apply_mute()
	var f := FileAccess.open(CFG, FileAccess.WRITE)
	if f:
		f.store_string("muted" if muted else "on")


func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)


func chime() -> void:
	_sfx.stream = load("res://assets/audio/sfx_chime.ogg")
	_sfx.play()


func bell() -> void:
	_sfx.stream = load("res://assets/audio/sfx_bell.ogg")
	_sfx.play()


func spell() -> void:
	_sfx.stream = load("res://assets/audio/sfx_spell.ogg")
	_sfx.play()


func _process(delta: float) -> void:
	var h := GameState.hour_of_day()
	var night := 1.0 if (h >= 20.0 or h < 5.5) else (0.0 if (h >= 7.0 and h < 18.5) else 0.5)
	var k := 1.5 * delta
	var indoors: bool = get_tree().current_scene != null and get_tree().current_scene.name != "Village"
	_music_day.volume_db = move_toward(_music_day.volume_db, -40.0 if indoors else lerpf(-12.0, -40.0, night), k * 10.0)
	_music_night.volume_db = move_toward(_music_night.volume_db, -40.0 if indoors else lerpf(-40.0, -14.0, night), k * 10.0)
	_music_academy.volume_db = move_toward(_music_academy.volume_db, -13.0 if indoors else -40.0, k * 10.0)
	_amb_day.volume_db = move_toward(_amb_day.volume_db, lerpf(-10.0, -40.0, night), k * 10.0)
	_amb_night.volume_db = move_toward(_amb_night.volume_db, lerpf(-40.0, -12.0, night), k * 10.0)
	var pl := get_tree().get_first_node_in_group("player")
	var wv := -40.0
	if pl and get_tree().current_scene and get_tree().current_scene.name == "Village":
		var d: float = (pl as Node3D).global_position.distance_to(Vector3(58, 0, 14))
		wv = lerpf(-6.0, -40.0, clampf((d - 20.0) / 25.0, 0.0, 1.0))
	_water.volume_db = move_toward(_water.volume_db, wv, k * 10.0)
	var rv := -40.0
	if get_tree().current_scene and get_tree().current_scene.name == "Village" and Story.weather() == "rain":
		rv = -9.0
	_rain.volume_db = move_toward(_rain.volume_db, rv, k * 10.0)
	# Inside the Academy the music is quieter and the ambience fades
	if get_tree().current_scene and get_tree().current_scene.name != "Village":
		_amb_day.volume_db = move_toward(_amb_day.volume_db, -40.0, k * 10.0)
		_amb_night.volume_db = move_toward(_amb_night.volume_db, -40.0, k * 10.0)
