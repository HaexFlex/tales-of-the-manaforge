class_name BattleResolver
extends RefCounted
## One strike of BATTLE_SCENE_DRAFT v4 §4. No turn loop, no statuses beyond
## the HP threshold, no log. Damage stays integer: multipliers are rationals
## and half-up is floor((2 * raw * num + den) / (2 * den)).
##
## Dice, in order: attack 2d6, defense 2d6, the damage die only if the blow
## landed, then a Fate roll 0–99 only if it landed and Fate > 0. A crit is
## that roll < Fate, applied as ×2 after rounding (it stacks with crushing).
## A miss rolls neither the damage die nor Fate. Beasts have Fate 0, so they
## roll no Fate die. HP is not clamped; a killing blow may leave it negative.


const HP_BASE: int = 10
const HP_PER_VITALITY: int = 3


static func max_hp_for(vitality: int) -> int:
	return HP_BASE + HP_PER_VITALITY * vitality


static func status_for(side: String, hp: int, max_hp: int) -> String:
	## 10% or below, all integer: hp * 10 <= max_hp. Party is knocked out.
	## Beasts are Calmed. Never slain.
	if hp * 10 <= max_hp:
		if side == "party":
			return "ko"
		return "calmed"
	return "active"


static func die_size(offense: int) -> int:
	## max(4, ceil(offense / 2)), then up to a real die:
	## 1–8 d4, 9–12 d6, 13–16 d8, 17–20 d10, 21–24 d12, 25–40 d20.
	## 41 and up stay on d(ceil(offense / 2)).
	var halved: int = 0
	if offense > 0:
		halved = (offense + 1) / 2
	var base: int = maxi(4, halved)
	if base <= 4:
		return 4
	if base <= 6:
		return 6
	if base <= 8:
		return 8
	if base <= 10:
		return 10
	if base <= 12:
		return 12
	if base <= 20:
		return 20
	return base


static func round_half_up(raw: int, num: int, den: int) -> int:
	## floor((2 * raw * num + den) / (2 * den)). Half goes up. raw >= 0.
	var d: int = den if den > 0 else 1
	return int((2 * raw * num + d) / (2 * d))


static func round_half_up_number(x: float) -> int:
	## Float form of the same half-up rule, for the exported rounding table.
	## Strike damage does not call this.
	return floori(x + 0.5)


static func resolve(attacker: Dictionary, defender: Dictionary, to_hit_mod: int, tel_num: int, tel_den: int, dice: BattleRng) -> Dictionary:
	var magic: bool = str(attacker.get("attack", "physical")) == "magic"
	var offense: int = int(attacker.get("arcana", 0)) if magic else int(attacker.get("might", 0))
	var soak: int = int(defender.get("ward", 0)) if magic else int(defender.get("resilience", 0))
	var guard: int = soak
	var swift: int = int(defender.get("swiftness", 0))
	var attack_total: int = dice.roll_die(6) + dice.roll_die(6) + offense + to_hit_mod
	var defense_total: int = dice.roll_die(6) + dice.roll_die(6) + int((guard + swift) / 2)
	var margin: int = attack_total - defense_total
	var band: String = "miss"
	var mult_num: int = 0
	var mult_den: int = 1
	if margin < 0:
		band = "miss"
	elif margin <= 2:
		band = "graze"
		mult_num = 1
		mult_den = 2
	elif margin <= 5:
		band = "hit"
		mult_num = 1
		mult_den = 1
	else:
		band = "crush"
		mult_num = 2
		mult_den = 1
	var damage: int = 0
	var fate_crit: bool = false
	var hp: int = int(defender.get("hp", 0))
	if band != "miss":
		var face: int = dice.roll_die(die_size(offense))
		var raw: int = face + offense - int(soak / 2)
		if raw < 1:
			raw = 1
		var den: int = tel_den if tel_den > 0 else 1
		damage = maxi(1, round_half_up(raw, mult_num * tel_num, mult_den * den))
		var fate: int = int(attacker.get("fate", 0))
		if fate > 0:
			var fate_roll: int = dice.roll_fate()
			if fate_roll < fate:
				fate_crit = true
				damage *= 2
		hp -= damage
	var side: String = str(defender.get("side", "beast"))
	var max_hp: int = int(defender.get("max_hp", 0))
	return {
		"attack_total": attack_total,
		"defense_total": defense_total,
		"margin": margin,
		"band": band,
		"damage": damage,
		"fate_crit": fate_crit,
		"defender_hp_after": hp,
		"defender_status": status_for(side, hp, max_hp),
	}
