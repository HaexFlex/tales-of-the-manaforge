class_name TreeWhispers
extends RefCounted
## Manatree ambient lines: shuffle bag per unlocked stage tier, no repeat until exhausted.

const INTERVAL_SEC: float = 1200.0

const STAGE_ORDER: Array[StringName] = [
	&"sapling", &"young", &"mature", &"elder", &"ancient"
]

const ALL_KEYS: Array[String] = [
	"tree_whisper_01_s1",
	"tree_whisper_02_s1",
	"tree_whisper_03_s1",
	"tree_whisper_04_s2",
	"tree_whisper_05_s2",
	"tree_whisper_06_s2",
	"tree_whisper_07_s3",
	"tree_whisper_08_s3",
	"tree_whisper_09_s4",
	"tree_whisper_10_s4",
	"tree_whisper_11_s5",
	"tree_whisper_12_s5",
]


static func min_stage_for_key(key: String) -> int:
	var marker: int = key.rfind("_s")
	if marker < 0:
		return 99
	return int(key.substr(marker + 2))


static func stage_level(stage_id: StringName) -> int:
	var idx: int = STAGE_ORDER.find(stage_id)
	if idx < 0:
		return 1
	return idx + 1


static func unlocked_keys_for_stage(stage_id: StringName) -> Array[String]:
	var level: int = stage_level(stage_id)
	var out: Array[String] = []
	for key: String in ALL_KEYS:
		if min_stage_for_key(key) <= level:
			out.append(key)
	return out


static func prune_bag(bag: Array, stage_id: StringName) -> void:
	var allowed: Dictionary = {}
	for key: String in unlocked_keys_for_stage(stage_id):
		allowed[key] = true
	var i: int = bag.size() - 1
	while i >= 0:
		if not allowed.has(str(bag[i])):
			bag.remove_at(i)
		i -= 1


static func refill_bag(bag: Array, stage_id: StringName) -> void:
	var fresh: Array[String] = unlocked_keys_for_stage(stage_id)
	fresh.shuffle()
	bag.clear()
	for key: String in fresh:
		bag.append(key)


static func draw_key(bag: Array, stage_id: StringName) -> String:
	prune_bag(bag, stage_id)
	if bag.is_empty():
		refill_bag(bag, stage_id)
	if bag.is_empty():
		return ""
	var key: String = str(bag.pop_back())
	return key
