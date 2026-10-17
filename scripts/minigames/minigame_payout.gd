class_name MinigamePayout
extends RefCounted
## Turns one success into seconds of the played worker's current yield.
## Wisps are refused. Tender's Knack is not applied: Design said no upgrades.


static func grant(worker: String, game_id: String, target_id: String, k_seconds: float) -> Dictionary:
	if worker != "keeper" and worker != "elaia":
		return {"ok": false, "reason": "wisp", "applied": 0.0}
	if k_seconds <= 0.0:
		return {"ok": false, "reason": "empty", "applied": 0.0}
	var kind: String = MinigameCatalog.kind(game_id)
	if kind == "gather":
		var row: Dictionary = GameState.grant_played_gather_seconds(worker, StringName(MinigameCatalog.resource_id(game_id)), k_seconds)
		row["applied"] = k_seconds if bool(row.get("ok", false)) else 0.0
		return row
	if kind == "water":
		var water: Dictionary = GameState.grant_played_water_seconds(worker, k_seconds)
		water["applied"] = k_seconds if bool(water.get("ok", false)) else 0.0
		return water
	if kind == "station":
		return ForgeJobs.grant_played_job_seconds(target_id, worker, k_seconds)
	return {"ok": false, "reason": "game", "applied": 0.0}
