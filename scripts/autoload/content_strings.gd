extends Node
## Content string table from data/strings_v01.json (CONTENT_STRINGS_V01).
## Away-panel copy is overlaid from data/offline_summary_v2_FINAL.json (Lore FINAL).

const OFFLINE_SUMMARY_FINAL: String = "res://data/offline_summary_v2_FINAL.json"
const SPRINT_R3_LORE_DRAFT: String = "res://data/sprint_r3_lore_DRAFT_v1.json"

var _table: Dictionary = {}
var _touch: Dictionary = {}


func _ready() -> void:
	var file := FileAccess.open("res://data/strings_v01.json", FileAccess.READ)
	if file == null:
		push_error("ContentStrings: missing strings_v01.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		var root: Dictionary = parsed as Dictionary
		if root.has("touch") and typeof(root["touch"]) == TYPE_DICTIONARY:
			_touch = root["touch"] as Dictionary
		_table = root.duplicate(true)
		_table.erase("touch")
	_merge_offline_summary_final()
	_merge_sprint_r3_lore_draft()


func _merge_sprint_r3_lore_draft() -> void:
	var lore_file := FileAccess.open(SPRINT_R3_LORE_DRAFT, FileAccess.READ)
	if lore_file == null:
		push_error("ContentStrings: missing %s" % SPRINT_R3_LORE_DRAFT)
		return
	var lore_parsed: Variant = JSON.parse_string(lore_file.get_as_text())
	lore_file.close()
	if typeof(lore_parsed) != TYPE_DICTIONARY:
		push_error("ContentStrings: %s did not parse" % SPRINT_R3_LORE_DRAFT)
		return
	for key_v: Variant in (lore_parsed as Dictionary).keys():
		var key: String = str(key_v)
		if key.begins_with("_"):
			continue
		_table[key] = (lore_parsed as Dictionary)[key_v]


func random_bench_saying() -> String:
	var idx: int = randi_range(1, 10)
	return get_text("bench_saying_%02d" % idx)


func _merge_offline_summary_final() -> void:
	var final_file := FileAccess.open(OFFLINE_SUMMARY_FINAL, FileAccess.READ)
	if final_file == null:
		push_error("ContentStrings: missing %s" % OFFLINE_SUMMARY_FINAL)
		return
	var final_parsed: Variant = JSON.parse_string(final_file.get_as_text())
	final_file.close()
	if typeof(final_parsed) != TYPE_DICTIONARY:
		push_error("ContentStrings: %s did not parse" % OFFLINE_SUMMARY_FINAL)
		return
	for key_v: Variant in (final_parsed as Dictionary).keys():
		_table[str(key_v)] = (final_parsed as Dictionary)[key_v]


func get_text(key: String, tokens: Dictionary = {}) -> String:
	var raw: String
	if _touch_mode() and _touch.has(key):
		raw = str(_touch[key])
	else:
		raw = str(_table.get(key, key))
	for t: Variant in tokens.keys():
		raw = raw.replace("{%s}" % str(t), str(tokens[t]))
	return raw


func _touch_mode() -> bool:
	if not has_node("/root/GameInput"):
		return false
	return GameInput.touch_mode()
