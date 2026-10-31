class_name NavGrid
extends Node
## Walkability grid built from the scene's physics colliders, with A* paths.
## Villagers, cats and sheep use it so they walk around houses, fences, the river and each other
## instead of through them. Built once per scene (first thing that asks for it), a few frames
## after the scene is assembled so every collider is in the physics space.
##
## Nodes: a square lattice (`step` apart). Each node stores the ground height under it, or
## BLOCKED when a probe finds a roof, water, a hill or nothing at all.
## Edges: 8 neighbours, each tested with two horizontal rays (shin and chest height) and a
## surface-continuity probe at the midpoint, so a crate top or a wall never counts as a step.
## Edges learned to be bad at run time (a walker got stuck there) are removed.

const BLOCKED := -1000.0
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var step := 3.0
var origin := Vector3.ZERO     # world position of node (0, 0)
var nx := 0
var nz := 0
var ys := PackedFloat32Array()
var edges := PackedByteArray()  # bit i set = neighbour DIRS[i] reachable
var built := false
var _building := false
var _space: PhysicsDirectSpaceState3D
var _cost: Callable = Callable()
var _waiters: Array[Callable] = []


## The grid for the current scene; created on first request.
static var _current: NavGrid

static func get_for(tree: SceneTree) -> NavGrid:
	var sc := tree.current_scene
	if sc == null:
		return null
	if is_instance_valid(_current) and _current._scene == sc:
		return _current
	var g := NavGrid.new()
	g.name = "NavGrid"
	g._scene = sc
	sc.add_child.call_deferred(g)
	_current = g
	return g

var _scene: Node


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	if _building:
		return
	_building = true
	var tree := get_tree()
	# Let the scene finish assembling and the physics server pick up every body.
	await tree.process_frame
	await tree.physics_frame
	await tree.physics_frame
	var sc := _scene
	if not is_instance_valid(sc) or not is_inside_tree():
		return
	_space = sc.get_viewport().world_3d.direct_space_state
	if sc.has_method("nav_cost"):
		_cost = Callable(sc, "nav_cost")
	# Bounds: the scene says where walkers go, otherwise every collider in the scene.
	var lo := Vector3(1e9, 0, 1e9)
	var hi := Vector3(-1e9, 0, -1e9)
	if sc.has_method("nav_bounds"):
		var r: Rect2 = sc.nav_bounds()
		lo = Vector3(r.position.x, 0, r.position.y)
		hi = Vector3(r.end.x, 0, r.end.y)
	else:
		for cs in sc.find_children("*", "CollisionShape3D", true, false):
			var p: Vector3 = (cs as Node3D).global_position
			lo.x = minf(lo.x, p.x)
			lo.z = minf(lo.z, p.z)
			hi.x = maxf(hi.x, p.x)
			hi.z = maxf(hi.z, p.z)
		lo = Vector3(maxf(lo.x - 6.0, -125.0), 0, maxf(lo.z - 6.0, -125.0))
		hi = Vector3(minf(hi.x + 6.0, 125.0), 0, minf(hi.z + 6.0, 125.0))
	if lo.x > hi.x:
		built = true
		_building = false
		return
	var extent := maxf(hi.x - lo.x, hi.z - lo.z)
	step = 2.5 if extent > 110.0 else 1.5
	origin = lo
	nx = int(ceil((hi.x - lo.x) / step)) + 1
	nz = int(ceil((hi.z - lo.z) / step)) + 1
	ys.resize(nx * nz)
	edges.resize(nx * nz)
	var t0 := Time.get_ticks_msec()
	# Pass 1: ground height under every node.
	for i in nx:
		for j in nz:
			ys[i * nz + j] = _surface_y(_pos(i, j))
		if i % 12 == 11:
			await tree.process_frame   # keep the frame rate up while building
			if not is_inside_tree():
				return
	# Pass 2: edges.
	var rq := PhysicsRayQueryParameters3D.new()
	rq.collision_mask = 1
	for i in nx:
		for j in nz:
			var k := i * nz + j
			if ys[k] == BLOCKED:
				continue
			var bits := 0
			for d in DIRS.size():
				var ni: int = i + DIRS[d].x
				var nj: int = j + DIRS[d].y
				if ni < 0 or nj < 0 or ni >= nx or nj >= nz:
					continue
				var nk := ni * nz + nj
				if ys[nk] == BLOCKED or absf(ys[nk] - ys[k]) > 0.9:
					continue
				if _edge_clear(rq, _pos(i, j) + Vector3(0, ys[k], 0), _pos(ni, nj) + Vector3(0, ys[nk], 0)):
					bits |= 1 << d
			edges[k] = bits
		if i % 8 == 7:
			await tree.process_frame
			if not is_inside_tree():
				return
	built = true
	_building = false
	if OS.has_feature("editor") or OS.has_feature("debug"):
		print("NavGrid: %dx%d nodes, step %.1f, %d ms" % [nx, nz, step, Time.get_ticks_msec() - t0])
	for w in _waiters:
		if w.is_valid():
			w.call()
	_waiters.clear()


## Call `cb` once the grid is ready (immediately if it already is).
func when_ready(cb: Callable) -> void:
	if built:
		cb.call()
	else:
		_waiters.append(cb)


func _pos(i: int, j: int) -> Vector3:
	return origin + Vector3(i * step, 0, j * step)


func _surface_y(p: Vector3) -> float:
	var rq := PhysicsRayQueryParameters3D.new()
	rq.from = p + Vector3(0, 30.0, 0)
	rq.to = p + Vector3(0, -3.0, 0)
	rq.collision_mask = 1
	var hit := _space.intersect_ray(rq)
	if hit.is_empty():
		return BLOCKED
	var y: float = hit["position"].y
	if y > 1.7 or y < -0.6:
		return BLOCKED   # roof, water wall, hill, crypt...
	# A walker must fit: nothing solid in a small sphere at chest height.
	var sq := PhysicsShapeQueryParameters3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 0.38
	sq.shape = sp
	sq.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, y + 0.95, 0))
	sq.collision_mask = 1
	if not _space.intersect_shape(sq, 1).is_empty():
		return BLOCKED
	return y


func _edge_clear(rq: PhysicsRayQueryParameters3D, a: Vector3, b: Vector3) -> bool:
	for h in [0.35, 1.05]:
		rq.from = a + Vector3(0, h, 0)
		rq.to = b + Vector3(0, h, 0)
		if not _space.intersect_ray(rq).is_empty():
			return false
	# Surface continuity: the ground halfway must sit on the line between the two ends
	# (catches crate tops, low walls and ledges that the rays pass over).
	var mid := (a + b) * 0.5
	rq.from = Vector3(mid.x, mid.y + 2.5, mid.z)
	rq.to = Vector3(mid.x, mid.y - 2.5, mid.z)
	var hit := _space.intersect_ray(rq)
	if hit.is_empty():
		return false
	return absf(hit["position"].y - mid.y) < 0.22


## Straight line walkable between two world points (two rays, shin and chest)?
func line_clear(a: Vector3, b: Vector3) -> bool:
	if _space == null:
		return true
	var rq := PhysicsRayQueryParameters3D.new()
	rq.collision_mask = 1
	for h in [0.35, 1.05]:
		rq.from = Vector3(a.x, a.y + h, a.z)
		rq.to = Vector3(b.x, b.y + h, b.z)
		if not _space.intersect_ray(rq).is_empty():
			return false
	return true


func _node_at(p: Vector3) -> Vector2i:
	return Vector2i(clampi(int(round((p.x - origin.x) / step)), 0, nx - 1), clampi(int(round((p.z - origin.z) / step)), 0, nz - 1))


## Nearest open node to `p` within `r` metres (grid search), or (-1,-1).
func _nearest_open(p: Vector3, r: float = 7.0) -> Vector2i:
	var c := _node_at(p)
	var rr := int(ceil(r / step))
	var best := Vector2i(-1, -1)
	var bd := 1e9
	for di in range(-rr, rr + 1):
		for dj in range(-rr, rr + 1):
			var i := c.x + di
			var j := c.y + dj
			if i < 0 or j < 0 or i >= nx or j >= nz:
				continue
			var k := i * nz + j
			if ys[k] == BLOCKED or edges[k] == 0:
				continue
			var d := _pos(i, j).distance_to(Vector3(p.x, 0, p.z))
			if d < bd:
				bd = d
				best = Vector2i(i, j)
	return best


## Remove the edge between the two nodes nearest `a` and `b` (a walker got stuck there).
func forget_edge(a: Vector3, b: Vector3) -> void:
	var na := _node_at(a)
	var nb := _node_at(b)
	var d := nb - na
	if d == Vector2i.ZERO or absi(d.x) > 1 or absi(d.y) > 1:
		return
	var di := DIRS.find(d)
	if di >= 0:
		edges[na.x * nz + na.y] &= ~(1 << di)
	var dj := DIRS.find(-d)
	if dj >= 0:
		edges[nb.x * nz + nb.y] &= ~(1 << dj)


## World-space waypoints from `from` to `to` (ends included), or [] when there is no route.
## When the straight line is clear the path is just [to].
func find_path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if not built:
		out.append(to)
		return out
	if from.distance_to(to) < step * 1.5 or line_clear(from, to):
		out.append(to)
		return out
	var s := _nearest_open(from)
	var g := _nearest_open(to)
	if s.x < 0 or g.x < 0:
		return out
	var sk := s.x * nz + s.y
	var gk := g.x * nz + g.y
	# A* with a binary heap.
	var gscore := {}
	var came := {}
	gscore[sk] = 0.0
	var heap: Array = [[_h(s, g), sk]]
	var closed := {}
	var found := false
	var iter := 0
	while heap.size() > 0 and iter < 20000:
		iter += 1
		var top: Array = _heap_pop(heap)
		var k: int = top[1]
		if closed.has(k):
			continue
		closed[k] = true
		if k == gk:
			found = true
			break
		var i := k / nz
		var j := k % nz
		var bits := edges[k]
		for d in DIRS.size():
			if bits & (1 << d) == 0:
				continue
			var ni: int = i + DIRS[d].x
			var nj: int = j + DIRS[d].y
			var nk := ni * nz + nj
			if closed.has(nk):
				continue
			var w := 1.0 if d < 4 else 1.4142
			if _cost.is_valid():
				w *= float(_cost.call(_pos(ni, nj)))
			var ng: float = gscore[k] + w
			if ng < float(gscore.get(nk, 1e18)):
				gscore[nk] = ng
				came[nk] = k
				_heap_push(heap, [ng + _h(Vector2i(ni, nj), g), nk])
	if not found:
		return out
	var chain: Array[int] = []
	var cur := gk
	while cur != sk:
		chain.append(cur)
		cur = came[cur]
	chain.reverse()
	for k in chain:
		out.append(_pos(k / nz, k % nz) + Vector3(0, ys[k], 0))
	out.append(to)
	return out


func _h(a: Vector2i, b: Vector2i) -> float:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	return float(maxi(dx, dy)) + 0.4142 * float(mini(dx, dy))


func _heap_push(h: Array, item: Array) -> void:
	h.append(item)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if h[p][0] <= h[i][0]:
			break
		var tmp = h[p]
		h[p] = h[i]
		h[i] = tmp
		i = p


func _heap_pop(h: Array) -> Array:
	var top: Array = h[0]
	var last = h.pop_back()
	if h.size() > 0:
		h[0] = last
		var i := 0
		var n := h.size()
		while true:
			var l := 2 * i + 1
			var r := l + 1
			var m := i
			if l < n and h[l][0] < h[m][0]:
				m = l
			if r < n and h[r][0] < h[m][0]:
				m = r
			if m == i:
				break
			var tmp = h[m]
			h[m] = h[i]
			h[i] = tmp
			i = m
	return top
