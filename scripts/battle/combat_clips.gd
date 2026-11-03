extends RefCounted
class_name CombatClips
## Wave 1 combat clips from assets/library/combat_2026-10-27/CODE_NOTES.md.
## Frame counts, milliseconds, hit frames, and anchors are copied from that note.
## A missing anchor is left empty. Nothing here invents a timing.

const ROOT: String = "res://assets/art/battle/modular/"

static var _textures: Dictionary = {}


static func catalog() -> Array[Dictionary]:
	var clips: Array[Dictionary] = []
	clips.append(_clip("elaia_attack", "elaia", "attack", 8, 125, 3, false, false, _elaia_attack_anchors()))
	clips.append(_clip("elaia_hit", "elaia", "hit", 4, 100, 1, false, false, []))
	clips.append(_clip("acorn_imp_hit", "acorn_imp", "hit", 4, 100, 1, false, false, []))
	clips.append(_clip("acorn_imp_calm", "acorn_imp", "calm", 6, 100, 3, false, true, []))
	clips.append(_clip("acorn_imp_attack", "acorn_imp", "attack", 8, 125, 3, false, false, []))
	return clips


static func find(actor: String, clip: String) -> Dictionary:
	for spec: Dictionary in catalog():
		if str(spec.get("actor", "")) == actor and str(spec.get("clip", "")) == clip:
			return spec
	return {}


static func has_clip(actor: String, clip: String) -> bool:
	return not find(actor, clip).is_empty()


static func frame_path(actor: String, clip: String, frame_index: int) -> String:
	return "%s%s/%s/frame_%04d.png" % [ROOT, actor, clip, frame_index]


static func duration_ms(spec: Dictionary) -> int:
	return int(spec.get("frames", 0)) * int(spec.get("ms", 0))


static func hit_ms(spec: Dictionary) -> int:
	return int(spec.get("hit_frame", 0)) * int(spec.get("ms", 0))


## Seconds until damage for an attack clip. Negative when this actor has no wave-1 attack.
static func strike_react_sec(actor: String) -> float:
	var spec: Dictionary = find(actor, "attack")
	if spec.is_empty():
		return -1.0
	return float(hit_ms(spec)) / 1000.0


static func anchor_for(spec: Dictionary, frame_index: int) -> Dictionary:
	var rows: Array = spec.get("anchors", []) as Array
	for row_v: Variant in rows:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		if int(row.get("frame", -1)) == frame_index:
			return row
	return {}


static func texture(spec: Dictionary, frame_index: int) -> Texture2D:
	var path: String = frame_path(str(spec.get("actor", "")), str(spec.get("clip", "")), frame_index)
	if _textures.has(path):
		return _textures[path] as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		_textures[path] = tex
	return tex


## Draw one frame. Wave-1 clips are unmirrored: flip_h stays off (imp stem stays on the right).
static func present(sprite: TextureRect, actor: String, clip: String, frame_index: int) -> bool:
	var spec: Dictionary = find(actor, clip)
	if spec.is_empty() or sprite == null:
		return false
	var tex: Texture2D = texture(spec, frame_index)
	if tex == null:
		return false
	sprite.texture = tex
	sprite.flip_h = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return true


static func _clip(
	id: String,
	actor: String,
	clip: String,
	frames: int,
	ms: int,
	hit_frame: int,
	mirrored: bool,
	loop: bool,
	anchors: Array
) -> Dictionary:
	return {
		"id": id,
		"actor": actor,
		"clip": clip,
		"frames": frames,
		"ms": ms,
		"hit_frame": hit_frame,
		"mirrored": mirrored,
		"loop": loop,
		"anchors": anchors,
	}


static func _elaia_attack_anchors() -> Array:
	## CODE_NOTES lists frames 0..3 only. Frames 4..7 stay without an anchor.
	var rows: Array = []
	rows.append({"frame": 0, "hand_x": 100, "hand_y": 66, "rot_index": 0, "z": "front"})
	rows.append({"frame": 1, "hand_x": 101, "hand_y": 66, "rot_index": 0, "z": "front"})
	rows.append({"frame": 2, "hand_x": 102, "hand_y": 66, "rot_index": 0, "z": "front"})
	rows.append({"frame": 3, "hand_x": 103, "hand_y": 66, "rot_index": 0, "z": "front"})
	return rows
