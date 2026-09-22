extends Node
## Echo Chamber session: 30 Essence fee, 1v1 scene, reward snapshot.
## Mid-fight HP is never written. Save is refused while a battle view is open.

const FEE: int = 30
const DATA_PATH: String = "res://data/echo_keeper_01.json"
const BATTLE_SCENE: String = "res://scenes/echo_battle.tscn"

var in_battle: bool = false
var reentry: bool = false
var battle: EchoBattle = null
var _battle_ui: Node = null
var _echo_def: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_def()


func _load_def() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("EchoChamber: missing echo_keeper_01.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_echo_def = parsed


func echo_def() -> Dictionary:
	return _echo_def


func echo_display_name() -> String:
	var labeled: String = ContentStrings.get_text("echo_elaia_name")
	if labeled != "" and labeled != "echo_elaia_name":
		return labeled
	return str(_echo_def.get("display_name", "Elaia"))


func portal_visible() -> bool:
	return GameState.portal_unlocked and not GameState.echo_01_resolved


func try_pay_fee() -> String:
	if not portal_visible():
		return "closed"
	if GameState.portal_fee_paid:
		return "already_paid"
	if GameState.essence < FEE:
		return "reject"
	GameState.add_resource(&"essence", -FEE)
	GameState.portal_fee_paid = true
	GameState.echo_flags_changed.emit()
	return "paid"


func open_battle(already_paid: bool) -> void:
	if in_battle:
		return
	reentry = already_paid
	battle = EchoBattle.new()
	battle.force_crit = -1
	battle.configure(_keeper_totals(), _echo_def)
	in_battle = true
	GameAudio.suspend_hub_for_battle()
	var packed: PackedScene = load(BATTLE_SCENE) as PackedScene
	if packed == null:
		push_error("EchoChamber: battle scene missing")
		in_battle = false
		return
	_battle_ui = packed.instantiate()
	get_tree().root.add_child(_battle_ui)
	get_tree().paused = true


func snapshot_payout(kind: String) -> int:
	var ranks: Dictionary = {}
	for sid: String in EchoBattle.STAT_ORDER:
		ranks[sid] = KeeperStats.get_rank(sid)
	var base: int = int(KeeperStats.params.get("cost_base", 100))
	var growth: float = float(KeeperStats.params.get("cost_growth", 1.65))
	return EchoBattle.payout(kind, ranks, Equipment.total_for("fate"), base, growth)


func apply_outcome(outcome: String) -> Dictionary:
	var shards: int = 0
	if outcome == "spare" or outcome == "defeat":
		shards = snapshot_payout(outcome)
		if shards > 0:
			GameState.add_resource(&"manashards", shards)
		GameState.forge_key = true
		GameState.echo_01_redeemed = outcome == "spare"
		GameState.echo_01_resolved = true
		GameState.portal_fee_paid = false
		if has_node("/root/Equipment"):
			Equipment.ensure_forge_key_equipped()
	elif outcome == "ko":
		GameState.portal_fee_paid = false
	GameState.echo_flags_changed.emit()
	return {"outcome": outcome, "shards": shards}


func finish_battle(outcome: String) -> void:
	apply_outcome(outcome)
	_teardown_view()
	_wake_at_tree()
	GameAudio.resume_hub_after_battle()
	if get_tree() != null:
		get_tree().paused = GameState.fruit_committed
	SaveService.save_game()


func dismiss_battle_without_reward() -> void:
	## Load / new game / quit abandon the fight. Disk state is the flee-equivalent.
	_teardown_view()
	GameAudio.resume_hub_after_battle()
	if get_tree() != null:
		get_tree().paused = GameState.fruit_committed


func _teardown_view() -> void:
	in_battle = false
	reentry = false
	battle = null
	if _battle_ui != null and is_instance_valid(_battle_ui):
		_battle_ui.queue_free()
	_battle_ui = null


func _wake_at_tree() -> void:
	var trees: Array[Node] = get_tree().get_nodes_in_group("manatree")
	var keepers: Array[Node] = get_tree().get_nodes_in_group("keeper")
	if trees.is_empty() or keepers.is_empty():
		return
	var tree: Node2D = trees[0] as Node2D
	var keeper: Node = keepers[0]
	if tree == null or keeper == null:
		return
	var dest: Vector2 = tree.global_position + Vector2(0, 48)
	if keeper is Node2D:
		(keeper as Node2D).global_position = dest
	if keeper.has_method("halt"):
		keeper.call("halt")
	var mains: Array[Node] = get_tree().get_nodes_in_group("main_root")
	if not mains.is_empty() and mains[0].has_method("focus_manatree"):
		mains[0].call("focus_manatree")


func _keeper_totals() -> Dictionary:
	return {
		"might": Equipment.total_for("might"),
		"arcana": Equipment.total_for("arcana"),
		"resilience": Equipment.total_for("resilience"),
		"ward": Equipment.total_for("ward"),
		"vitality": Equipment.total_for("vitality"),
		"swiftness": Equipment.total_for("swiftness"),
		"fate": Equipment.total_for("fate"),
	}
