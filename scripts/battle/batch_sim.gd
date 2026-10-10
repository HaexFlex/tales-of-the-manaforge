class_name BatchSim
extends RefCounted
## Fixed-seed idle fight batches for sim parity and resolver perf gates.


const _SHEET_UNLOCK: String = "unlock"
const _SHEET_DUO: String = "duo"
const _SALVE_LOADOUT: Dictionary = {"heart_salve": 2}


static func run_batch(sheet: String, depth: int, n: int, base_seed: int) -> Dictionary:
	var wins: int = 0
	var flees: int = 0
	var overwhelmed: int = 0
	for i: int in range(n):
		var room_seed: int = BattleRng.mask_seed(base_seed + i * 7919)
		var room: Array[Dictionary] = SpawnRoller.roll_room(
			depth, SpawnRoller.room_seed_rng(room_seed), false
		)
		var fight: FightState = _fight_for_sheet(sheet, room, room_seed)
		var outcome: String = AutoPolicy.run_idle(fight)
		match outcome:
			"win":
				wins += 1
			"flee":
				flees += 1
			"overwhelmed":
				overwhelmed += 1
			_:
				push_error("BatchSim: unexpected outcome %s" % outcome)
	return {
		"win": _pct(wins, n),
		"flee": _pct(flees, n),
		"overwhelmed": _pct(overwhelmed, n),
		"n": n,
	}


static func _pct(count: int, n: int) -> float:
	if n <= 0:
		return 0.0
	return roundi(float(count) * 1000.0 / float(n)) / 10.0


static func _fight_for_sheet(sheet: String, room: Array[Dictionary], room_seed: int) -> FightState:
	var fight: FightState = FightState.new()
	fight.loadout = _SALVE_LOADOUT.duplicate()
	fight.set_combat_seed(BattleRng.mix_stream(room_seed, "combat"))
	_add_party(fight, sheet)
	for beast_row: Dictionary in room:
		var species: String = str(beast_row.get("beast", ""))
		var slot: int = int(beast_row.get("slot", 0))
		var row: String = str(beast_row.get("row", "front"))
		fight.add_beast(species, slot, row, species)
	return fight


static func _add_party(fight: FightState, sheet: String) -> void:
	var keeper: Dictionary = {
		"might": 11,
		"arcana": 5,
		"resilience": 6,
		"ward": 5,
		"vitality": 6,
		"swiftness": 7,
		"fate": 7,
		"attack": "physical",
	}
	fight.add_member("keeper", keeper, 0, "front", "keeper")
	if sheet == _SHEET_DUO:
		var elaia: Dictionary = {
			"might": 4,
			"arcana": 7,
			"resilience": 5,
			"ward": 7,
			"vitality": 6,
			"swiftness": 6,
			"fate": 5,
			"attack": "magic",
		}
		fight.add_member("elaia", elaia, 1, "back", "elaia")
