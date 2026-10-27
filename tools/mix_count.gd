extends SceneTree
# Usage: godot --headless --path <project> -s res://tools/mix_count.gd
func _init() -> void:
	var line := ""
	for d in [1,2,3,5,6,8,12,15,20,25]:
		var seen := {}
		for s in range(200):
			var room: Array = SpawnRoller.roll_room(d, SpawnRoller.room_seed_rng(d * 100003 + s))
			var ids: Array = []
			for r in room: ids.append(str(r.get("beast", r.get("id", "?"))))
			ids.sort()
			seen[",".join(ids)] = true
		line += "D%d %d  " % [d, seen.size()]
	print("MIXES: ", line)
	quit()
