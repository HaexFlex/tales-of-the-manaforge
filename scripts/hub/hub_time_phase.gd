class_name HubTimePhase
## Hub phase driven by HubDayNightCycle via set_driven_phase01() when that sprint lands.
## Until then phase01 stays 0 (daylight) unless tests set it.


static var _driven_phase01: float = 0.0


static func set_driven_phase01(phase01: float) -> void:
	_driven_phase01 = clampf(phase01, 0.0, 1.0)


static func sample_phase01() -> float:
	return _driven_phase01


static func wrap_phase01(phase01: float) -> float:
	var p: float = fmod(phase01, 1.0)
	if p < 0.0:
		p += 1.0
	return p


static func is_dusk_band(phase01: float) -> bool:
	var p: float = wrap_phase01(phase01)
	return p >= 0.32 and p < 0.48


static func is_night_band(phase01: float) -> bool:
	var p: float = wrap_phase01(phase01)
	return p >= 0.48 and p < 0.82


static func is_dusk() -> bool:
	return is_dusk_band(sample_phase01())


static func is_night() -> bool:
	return is_night_band(sample_phase01())


static func is_dusk_or_night() -> bool:
	var p: float = wrap_phase01(sample_phase01())
	return p >= 0.32 and p < 0.82
