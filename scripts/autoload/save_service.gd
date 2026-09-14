extends Node
## Versioned save/load to user://manaforge_save.json (SYSTEMS_V01 schema).

signal save_completed(ok: bool)
signal load_completed(ok: bool)

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://manaforge_save.json"


func save_game() -> bool:
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"state": GameState.to_save_dict(),
	}
	var json_text: String = JSON.stringify(payload, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: write failed %s err=%s" % [SAVE_PATH, FileAccess.get_open_error()])
		save_completed.emit(false)
		return false
	file.store_string(json_text)
	file.close()
	save_completed.emit(true)
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		load_completed.emit(false)
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		load_completed.emit(false)
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		load_completed.emit(false)
		return false
	var root: Dictionary = parsed
	var version: int = int(root.get("save_version", 0))
	if version > SAVE_VERSION:
		push_error("SaveService: save v%d newer than %d" % [version, SAVE_VERSION])
		load_completed.emit(false)
		return false
	var state: Variant = root.get("state", {})
	if typeof(state) != TYPE_DICTIONARY:
		load_completed.emit(false)
		return false
	GameState.apply_save_dict(_migrate(version, state as Dictionary))
	load_completed.emit(true)
	return true


func _migrate(_from_version: int, state: Dictionary) -> Dictionary:
	return state.duplicate(true)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
