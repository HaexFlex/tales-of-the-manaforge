extends RefCounted
class_name CombatAnimsConfig

const DATA_PATH: String = "res://data/combat_anims.json"
const HAND_ANCHORS_PATH: String = "res://assets/library/combat_2026-10-27/hand_anchors.json"
const MODULAR_BODY_PATH: String = "res://assets/art/battle/modular/%s/%s/frame_%04d.png"
const WEAPON_GRIP: Vector2 = Vector2(0.0, 3.0)
const WEAPON_ROT_PATH: String = "res://assets/art/battle/weapons/rot/%s_r%d.png"
const KEEPER_ATTACK_ROT_SEQUENCE: Array[int] = [6, 7, 0, 0, 1, 1, 0, 7]

static var _data: Dictionary = {}
static var _anchors: Array = []
static var _item_to_sprite: Dictionary = {}
static var _loaded: bool = false
static var _art_frame_cache: Dictionary = {}


static func reload() -> void:
	_loaded = false
	_data.clear()
	_anchors.clear()
	_item_to_sprite.clear()
	_art_frame_cache.clear()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	_data = raw as Dictionary if raw is Dictionary else {}
	var anchor_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(HAND_ANCHORS_PATH))
	_anchors = anchor_raw as Array if anchor_raw is Array else []
	for _family_key: String in (_data.get("weapon_families", {}) as Dictionary).keys():
		var family: Dictionary = (_data.get("weapon_families", {}) as Dictionary)[_family_key] as Dictionary
		for item_v: Variant in family.get("items", []) as Array:
			if item_v is Dictionary:
				var item: Dictionary = item_v as Dictionary
				_item_to_sprite[str(item.get("id", ""))] = str(item.get("sprite_id", ""))


static func clip_for_pose(pose: String) -> String:
	match pose:
		"hurt":
			return "hit"
		"calmed":
			return "calm"
		_:
			return pose


static func timing(side: String, clip: String) -> Dictionary:
	_ensure_loaded()
	var bucket: String = "party" if side == "party" else "enemy"
	var table: Dictionary = ((_data.get("timings_1x", {}) as Dictionary).get(bucket, {}) as Dictionary)
	return (table.get(clip, {}) as Dictionary).duplicate()


static func ms_per_frame_at_speed(speed: int, base_ms: int) -> float:
	return float(base_ms) / float(maxi(1, speed))


static func wall_sec_for_frame_index(speed: int, base_ms: int, frame_index: int) -> float:
	return float(frame_index) * ms_per_frame_at_speed(speed, base_ms) / 1000.0


static func logical_frame_at(elapsed_sec: float, speed: int, base_ms: int, frame_count: int) -> int:
	var ms: float = ms_per_frame_at_speed(speed, base_ms)
	if ms <= 0.0:
		return 0
	var idx: int = int(floorf(elapsed_sec * 1000.0 / ms))
	return clampi(idx, 0, maxi(0, frame_count - 1))


static func display_logical_frame(logical: int, speed: int, hit_frame: int, frame_count: int) -> int:
	if speed < 8:
		return logical
	if logical < hit_frame:
		return 0
	if logical < frame_count - 1:
		return hit_frame
	return frame_count - 1


static func uses_one_to_one_art(actor: String, clip: String) -> bool:
	return actor == "keeper" and clip == "attack"


static func weapon_sprite_id_for_item(item_id: String) -> String:
	_ensure_loaded()
	if item_id == "":
		return str(_data.get("bare_hands_sprite_id", "wpn_none"))
	if _item_to_sprite.has(item_id):
		return str(_item_to_sprite[item_id])
	return str(_data.get("bare_hands_sprite_id", "wpn_none"))


static func weapon_texture_path(sprite_id: String) -> String:
	_ensure_loaded()
	if sprite_id == "" or sprite_id == "wpn_none":
		return ""
	var pattern: String = str((_data.get("sheet_layout", {}) as Dictionary).get("path_pattern_weapon", ""))
	return pattern.replace("{sprite_id}", sprite_id)


static func weapon_rot_texture_path(sprite_id: String, rot_index: int) -> String:
	return WEAPON_ROT_PATH % [sprite_id, rot_index]


static func weapon_texture_for_rot(sprite_id: String, rot_index: int) -> String:
	var rot_path: String = weapon_rot_texture_path(sprite_id, rot_index)
	if rot_path != "" and ResourceLoader.exists(rot_path):
		return rot_path
	return weapon_texture_path(sprite_id)


## Pre-rotated sprites: node rotation stays 0 (CODE_NOTES.md).
static func weapon_rotation_rad(_rot_index: int) -> float:
	return 0.0


static func modular_body_path(actor: String, clip: String, art_frame: int) -> String:
	return MODULAR_BODY_PATH % [actor, clip, art_frame]


static func art_frame_count(actor: String, clip: String) -> int:
	_ensure_loaded()
	var key: String = "%s|%s" % [actor, clip]
	if _art_frame_cache.has(key):
		return int(_art_frame_cache[key])
	var count: int = 0
	while ResourceLoader.exists(modular_body_path(actor, clip, count)):
		count += 1
	_art_frame_cache[key] = count
	return count


static func has_modular_body(actor: String, clip: String) -> bool:
	return art_frame_count(actor, clip) > 0


static func art_frame_for_logical(actor: String, clip: String, logical: int, logical_total: int) -> int:
	var art_count: int = art_frame_count(actor, clip)
	if art_count <= 0:
		return 0
	if logical_total <= 0:
		return 0
	return clampi((logical * art_count) / logical_total, 0, art_count - 1)


static func art_frame_index(actor: String, clip: String, display_logical: int, logical_total: int) -> int:
	if uses_one_to_one_art(actor, clip):
		var count: int = art_frame_count(actor, clip)
		return clampi(display_logical, 0, maxi(0, count - 1))
	return art_frame_for_logical(actor, clip, display_logical, logical_total)


static func hand_anchor(actor: String, clip: String, art_frame: int) -> Dictionary:
	_ensure_loaded()
	for row_v: Variant in _anchors:
		if not row_v is Dictionary:
			continue
		var row: Dictionary = row_v as Dictionary
		if (
			str(row.get("actor", "")) == actor
			and str(row.get("clip", "")) == clip
			and int(row.get("frame", -1)) == art_frame
		):
			return row
	return {}


static func keeper_attack_rot_indices_from_anchors() -> Array[int]:
	var out: Array[int] = []
	for frame: int in range(8):
		var row: Dictionary = hand_anchor("keeper", "attack", frame)
		out.append(int(row.get("rot_index", -1)))
	return out


static func sprite_file_bytes(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(path)


static func clips_with_weapon_overlay(actor: String) -> Array[String]:
	var out: Array[String] = ["attack", "cast"]
	return out


static func uses_weapon_overlay(actor: String, clip: String) -> bool:
	return clip in clips_with_weapon_overlay(actor) and not hand_anchor(actor, clip, 0).is_empty()
