extends Node
## Content string table from data/strings_v01.json (CONTENT_STRINGS_V01).

var _table: Dictionary = {}


func _ready() -> void:
	var file := FileAccess.open("res://data/strings_v01.json", FileAccess.READ)
	if file == null:
		push_error("ContentStrings: missing strings_v01.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_table = parsed


func get_text(key: String, tokens: Dictionary = {}) -> String:
	var raw: String = str(_table.get(key, key))
	for t: Variant in tokens.keys():
		raw = raw.replace("{%s}" % str(t), str(tokens[t]))
	return raw
