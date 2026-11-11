extends Node
## Trạng thái chung của game: giờ trong game, túi đồ, lưu/tải.
## Được nạp tự động (autoload) với tên "GameState".

signal inventory_changed
signal toast(text: String)

const SAVE_PATH := "user://save.json"

## Tên hiển thị của các loại thảo dược và vật phẩm.
const ITEM_NAMES := {
	"moonpetal": "Moonpetal",
	"emberroot": "Emberroot",
	"whisperleaf": "Whisperleaf",
	"potion": "Starlight Potion",
	"tonic": "Warmth Tonic",
	"draught": "Dream Draught",
	"elixir": "Ember Elixir",
	"minnow": "Mirren Minnow",
	"perch": "Reed Perch",
	"moonfish": "Moonfish",
	"nightcap": "Nightcap",
	"shade": "Shade Draught",
	"sunbell": "Sunbell",
	"glow": "Glowbrew",
	"pumpkin_seed": "Pumpkin seed",
	"pumpkin": "Pumpkin",
	"pie": "Fernmoor Fish Pie",
	"oil": "Lantern Oil",
	"broth": "Heron Broth",
}

var inventory := {"moonpetal": 0, "emberroot": 0, "whisperleaf": 0, "potion": 0, "tonic": 0, "draught": 0, "elixir": 0, "minnow": 0, "perch": 0, "moonfish": 0, "oil": 0, "broth": 0, "nightcap": 0, "shade": 0, "pie": 0, "sunbell": 0, "glow": 0, "pumpkin_seed": 0, "pumpkin": 0}
var coins := 0
var ember := 0
var friendship := {}        # npc id -> points
var quests_done := {}       # request id -> true
var intro_seen := false
var met := {}               # npc id -> true (intro dialogue shown)
var gate_open := false
var spells := {}            # spell id -> true
var lanterns_lit := {}      # lantern id -> true
var verdant_used := {}      # plot key -> day key
var chapter2_done := false
var chapter3_done := false
var books_read := {}
var pages_found := {}
var decor := {}
var last_letter_day := ""
var recipes_unlocked := {}
var marks := 0               # Academy marks (lessons + Trial Field)
var lessons_done := {}       # "daykey/lesson" -> marks earned
var best_targets := 0
var order := ""              # Ashenvale Order (sorting ceremony)
var order_points := {}       # order id -> points (all four, for the board)
var stars_seen := {}         # constellation id -> true
var chapter4_done := false
var broom := false
var best_broom := 0.0
var best_broom2 := 0.0
var shards := {}             # shard id -> true
var mended := {}             # broken id -> true
var chapter5_done := false
var fish_caught := 0
var best_duel := 0
var staff_color := "blue"
var gifts_given := {}        # npc id -> day key
var garden_level := 0        # extra herb beds bought from Tamsin
var chapter6_done := false
var memories_heard := {}
var cards := {}
var lantern_walk_day := ""
var chapter7_done := false
var star_stone_day := ""
var home_decor := {}
var sky_lanterns := {}
var daily := {}
var honours := {}
var hide_day := ""
var sheep_day := ""
var sunbell_bed := false
var patrol_day := ""
var favours := {}            # student id -> true when done
var shrine_smelled := false
var pumpkin_planted := ""    # day key when planted ("" = none)
var pumpkin_best := 0
var contest_day := ""
var cat_pets := 0
var cat_name := ""
var tutorial := {}              # snapshot at the start of the day for the bedtime summary
var glimmer_until := 0.0     # ticks seconds while Glimmer is active (not saved)
var haste_until := 0.0
var shade_until := 0.0
## Where to spawn when the next scene loads (set before change_scene).
var spawn_at := Vector3.INF
var spawn_yaw := 0.0
var title_shown := false
## True while the title screen is up: HUD and player ignore input.
var ui_locked := false

signal ember_changed
signal spells_changed

## Số giây cộng thêm vào đồng hồ thật (dùng khi tua nhanh thời gian để thử).
var time_offset := 0.0
## Hệ số tua nhanh: 1 = giờ thật, 720 = 1 ngày trong 2 phút.
var time_scale := 1.0
## Giờ ép buộc (0-24) dùng khi chụp ảnh thử; -1 = không ép.
var forced_hour := -1.0

## Dữ liệu các luống cây, khoá theo tên luống.
var plots := {}

## Graphics quality: "high" or "low" (saved separately from the game save).
var quality := "high"
const QCFG := "user://quality.cfg"

func load_quality() -> void:
	if FileAccess.file_exists(QCFG):
		quality = FileAccess.get_file_as_string(QCFG).strip_edges()
	elif OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		quality = "low"
	if quality != "low":
		quality = "high"

func set_quality(q: String) -> void:
	quality = q
	var f := FileAccess.open(QCFG, FileAccess.WRITE)
	if f:
		f.store_string(q)
	get_tree().call_group("quality", "apply_quality")

var _save_timer := 0.0
var _dirty := false


func _ready() -> void:
	load_quality()
	_install_font()
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--hour="):
			forced_hour = float(arg.get_slice("=", 1))
	if not args.has("--fresh"):
		load_game()


func _process(delta: float) -> void:
	if Engine.get_process_frames() % 120 == 0:
		_ensure_daily()
	if time_scale != 1.0:
		time_offset += delta * (time_scale - 1.0)
	if _dirty:
		_save_timer -= delta
		if _save_timer <= 0.0:
			save_game()


## Thời điểm hiện tại trong game, tính bằng giây (unix time + phần tua).
func now() -> float:
	return Time.get_unix_time_from_system() + time_offset


## Giờ trong ngày, từ 0.0 đến 24.0, theo múi giờ máy.
func hour_of_day() -> float:
	if forced_hour >= 0.0:
		return forced_hour
	var bias := Time.get_time_zone_from_system().get("bias", 0) as int
	var local := now() + bias * 60.0
	return fposmod(local, 86400.0) / 3600.0


func is_night() -> bool:
	var h := hour_of_day()
	return h >= 19.5 or h < 5.5


func add_item(id: String, amount: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + amount
	inventory_changed.emit()
	mark_dirty()


func take_item(id: String, amount: int = 1) -> bool:
	if inventory.get(id, 0) < amount:
		return false
	inventory[id] -= amount
	inventory_changed.emit()
	mark_dirty()
	return true


func say(text: String) -> void:
	toast.emit(text)


func add_ember(n: int) -> void:
	ember += n
	ember_changed.emit()
	mark_dirty()


func add_friend(npc: String, n: int) -> void:
	friendship[npc] = friendship.get(npc, 0) + n
	mark_dirty()


## Village lanterns lit by Kindle (the Academy brazier does not count).
func village_lanterns_lit() -> int:
	var n := 0
	for k in lanterns_lit:
		if str(k).begins_with("village_"):
			n += 1
	return n


func add_marks(n: int, why: String) -> void:
	var before := Story.rank_for(marks)
	marks += n
	if order != "":
		order_points[order] = int(order_points.get(order, 0)) + n
	mark_dirty()
	var after := Story.rank_for(marks)
	Sound.chime()
	say("+%d Mark%s — %s   (%d total)" % [n, "s" if n != 1 else "", why, marks])
	if after != before:
		say("Rank up!  You are now a %s of Ashenvale." % after)


func friend_level(npc: String) -> int:
	var f: int = friendship.get(npc, 0)
	return 0 if f < 3 else (1 if f < 7 else 2)


func mark_dirty() -> void:
	_dirty = true
	_save_timer = 1.0


func save_game() -> void:
	_dirty = false
	var data := {"inventory": inventory, "plots": plots, "time_offset": time_offset, "coins": coins, "ember": ember, "friendship": friendship, "quests_done": quests_done, "intro_seen": intro_seen, "met": met, "gate_open": gate_open, "spells": spells, "lanterns_lit": lanterns_lit, "verdant_used": verdant_used, "chapter2_done": chapter2_done, "chapter3_done": chapter3_done, "books_read": books_read, "pages_found": pages_found, "decor": decor, "last_letter_day": last_letter_day, "recipes_unlocked": recipes_unlocked, "marks": marks, "lessons_done": lessons_done, "best_targets": best_targets, "order": order, "order_points": order_points, "stars_seen": stars_seen, "chapter4_done": chapter4_done, "broom": broom, "best_broom": best_broom, "best_broom2": best_broom2, "shards": shards, "mended": mended, "chapter5_done": chapter5_done, "fish_caught": fish_caught, "best_duel": best_duel, "staff_color": staff_color, "gifts_given": gifts_given, "garden_level": garden_level, "chapter6_done": chapter6_done, "memories_heard": memories_heard, "cards": cards, "lantern_walk_day": lantern_walk_day, "chapter7_done": chapter7_done, "star_stone_day": star_stone_day, "home_decor": home_decor, "sky_lanterns": sky_lanterns, "daily": daily, "honours": honours, "hide_day": hide_day, "sheep_day": sheep_day, "sunbell_bed": sunbell_bed, "patrol_day": patrol_day, "favours": favours, "shrine_smelled": shrine_smelled, "pumpkin_planted": pumpkin_planted, "pumpkin_best": pumpkin_best, "contest_day": contest_day, "cat_pets": cat_pets, "cat_name": cat_name, "tutorial": tutorial}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func reset() -> void:
	inventory = {"moonpetal": 0, "emberroot": 0, "whisperleaf": 0, "potion": 0, "tonic": 0, "draught": 0, "elixir": 0, "minnow": 0, "perch": 0, "moonfish": 0, "oil": 0, "broth": 0, "nightcap": 0, "shade": 0, "pie": 0, "sunbell": 0, "glow": 0, "pumpkin_seed": 0, "pumpkin": 0}
	coins = 0; ember = 0; friendship = {}; quests_done = {}; intro_seen = false; met = {}; gate_open = false
	spells = {}; lanterns_lit = {}; verdant_used = {}; chapter2_done = false; chapter3_done = false
	books_read = {}; pages_found = {}; decor = {}; last_letter_day = ""; recipes_unlocked = {}; plots = {}; time_offset = 0.0; marks = 0; lessons_done = {}; best_targets = 0; order = ""; order_points = {}; stars_seen = {}; chapter4_done = false; broom = false; best_broom = 0.0; best_broom2 = 0.0; shards = {}; mended = {}; chapter5_done = false; fish_caught = 0; best_duel = 0; staff_color = "blue"; gifts_given = {}; garden_level = 0; chapter6_done = false; memories_heard = {}; cards = {}; lantern_walk_day = ""; chapter7_done = false; star_stone_day = ""; home_decor = {}; sky_lanterns = {}; daily = {}; honours = {}; hide_day = ""; sheep_day = ""; sunbell_bed = false; patrol_day = ""; favours = {}; shrine_smelled = false; pumpkin_planted = ""; pumpkin_best = 0; contest_day = ""; cat_pets = 0; cat_name = ""; tutorial = {}
	inventory_changed.emit(); ember_changed.emit(); spells_changed.emit()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for k in parsed.get("inventory", {}):
		inventory[k] = int(parsed["inventory"][k])
	plots = parsed.get("plots", {})
	time_offset = float(parsed.get("time_offset", 0.0))
	coins = int(parsed.get("coins", 0))
	ember = int(parsed.get("ember", 0))
	friendship = parsed.get("friendship", {})
	quests_done = parsed.get("quests_done", {})
	intro_seen = bool(parsed.get("intro_seen", false))
	met = parsed.get("met", {})
	gate_open = bool(parsed.get("gate_open", false))
	spells = parsed.get("spells", {})
	lanterns_lit = parsed.get("lanterns_lit", {})
	verdant_used = parsed.get("verdant_used", {})
	chapter2_done = bool(parsed.get("chapter2_done", false))
	chapter3_done = bool(parsed.get("chapter3_done", false))
	books_read = parsed.get("books_read", {})
	pages_found = parsed.get("pages_found", {})
	decor = parsed.get("decor", {})
	last_letter_day = str(parsed.get("last_letter_day", ""))
	recipes_unlocked = parsed.get("recipes_unlocked", {})
	marks = int(parsed.get("marks", 0))
	lessons_done = parsed.get("lessons_done", {})
	best_targets = int(parsed.get("best_targets", 0))
	order = str(parsed.get("order", ""))
	order_points = parsed.get("order_points", {})
	stars_seen = parsed.get("stars_seen", {})
	chapter4_done = bool(parsed.get("chapter4_done", false))
	broom = bool(parsed.get("broom", false))
	best_broom = float(parsed.get("best_broom", 0.0))
	best_broom2 = float(parsed.get("best_broom2", 0.0))
	shards = parsed.get("shards", {})
	mended = parsed.get("mended", {})
	chapter5_done = bool(parsed.get("chapter5_done", false))
	fish_caught = int(parsed.get("fish_caught", 0))
	best_duel = int(parsed.get("best_duel", 0))
	staff_color = str(parsed.get("staff_color", "blue"))
	gifts_given = parsed.get("gifts_given", {})
	garden_level = int(parsed.get("garden_level", 0))
	chapter6_done = bool(parsed.get("chapter6_done", false))
	memories_heard = parsed.get("memories_heard", {})
	cards = parsed.get("cards", {})
	lantern_walk_day = str(parsed.get("lantern_walk_day", ""))
	chapter7_done = bool(parsed.get("chapter7_done", false))
	star_stone_day = str(parsed.get("star_stone_day", ""))
	home_decor = parsed.get("home_decor", {})
	sky_lanterns = parsed.get("sky_lanterns", {})
	daily = parsed.get("daily", {})
	honours = parsed.get("honours", {})
	hide_day = str(parsed.get("hide_day", ""))
	sheep_day = str(parsed.get("sheep_day", ""))
	sunbell_bed = bool(parsed.get("sunbell_bed", false))
	patrol_day = str(parsed.get("patrol_day", ""))
	favours = parsed.get("favours", {})
	shrine_smelled = bool(parsed.get("shrine_smelled", false))
	pumpkin_planted = str(parsed.get("pumpkin_planted", ""))
	pumpkin_best = int(parsed.get("pumpkin_best", 0))
	contest_day = str(parsed.get("contest_day", ""))
	cat_pets = int(parsed.get("cat_pets", 0))
	cat_name = str(parsed.get("cat_name", ""))
	tutorial = parsed.get("tutorial", {})


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


## Sleep in the dormitory: skip to 6:30 next morning (time_offset moves the clock forward).
func day_summary() -> String:
	_ensure_daily()
	var d := daily
	var lines := []
	lines.append("Coins: %+d   Ember: %+d   Marks: %+d" % [coins - int(d["coins"]), ember - int(d["ember"]), marks - int(d["marks"])])
	lines.append("Fish: %+d   Lanterns lit: %+d   Friends made closer: %+d" % [fish_caught - int(d["fish"]), lanterns_lit.size() - int(d["lanterns"]), _friend_sum() - int(d["friends"])])
	var done := 0
	for k in lessons_done:
		if str(k).begins_with(Story.today_key()):
			done += 1
	lines.append("Lessons and practicals today: %d" % done)
	return "\n".join(lines)


func _friend_sum() -> int:
	var n := 0
	for k in friendship:
		n += int(friendship[k])
	return n


func _ensure_daily() -> void:
	if daily.get("day", "") != Story.today_key():
		daily = {"day": Story.today_key(), "coins": coins, "ember": ember, "marks": marks, "fish": fish_caught, "lanterns": lanterns_lit.size(), "friends": _friend_sum()}
		mark_dirty()


func sleep_until_morning() -> void:
	var h := hour_of_day()
	var ahead: float = (6.5 - h) if h < 6.5 else (30.5 - h)
	time_offset += ahead * 3600.0
	daily = {}
	mark_dirty()


## Order points for the board: the player's Order gets their Marks; the others drift with the days.
func order_board() -> Dictionary:
	var out := {}
	var seed_day := Story.today_key().hash()
	var i := 0
	for id in Story.ORDERS:
		var base := int(order_points.get(id, 0))
		if id != order:
			base += (seed_day + i * 7919) % 23 + marks / 2
		out[id] = base
		i += 1
	return out


func glimmer_active() -> bool:
	return Time.get_ticks_msec() / 1000.0 < glimmer_until or Time.get_ticks_msec() / 1000.0 < shade_until


func haste_active() -> bool:
	return Time.get_ticks_msec() / 1000.0 < haste_until


## Practical work during a lesson: once per lesson per day, +1 Mark.
func practical(lesson_id: String, why: String) -> bool:
	if Story.lesson_now() != lesson_id:
		return false
	var key := "%s/%s/practical" % [Story.today_key(), lesson_id]
	if lessons_done.has(key):
		return false
	lessons_done[key] = 1
	add_marks(1, "Practical: " + why)
	return true


## Progress on today's Order task (see Story.ORDER_TASKS).
func order_task_progress() -> int:
	var day := Story.today_key()
	match order:
		"emberwing":
			var n := 0
			for k in lanterns_lit:
				if str(k).begins_with("trial_") and str(k).ends_with("@" + day):
					n += 1
			return n
		"tidewatch":
			var n := 0
			for k in quests_done:
				if str(k).begins_with(day + ":"):
					n += 1
			return n
		"thornhollow":
			var n := 0
			for k in verdant_used:
				if str(verdant_used[k]) == day:
					n += 1
			return n
		"moonquill":
			var n := 0
			for k in lessons_done:
				if str(k).begins_with(day) and str(k).ends_with("/practical"):
					n += 1
			return n
	return 0


func _honour(id: String) -> void:
	if honours.has(id):
		return
	honours[id] = true
	mark_dirty()
	Sound.chime()
	say("Honour earned: %s — %s" % [Story.HONOURS[id]["name"], Story.HONOURS[id]["text"]])


## Called every few seconds by the HUD; cheap checks against saved state.
func check_honours() -> void:
	var potions := 0
	for k in ["potion", "tonic", "draught", "elixir", "oil", "broth", "shade", "pie"]:
		potions += int(inventory.get(k, 0))
	if _brewed:
		_honour("first_brew")
	if gate_open: _honour("gate")
	if order != "": _honour("sorted")
	if spells.size() >= 4: _honour("four_spells")
	if village_lanterns_lit() >= Story.DARK_LANTERNS: _honour("all_lanterns")
	if broom: _honour("broom")
	if fish_caught >= 10: _honour("ten_fish")
	if cards.size() >= Story.CARDS.size(): _honour("all_cards")
	if shards.size() >= Story.SHARDS.size(): _honour("all_shards")
	if sky_lanterns.size() >= Story.SKY_LANTERNS.size(): _honour("all_sky")
	if mended.size() >= Story.BROKEN.size(): _honour("all_mend")
	var all_f := true
	for id in Story.NPCS:
		if Story.NPCS[id].get("hidden", false): continue
		if friend_level(id) < 1: all_f = false
	if all_f: _honour("friends")
	if memories_heard.size() >= 5: _honour("close")
	if marks >= 15: _honour("adept")
	if marks >= 60: _honour("mage")
	if quests_done.has("ring"): _honour("ring")
	if chapter7_done: _honour("star")
	if best_duel >= 8: _honour("perfect_duel")
	var all_r := true
	for id in Story.RECIPES:
		if Story.RECIPES[id].get("locked", false) and not recipes_unlocked.has(id): all_r = false
	if all_r: _honour("all_recipes")
	if home_decor.size() >= Story.HOME_DECOR.size(): _honour("cottage")


var _brewed := false
func _brewed_any() -> bool:
	return _brewed


## Days since the pumpkin was planted (real days).
func pumpkin_days() -> int:
	if pumpkin_planted == "":
		return -1
	var p := pumpkin_planted.split("-")
	var q := Story.today_key().split("-")
	var a := Time.get_unix_time_from_datetime_dict({"year": int(p[0]), "month": int(p[1]), "day": int(p[2]), "hour": 0, "minute": 0, "second": 0})
	var b := Time.get_unix_time_from_datetime_dict({"year": int(q[0]), "month": int(q[1]), "day": int(q[2]), "hour": 0, "minute": 0, "second": 0})
	return int(round((b - a) / 86400.0))


## House typeface: EB Garamond (SIL OFL), with the engine font as fallback for symbols.
func _install_font() -> void:
	var f: FontFile = load("res://assets/fonts/eb-garamond-latin-500-normal.woff2")
	if f == null:
		return
	var fb: Array[Font] = []
	for extra in ["res://assets/fonts/eb-garamond-latin-ext-500-normal.woff2", "res://assets/fonts/eb-garamond-vietnamese-500-normal.woff2", "res://assets/fonts/DejaVuSans.ttf"]:   # DejaVu: arrows, stars, ticks
		var e: FontFile = load(extra)
		if e:
			fb.append(e)
	var engine_font := ThemeDB.fallback_font
	if engine_font != f:
		fb.append(engine_font)
	f.fallbacks = fb
	var th := ThemeDB.get_default_theme()
	th.default_font = f
	ThemeDB.fallback_font = f
	# Buttons: dark plate, thin brass edge.
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": Color(0.06, 0.06, 0.09, 0.82), "hover": Color(0.12, 0.11, 0.13, 0.9), "pressed": Color(0.2, 0.16, 0.1, 0.92), "focus": Color(0.06, 0.06, 0.09, 0.0), "disabled": Color(0.05, 0.05, 0.07, 0.6)}[st]
		sb.border_color = Color(0.78, 0.64, 0.36, 0.95) if st in ["hover", "pressed"] else Color(0.42, 0.36, 0.24, 0.9)
		sb.set_border_width_all(0 if st == "focus" else 1)
		sb.set_corner_radius_all(2)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 5
		sb.content_margin_bottom = 5
		th.set_stylebox(st, "Button", sb)
	th.set_color("font_color", "Button", Color(0.84, 0.78, 0.66))
	th.set_color("font_hover_color", "Button", Color(0.98, 0.9, 0.7))
	th.set_color("font_pressed_color", "Button", Color(1.0, 0.86, 0.55))
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.47, 0.42))
