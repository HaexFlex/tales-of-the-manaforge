extends Node

const DATA_PATH: String = "res://data/companion_sheets.json"

var _sheets: Dictionary = {}


func _ready() -> void:
	_load()


func _load() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("CompanionSheets: missing companion_sheets.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_sheets = (parsed as Dictionary).duplicate(true)


func has_actor(actor: String) -> bool:
	return _sheets.has(actor)


func base_stats(actor: String) -> Dictionary:
	var row: Variant = _sheets.get(actor, {})
	return row if typeof(row) == TYPE_DICTIONARY else {}


func attack_kind(actor: String) -> String:
	return str(base_stats(actor).get("attack", "physical"))


func abilities(actor: String) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = base_stats(actor).get("abilities", [])
	if raw is Array:
		for a: Variant in raw as Array:
			var id: String = str(a).strip_edges()
			if id != "":
				out.append(id)
	return out
