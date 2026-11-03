extends RefCounted
class_name CombatAnimsConfig

const DATA_PATH: String = "res://data/combat_anims.json"
const HAND_ANCHORS_PATH: String = "res://assets/library/combat_2026-10-27/hand_anchors.json"
const GRIP_OFFSETS_PATH: String = "res://assets/art/battle/weapons/rot/grip_offsets.json"
const MODULAR_BODY_PATH: String = "res://assets/art/battle/modular/%s/%s/frame_%04d.png"
const WEAPON_ROT_PATH: String = "res://assets/art/battle/weapons/rot/%s_r%d.png"
const WAND_SPARK_PATH: String = "res://assets/art/battle/fx/wand_cast_spark_strip.png"
const ARROW_SPRITE_PATH: String = "res://assets/art/battle/weapons/wpn_arrow_t0.png"
const ARROW_NOCK: Vector2 = Vector2(1.0, 1.0)
const BOW_ARROW_FLIGHT_SEC: float = 0.12
const KEEPER_ATTACK_ROT_SEQUENCE: Array[int] = [5, 6, 7, 1, 1, 1, 0, 0]
const FIGHTER_SOLE: Vector2 = Vector2(64.0, 123.0)
const BODY_FRAME: Vector2 = Vector2(128.0, 128.0)
const CONTACT_CELL_MARGIN: int = 36

const WEAPON_FAMILY_GRIP: Dictionary = {
	"sword": Vector2(0.0, 4.0),
	"wand": Vector2(4.0, 12.0),
	"bow": Vector2(4.0, 20.0),
}
const WEAPON_FAMILY_SIZE: Dictionary = {
	"sword": Vector2(28.0, 10.0),
	"wand": Vector2(9.0, 36.0),
	"bow": Vector2(22.0, 42.0),
}

static var _data: Dictionary = {}
static var _anchors: Array = []
static var _grip_offsets: Dictionary = {}
static var _item_to_sprite: Dictionary = {}
static var _loaded: bool = false
static var _art_frame_cache: Dictionary = {}


static func reload() -> void:
	_loaded = false
	_data.clear()
	_anchors.clear()
	_grip_offsets.clear()
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
	var grip_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(GRIP_OFFSETS_PATH))
	_grip_offsets = grip_raw as Dictionary if grip_raw is Dictionary else {}
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
	return actor == "keeper" and clip in ["attack", "attack_wand", "attack_bow"]


static func strike_clip_for_weapon_family(family: String) -> String:
	match family:
		"wand":
			return "attack_wand"
		"bow":
			return "attack_bow"
		_:
			return "attack"


static func strike_clip_for_sprite(sprite_id: String) -> String:
	return strike_clip_for_weapon_family(weapon_family_from_sprite(sprite_id))


static func resolve_playback_clip(actor: String, clip: String, weapon_sprite_id: String) -> String:
	var norm: String = clip_for_pose(clip)
	if actor == "keeper" and norm == "attack" and weapon_sprite_id != "":
		var family_clip: String = strike_clip_for_sprite(weapon_sprite_id)
		if has_modular_body(actor, family_clip):
			return family_clip
	return norm


static func weapon_rot_degrees(rot_index: int) -> float:
	return float(rot_index) * 45.0 - 270.0


static func rotate_local_offset(ox: float, oy: float, rot_index: int) -> Vector2:
	var rad: float = deg_to_rad(weapon_rot_degrees(rot_index))
	var c: float = cos(rad)
	var s: float = sin(rad)
	return Vector2(ox * c - oy * s, ox * s + oy * c)


static func wand_tip_in_body_texture(anchor: Dictionary) -> Vector2:
	var hx: float = float(anchor.get("hand_x", 0))
	var hy: float = float(anchor.get("hand_y", 0))
	var rot_i: int = int(anchor.get("rot_index", 0))
	var tip: Vector2 = rotate_local_offset(
		float(anchor.get("tip_ox", 0)),
		float(anchor.get("tip_oy", -9)),
		rot_i,
	)
	return Vector2(hx, hy) + tip


static func wand_spark_visible(clip: String, art_frame: int) -> bool:
	return clip == "attack_wand" and art_frame >= 2 and art_frame <= 5


static func bow_arrow_nocked_visible(clip: String, art_frame: int) -> bool:
	return clip == "attack_bow" and art_frame >= 0 and art_frame <= 5


static func bow_string_tip_in_body(
	hand_x: int,
	hand_y: int,
	sprite_id: String,
	rot_index: int,
	which: String,
) -> Vector2:
	_ensure_loaded()
	var pivot: Vector2 = weapon_pivot_for_rot(sprite_id, rot_index)
	var tips_root: Dictionary = (_grip_offsets.get("string_tips", {}) as Dictionary)
	var bow_entry: Dictionary = (tips_root.get(sprite_id, {}) as Dictionary)
	var rots: Dictionary = (bow_entry.get("rots", {}) as Dictionary)
	var rot_key: String = "r%d" % rot_index
	var rot_tips: Dictionary = (rots.get(rot_key, {}) as Dictionary)
	var tip_arr: Variant = rot_tips.get(which, [])
	if tip_arr is Array and (tip_arr as Array).size() >= 2:
		var tip: Vector2 = Vector2(float(tip_arr[0]), float(tip_arr[1]))
		return Vector2(float(hand_x), float(hand_y)) - pivot + tip
	return Vector2(float(hand_x), float(hand_y))


static func bow_string_points_in_body(
	hand_x: int,
	hand_y: int,
	hand2_x: int,
	hand2_y: int,
	sprite_id: String,
	rot_index: int,
	string_draw: float,
) -> PackedVector2Array:
	var top: Vector2 = bow_string_tip_in_body(hand_x, hand_y, sprite_id, rot_index, "top")
	var bottom: Vector2 = bow_string_tip_in_body(hand_x, hand_y, sprite_id, rot_index, "bottom")
	if string_draw <= 0.0:
		return PackedVector2Array([top, bottom])
	var hand2: Vector2 = Vector2(float(hand2_x), float(hand2_y))
	return PackedVector2Array([top, hand2, bottom])


static func strike_react_sec(sprite_id: String) -> float:
	_ensure_loaded()
	var family: String = weapon_family_from_sprite(sprite_id)
	match family:
		"wand":
			return float(timing("party", "attack_wand").get("hit_ms", 500)) / 1000.0
		"bow":
			var bow_t: Dictionary = timing("party", "attack_bow")
			var release_frame: int = int(bow_t.get("arrow_release_frame", 6))
			var ms: int = int(bow_t.get("ms_per_frame", 100))
			var flight: float = float(bow_t.get("arrow_flight_sec", BOW_ARROW_FLIGHT_SEC))
			return float(release_frame * ms) / 1000.0 + flight
		_:
			return float(timing("party", "attack").get("hit_ms", 400)) / 1000.0


static func arrow_angle_rad(hand_x: int, hand_y: int, hand2_x: int, hand2_y: int) -> float:
	var grip: Vector2 = Vector2(float(hand_x), float(hand_y))
	var nock: Vector2 = Vector2(float(hand2_x), float(hand2_y))
	return atan2(grip.y - nock.y, grip.x - nock.x)


static func arrow_top_left_in_body(hand2_x: int, hand2_y: int, angle_rad: float) -> Vector2:
	var nock: Vector2 = Vector2(float(hand2_x), float(hand2_y))
	var pivot_world: Vector2 = ARROW_NOCK.rotated(angle_rad)
	return nock - pivot_world


static func weapon_sprite_id_for_item(item_id: String) -> String:
	_ensure_loaded()
	if item_id == "":
		return str(_data.get("bare_hands_sprite_id", "wpn_none"))
	if _item_to_sprite.has(item_id):
		return str(_item_to_sprite[item_id])
	return str(_data.get("bare_hands_sprite_id", "wpn_none"))


static func weapon_family_from_sprite(sprite_id: String) -> String:
	if sprite_id.begins_with("wpn_sword"):
		return "sword"
	if sprite_id.begins_with("wpn_wand"):
		return "wand"
	if sprite_id.begins_with("wpn_bow"):
		return "bow"
	return ""


static func weapon_texture_path(sprite_id: String) -> String:
	_ensure_loaded()
	if sprite_id == "" or sprite_id == "wpn_none":
		return ""
	var pattern: String = str((_data.get("sheet_layout", {}) as Dictionary).get("path_pattern_weapon", ""))
	return pattern.replace("{sprite_id}", sprite_id)


static func weapon_rot_texture_path(sprite_id: String, rot_index: int) -> String:
	return WEAPON_ROT_PATH % [sprite_id, rot_index]


static func weapon_rot_grip_key(sprite_id: String, rot_index: int) -> String:
	return "%s_r%d" % [sprite_id, rot_index]


static func weapon_rot_grip_entry(sprite_id: String, rot_index: int) -> Dictionary:
	_ensure_loaded()
	var key: String = weapon_rot_grip_key(sprite_id, rot_index)
	return (_grip_offsets.get(key, {}) as Dictionary).duplicate()


static func weapon_pivot_for_rot(sprite_id: String, rot_index: int) -> Vector2:
	var entry: Dictionary = weapon_rot_grip_entry(sprite_id, rot_index)
	return Vector2(float(entry.get("gx", 0.0)), float(entry.get("gy", 0.0)))


static func weapon_size_for_rot(sprite_id: String, rot_index: int) -> Vector2:
	var entry: Dictionary = weapon_rot_grip_entry(sprite_id, rot_index)
	return Vector2(float(entry.get("w", 0.0)), float(entry.get("h", 0.0)))


static func weapon_texture_for_rot(sprite_id: String, rot_index: int) -> String:
	var rot_path: String = weapon_rot_texture_path(sprite_id, rot_index)
	if rot_path != "" and ResourceLoader.exists(rot_path):
		return rot_path
	return weapon_texture_path(sprite_id)


## Pre-rotated sprites: node rotation stays 0 (CODE_NOTES.md).
static func weapon_rotation_rad(_rot_index: int) -> float:
	return 0.0


static func body_sprite_offset_in_root() -> Vector2:
	return -FIGHTER_SOLE


static func hand_point_in_root(hand_x: int, hand_y: int) -> Vector2:
	return Vector2(-FIGHTER_SOLE.x + float(hand_x), -FIGHTER_SOLE.y + float(hand_y))


static func weapon_top_left_in_root(
	hand_x: int,
	hand_y: int,
	sprite_id: String,
	rot_index: int,
) -> Vector2:
	return hand_point_in_root(hand_x, hand_y) - weapon_pivot_for_rot(sprite_id, rot_index)


static func weapon_top_left_in_body_texture(
	hand_x: int,
	hand_y: int,
	sprite_id: String,
	rot_index: int,
) -> Vector2:
	return Vector2(float(hand_x), float(hand_y)) - weapon_pivot_for_rot(sprite_id, rot_index)


static func weapon_grip_matches_hand_exact(
	hand_x: int,
	hand_y: int,
	sprite_id: String,
	rot_index: int,
) -> bool:
	var pivot: Vector2 = weapon_pivot_for_rot(sprite_id, rot_index)
	var grip: Vector2 = weapon_top_left_in_root(hand_x, hand_y, sprite_id, rot_index) + pivot
	var hand: Vector2 = hand_point_in_root(hand_x, hand_y)
	return grip.is_equal_approx(hand)


static func contact_cell_size() -> Vector2i:
	var side: int = int(BODY_FRAME.x) + CONTACT_CELL_MARGIN * 2
	return Vector2i(side, side)


static func contact_cell_size_scaled(scale: int) -> Vector2i:
	var base: Vector2i = contact_cell_size()
	return Vector2i(base.x * scale, base.y * scale)


static func craft_weapon_rows_for_contact() -> Array[Dictionary]:
	_ensure_loaded()
	return [
		_row_for_item("stone_sword", "Flintblade"),
		_row_for_item("rootsteel_edge", "Rootsteel"),
		_row_for_item("heartwand", "Heartwand"),
		_row_for_item("thornbow", "Thornbow"),
	]


static func _row_for_item(item_id: String, label: String) -> Dictionary:
	var sprite_id: String = weapon_sprite_id_for_item(item_id)
	return {
		"label": label,
		"item_id": item_id,
		"sprite_id": sprite_id,
		"clip": strike_clip_for_sprite(sprite_id),
	}


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
	return ["attack", "attack_wand", "attack_bow", "cast"]


static func uses_weapon_overlay(actor: String, clip: String) -> bool:
	return clip in clips_with_weapon_overlay(actor) and not hand_anchor(actor, clip, 0).is_empty()
