class_name HubWispPhaseGreetings
## First Wisp select per Dusk/Dawn band shows one random greeting line (DRAFT v1).

const _DUSK_COUNT: int = 6
const _DAWN_COUNT: int = 6

static var _in_dusk: bool = false
static var _in_dawn: bool = false
static var _dusk_shown: bool = true
static var _dawn_shown: bool = true


static func reset_for_tests() -> void:
	_in_dusk = false
	_in_dawn = false
	_dusk_shown = true
	_dawn_shown = true


static func track_phase(phase01: float) -> void:
	var dusk: bool = HubTimePhase.is_dusk_band(phase01)
	var dawn: bool = HubTimePhase.is_dawn_band(phase01)
	if dusk and not _in_dusk:
		_dusk_shown = false
	if dawn and not _in_dawn:
		_dawn_shown = false
	_in_dusk = dusk
	_in_dawn = dawn


static func try_greeting(phase01: float) -> String:
	track_phase(phase01)
	if HubTimePhase.is_dusk_band(phase01) and not _dusk_shown:
		_dusk_shown = true
		return _line_for_key(_pick_key(&"wisp_dusk_", _DUSK_COUNT))
	if HubTimePhase.is_dawn_band(phase01) and not _dawn_shown:
		_dawn_shown = true
		return _line_for_key(_pick_key(&"wisp_dawn_", _DAWN_COUNT))
	return ""


static func _line_for_key(key: String) -> String:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	if loop == null:
		return key
	var cs: Node = loop.root.get_node_or_null("ContentStrings")
	if cs == null:
		return key
	return str(cs.call("get_text", key))


static func _pick_key(prefix: StringName, count: int) -> String:
	var slot: int = randi_range(1, count)
	return "%s%02d" % [String(prefix), slot]
