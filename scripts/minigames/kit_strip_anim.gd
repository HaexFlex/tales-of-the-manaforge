class_name KitStripAnim
extends Control
## Plays a horizontal strip texture (frame 0..n-1) then frees itself.

var _tex: Texture2D
var _frame_w: int = 1
var _frames: int = 1
var _fps: float = 12.0
var _elapsed: float = 0.0
var _frame: int = 0
var _one_shot: bool = true


func setup(tex: Texture2D, frame_w: int, frames: int, fps: float, one_shot: bool = true) -> void:
	_tex = tex
	_frame_w = frame_w
	_frames = maxi(1, frames)
	_fps = maxf(fps, 1.0)
	_one_shot = one_shot
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _tex != null:
		custom_minimum_size = Vector2(float(_frame_w), _tex.get_height())
		size = custom_minimum_size
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var idx: int = int(_elapsed * _fps)
	if idx >= _frames:
		if _one_shot:
			queue_free()
			return
		idx = idx % _frames
	if idx != _frame:
		_frame = idx
		queue_redraw()


func _draw() -> void:
	if _tex == null:
		return
	var h: float = _tex.get_height()
	draw_texture_rect_region(
		_tex,
		Rect2(Vector2.ZERO, Vector2(float(_frame_w), h)),
		Rect2(float(_frame) * float(_frame_w), 0.0, float(_frame_w), h),
	)
