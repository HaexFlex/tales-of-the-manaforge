class_name InputBinds
extends RefCounted
## Keyboard shortcuts the game already handles. Missing features (walk keys, map,
## quick save) are not listed here, so Options cannot offer a button for them.

const PATH: String = "user://input_binds.cfg"
const SECTION: String = "keys"

const DEFAULTS: Dictionary = {
	"pause": KEY_ESCAPE,
	"character": KEY_C,
	"inventory": KEY_I,
}

static var _keys: Dictionary = {}
static var _loaded: bool = false


static func ensure() -> void:
	if _loaded:
		return
	_loaded = true
	_keys = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for action: String in DEFAULTS.keys():
		var code: int = int(cfg.get_value(SECTION, action, int(DEFAULTS[action])))
		if code > 0:
			_keys[action] = code as Key


static func keycode(action: String) -> Key:
	ensure()
	return int(_keys.get(action, DEFAULTS.get(action, KEY_NONE))) as Key


static func event_matches(event: InputEvent, action: String) -> bool:
	if not (event is InputEventKey):
		return false
	var key: InputEventKey = event as InputEventKey
	if key.echo or key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return false
	var bound: int = int(keycode(action))
	return int(key.keycode) == bound or int(key.physical_keycode) == bound


static func set_keycode(action: String, code: Key) -> void:
	ensure()
	if not DEFAULTS.has(action) or int(code) <= 0:
		return
	_keys[action] = code
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	for saved: String in _keys.keys():
		cfg.set_value(SECTION, saved, int(_keys[saved]))
	cfg.save(PATH)


static func conflict(action: String, code: Key) -> String:
	ensure()
	for other: String in _keys.keys():
		if other == action:
			continue
		if int(_keys[other]) == int(code):
			return other
	return ""


static func display(code: Key) -> String:
	var text: String = OS.get_keycode_string(code)
	if text == "":
		return "?"
	return text
