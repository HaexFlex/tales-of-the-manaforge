extends RefCounted
## One prepaid crafting batch shared by Forge stations and the workbench.
## Refund and offline catch-up are exact. Offline does not simulate ticks.

const MAX_COUNT: int = 999

var recipe_id: String = ""
var total: int = 0
var done: int = 0
var item_elapsed_s: float = 0.0
var item_time_s: float = 1.0
var paid: Dictionary = {}
var wisps: int = 0


func unfinished() -> int:
	return maxi(0, total - done)


static func refund_qty(unfinished_count: int, per_item: int) -> int:
	## ceil(unfinished * per_item / 2). The item in progress counts as unfinished.
	if unfinished_count <= 0 or per_item <= 0:
		return 0
	var n: int = unfinished_count * per_item
	return int(float(n + 1) / 2.0)


func per_item_cost() -> Dictionary:
	var out: Dictionary = {}
	if total <= 0:
		return out
	for key: Variant in paid.keys():
		out[str(key)] = int(int(paid[key]) / total)
	return out


func refund_map() -> Dictionary:
	var left: int = unfinished()
	var costs: Dictionary = per_item_cost()
	var out: Dictionary = {}
	for key: Variant in costs.keys():
		var mat: String = str(key)
		var qty: int = refund_qty(left, int(costs[mat]))
		if qty > 0:
			out[mat] = qty
	return out


static func catch_up(offline_s: float, speed: float, item_elapsed: float, item_time: float, remaining: int) -> Dictionary:
	## finished = floor((offline_s * speed + item_elapsed) / item_time), clamped to remaining.
	if remaining <= 0 or item_time <= 0.0 or speed <= 0.0 or offline_s <= 0.0:
		return {"finished": 0, "item_elapsed": item_elapsed}
	var work: float = offline_s * speed + item_elapsed
	if work < 0.0:
		work = 0.0
	var finished: int = int(floor(work / item_time))
	if finished < 0:
		finished = 0
	if finished > remaining:
		finished = remaining
	var elapsed: float = work - float(finished) * item_time
	if finished >= remaining or elapsed < 0.0:
		elapsed = 0.0
	return {"finished": finished, "item_elapsed": elapsed}


func to_dict() -> Dictionary:
	return {
		"recipe_id": recipe_id,
		"total": total,
		"done": done,
		"item_elapsed_s": item_elapsed_s,
		"item_time_s": item_time_s,
		"paid": paid.duplicate(true),
		"wisps": wisps,
	}


func read(data: Dictionary) -> void:
	recipe_id = str(data.get("recipe_id", ""))
	total = maxi(0, int(data.get("total", 0)))
	done = clampi(int(data.get("done", 0)), 0, maxi(total, 0))
	item_elapsed_s = maxf(0.0, float(data.get("item_elapsed_s", 0.0)))
	item_time_s = maxf(0.05, float(data.get("item_time_s", data.get("duration", 1.0))))
	var paid_v: Variant = data.get("paid", {})
	paid = (paid_v as Dictionary).duplicate(true) if typeof(paid_v) == TYPE_DICTIONARY else {}
	wisps = maxi(0, int(data.get("wisps", 0)))


func read_legacy(data: Dictionary, per_item: Dictionary, item_time: float, wisp_count: int) -> void:
	## A running Keep-going job is one in-progress item. Its materials were already paid.
	recipe_id = str(data.get("recipe_id", ""))
	total = 1
	done = 0
	item_elapsed_s = maxf(0.0, float(data.get("progress", data.get("item_elapsed_s", 0.0))))
	item_time_s = maxf(0.05, float(data.get("duration", item_time)))
	paid = per_item.duplicate(true)
	wisps = maxi(0, wisp_count)
