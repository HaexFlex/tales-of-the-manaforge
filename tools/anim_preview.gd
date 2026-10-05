extends Control
## Debug preview of Keeper and Elaia. Clips come from their SpriteFrames.
##   godot --path . res://tools/AnimPreview.tscn
## Windows Release / Stable strips tools/, so that pack does not contain this scene.
## Windows Testing / Experimental keeps it. F9 opens it only on the testing path.

const PREVIEW_SCALE: int = 2
const FEET_Y: float = 478.0
const KEEPER_X: float = 420.0
const ELAIA_X: float = 880.0

const FAMILY_ORDER: Array[String] = [
	"idle",
	"walk",
	"run",
	"harvest_axe",
	"harvest_pickaxe",
	"harvest_berries",
	"harvest_water",
	"station_work",
]

const FAMILY_LABELS: Dictionary = {
	"idle": "Idle",
	"walk": "Walk",
	"run": "Run",
	"harvest_axe": "Axe",
	"harvest_pickaxe": "Pickaxe",
	"harvest_berries": "Berries",
	"harvest_water": "Water",
	"station_work": "Station",
}

const DIR_ORDER: Array[String] = [
	"north", "east", "south", "west", "front", "back",
]

const DIR_LABELS: Dictionary = {
	"north": "N",
	"east": "E",
	"south": "S",
	"west": "W",
	"front": "Front",
	"back": "Back",
	"": "Base",
}

const COLOR_SELECTED := Color(0.93, 0.78, 0.42)
const COLOR_IDLE := Color(0.78, 0.84, 0.74)
const COLOR_DISABLED := Color(0.32, 0.36, 0.32)
const COLOR_INK := Color(0.14, 0.12, 0.08)

var _keeper_body: Keeper
var _elaia_body: Elaia
var _keeper_frames: SpriteFrames
var _elaia_frames: SpriteFrames
var _keeper_sprite: AnimatedSprite2D
var _elaia_sprite: AnimatedSprite2D
var _family_buttons: Dictionary = {}
var _dir_buttons: Dictionary = {}
var _play_button: Button
var _speed_slider: HSlider
var _speed_label: Label
var _status: Label
var _family: String = "walk"
var _dir: String = "south"
var _playing: bool = true
var _speed: float = 1.0


func _ready() -> void:
	_keeper_body = Keeper.new()
	_elaia_body = Elaia.new()
	_keeper_frames = _keeper_body._build_frames()
	_elaia_frames = _elaia_body._build_frames()
	_family = "walk" if _has_family("walk") else _first_family()
	_dir = _pick_dir(_family, "south")
	_build_view()
	_apply_anim()


func _exit_tree() -> void:
	if _keeper_body != null:
		_keeper_body.free()
	if _elaia_body != null:
		_elaia_body.free()


func _build_view() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.18, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var ground := ColorRect.new()
	ground.color = Color(0.47, 0.64, 0.36)
	ground.position = Vector2(150.0, FEET_Y)
	ground.size = Vector2(980.0, 3.0)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)

	var stage := Node2D.new()
	stage.name = "Stage"
	add_child(stage)
	_keeper_sprite = _make_sprite(stage, Vector2(KEEPER_X, FEET_Y))
	_elaia_sprite = _make_sprite(stage, Vector2(ELAIA_X, FEET_Y))
	_name_label("Keeper", KEEPER_X)
	_name_label("Elaia", ELAIA_X)

	var title := _caption("Animation preview", Vector2(28, 16), 22, Color(0.95, 0.96, 0.9), 700.0)
	title.add_theme_font_size_override("font_size", 22)
	var hint := _caption(
		"Nearest filtering, 2× integer scale. Clips come from their SpriteFrames, so a new one shows up on its own.",
		Vector2(28, 48),
		15,
		Color(0.78, 0.84, 0.76),
		1200.0
	)
	hint.add_theme_font_size_override("font_size", 15)

	var strip := ColorRect.new()
	strip.color = Color(0.08, 0.1, 0.09, 0.94)
	strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -228.0
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)

	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 28.0
	panel.offset_right = -28.0
	panel.offset_top = -212.0
	panel.offset_bottom = -16.0
	panel.add_theme_constant_override("separation", 10)
	add_child(panel)

	var families := HFlowContainer.new()
	families.add_theme_constant_override("h_separation", 8)
	families.add_theme_constant_override("v_separation", 8)
	panel.add_child(families)
	for family: String in _families_in_order():
		var button := _make_button(_family_label(family), Vector2(112, 36))
		button.pressed.connect(_on_family.bind(family))
		families.add_child(button)
		_family_buttons[family] = button

	var dirs := HBoxContainer.new()
	dirs.add_theme_constant_override("separation", 8)
	panel.add_child(dirs)
	for dir_name: String in _dirs_present():
		var dir_button := _make_button(_dir_label(dir_name), Vector2(72, 36))
		dir_button.pressed.connect(_on_dir.bind(dir_name))
		dirs.add_child(dir_button)
		_dir_buttons[dir_name] = dir_button

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 14)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(controls)
	_play_button = _make_button("Pause", Vector2(96, 36))
	_play_button.pressed.connect(_on_play)
	controls.add_child(_play_button)
	var speed_name := Label.new()
	speed_name.text = "Speed"
	speed_name.add_theme_font_size_override("font_size", 16)
	speed_name.add_theme_color_override("font_color", Color(0.93, 0.94, 0.88))
	speed_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_child(speed_name)
	_speed_slider = HSlider.new()
	_speed_slider.min_value = 0.1
	_speed_slider.max_value = 3.0
	_speed_slider.step = 0.1
	_speed_slider.value = 1.0
	_speed_slider.custom_minimum_size = Vector2(320, 28)
	_speed_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speed_slider.value_changed.connect(_on_speed)
	controls.add_child(_speed_slider)
	_speed_label = Label.new()
	_speed_label.custom_minimum_size = Vector2(72, 0)
	_speed_label.add_theme_font_size_override("font_size", 16)
	_speed_label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.88))
	_speed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speed_label.text = "1.0×"
	controls.add_child(_speed_label)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color(0.96, 0.93, 0.84))
	panel.add_child(_status)


func _make_sprite(stage: Node2D, at: Vector2) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
	sprite.position = at
	stage.add_child(sprite)
	return sprite


func _name_label(text: String, at_x: float) -> void:
	var label := _caption(text, Vector2(at_x - 80.0, 176.0), 18, Color(0.95, 0.96, 0.9), 160.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _caption(text: String, at: Vector2, size: int, color: Color, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = Vector2(width, float(size) + 10.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _make_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", COLOR_INK)
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.56, 0.52))
	return button


func _on_family(family: String) -> void:
	_family = family
	_dir = _pick_dir(family, _dir)
	_apply_anim()


func _on_dir(dir_name: String) -> void:
	if not _dirs_for(_family).has(dir_name):
		return
	_dir = dir_name
	_apply_anim()


func _on_play() -> void:
	_playing = not _playing
	_play_button.text = "Pause" if _playing else "Play"
	_sync_playback()


func _on_speed(value: float) -> void:
	_speed = snappedf(value, 0.1)
	_speed_label.text = "%.1f×" % _speed
	_sync_playback()


func _apply_anim() -> void:
	var anim := _anim_for(_family, _dir)
	var offset := _keeper_body._offset_for_anim(anim)
	var keeper_ok := _show(_keeper_sprite, _keeper_frames, anim, offset)
	var elaia_ok := _show(_elaia_sprite, _elaia_frames, anim, offset)
	_status.text = "%s · %s · %s" % [anim, _count_text(_keeper_frames, anim, "Keeper", keeper_ok), _count_text(_elaia_frames, anim, "Elaia", elaia_ok)]
	_refresh_buttons()


func _show(sprite: AnimatedSprite2D, frames: SpriteFrames, anim: String, offset: Vector2) -> bool:
	var anim_name := StringName(anim)
	if frames == null or not frames.has_animation(anim_name) or frames.get_frame_count(anim_name) == 0:
		sprite.visible = false
		sprite.stop()
		return false
	sprite.visible = true
	sprite.sprite_frames = frames
	sprite.offset = offset
	sprite.speed_scale = _speed
	sprite.play(anim_name)
	if not _playing:
		sprite.pause()
		sprite.frame = 0
	return true


func _sync_playback() -> void:
	for sprite: AnimatedSprite2D in [_keeper_sprite, _elaia_sprite]:
		if sprite == null or not sprite.visible:
			continue
		sprite.speed_scale = _speed
		if _playing:
			if not sprite.is_playing():
				sprite.play()
		else:
			sprite.pause()


func _refresh_buttons() -> void:
	var have_dirs := _dirs_for(_family)
	for family: String in _family_buttons:
		_paint(_family_buttons[family] as Button, family == _family, true)
	for dir_name: String in _dir_buttons:
		var enabled: bool = have_dirs.has(dir_name)
		_paint(_dir_buttons[dir_name] as Button, enabled and dir_name == _dir, enabled)
	if _play_button:
		_paint(_play_button, true, true)


func _paint(button: Button, selected: bool, enabled: bool) -> void:
	button.disabled = not enabled
	var fill := COLOR_SELECTED if selected else COLOR_IDLE
	if not enabled:
		fill = COLOR_DISABLED
	button.add_theme_stylebox_override("normal", _flat(fill))
	button.add_theme_stylebox_override("hover", _flat(fill.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _flat(fill.darkened(0.08)))
	button.add_theme_stylebox_override("disabled", _flat(COLOR_DISABLED))


func _flat(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(4)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box


func _count_text(frames: SpriteFrames, anim: String, who: String, ok: bool) -> String:
	if not ok or frames == null:
		return "%s no clip" % who
	return "%s %d frames" % [who, frames.get_frame_count(StringName(anim))]


func _families_in_order() -> PackedStringArray:
	var found: Dictionary = _family_map()
	var ordered := PackedStringArray()
	for family: String in FAMILY_ORDER:
		if found.has(family):
			ordered.append(family)
			found.erase(family)
	var rest: Array = found.keys()
	rest.sort()
	for entry: Variant in rest:
		ordered.append(str(entry))
	return ordered


func _dirs_present() -> PackedStringArray:
	var have: Dictionary = {}
	var found: Dictionary = _family_map()
	for family: String in found:
		var dirs: Dictionary = found[family] as Dictionary
		for dir_name: String in dirs:
			have[dir_name] = true
	return _order_dirs(have)


func _dirs_for(family: String) -> PackedStringArray:
	var found: Dictionary = _family_map()
	var dirs: Dictionary = found.get(family, {}) as Dictionary
	return _order_dirs(dirs)


func _order_dirs(have: Dictionary) -> PackedStringArray:
	var ordered := PackedStringArray()
	for dir_name: String in DIR_ORDER:
		if have.has(dir_name):
			ordered.append(dir_name)
	if have.has(""):
		ordered.append("")
	return ordered


func _family_map() -> Dictionary:
	var found: Dictionary = {}
	_gather(_keeper_frames, found)
	_gather(_elaia_frames, found)
	return found


func _gather(frames: SpriteFrames, found: Dictionary) -> void:
	if frames == null:
		return
	for anim_name: String in frames.get_animation_names():
		var split: Dictionary = _split_anim(anim_name)
		var family: String = str(split["family"])
		var dir_name: String = str(split["dir"])
		var dirs: Dictionary = {}
		if found.has(family):
			dirs = found[family] as Dictionary
		dirs[dir_name] = true
		found[family] = dirs


func _split_anim(anim_name: String) -> Dictionary:
	for dir_name: String in DIR_ORDER:
		var suffix := "_%s" % dir_name
		if anim_name.ends_with(suffix):
			var family := anim_name.substr(0, anim_name.length() - suffix.length())
			return {"family": family, "dir": dir_name}
	return {"family": anim_name, "dir": ""}


func _anim_for(family: String, dir_name: String) -> String:
	if dir_name == "":
		return family
	return "%s_%s" % [family, dir_name]


func _pick_dir(family: String, prefer: String) -> String:
	var dirs := _dirs_for(family)
	if dirs.has(prefer):
		return prefer
	if dirs.has("south"):
		return "south"
	if dirs.is_empty():
		return ""
	return dirs[0]


func _has_family(family: String) -> bool:
	return _family_map().has(family)


func _first_family() -> String:
	var ordered := _families_in_order()
	if ordered.is_empty():
		return ""
	return ordered[0]


func _family_label(family: String) -> String:
	if FAMILY_LABELS.has(family):
		return str(FAMILY_LABELS[family])
	return family.replace("_", " ").capitalize()


func _dir_label(dir_name: String) -> String:
	if DIR_LABELS.has(dir_name):
		return str(DIR_LABELS[dir_name])
	return dir_name.capitalize()
