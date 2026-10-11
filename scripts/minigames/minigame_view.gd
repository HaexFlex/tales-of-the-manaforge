class_name MinigameView
extends Control
## 640×320 play-area view bound to a MinigameCore.

var core: MinigameCore


func bind(p_core: MinigameCore) -> void:
	core = p_core
	queue_redraw()


func hint_key() -> String:
	return ""


func handle_input(_ev: InputEvent, _local: Vector2) -> void:
	pass
