class_name HubTimePhase
## Hub phase driven by HubDayNightCycle via set_driven_phase01().


static var _driven_phase01: float = 0.0


static func set_driven_phase01(phase01: float) -> void:
	_driven_phase01 = clampf(phase01, 0.0, 1.0)


static func sample_phase01() -> float:
	return _driven_phase01


## 0 in daylight, ramps through dusk, full at night, fades before dawn.
static func firefly_strength(phase01: float) -> float:
	var p: float = fmod(phase01, 1.0)
	if p < 0.0:
		p += 1.0
	if p < 0.32:
		return 0.0
	if p < 0.48:
		return smoothstep(0.32, 0.48, p)
	if p < 0.82:
		return 1.0
	return 1.0 - smoothstep(0.82, 0.98, p)
