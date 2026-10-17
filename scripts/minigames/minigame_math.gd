class_name MinigameMath
extends RefCounted
## Payout clock. A perfect minute adds perfect_bonus seconds on top of the
## minute already worked, which is a 3× pace. The readout never goes past that.

const PERFECT_BONUS_PER_MIN: float = 120.0
const PACE_CEILING: float = 3.0


static func k_from_r(inputs_per_minute: float) -> float:
	if inputs_per_minute <= 0.0:
		return 0.0
	return PERFECT_BONUS_PER_MIN / inputs_per_minute


static func pace_multiplier(bonus_seconds: float, elapsed: float) -> float:
	if elapsed <= 0.0001 or bonus_seconds <= 0.0:
		return 1.0
	return minf(PACE_CEILING, 1.0 + bonus_seconds / elapsed)


static func woodsong_k(heavy: bool, inputs_per_minute: float, heavy_every: int, heavy_mult: float) -> float:
	## Heavy beats pay heavy_mult times a normal beat. Normal k is tuned so the
	## average beat still pays k_from_r (a perfect minute stays +120s).
	var every: int = maxi(heavy_every, 1)
	var mult: float = maxf(heavy_mult, 1.0)
	var avg: float = k_from_r(inputs_per_minute)
	var parts: float = float(every - 1) + mult
	var normal: float = avg * float(every) / parts
	if heavy:
		return normal * mult
	return normal


static func grain_round_seconds(curvy: bool, phone: bool, straight_sec: float, curvy_phone_sec: float) -> float:
	if phone and curvy:
		return curvy_phone_sec
	return straight_sec


static func grain_k(average_round_sec: float) -> float:
	## k = 120 / r and r = 60 / average round, so k = 2 × the average round.
	if average_round_sec <= 0.0:
		return 0.0
	return k_from_r(60.0 / average_round_sec)
