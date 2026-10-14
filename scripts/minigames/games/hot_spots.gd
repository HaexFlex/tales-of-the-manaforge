class_name HotSpots
extends Minigame
## Forge Glow's replacement. Spots flare on the station and cool over one spawn.
## A tap on a live spot pays. A tap elsewhere, and a spot that cools out, pay nothing.

var _k: float = 5.0
var _spawn_sec: float = 2.5
var _life_sec: float = 2.5
var _white_sec: float = 0.8
var _orange_sec: float = 1.7
var _max_spots: int = 3
var _tap_r: float = 28.0
var _separate: float = 70.0
var _clock: float = 0.0
var _spawned: int = -1
var _station: String = "anvil"
var _points: PackedVector2Array = PackedVector2Array()
var _spots: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func game_id() -> String:
	return "hot_spots"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row: Dictionary = MinigameCatalog.game("hot_spots")
	_k = MinigameCatalog.k_for("hot_spots")
	var rate: float = MinigameCatalog.r_of("hot_spots")
	_spawn_sec = 60.0 / rate if rate > 0.0 else 2.5
	_life_sec = float(row.get("life_sec", _spawn_sec))
	_white_sec = float(row.get("white_sec", 0.8))
	_orange_sec = float(row.get("orange_sec", 1.7))
	_max_spots = maxi(1, int(row.get("max_spots", 3)))
	_tap_r = float(row.get("tap_r", 28.0))
	_separate = float(row.get("separate_px", 70.0))
	_rng.randomize()
	_apply_station("anvil")


func bind_target(target_id: String) -> void:
	if target_id == "crucible" or target_id == "anvil" or target_id == "reliquary":
		_apply_station(target_id)


func begin() -> void:
	super.begin()
	_tick(0.0)


func _process(delta: float) -> void:
	if not playing:
		return
	_tick(delta)


func _gui_input(event: InputEvent) -> void:
	if not playing or not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_strike(mb.position)


func _tick(delta: float) -> void:
	_clock += delta
	var kept: Array[Dictionary] = []
	for spot: Dictionary in _spots:
		if bool(spot.get("hit", false)):
			continue
		if _clock - float(spot.get("t0", 0.0)) >= _life_sec:
			var dead: Sprite2D = spot.get("sprite") as Sprite2D
			if dead != null and is_instance_valid(dead):
				dead.queue_free()
			continue
		kept.append(spot)
	_spots = kept
	var idx: int = int(floor(_clock / _spawn_sec))
	while _spawned < idx:
		_spawned += 1
		if _spots.size() < _max_spots:
			_spawn_spot()
	_animate()


func _apply_station(station: String) -> void:
	_station = station
	_points = MinigameCatalog.hot_spot_points(station)
	var plate: String = "close_%s.png" % station
	if get_node_or_null("Plate") == null:
		var bg: Sprite2D = MinigameArt.add_sprite(self, plate, Vector2(320, 160))
		bg.name = "Plate"
	else:
		var existing: Sprite2D = get_node("Plate") as Sprite2D
		existing.texture = MinigameArt.texture(plate)


func _spawn_spot() -> void:
	if _points.is_empty():
		return
	var picked := Vector2.ZERO
	var tries: int = 0
	while tries < 30:
		tries += 1
		picked = _points[_rng.randi_range(0, _points.size() - 1)]
		var crowded: bool = false
		for spot: Dictionary in _spots:
			if picked.distance_to(Vector2(float(spot.get("x", 0.0)), float(spot.get("y", 0.0)))) < _separate:
				crowded = true
				break
		if not crowded:
			break
	var prefix: String = "bub_" if _station == "crucible" else "hot_"
	var spr: Sprite2D = MinigameArt.add_sprite(self, prefix + "white.png", picked)
	spr.z_index = 3
	_spots.append({"x": picked.x, "y": picked.y, "t0": _clock, "hit": false, "sprite": spr, "prefix": prefix})


func _heat(age: float) -> String:
	if age < _white_sec:
		return "white"
	if age < _orange_sec:
		return "orange"
	return "grey"


func _animate() -> void:
	for spot: Dictionary in _spots:
		var spr: Sprite2D = spot.get("sprite") as Sprite2D
		if spr == null or not is_instance_valid(spr):
			continue
		var age: float = _clock - float(spot.get("t0", 0.0))
		var heat: String = _heat(age)
		var tex: Texture2D = MinigameArt.texture(str(spot.get("prefix", "hot_")) + heat + ".png")
		if tex != null:
			spr.texture = tex
		var bob: float = -1.0 if heat == "white" and int(floor(_clock * 10.0)) % 2 == 0 else 0.0
		spr.position = Vector2(float(spot.get("x", 0.0)), float(spot.get("y", 0.0)) + bob)
	var sparks_left: Array[Dictionary] = []
	for spark: Dictionary in _sparks:
		var age_s: float = _clock - float(spark.get("t0", 0.0))
		var spr_s: Sprite2D = spark.get("sprite") as Sprite2D
		if age_s >= 0.32:
			if spr_s != null and is_instance_valid(spr_s):
				spr_s.queue_free()
			continue
		if spr_s != null and is_instance_valid(spr_s):
			spr_s.frame = mini(3, int(floor(age_s / 0.08)))
		sparks_left.append(spark)
	_sparks = sparks_left


func _strike(at: Vector2) -> void:
	var best: int = -1
	var best_d: float = _tap_r + 0.001
	for i: int in _spots.size():
		var spot: Dictionary = _spots[i]
		if bool(spot.get("hit", false)):
			continue
		var d: float = at.distance_to(Vector2(float(spot.get("x", 0.0)), float(spot.get("y", 0.0))))
		if d <= _tap_r and d < best_d:
			best_d = d
			best = i
	if best < 0:
		return
	var hit: Dictionary = _spots[best]
	hit["hit"] = true
	_spots[best] = hit
	var spr: Sprite2D = hit.get("sprite") as Sprite2D
	if spr != null and is_instance_valid(spr):
		spr.queue_free()
	var where := Vector2(float(hit.get("x", 0.0)), float(hit.get("y", 0.0)))
	var burst: Sprite2D = MinigameArt.add_sprite(self, "sparks_4f.png", where, 4)
	burst.z_index = 4
	_sparks.append({"t0": _clock, "sprite": burst})
	succeed(_k)
