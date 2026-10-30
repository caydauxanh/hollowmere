extends Control
## Hand-drawn world map of the valley: roads, river, lake, districts, villages and the player.

const SCALE := 2.2   # px per world unit
var player: Node3D


func _ready() -> void:
	custom_minimum_size = Vector2(560, 560)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _w(p: Vector3) -> Vector2:
	return Vector2(size.x / 2.0 + p.x * SCALE, size.y / 2.0 + p.z * SCALE)


func _process(_d: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var parchment := Color(0.93, 0.86, 0.68)
	draw_rect(Rect2(Vector2.ZERO, size), parchment)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.3, 0.15), false, 4.0)
	# meadow tint and mountains ring
	draw_circle(size / 2.0, 108.0 * SCALE, Color(0.78, 0.82, 0.6))
	for i in 14:
		var a := i * TAU / 14.0 + 0.3
		var r := 108.0 + (i % 3) * 8.0
		var c := _w(Vector3(cos(a) * r, 0, sin(a) * r))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 8), c + Vector2(0, -14), c + Vector2(14, 8)]), Color(0.6, 0.55, 0.5))
	# lake, pond, river
	draw_circle(_w(Vector3(58, 0, 14)), 22 * SCALE, Color(0.5, 0.7, 0.9))
	draw_circle(_w(Vector3(66, 0, 14)), 5 * SCALE, Color(0.6, 0.75, 0.5))
	draw_circle(_w(Vector3(13, 0, 33)), 5 * SCALE, Color(0.5, 0.7, 0.9))
	var river := [Vector3(38, 0, 26), Vector3(24, 0, 38), Vector3(6, 0, 46), Vector3(-14, 0, 46), Vector3(-30, 0, 38), Vector3(-50, 0, 24), Vector3(-64, 0, 10)]
	for i in river.size() - 1:
		draw_line(_w(river[i]), _w(river[i + 1]), Color(0.5, 0.7, 0.9), 6.0)
	# roads
	for rd in [[Vector3(8, 0, 0), Vector3(40, 0, 12)], [Vector3(-8, 0, 6), Vector3(-56, 0, 44)], [Vector3(10, 0, -12), Vector3(52, 0, -52)]]:
		draw_line(_w(rd[0]), _w(rd[1]), Color(0.7, 0.58, 0.4), 4.0)
	draw_line(_w(Vector3(0, 0, 0)), _w(Vector3(4, 0, -30)), Color(0.7, 0.58, 0.4), 4.0)
	# bridge
	draw_circle(_w(Vector3(-40, 0, 31)), 4.0, Color(0.5, 0.45, 0.4))
	# places
	var font := ThemeDB.fallback_font
	var places := [
		[Vector3(0, 0, 0), "Hollowmere", Color(0.3, 0.2, 0.1)], [Vector3(-4, 0, -40), "Ashenvale Academy", Color(0.25, 0.25, 0.55)],
		[Vector3(-58, 0, 46), "Fernmoor", Color(0.2, 0.4, 0.2)], [Vector3(56, 0, -56), "Old Watchtower", Color(0.4, 0.25, 0.2)],
		[Vector3(48, 0, 30), "Lake Mirren", Color(0.2, 0.3, 0.5)], [Vector3(66, 0, 8), "Heron Isle", Color(0.2, 0.4, 0.2)],
	]
	for id in Story.DISTRICTS:
		if id != "isle":
			places.append([Story.DISTRICTS[id]["pos"], Story.DISTRICTS[id]["name"], Color(0.35, 0.22, 0.1)])
	for p in places:
		var c := _w(p[0])
		draw_circle(c, 5.0, p[2])
		draw_string(font, c + Vector2(7, 4), p[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, p[2])
	# shards / broken left (hints)
	for sid in Story.SHARDS:
		if not GameState.shards.has(sid):
			draw_string(font, _w(Story.SHARDS[sid]) + Vector2(-4, 4), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.7, 0.7))
	draw_circle(_w(Vector3(-62, 0, -62)), 22 * SCALE, Color(0.45, 0.47, 0.42))
	for lid in Story.SKY_LANTERNS:
		if not GameState.sky_lanterns.has(lid):
			draw_string(font, _w(Story.SKY_LANTERNS[lid]) + Vector2(-4, 4), "◌", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.5, 0.2, 0.8))
	# player
	if player:
		var pc := _w(player.global_position)
		draw_circle(pc, 7.0, Color(1.0, 0.95, 0.9))
		draw_circle(pc, 5.0, Color(0.9, 0.25, 0.3))
	draw_string(font, Vector2(14, 24), "The Valley of Ashenvale", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.3, 0.2, 0.1))
	draw_string(font, Vector2(14, size.y - 12), "✦ star shard (Glimmer after dark)   ◌ sky lantern (broom)   ·   M closes", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.3, 0.2))
