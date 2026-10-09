extends Node
## Echo Chamber session: 30 Essence fee, 1v1 scene, reward snapshot.
## Mid-fight HP is never written. Save is refused while a battle view is open.

const FEE: int = 30
const BRAMBLE_FEE: int = 50
const DATA_PATH: String = "res://data/echo_keeper_01.json"
const BRAMBLE_PATH: String = "res://data/echo_bramble_02.json"
const BATTLE_SCENE: String = "res://scenes/echo_battle.tscn"
const FORGE_WEAPONS: PackedStringArray = ["rootsteel_edge", "heartwand", "switchshaft"]

var in_battle: bool = false
var reentry: bool = false
## "" and "echo1" are Elaia. "echo2" is Bramble.
var battle_context: String = ""
var battle: EchoBattle = null
var _battle_ui: Node = null
var _echo_def: Dictionary = {}
var _bramble_def: Dictionary = {}


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
	var bramble := FileAccess.open(BRAMBLE_PATH, FileAccess.READ)
	if bramble == null:
		push_error("EchoChamber: missing echo_bramble_02.json")
		return
	var bramble_parsed: Variant = JSON.parse_string(bramble.get_as_text())
	bramble.close()
	if typeof(bramble_parsed) == TYPE_DICTIONARY:
		_bramble_def = bramble_parsed


func echo_def() -> Dictionary:
	return _echo_def


func bramble_def() -> Dictionary:
	return _bramble_def


func owns_anvil_weapon() -> bool:
	if not has_node("/root/Equipment"):
		return false
	for item_id: String in FORGE_WEAPONS:
		if Equipment.owns_anywhere(item_id):
			return true
	return false


func bramble_gate_open() -> bool:
	return owns_anvil_weapon() and not GameState.echo_02_resolved


func try_pay_bramble() -> String:
	if not bramble_gate_open():
		return "closed"
	if GameState.echo_02_fee_paid:
		return "already_paid"
	if GameState.essence < BRAMBLE_FEE:
		return "reject"
	GameState.add_resource(&"essence", -BRAMBLE_FEE)
	GameState.echo_02_fee_paid = true
	GameState.echo_flags_changed.emit()
	return "paid"


func echo_display_name() -> String:
	var labeled: String = ContentStrings.get_text("echo_elaia_name")
	if labeled != "" and labeled != "echo_elaia_name":
		return labeled
	return str(_echo_def.get("display_name", "Elaia"))


func portal_visible() -> bool:
	## Elaia's half of the hub portal. Use hub_portal_context() for the arch itself.
	return GameState.portal_unlocked and not GameState.echo_01_resolved


func hub_portal_context() -> String:
	## Which Echo the hub portal arch opens right now. One arch serves both:
	## "echo1" while Elaia is unresolved, then "echo2" once the first Anvil weapon
	## exists and Bramble is unresolved. "" hides the arch (and its walk box).
	if portal_visible():
		return "echo1"
	if GameState.echo_01_resolved and bramble_gate_open():
		return "echo2"
	return ""


func hub_portal_open() -> bool:
	return hub_portal_context() != ""


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
	open_context(_echo_def, "echo1", _keeper_totals(), Equipment.equipped_strike_kind(), already_paid)


func open_bramble(already_paid: bool) -> void:
	var def: Dictionary = _bramble_def.duplicate(true)
	var labeled: String = ContentStrings.get_text("bramble_name")
	if labeled != "" and labeled != "bramble_name":
		def["display_name"] = labeled
	open_context(def, "echo2", _keeper_totals(), Equipment.equipped_strike_kind(), already_paid)


func open_context(def: Dictionary, context: String, totals: Dictionary, strike_kind: String, already_paid: bool) -> void:
	if in_battle:
		return
	battle_context = context
	reentry = already_paid
	battle = EchoBattle.new()
	battle.force_crit = -1
	battle.configure(totals, def)
	battle.strike_kind = strike_kind if strike_kind != "" else "physical"
	battle.arrow_mode = "magical" if GameState.arrow_mode == "magical" else "physical"
	in_battle = true
	GameAudio.suspend_hub_for_battle()
	var packed: PackedScene = load(BATTLE_SCENE) as PackedScene
	if packed == null:
		push_error("EchoChamber: battle scene missing")
		in_battle = false
		battle_context = ""
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
	var fate_total: int = Equipment.total_for("fate")
	if battle != null:
		fate_total = battle.keeper_fate()
	return EchoBattle.payout(kind, ranks, fate_total, base, growth)


func apply_outcome(outcome: String) -> Dictionary:
	var ctx: String = battle_context
	battle_context = ""
	if ctx == "echo2":
		return _apply_bramble(outcome)
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


func _apply_bramble(outcome: String) -> Dictionary:
	if outcome == "spare" or outcome == "defeat":
		GameState.echo_02_resolved = true
		GameState.echo_02_fee_paid = false
		GameState.echo_02_outcome = outcome
		var toast_key: String = "adventure_echo2_toast_spare" if outcome == "spare" else "adventure_echo2_toast_defeat"
		var scar_key: String = "adventure_scar_spare" if outcome == "spare" else "adventure_scar_defeat"
		GameState.status_message.emit(ContentStrings.get_text(toast_key))
		GameState.status_message.emit(ContentStrings.get_text("path_east_open_toast"))
		GameState.status_message.emit(ContentStrings.get_text(scar_key))
	elif outcome == "ko":
		GameState.echo_02_fee_paid = false
		GameState.echo_02_outcome = "ko"
	elif outcome == "flee":
		GameState.echo_02_outcome = "flee"
	GameState.echo_flags_changed.emit()
	return {"outcome": outcome, "shards": 0}


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
	if battle_context == "echo2" and GameState.echo_02_fee_paid and not GameState.echo_02_resolved:
		GameState.echo_02_outcome = "flee"
		GameState.echo_flags_changed.emit()
	battle_context = ""
	_teardown_view()
	GameAudio.resume_hub_after_battle()
	if get_tree() != null:
		get_tree().paused = GameState.fruit_committed


func _teardown_view() -> void:
	in_battle = false
	reentry = false
	battle = null
	battle_context = ""
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
