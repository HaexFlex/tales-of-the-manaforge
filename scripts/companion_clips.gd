class_name CompanionClips
extends RefCounted
## Clip layout and frame paths from data/companions.json (anim.clips).

const DEFAULT_SIZE: Vector2 = Vector2(128.0, 128.0)
const DEFAULT_OFFSET: Vector2 = Vector2(-64.0, -128.0)


static func anim_root(actor_id: String) -> String:
	var anim_v: Variant = CompanionRoster.row(actor_id).get("anim", {})
	var anim: Dictionary = anim_v if typeof(anim_v) == TYPE_DICTIONARY else {}
	return str(anim.get("root", ""))


static func clip_spec(actor_id: String, clip_name: String) -> Dictionary:
	var anim_v: Variant = CompanionRoster.row(actor_id).get("anim", {})
	var anim: Dictionary = anim_v if typeof(anim_v) == TYPE_DICTIONARY else {}
	var clips_v: Variant = anim.get("clips", {})
	if typeof(clips_v) != TYPE_DICTIONARY:
		return {}
	var raw: Variant = (clips_v as Dictionary).get(clip_name, {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


static func frame_dir(actor_id: String, clip_name: String) -> String:
	var clip: Dictionary = clip_spec(actor_id, clip_name)
	var folder: String = str(clip.get("dir", ""))
	var root: String = anim_root(actor_id)
	if root == "" or folder == "":
		return ""
	return "%s/%s" % [root, folder]


static func count_frames_on_disk(dir_path: String) -> int:
	if dir_path == "":
		return 0
	var count: int = 0
	while ResourceLoader.exists("%s/frame_%04d.png" % [dir_path, count]):
		count += 1
	return count


static func declared_frame_count(clip: Dictionary) -> int:
	var frames: int = int(clip.get("frames", 0))
	if frames > 0:
		return frames
	var ms_v: Variant = clip.get("ms", [])
	if typeof(ms_v) == TYPE_ARRAY:
		return (ms_v as Array).size()
	return 0


static func frame_ms(clip: Dictionary) -> float:
	var ms_v: Variant = clip.get("ms", [])
	if typeof(ms_v) == TYPE_ARRAY and not (ms_v as Array).is_empty():
		return float((ms_v as Array)[0])
	return float(clip.get("frame_ms", 100.0))


static func layout(clip: Dictionary) -> Dictionary:
	var size: Vector2 = DEFAULT_SIZE
	var canvas_v: Variant = clip.get("canvas", [])
	if typeof(canvas_v) == TYPE_ARRAY and (canvas_v as Array).size() >= 2:
		size = Vector2(float((canvas_v as Array)[0]), float((canvas_v as Array)[1]))
	var offset: Vector2 = DEFAULT_OFFSET
	var offset_v: Variant = clip.get("offset", [])
	if typeof(offset_v) == TYPE_ARRAY and (offset_v as Array).size() >= 2:
		offset = Vector2(float((offset_v as Array)[0]), float((offset_v as Array)[1]))
	elif not is_equal_approx(size.x, DEFAULT_SIZE.x):
		offset = Vector2(-size.x * 0.5, -128.0)
	return {"size": size, "offset": offset}


static func hit_frame_index(clip: Dictionary) -> int:
	return int(clip.get("hit_frame", -1))


static func hit_time_sec(clip: Dictionary) -> float:
	var hit: int = hit_frame_index(clip)
	if hit < 0:
		return -1.0
	return float(hit) * frame_ms(clip) / 1000.0


static func frame_path(dir_path: String, index: int) -> String:
	return "%s/frame_%04d.png" % [dir_path, index]


static func load_frame(dir_path: String, index: int) -> Texture2D:
	var path: String = frame_path(dir_path, index)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func battle_clip_name(pose: String) -> String:
	match pose:
		"attack":
			return "battle_attack"
		"hurt", "hit":
			return "battle_hit"
		_:
			return ""


static func build_sprite_frames(actor_id: String, clip_name: String, loop: bool) -> SpriteFrames:
	var clip: Dictionary = clip_spec(actor_id, clip_name)
	var dir_path: String = frame_dir(actor_id, clip_name)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var anim_name: StringName = StringName(clip_name)
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, 1000.0)
	var ms: float = frame_ms(clip)
	var count: int = count_frames_on_disk(dir_path)
	for i: int in range(count):
		var tex: Texture2D = load_frame(dir_path, i)
		if tex == null:
			continue
		frames.add_frame(anim_name, tex, ms)
	return frames
