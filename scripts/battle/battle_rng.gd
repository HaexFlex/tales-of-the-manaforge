class_name BattleRng
extends RefCounted
## 31-bit fight RNG. Wraps RandomNumberGenerator.
## Seeds are masked with & 0x7FFFFFFF. The generator state is saved as a decimal
## String (str of the 64-bit state) because JSON numbers are floats and would
## drop bits. Restore with set_seed(saved_seed) first, then set_state_string:
## the seed rebuilds the generator's increment, and the string puts the stream
## back on the saved draw.
##
## Room streams (spawn, combat, loot, twist) are NOT Godot's hash(). They are
## FNV-1a 32-bit over the UTF-8 of "%d:%s" % [room_seed & 0x7FFFFFFF, stream],
## then & 0x7FFFFFFF. Offset basis 2166136261, prime 16777619. Same input,
## same seed, on every engine version.
##
## Scripted mode (with_faces) pops a queued list instead of drawing. roll_die
## and roll_fate share that queue, so the caller controls consumption order.


const SEED_MASK: int = 0x7FFFFFFF
const FNV_OFFSET: int = 2166136261
const FNV_PRIME: int = 16777619
const STREAMS: Array[String] = ["spawn", "combat", "loot", "twist"]

var _rng: RandomNumberGenerator
var _seed: int = 1
var _queue: Array[int] = []
var _cursor: int = 0
var _underrun: int = 0
var _scripted: bool = false


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	set_seed(1)


func set_seed(seed_value: int) -> void:
	_seed = mask_seed(seed_value)
	_rng.seed = _seed


func seed_value() -> int:
	return _seed


func state_string() -> String:
	return str(_rng.state)


func set_state_string(saved: String) -> void:
	_rng.state = saved.strip_edges().to_int()


static func mask_seed(seed_value: int) -> int:
	return seed_value & SEED_MASK


static func mix_stream(room_seed: int, stream: String) -> int:
	var text: String = "%d:%s" % [mask_seed(room_seed), stream]
	var hash: int = FNV_OFFSET
	var bytes: PackedByteArray = text.to_utf8_buffer()
	for i: int in bytes.size():
		var b: int = int(bytes[i])
		hash = (hash ^ b) & 0xFFFFFFFF
		hash = (hash * FNV_PRIME) & 0xFFFFFFFF
	return hash & SEED_MASK


func roll_die(sides: int) -> int:
	var hi: int = maxi(1, sides)
	if _scripted:
		return _pop()
	return _rng.randi_range(1, hi)


func roll_fate() -> int:
	if _scripted:
		return _pop()
	return _rng.randi_range(0, 99)


func remaining() -> int:
	return maxi(0, _queue.size() - _cursor)


func underrun() -> int:
	return _underrun


func queued_faces() -> Array[int]:
	var left: Array[int] = []
	for i: int in range(_cursor, _queue.size()):
		left.append(_queue[i])
	return left


static func with_faces(faces: Array[int]) -> BattleRng:
	var dice := BattleRng.new()
	dice._scripted = true
	dice._queue = faces.duplicate()
	dice._cursor = 0
	dice._underrun = 0
	return dice


func _pop() -> int:
	if _cursor >= _queue.size():
		_underrun += 1
		return 0
	var face: int = _queue[_cursor]
	_cursor += 1
	return face
