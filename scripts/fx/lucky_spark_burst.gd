class_name LuckySparkBurst
extends Node2D
## One-shot 4-frame burst (75 ms/frame) from lucky_burst_strip_7x7x4.

const TEX_PATH: String = "res://assets/art/fx/lucky_spark/lucky_burst_strip_7x7x4.png"
const FRAME_SEC: float = 0.075
const FRAME_COUNT: int = 4

var _sprite: Sprite2D
var _age: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Burst"
	_sprite.texture = load(TEX_PATH) as Texture2D
	_sprite.hframes = FRAME_COUNT
	_sprite.frame = 0
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE
	add_child(_sprite)


func _process(delta: float) -> void:
	_age += delta
	var frame_i: int = int(floor(_age / FRAME_SEC))
	if frame_i >= FRAME_COUNT:
		queue_free()
		return
	_sprite.frame = frame_i
