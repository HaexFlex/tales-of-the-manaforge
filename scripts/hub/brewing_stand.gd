extends Area2D
## R5 brewing stand — stand art, bubble loop while brewing, done glint once, wisp work spot.

const STAND_TEX: String = "res://assets/art/props/brewing_stand.png"
const BUBBLE_STRIP: String = "res://assets/art/fx/brewing/brew_bubbles_strip_24x32x6.png"
const GLINT_STRIP: String = "res://assets/art/fx/brewing/brew_done_glint_strip_12x12x4.png"
const WISP_SPOT_TEX: String = "res://assets/art/fx/brewing/wisp_work_spot_18x10.png"
const BUBBLE_MS: float = 150.0
const GLINT_MS: float = 90.0

var _stand: Sprite2D
var _bubbles: AnimatedSprite2D
var _glint: AnimatedSprite2D
var _wisp_spot: Sprite2D
var _was_working: bool = false
var _glint_playing: bool = false


func _ready() -> void:
	add_to_group("brewing_stand")
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	input_pickable = true
	_build_visuals()
	visible = GameState.brewing_unlocked
	if not GameState.echo_flags_changed.is_connected(_on_flags):
		GameState.echo_flags_changed.connect(_on_flags)
	set_process(true)


func _build_visuals() -> void:
	_stand = Sprite2D.new()
	_stand.name = "StandArt"
	_stand.texture = load(STAND_TEX) as Texture2D
	_stand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_stand.centered = false
	_stand.offset = Vector2(-32, -80)
	add_child(_stand)
	_bubbles = AnimatedSprite2D.new()
	_bubbles.name = "Bubbles"
	_bubbles.position = Vector2(-12, -72)
	_bubbles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bubbles.sprite_frames = _strip_frames(BUBBLE_STRIP, 24, 32, 6, BUBBLE_MS, true)
	_bubbles.visible = false
	add_child(_bubbles)
	_glint = AnimatedSprite2D.new()
	_glint.name = "DoneGlint"
	_glint.position = Vector2(-6, -76)
	_glint.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glint.sprite_frames = _strip_frames(GLINT_STRIP, 12, 12, 4, GLINT_MS, false)
	_glint.visible = false
	_glint.animation_finished.connect(_on_glint_finished)
	add_child(_glint)
	_wisp_spot = Sprite2D.new()
	_wisp_spot.name = "WispSpot"
	_wisp_spot.position = Vector2(-9, -8)
	_wisp_spot.texture = load(WISP_SPOT_TEX) as Texture2D
	_wisp_spot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wisp_spot.centered = false
	_wisp_spot.visible = false
	add_child(_wisp_spot)


func _strip_frames(path: String, fw: int, fh: int, count: int, ms: float, loop: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return frames
	frames.add_animation(&"fx")
	frames.set_animation_loop(&"fx", loop)
	frames.set_animation_speed(&"fx", 1000.0 / ms)
	for i: int in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float(i * fw), 0.0, float(fw), float(fh))
		frames.add_frame(&"fx", atlas)
	return frames


func _on_flags() -> void:
	visible = GameState.brewing_unlocked


func _process(_delta: float) -> void:
	if not visible or not has_node("/root/BrewingJobs"):
		return
	var working: bool = BrewingJobs.job_working()
	if working:
		if not _bubbles.visible:
			_bubbles.visible = true
			_bubbles.play(&"fx")
	elif _bubbles.visible:
		_bubbles.visible = false
		_bubbles.stop()
	if _was_working and not working and not _glint_playing:
		_glint_playing = true
		_glint.visible = true
		_glint.play(&"fx")
	_was_working = working
	var wisps: int = GameState.count_wisps_on_node("brewing") if working or BrewingJobs.unlocked() else 0
	_wisp_spot.visible = wisps > 0


func _on_glint_finished() -> void:
	_glint_playing = false
	_glint.visible = false


func world_hover_name() -> String:
	return ContentStrings.get_text("brewing_stand_title")
