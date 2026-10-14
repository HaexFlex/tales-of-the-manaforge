class_name AssetsExtra
extends RefCounted
## Paths under res://assets_extra/ (see assets_extra/ASSETS_EXTRA.md).

const ROOT: String = "res://assets_extra/"
const BATTLE: String = ROOT + "battle/"
const BOARD: String = ROOT + "board/"
const SHARED: String = ROOT + "shared/"
const HUD: String = ROOT + "hud/"


static func tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var full: String = path if path.begins_with("res://") else ROOT + path
	if not ResourceLoader.exists(full):
		return null
	return load(full) as Texture2D


static func battle_tex(file_name: String) -> Texture2D:
	for prefix: String in [BATTLE, SHARED, "res://assets/art/battle/ui/"]:
		var p: String = prefix + file_name
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
	return null


static func board_tex(file_name: String) -> Texture2D:
	var extra: String = BOARD + file_name
	if ResourceLoader.exists(extra):
		return load(extra) as Texture2D
	var legacy: String = "res://assets/art/ui/board/" + file_name
	if ResourceLoader.exists(legacy):
		return load(legacy) as Texture2D
	return null
