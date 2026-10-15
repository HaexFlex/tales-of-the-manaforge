class_name RipeCatch
extends Minigame
## Basket under a fixed 1.5s clock. Rotten berries are extra and never pay.

## 48 px spawn to the 278 px landing line in 1.6 s.
const FALL: float = 143.75
const BASKET_Y: float = 286.0

var _k: float = 3.0
var _spawn_sec: float = 1.5
var _rotten_every: int = 8
var _catch_half: float = 23.0
var _spawn_t: float = 0.0
var _spawn_i: int = 0
var _basket: Sprite2D
var _keeper: Sprite2D
var _falling: Array[Sprite2D] = []
var _anim_t: float = 0.0
var _face: float = 1.0
var _moved_at: float = -10.0
var _prev_x: float = -1.0


func game_id() -> String:
	return "ripe_catch"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("ripe_catch")
	_k = MinigameCatalog.k_for("ripe_catch")
	_spawn_sec = float(row.get("spawn_sec", 1.5))
	_rotten_every = maxi(1, int(row.get("rotten_every", 8)))
	_catch_half = float(row.get("catch_width", 46.0)) * 0.5
	MinigameArt.add_sprite(self, "bg_grass.png", Vector2(320, 160))
	var canopy: Sprite2D = MinigameArt.add_sprite(self, "canopy.png", Vector2(320, 28))
	canopy.z_index = 2
	MinigameArt.add_sprite(self, "node_berry.png", Vector2(78, 168))
	_keeper = MinigameArt.add_sprite(self, "keeper_walk_e.png", Vector2(300, 268), 8)
	_keeper.z_index = 2
	_basket = MinigameArt.add_sprite(self, "basket.png", Vector2(320, BASKET_Y))
	_basket.z_index = 4
	_place_keeper()


func _process(delta: float) -> void:
	if not playing:
		return
	_anim_t += delta
	_slide_basket(delta)
	_place_keeper()
	_spawn_t += delta
	while _spawn_t >= _spawn_sec:
		_spawn_t -= _spawn_sec
		_spawn(false)
		if _spawn_i % _rotten_every == 0:
			_spawn(true)
	var kept: Array[Sprite2D] = []
	for berry: Sprite2D in _falling:
		if not is_instance_valid(berry):
			continue
		berry.position.y += FALL * delta
		if bool(berry.get_meta("caught", false)):
			continue
		if berry.position.y >= BASKET_Y - 8.0:
			_land(berry)
			continue
		kept.append(berry)
	_falling = kept


func _slide_basket(delta: float) -> void:
	if _basket == null:
		return
	var x: float = _basket.position.x
	if get_global_rect().has_point(get_global_mouse_position()):
		x = get_local_mouse_position().x
	var dir: float = 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir += 1.0
	x += dir * 320.0 * delta
	_basket.position.x = clampf(x, 36.0, 604.0)


## Walk frames follow the basket. Frame 0 stands; 1–7 step. Facing left mirrors the sheet.
func _place_keeper() -> void:
	if _keeper == null or _basket == null:
		return
	var x: float = _basket.position.x
	if _prev_x >= 0.0 and absf(x - _prev_x) > 0.3:
		_face = 1.0 if x > _prev_x else -1.0
		_moved_at = _anim_t
	_prev_x = x
	var moving: bool = _anim_t - _moved_at < 0.12
	_keeper.frame = (1 + int(floor(_anim_t * 10.0)) % 7) if moving else 0
	_keeper.scale = Vector2(_face, 1.0)
	var side: float = -20.0 if _face > 0.0 else 20.0
	_keeper.position = Vector2(x + side, _basket.position.y - 18.0)


func _spawn(rotten: bool) -> void:
	_spawn_i += 1
	var file: String = "berry_rotten.png" if rotten else "berry.png"
	var x: float = randf_range(120.0, 580.0)
	if rotten:
		x = clampf(x + 70.0, 120.0, 580.0)
	var berry: Sprite2D = MinigameArt.add_sprite(self, file, Vector2(x, 48))
	berry.z_index = 3
	berry.set_meta("rotten", rotten)
	berry.set_meta("caught", false)
	_falling.append(berry)


func _land(berry: Sprite2D) -> void:
	berry.set_meta("caught", true)
	var basket_x: float = _basket.position.x if _basket != null else 0.0
	var in_basket: bool = absf(berry.position.x - basket_x) <= _catch_half
	var rotten: bool = bool(berry.get_meta("rotten", false))
	## Rotten berries pay nothing and are not misses, caught or ignored.
	if not rotten:
		if in_basket:
			succeed(_k, 1.0, berry.position)
		else:
			miss()
	berry.queue_free()
