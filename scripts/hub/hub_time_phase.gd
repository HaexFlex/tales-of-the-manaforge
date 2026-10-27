class_name HubTimePhase
## Hub phase driven by HubDayNightCycle via set_driven_phase01().


static var _driven_phase01: float = 0.0

const HUB_AMBIENCE_DAY_CUTOFF_HZ: float = 20000.0
const HUB_AMBIENCE_DUSK_MID_CUTOFF_HZ: float = 6000.0
const HUB_AMBIENCE_NIGHT_CUTOFF_HZ: float = 2500.0
const HUB_AMBIENCE_DAWN_MID_CUTOFF_HZ: float = 6000.0

const _PHASE_DAY_END: float = 0.32
const _PHASE_DUSK_MID: float = 0.40
const _PHASE_DUSK_END: float = 0.48
const _PHASE_NIGHT_END: float = 0.82
const _PHASE_DAWN_MID: float = 0.90
const _PHASE_DAWN_END: float = 0.98


static func set_driven_phase01(phase01: float) -> void:
	_driven_phase01 = clampf(phase01, 0.0, 1.0)


static func sample_phase01() -> float:
	return _driven_phase01


static func wrap_phase01(phase01: float) -> float:
	var p: float = fmod(phase01, 1.0)
	if p < 0.0:
		p += 1.0
	return p


static func _log_lerp_hz(from_hz: float, to_hz: float, t: float) -> float:
	var u: float = clampf(t, 0.0, 1.0)
	if is_equal_approx(from_hz, to_hz):
		return from_hz
	return exp(lerpf(log(from_hz), log(to_hz), u))


## Dusk greeting band (matches firefly ramp).
static func is_dusk_band(phase01: float) -> bool:
	var p: float = wrap_phase01(phase01)
	return p >= 0.32 and p < 0.48


## Dawn greeting band (matches firefly fade).
static func is_dawn_band(phase01: float) -> bool:
	var p: float = wrap_phase01(phase01)
	return p >= 0.82 and p < 0.98


## 0 in daylight, ramps through dusk, full at night, fades before dawn.
static func firefly_strength(phase01: float) -> float:
	var p: float = wrap_phase01(phase01)
	if p < 0.32:
		return 0.0
	if p < 0.48:
		return smoothstep(0.32, 0.48, p)
	if p < 0.82:
		return 1.0
	return 1.0 - smoothstep(0.82, 0.98, p)


## 0 = filter open (day), 1 = darkest (night). Same phase bands as fireflies.
static func hub_ambience_filter_strength(phase01: float) -> float:
	return firefly_strength(phase01)


## Phase-driven hub bed low-pass cutoff (log-Hz segments; same bands as fireflies).
static func hub_ambience_filter_cutoff_hz(phase01: float) -> float:
	var p: float = wrap_phase01(phase01)
	if p < _PHASE_DAY_END:
		return HUB_AMBIENCE_DAY_CUTOFF_HZ
	if p < _PHASE_DUSK_MID:
		var t: float = inverse_lerp(_PHASE_DAY_END, _PHASE_DUSK_MID, p)
		return _log_lerp_hz(HUB_AMBIENCE_DAY_CUTOFF_HZ, HUB_AMBIENCE_DUSK_MID_CUTOFF_HZ, t)
	if p < _PHASE_DUSK_END:
		var t: float = inverse_lerp(_PHASE_DUSK_MID, _PHASE_DUSK_END, p)
		return _log_lerp_hz(HUB_AMBIENCE_DUSK_MID_CUTOFF_HZ, HUB_AMBIENCE_NIGHT_CUTOFF_HZ, t)
	if p < _PHASE_NIGHT_END:
		return HUB_AMBIENCE_NIGHT_CUTOFF_HZ
	if p < _PHASE_DAWN_MID:
		var t: float = inverse_lerp(_PHASE_NIGHT_END, _PHASE_DAWN_MID, p)
		return _log_lerp_hz(HUB_AMBIENCE_NIGHT_CUTOFF_HZ, HUB_AMBIENCE_DAWN_MID_CUTOFF_HZ, t)
	if p < _PHASE_DAWN_END:
		var t: float = inverse_lerp(_PHASE_DAWN_MID, _PHASE_DAWN_END, p)
		return _log_lerp_hz(HUB_AMBIENCE_DAWN_MID_CUTOFF_HZ, HUB_AMBIENCE_DAY_CUTOFF_HZ, t)
	return HUB_AMBIENCE_DAY_CUTOFF_HZ


## Full-night plateau for firefly twinkle SFX (not dusk ramp or pre-dawn fade).
static func firefly_twinkle_night(phase01: float) -> bool:
	var p: float = wrap_phase01(phase01)
	return p >= 0.48 and p < 0.82
