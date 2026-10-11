class_name MinigameKit
extends RefCounted
## Shared minigame UI art paths and helpers (approved kit under assets/art/ui/minigames/kit/).

const DIR: String = "res://assets/art/ui/minigames/kit/"
const PLACEHOLDER_KIT: String = "res://assets/art/ui/minigames/placeholder/kit/"
const INK: Color = Color(0.243137, 0.164706, 0.094118, 1.0) # #3E2A18 parchment labels
const WOOD_LABEL: Color = Color(0.980392, 0.933333, 0.8, 1.0) # cream on wood (Title, Stop)


static func tex(file: String) -> String:
	return DIR + file


static func load_tex(file: String) -> Texture2D:
	return load(tex(file)) as Texture2D


static func hint_glyph_files(game_id: String) -> PackedStringArray:
	match game_id:
		"ripe_catch":
			return PackedStringArray([
				"mouse_l_8x10.png", "keycap_a_14x15.png", "keycap_d_14x15.png",
				"keycap_left_14x15.png", "keycap_right_14x15.png",
			])
		"splitting_stone":
			return PackedStringArray([
				"mouse_l_8x10.png", "keycap_1_14x15.png", "keycap_2_14x15.png", "keycap_3_14x15.png",
			])
		"woodsong":
			return PackedStringArray(["mouse_l_8x10.png", "keycap_space_40x15.png"])
		"just_enough":
			return PackedStringArray(["mouse_hold_12x10.png", "keycap_space_40x15.png"])
		"forge_glow":
			return PackedStringArray(["mouse_l_8x10.png", "keycap_space_40x15.png"])
		"steady_press":
			return PackedStringArray(["mouse_hold_12x10.png", "mouse_circle_14x14.png"])
		"with_the_grain":
			return PackedStringArray(["mouse_drag_16x10.png"])
		"steeping":
			return PackedStringArray([
				"keycap_1_14x15.png", "keycap_2_14x15.png", "keycap_3_14x15.png",
				"keycap_4_14x15.png", "keycap_5_14x15.png",
			])
		_:
			return PackedStringArray(["keycap_space_40x15.png"])


static func spawn_strip_fx(
	parent: Control,
	tex_path: String,
	frame_w: int,
	frames: int,
	fps: float,
	center: Vector2,
	one_shot: bool = true,
) -> KitStripAnim:
	var tex: Texture2D = load(tex_path) as Texture2D
	var node := KitStripAnim.new()
	node.setup(tex, frame_w, frames, fps, one_shot)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h: float = tex.get_height() if tex != null else float(frame_w)
	node.position = center - Vector2(float(frame_w) * 0.5, h * 0.5)
	parent.add_child(node)
	return node


static func spawn_word_fb(parent: Control, kind: String, center: Vector2) -> TextureRect:
	var file: String = ""
	match kind:
		"perfect":
			file = "fb_perfect_72x22.png"
		"good":
			file = "fb_good_48x22.png"
		_:
			file = "fb_miss_44x22.png"
	var t: Texture2D = load_tex(file)
	if t == null:
		return null
	var tr := TextureRect.new()
	tr.texture = t
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sz := t.get_size()
	tr.position = center - sz * 0.5
	tr.size = sz
	parent.add_child(tr)
	var tw := tr.create_tween()
	tw.tween_property(tr, "modulate:a", 0.0, 0.55).set_delay(0.35)
	tw.tween_callback(tr.queue_free)
	return tr


static func spawn_resolve_fx(parent: Control, center: Vector2, success: bool, weight: int) -> void:
	if success:
		if weight > 1:
			spawn_word_fb(parent, "perfect", center)
			spawn_strip_fx(parent, tex("fx_perfect_32x32_4f.png"), 32, 4, 1.0 / 0.06, center)
		else:
			spawn_word_fb(parent, "good", center)
			spawn_strip_fx(parent, tex("fx_good_24x24_4f.png"), 24, 4, 1.0 / 0.07, center)
	else:
		spawn_word_fb(parent, "miss", center)
		spawn_strip_fx(parent, tex("fx_miss_24x24_3f.png"), 24, 3, 1.0 / 0.09, center)
