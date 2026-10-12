class_name Pack
extends RefCounted
## Cleared-room loot holder until the slot engine banks it (job 23b).


var items: Dictionary = {}


func add(item_id: String, n: int) -> void:
	if n <= 0 or item_id == "":
		return
	if item_id == "essence" or item_id == "exp":
		push_warning("Pack cannot hold %s" % item_id)
		return
	var cur: int = int(items.get(item_id, 0))
	var new_count: int = cur + n
	if new_count <= 0:
		items.erase(item_id)
	else:
		items[item_id] = new_count


func add_all(loot: Dictionary) -> void:
	for k: Variant in loot.keys():
		add(str(k), int(loot[k]))


func count(item_id: String) -> int:
	return int(items.get(item_id, 0))


func total() -> int:
	var sum: int = 0
	for v: Variant in items.values():
		sum += int(v)
	return sum


func is_empty() -> bool:
	return items.is_empty()


func clear() -> void:
	items.clear()


func halve() -> Dictionary:
	var lost: Dictionary = {}
	var keys: Array = items.keys()
	for k: Variant in keys:
		var item_id: String = str(k)
		var n: int = int(items[item_id])
		var keep: int = int(n / 2)
		var drop: int = n - keep
		if drop > 0:
			lost[item_id] = drop
		if keep > 0:
			items[item_id] = keep
		else:
			items.erase(item_id)
	return lost


func banked_share(pct: int) -> Dictionary:
	if pct != 100 and pct != 50 and pct != 0:
		push_error("Pack.banked_share: invalid pct %d" % pct)
		return {}
	var out: Dictionary = {}
	for k: Variant in items.keys():
		var item_id: String = str(k)
		var n: int = int(items[item_id])
		var share: int = 0
		if pct == 100:
			share = n
		elif pct == 50:
			share = int(n / 2)
		if share > 0:
			out[item_id] = share
	return out


func bank(pct: int) -> Dictionary:
	return _bank_real(pct)


func _bank_real(pct: int) -> Dictionary:
	var banked: Dictionary = banked_share(pct)
	var tree_root: Window = Engine.get_main_loop().root as Window
	var game_state: Node = tree_root.get_node_or_null("GameState")
	var backpack: Node = tree_root.get_node_or_null("Backpack")
	for k: Variant in banked.keys():
		var item_id: String = str(k)
		var n: int = int(banked[item_id])
		if n <= 0:
			continue
		if item_id == "wood" or item_id == "stone" or item_id == "food":
			if game_state != null:
				game_state.call("add_resource", StringName(item_id), n)
		else:
			if backpack == null:
				continue
			if not bool(backpack.call("is_known_item", item_id)):
				push_error("Pack.bank: unknown item %s" % item_id)
				continue
			backpack.call("add_item", item_id, n)
	clear()
	return banked


func to_dict() -> Dictionary:
	var copy: Dictionary = {}
	for k: Variant in items.keys():
		copy[str(k)] = int(items[k])
	return {"items": copy}


static func from_dict(d: Dictionary) -> Pack:
	var p: Pack = Pack.new()
	var raw: Variant = d.get("items", {})
	if raw is Dictionary:
		for k: Variant in (raw as Dictionary).keys():
			p.items[str(k)] = int((raw as Dictionary)[k])
	return p
