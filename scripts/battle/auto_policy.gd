class_name AutoPolicy
extends RefCounted
## Idle Auto and Strike-for-me decisions on the stepwise FightState API. No UI.


static func strike_for_me_action(fight: FightState, actor_id: String) -> Dictionary:
	var targets: Array[String] = fight.legal_targets(actor_id)
	var target: String = targets[0] if targets.size() > 0 else ""
	return {"kind": "strike", "target": target}


static func idle_action(fight: FightState, actor_id: String) -> Dictionary:
	var salve_target: String = _salve_target_id(fight)
	if salve_target != "" and fight.salves_used < 2 and int(fight.loadout.get("heart_salve", 0)) > 0:
		return {"kind": "item", "item": "heart_salve", "target": salve_target}
	return strike_for_me_action(fight, actor_id)


static func should_flee(fight: FightState) -> bool:
	return fight.round > 1 and bool(fight.flee_check().get("should_flee", false))


static func run_idle(fight: FightState) -> String:
	if fight.round == 0:
		fight.start_fight()
	var flee_checked_through: int = 0
	var steps: int = 0
	while fight.outcome() == "":
		if steps >= 10000:
			push_error("AutoPolicy.run_idle: step guard tripped")
			return "flee"
		if flee_checked_through < fight.round:
			if should_flee(fight):
				return "flee"
			flee_checked_through = fight.round
		var actor_id: String = fight.current_actor()
		if actor_id == "":
			break
		var card: Dictionary = fight.fighter_dict(actor_id)
		if str(card.get("side", "")) == "party":
			fight.step(idle_action(fight, actor_id))
		else:
			fight.step()
		steps += 1
	return fight.outcome()


static func _salve_target_id(fight: FightState) -> String:
	var best_id: String = ""
	for fighter_id: String in fight.order:
		var card: Dictionary = fight.fighter_dict(fighter_id)
		if str(card.get("side", "")) != "party":
			continue
		if str(card.get("status", "")) != "active":
			continue
		var hp: int = int(card.get("hp", 0))
		var max_hp: int = int(card.get("max_hp", 0))
		if max_hp <= 0:
			continue
		if hp * 10 >= max_hp * 4:
			continue
		if best_id == "":
			best_id = fighter_id
			continue
		var best: Dictionary = fight.fighter_dict(best_id)
		var best_hp: int = int(best.get("hp", 0))
		var best_max: int = int(best.get("max_hp", 1))
		if hp * best_max < best_hp * max_hp:
			best_id = fighter_id
		elif hp * best_max == best_hp * max_hp:
			var slot: int = int(card.get("slot", 0))
			var best_slot: int = int(best.get("slot", 0))
			if slot < best_slot:
				best_id = fighter_id
	return best_id
