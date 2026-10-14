@tool
class_name VineFrame
extends Control
## Seeded vines + cyan sparks for a kit frame (frame_9s_96, 24 px border).
## Put it as a full-rect child of the window panel (mouse_filter = IGNORE).
## Same window_id + same size => identical vines, every time (see MOCKUPS.md v8).

const KIT := "res://assets/ui/theme/"
const V0 := Color8(30, 58, 26)     # L0 board vine dark
const V1 := Color8(54, 96, 44)     # L1 stem
const V2 := Color8(86, 138, 54)    # L2 highlight
const CY0 := Color8(58, 166, 180)
const CY1 := Color8(143, 227, 230)
const CORE := Color8(243, 230, 194)
const EDGES := [["T", "lo"], ["L", "lo"], ["T", "hi"], ["R", "lo"], ["B", "hi"], ["R", "hi"], ["B", "lo"], ["L", "hi"]]
const D0 := {"T": 10, "B": 9, "L": 11, "R": 10}
const TWINKLE := [0, 1, 2, 1, 0]   # spark size per frame (frame swap, hard alpha)
const FRAME_TIME := 0.08

@export var window_id := "window":
	set(v): window_id = v; _rebuild()
@export var seed_override := 0:          ## 0 = hash(window_id)
	set(v): seed_override = v; _rebuild()
@export var reduce_motion := false:
	set(v): reduce_motion = v; queue_redraw()

static var _cache := {}
var _tex: Texture2D
var _sparks: Array[Vector2i] = []
var _phase: Array[float] = []      # <0 idle, >=0 time into twinkle
var _next: Array[float] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_rebuild)
	_rebuild()

func get_seed() -> int:
	return seed_override if seed_override != 0 else window_id.hash()

func _rebuild() -> void:
	if not is_inside_tree(): return
	var sz := Vector2i(size)
	if sz.x < 96 or sz.y < 96: _tex = null; queue_redraw(); return
	var key := "%s|%d|%dx%d" % [window_id, get_seed(), sz.x, sz.y]
	if not _cache.has(key): _cache[key] = _bake(sz)
	var c: Dictionary = _cache[key]
	_tex = c.tex; _sparks = c.sparks
	_phase.resize(_sparks.size()); _next.resize(_sparks.size())
	_rng.seed = get_seed()
	for i in _sparks.size(): _phase[i] = -1.0; _next[i] = _rng.randf_range(0.5, 4.0)
	queue_redraw()

# ---------------------------------------------------------------- baking
func _pt(side: String, a: int, d: int, sz: Vector2i) -> Vector2i:
	match side:
		"T": return Vector2i(a, d)
		"B": return Vector2i(a, sz.y - 1 - d)
		"L": return Vector2i(d, a)
	return Vector2i(sz.x - 1 - d, a)

func _put(img: Image, p: Vector2i, c: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height(): img.set_pixelv(p, c)

func _load_img(n: String) -> Image:
	var im: Image = (load(KIT + n) as Texture2D).get_image()
	if im.is_compressed(): im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	return im

func _stamp(img: Image, src: Image, side: String, p: Vector2i, out: int, flip: int) -> void:
	var im := src.duplicate() as Image
	if flip < 0: im.flip_x()
	if side == "L" or side == "R":
		im.rotate_90(COUNTERCLOCKWISE if ((side == "L") == (out < 0)) else CLOCKWISE)
	elif (side == "T") == (out > 0):
		im.flip_y()
	var w := im.get_width(); var h := im.get_height(); var o := Vector2i()
	if side == "T" or side == "B":
		o.x = p.x - (0 if flip > 0 else w - 1)
		o.y = p.y - h + 1 if ((side == "T") == (out < 0)) else p.y
	else:
		o.y = p.y - (0 if flip > 0 else h - 1)
		o.x = p.x - w + 1 if ((side == "L") == (out < 0)) else p.x
	img.blend_rect(im, Rect2i(0, 0, w, h), o)

func _corner(img: Image, corner: String, sz: Vector2i, tl: Image, br: Image) -> void:
	var im: Image
	var o := Vector2i()
	if corner[0] == "T":
		im = tl.duplicate()
		if corner[1] == "R": im.flip_x()
		o.x = 3 if corner[1] == "L" else sz.x - 3 - im.get_width(); o.y = 2
	else:
		im = br.duplicate()
		if corner[1] == "L": im.flip_x()
		o.x = sz.x - 62 if corner[1] == "R" else 62 - im.get_width(); o.y = sz.y - 52
	img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), o)

func _creep(img: Image, side: String, start: int, length: int, dir: int, rng: RandomNumberGenerator, sz: Vector2i, leaf: Image, blob: Image, leaf_tips: Array) -> Vector2i:
	var d := float(D0[side] + rng.randi_range(-1, 1)); var vel := 0.0
	var nxt := rng.randi_range(4, 9); var out := -1 if rng.randf() < 0.5 else 1
	var last := Vector2i(start, int(d))
	for i in length:
		var a := start + dir * i
		vel = clampf(vel + rng.randf_range(-0.25, 0.25), -0.6, 0.6)
		d = clampf(d + vel, 6.0, 16.0)
		if d <= 6.0 or d >= 16.0: vel = -vel
		var di := int(round(d)); var taper := length - i < 6
		_put(img, _pt(side, a, di, sz), V1)
		if not taper: _put(img, _pt(side, a, di + 1, sz), V0)
		if i % 9 == 4 and not taper: _put(img, _pt(side, a, di, sz), V2)
		if i >= nxt and not taper:
			var dd := di if out < 0 else di + 1
			_stamp(img, blob if rng.randf() < 0.2 else leaf, side, _pt(side, a, dd, sz), out, dir)
			if rng.randf() < 0.18: leaf_tips.append(_pt(side, a + dir * 6, dd + out * 3, sz))
			out = -out; nxt = i + rng.randi_range(11, 16)
		last = Vector2i(a, di)
	var tip := _pt(side, last.x + dir, last.y - 1, sz)
	_put(img, tip, V1)
	return tip

func _bake(sz: Vector2i) -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.seed = get_seed()
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var leaf := _load_img("deco_leaf_8x5.png")
	var tl := _load_img("deco_vine_tl.png"); var br := _load_img("deco_vine_br.png")
	var blob := tl.get_region(Rect2i(21, 0, 8, 5))
	# 8 distinct lengths in 1/8..1/4 of the edge
	var pool: Array[float] = []
	for i in 16: pool.append(0.125 + i * (0.125 / 15.0))
	var fr: Array[float] = []
	for i in 8: fr.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	var corners := ["TL", "TR", "BR", "BL"]
	var kit_corners: Array[String] = []
	for i in 2: kit_corners.append(corners.pop_at(rng.randi_range(0, corners.size() - 1)))
	for c in kit_corners: _corner(img, c, sz, tl, br)
	var tips: Array = []; var leaf_tips: Array = []
	for k in 8:
		var side: String = EDGES[k][0]; var lo: bool = EDGES[k][1] == "lo"
		var L := sz.x if side in ["T", "B"] else sz.y
		var n := int(L * fr[k])
		tips.append(_creep(img, side, 18 if lo else L - 19, n, 1 if lo else -1, rng, sz, leaf, blob, leaf_tips))
	var n_sparks := rng.randi_range(3, 5)
	var cand: Array = []
	for i in range(0, tips.size(), 2): cand.append(tips[i])
	cand.append_array(leaf_tips)
	var sparks: Array[Vector2i] = []
	for i in mini(n_sparks, cand.size()): sparks.append(cand.pop_at(rng.randi_range(0, cand.size() - 1)))
	return {"tex": ImageTexture.create_from_image(img), "sparks": sparks}

# ---------------------------------------------------------------- sparks
func _process(delta: float) -> void:
	if reduce_motion or Engine.is_editor_hint() or _sparks.is_empty(): return
	var lit := 0
	for i in _sparks.size(): if _phase[i] >= 0.0: lit += 1
	var dirty := false
	for i in _sparks.size():
		if _phase[i] >= 0.0:
			_phase[i] += delta; dirty = true
			if _phase[i] >= TWINKLE.size() * FRAME_TIME: _phase[i] = -1.0; _next[i] = _rng.randf_range(2.0, 5.0)
		else:
			_next[i] -= delta
			if _next[i] <= 0.0:
				if lit < 2: _phase[i] = 0.0; lit += 1; dirty = true
				else: _next[i] = _rng.randf_range(0.3, 1.0)
	if dirty: queue_redraw()

func _spark(p: Vector2, s: int) -> void:
	draw_rect(Rect2(p, Vector2.ONE), CORE)
	for r in range(1, s + 2):
		var c := CY1 if r <= s else CY0
		for o in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]: draw_rect(Rect2(p + o, Vector2.ONE), c)

func _draw() -> void:
	if _tex == null: return
	draw_texture(_tex, Vector2.ZERO)
	for i in _sparks.size():
		var s := 1
		if not reduce_motion and not Engine.is_editor_hint():
			s = 1 if _phase[i] < 0.0 else TWINKLE[mini(int(_phase[i] / FRAME_TIME), TWINKLE.size() - 1)] + 1
		_spark(Vector2(_sparks[i]), s - 1 if s > 0 else 0)
