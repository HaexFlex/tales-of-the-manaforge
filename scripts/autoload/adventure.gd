extends Node
## Adventure Phase 0. Echo 2, timed reaches, crates, herbs, Heart Salve and Bile Vial.
## Open-game time only. Ancient pauses the route. Ascend wipes crates, herbs, and potions.

signal adventure_changed

const DATA_PATH: String = "res://data/adventure.json"
const CORVANE_PATH: String = "res://data/echo_corvane.json"
const ECHO2_FEE: int = 50
const IDLE_REACH_SEC: float = 720.0
const MANUAL_REACH_SEC: float = 240.0
const JOIN_REACHES: int = 20
const HERB_REACH: int = 6
const HERB_CHANCE: float = 0.30
const SUCCESS_ESSENCE: int = 3
const PRIMARY_MIN: int = 8
const PRIMARY_MAX: int = 12
const SECONDARY_MIN: int = 2
const SECONDARY_MAX: int = 4
const POTION_CAP: int = 5
const HERB_CRAFT: int = 3
const POTION_ESSENCE: int = 10
const SALVE_HEAL: int = 25
const BILE_DAMAGE: int = 15
const SALVE_HP_FRACTION: float = 0.40
const THREAT_POWER: int = 28
const SCRAPE_RATIO: float = 0.75
const IDLE_DAMAGE_SUCCESS: int = 8
const IDLE_DAMAGE_SCRAPE: int = 22
const IDLE_DAMAGE_FAIL: int = 36
const FORGE_WEAPONS: PackedStringArray = PackedStringArray([
	"rootsteel_edge", "heartwand", "switchshaft",
])
const RAW_IDS: PackedStringArray = PackedStringArray(["wood", "stone", "food"])
const RAW_WEIGHTS: PackedInt32Array = PackedInt32Array([1, 1, 1])
const ART_CORVANE_PORTRAIT: String = "res://assets/art/portraits/corvane_portrait.png"
const ART_CORVANE_SHEET: String = "res://assets/art/portraits/corvane_portrait_sheet.png"
const ART_CORVANE_BATTLE: String = "res://assets/art/echo/battle_corvane_idle.png"
const ART_BREWING_STAND: String = "res://assets/art/props/brewing_stand.png"
const ART_GLOWCAP: String = "res://assets/art/ui/icon_glowcap.png"
const ART_BITTERROOT: String = "res://assets/art/ui/icon_bitterroot.png"
const ART_HEART_SALVE: String = "res://assets/art/ui/icon_heart_salve.png"
const ART_BILE_VIAL: String = "res://assets/art/ui/icon_bile_vial.png"
const BREWING_STAND_POS: Vector2 = Vector2(2420, 2220)

var adventure_unlocked: bool = false
var corvane_outcome: String = ""
var corvane_promised: bool = false
var corvane_joined: bool = false
var brewing_unlocked: bool = false
var echo2_fee_paid: bool = false
var echo2_resolved: bool = false
var cumulative_reaches: int = 0
var reach_active: bool = false
var awaiting_manual: bool = false
var reach_mode: String = "idle"
var reach_elapsed: float = 0.0
var reach_party: Array[String] = []
var selected_party: Array[String] = ["keeper"]
var crates: Array[Dictionary] = []
var herbs: Dictionary = {"glowcap": 0, "bitterroot": 0}
var potions: Dictionary = {"heart_salve": 0, "bile_vial": 0}
var party_hp: int = 0
var party_max_hp: int = 0
## Headless tests set this false so a finished manual reach does not open the battle scene.
var present_battles: bool = true
var _corvane_def: Dictionary = {}
var _reach_foe_def: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _panel: Node = null
var _ui_ready: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	_load_tables()
	call_deferred("_ensure_panel")


func _process(delta: float) -> void:
	advance_open_time(delta)
	if _panel != null and is_instance_valid(_panel) and _panel.has_method("sync"):
		_panel.call("sync")


func _load_tables() -> void:
	var adv: Variant = _read_json(DATA_PATH)
	if typeof(adv) == TYPE_DICTIONARY:
		var foe: Variant = (adv as Dictionary).get("reach_foe", {})
		if typeof(foe) == TYPE_DICTIONARY:
			_reach_foe_def = (foe as Dictionary).duplicate(true)
	var corv: Variant = _read_json(CORVANE_PATH)
	if typeof(corv) == TYPE_DICTIONARY:
		_corvane_def = (corv as Dictionary).duplicate(true)


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Adventure: missing %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed


func _ensure_panel() -> void:
	if _ui_ready:
		return
	_ui_ready = true
	var script: Script = load("res://scripts/adventure_panel.gd") as Script
	if script == null:
		return
	var panel := CanvasLayer.new()
	panel.set_script(script)
	panel.name = "AdventurePanel"
	add_child(panel)
	_panel = panel


func attach_brewing_stand(world: Node2D) -> void:
	if world == null:
		return
	var existing: Node = world.get_node_or_null("BrewingStand")
	if existing != null:
		if existing.has_method("refresh"):
			existing.call("refresh")
		return
	var script: Script = load("res://scripts/brewing_stand.gd") as Script
	if script == null:
		return
	var stand := Area2D.new()
	stand.set_script(script)
	stand.name = "BrewingStand"
	world.add_child(stand)


func toggle_panel() -> void:
	if _panel != null and _panel.has_method("toggle"):
		_panel.call("toggle")


func open_panel() -> void:
	if _panel != null and _panel.has_method("open"):
		_panel.call("open")


func corvane_def() -> Dictionary:
	return _corvane_def.duplicate(true)


func reach_foe_def() -> Dictionary:
	if _reach_foe_def.is_empty():
		return {
			"id": "reach_foe",
			"display_name": "Briar Warden",
			"crit_multiplier": 1.2,
			"attack_profile": "physical",
			"stats": {
				"might": 6, "arcana": 3, "resilience": 5, "ward": 4,
				"vitality": 6, "swiftness": 4, "fate": 5,
			},
		}
	var def: Dictionary = _reach_foe_def.duplicate(true)
	var key: String = str(def.get("display_name_key", ""))
	if key != "" and has_node("/root/ContentStrings"):
		var labeled: String = ContentStrings.get_text(key)
		if labeled != "" and labeled != key:
			def["display_name"] = labeled
	return def


func owns_forge_weapon() -> bool:
	if not has_node("/root/Equipment"):
		return false
	for item_id: String in FORGE_WEAPONS:
		if Equipment.owns_anywhere(item_id):
			return true
	return false


func echo2_gate_open() -> bool:
	return owns_forge_weapon() and not echo2_resolved


func echo2_portal_visible() -> bool:
	## Same arch as Echo 1. Echo 1 keeps it until that fight is resolved.
	if not echo2_gate_open():
		return false
	if has_node("/root/GameState") and GameState.portal_unlocked and not GameState.echo_01_resolved:
		return false
	return true


func try_pay_echo2() -> String:
	if not echo2_gate_open():
		return "closed"
	if echo2_fee_paid:
		return "already_paid"
	if not has_node("/root/GameState") or GameState.essence < ECHO2_FEE:
		return "reject"
	GameState.add_resource(&"essence", -ECHO2_FEE)
	echo2_fee_paid = true
	GameState.echo_flags_changed.emit()
	_changed()
	return "paid"


func open_echo2_battle(already_paid: bool) -> void:
	if not has_node("/root/EchoChamber"):
		return
	var def: Dictionary = corvane_def()
	if has_node("/root/ContentStrings"):
		var labeled: String = ContentStrings.get_text("corvane_name")
		if labeled != "" and labeled != "corvane_name":
			def["display_name"] = labeled
	EchoChamber.open_context(def, "echo2", _keeper_totals(), _strike_kind_for("keeper"), already_paid)


func apply_echo2_outcome(outcome: String) -> Dictionary:
	if outcome == "spare" or outcome == "defeat":
		echo2_resolved = true
		echo2_fee_paid = false
		adventure_unlocked = true
		corvane_promised = true
		corvane_outcome = outcome
		refresh_milestones()
		if has_node("/root/GameState"):
			var key: String = "adventure_scar_spare" if outcome == "spare" else "adventure_scar_defeat"
			GameState.status_message.emit(ContentStrings.get_text(key))
			GameState.echo_flags_changed.emit()
	elif outcome == "ko":
		echo2_fee_paid = false
		if has_node("/root/GameState"):
			GameState.echo_flags_changed.emit()
	_changed()
	return {"outcome": outcome, "shards": 0}


func ancient_blocks_adventure() -> bool:
	if not has_node("/root/GameState"):
		return false
	if String(GameState.stage_id) == "ancient":
		return true
	if GameState.fruit_committed or GameState.ancient_frozen:
		return true
	return false


func adventure_clock_runs() -> bool:
	if not reach_active:
		return false
	var tree: SceneTree = get_tree()
	if tree != null and tree.paused:
		return false
	if ancient_blocks_adventure():
		return false
	return true


func reach_duration_sec() -> float:
	return MANUAL_REACH_SEC if reach_mode == "manual" else IDLE_REACH_SEC


func advance_open_time(delta: float) -> void:
	if delta <= 0.0 or not adventure_clock_runs():
		return
	reach_elapsed += delta
	if reach_elapsed + 0.0001 < reach_duration_sec():
		return
	reach_elapsed = reach_duration_sec()
	_complete_timed_reach()


func normalize_party(ids: Array) -> Array[String]:
	var out: Array[String] = []
	var elaia_ok: bool = has_node("/root/GameState") and GameState.elaia_in_party()
	for raw: Variant in ids:
		var id: String = str(raw)
		if id == "keeper" and not out.has("keeper"):
			out.append("keeper")
		elif id == "elaia" and elaia_ok and not out.has("elaia"):
			out.append("elaia")
	return out


func set_selected_party(ids: Array) -> void:
	if reach_active or awaiting_manual:
		return
	var party: Array[String] = normalize_party(ids)
	if party.is_empty():
		return
	selected_party = party
	_changed()


func toggle_party_member(actor: String) -> void:
	if reach_active or awaiting_manual:
		return
	var next: Array[String] = []
	next.assign(selected_party)
	if next.has(actor):
		next.erase(actor)
	else:
		next.append(actor)
	set_selected_party(next)


func try_start_reach(mode: String) -> String:
	if not adventure_unlocked:
		return "locked"
	if reach_active or awaiting_manual:
		return "busy"
	if ancient_blocks_adventure():
		return "ancient"
	var party: Array[String] = normalize_party(selected_party)
	if party.is_empty():
		return "no_party"
	reach_mode = "manual" if mode == "manual" else "idle"
	reach_party = party
	selected_party = party
	reach_elapsed = 0.0
	reach_active = true
	awaiting_manual = false
	party_max_hp = party_max_hp_for(party)
	party_hp = party_max_hp
	_halt_party(party)
	_changed()
	return "ok"


func cancel_reach() -> String:
	## Mid-reach and an unfought manual both pay nothing. The timer is discarded.
	if not reach_active and not awaiting_manual:
		return "idle"
	_clear_active_reach()
	_changed()
	if has_node("/root/GameState"):
		GameState.status_message.emit(ContentStrings.get_text("adventure_cancelled"))
	return "cancelled"


func actor_is_away(actor: String) -> bool:
	if not reach_active and not awaiting_manual:
		return false
	return reach_party.has(actor)


func _complete_timed_reach() -> void:
	reach_active = false
	if reach_mode == "manual":
		awaiting_manual = true
		_changed()
		if present_battles:
			present_manual_battle()
		return
	_resolve_idle()


func _resolve_idle() -> void:
	var band: String = idle_band(party_power(reach_party))
	apply_idle_hit(band)
	var reach_number: int = cumulative_reaches + 1
	if band == "fail":
		store_crate(roll_consolation_crate())
	else:
		store_crate(roll_success_crate(reach_number))
	cumulative_reaches = reach_number
	_clear_active_reach()
	refresh_milestones()
	_changed()


func present_manual_battle() -> String:
	if not awaiting_manual:
		return "idle"
	if not has_node("/root/EchoChamber"):
		return "no_echo"
	if EchoChamber.in_battle:
		return "busy"
	var totals: Dictionary = combat_totals_for(reach_party)
	var kind: String = party_strike_kind(reach_party)
	EchoChamber.open_context(reach_foe_def(), "manual", totals, kind, false)
	return "ok"


func apply_manual_battle(outcome: String) -> Dictionary:
	awaiting_manual = false
	if outcome == "spare" or outcome == "defeat":
		var reach_number: int = cumulative_reaches + 1
		var crate: Dictionary = roll_success_crate(reach_number)
		_apply_special(crate)
		store_crate(crate)
		cumulative_reaches = reach_number
		refresh_milestones()
	elif outcome == "ko":
		store_crate(roll_consolation_crate())
		cumulative_reaches += 1
		refresh_milestones()
	_clear_active_reach()
	_changed()
	return {"outcome": outcome, "shards": 0}


func abandon_manual_battle() -> void:
	awaiting_manual = false
	_clear_active_reach()
	_changed()


func refresh_milestones() -> void:
	var joined: bool = adventure_unlocked and cumulative_reaches >= JOIN_REACHES
	if joined and not corvane_joined:
		corvane_joined = true
		brewing_unlocked = true
		if has_node("/root/GameState"):
			GameState.status_message.emit(ContentStrings.get_text("adventure_joined"))
			GameState.echo_flags_changed.emit()
	elif joined:
		corvane_joined = true
		brewing_unlocked = true
	_refresh_stand()


func corvane_selectable() -> bool:
	return corvane_joined


func crate_count() -> int:
	return crates.size()


func herb_count(herb_id: String) -> int:
	return int(herbs.get(herb_id, 0))


func potion_count(potion_id: String) -> int:
	return int(potions.get(potion_id, 0))


func set_herb(herb_id: String, amount: int) -> void:
	if herb_id != "glowcap" and herb_id != "bitterroot":
		return
	herbs[herb_id] = maxi(0, amount)
	_changed()


func set_potion(potion_id: String, amount: int) -> void:
	if potion_id != "heart_salve" and potion_id != "bile_vial":
		return
	potions[potion_id] = clampi(amount, 0, POTION_CAP)
	_changed()


func store_crate(crate: Dictionary) -> void:
	crates.append(crate.duplicate(true))
	_changed()


func open_crate(index: int = 0) -> String:
	if index < 0 or index >= crates.size():
		return "missing"
	var crate: Dictionary = crates[index]
	crates.remove_at(index)
	if has_node("/root/GameState"):
		for res_id: String in ["wood", "stone", "food", "essence"]:
			var n: int = int(crate.get(res_id, 0))
			if n > 0:
				GameState.add_resource(StringName(res_id), n)
	for herb_id: String in ["glowcap", "bitterroot"]:
		var herbs_n: int = int(crate.get(herb_id, 0))
		if herbs_n > 0:
			herbs[herb_id] = int(herbs.get(herb_id, 0)) + herbs_n
	if has_node("/root/Backpack"):
		var fert: int = int(crate.get("fertilizer", 0))
		if fert > 0:
			Backpack.add_item("fertilizer", fert)
		var amber: int = int(crate.get("amberbind", 0))
		if amber > 0:
			Backpack.add_item("amberbind", amber)
	_changed()
	return "ok"


func try_brew(potion_id: String) -> String:
	if not brewing_unlocked:
		return "locked"
	var herb_id: String = _herb_for_potion(potion_id)
	if herb_id == "":
		return "unknown"
	if potion_count(potion_id) >= POTION_CAP:
		return "full"
	if herb_count(herb_id) < HERB_CRAFT:
		return "need_herb"
	if not has_node("/root/GameState") or GameState.essence < POTION_ESSENCE:
		return "need_essence"
	herbs[herb_id] = herb_count(herb_id) - HERB_CRAFT
	GameState.add_resource(&"essence", -POTION_ESSENCE)
	potions[potion_id] = potion_count(potion_id) + 1
	_changed()
	return "ok"


func spend_potion(potion_id: String) -> bool:
	if potion_count(potion_id) <= 0:
		return false
	potions[potion_id] = potion_count(potion_id) - 1
	_changed()
	return true


func apply_idle_hit(band: String) -> Dictionary:
	## One salve per trigger. Bile is never thrown on an idle reach.
	var dmg: int = idle_damage_for(band)
	var before: int = party_hp
	party_hp = maxi(1, party_hp - dmg)
	var used: bool = false
	if party_max_hp > 0 and float(party_hp) < SALVE_HP_FRACTION * float(party_max_hp):
		if potion_count("heart_salve") > 0:
			potions["heart_salve"] = potion_count("heart_salve") - 1
			party_hp = mini(party_max_hp, party_hp + SALVE_HEAL)
			used = true
	return {"band": band, "damage": dmg, "hp_before": before, "hp": party_hp, "salve": used}


func idle_damage_for(band: String) -> int:
	if band == "success":
		return IDLE_DAMAGE_SUCCESS
	if band == "scrape":
		return IDLE_DAMAGE_SCRAPE
	return IDLE_DAMAGE_FAIL


func idle_band(power: int) -> String:
	if power >= THREAT_POWER:
		return "success"
	if float(power) >= float(THREAT_POWER) * SCRAPE_RATIO:
		return "scrape"
	return "fail"


func party_power(members: Array[String]) -> int:
	var total: int = 0
	for actor: String in members:
		total += actor_body_power(actor)
	return total


func actor_body_power(actor: String) -> int:
	var total: int = 0
	for stat_id: String in ["might", "arcana", "resilience", "ward", "vitality"]:
		total += _actor_total(actor, stat_id)
	return total


func party_max_hp_for(members: Array[String]) -> int:
	var hp: int = 0
	for actor: String in members:
		hp += EchoBattle.hp_max_for(_actor_total(actor, "vitality"))
	return maxi(1, hp)


func combat_totals_for(members: Array[String]) -> Dictionary:
	var keys: PackedStringArray = PackedStringArray([
		"might", "arcana", "resilience", "ward", "swiftness", "fate",
	])
	var out: Dictionary = {}
	for stat_id: String in keys:
		var best: int = 0
		for actor: String in members:
			best = maxi(best, _actor_total(actor, stat_id))
		out[stat_id] = best
	var vit: int = 0
	for actor2: String in members:
		vit += _actor_total(actor2, "vitality")
	out["vitality"] = maxi(1, vit)
	return out


func party_strike_kind(members: Array[String]) -> String:
	var physical: bool = false
	var magical: bool = false
	var hybrid: bool = false
	for actor: String in members:
		var kind: String = _strike_kind_for(actor)
		if kind == "hybrid":
			hybrid = true
		elif kind == "magical":
			magical = true
		else:
			physical = true
	if hybrid or (physical and magical):
		return "hybrid"
	if magical:
		return "magical"
	return "physical"


func on_ascend() -> void:
	## Crates, herbs, and potions are the Phase 0 sink. Reaches and the scar stay.
	_clear_active_reach()
	crates.clear()
	herbs = {"glowcap": 0, "bitterroot": 0}
	potions = {"heart_salve": 0, "bile_vial": 0}
	_changed()


func capture_save_fields() -> Dictionary:
	var party: Array = []
	for actor: String in reach_party:
		party.append(actor)
	var picked: Array = []
	for actor2: String in selected_party:
		picked.append(actor2)
	var stored: Array = []
	for crate: Dictionary in crates:
		stored.append(crate.duplicate(true))
	return {
		"adventure_unlocked": adventure_unlocked,
		"corvane_outcome": corvane_outcome,
		"corvane_promised": corvane_promised,
		"corvane_joined": corvane_joined,
		"brewing_unlocked": brewing_unlocked,
		"echo2_fee_paid": echo2_fee_paid,
		"echo2_resolved": echo2_resolved,
		"cumulative_reaches": cumulative_reaches,
		"reach_active": reach_active,
		"awaiting_manual": awaiting_manual,
		"reach_mode": reach_mode,
		"reach_elapsed": reach_elapsed,
		"reach_party": party,
		"selected_party": picked,
		"adventure_crates": stored,
		"adventure_herbs": herbs.duplicate(true),
		"adventure_potions": potions.duplicate(true),
		"adventure_party_hp": party_hp,
		"adventure_party_max_hp": party_max_hp,
	}


func apply_save_fields(data: Dictionary) -> void:
	adventure_unlocked = bool(data.get("adventure_unlocked", false))
	corvane_outcome = str(data.get("corvane_outcome", ""))
	corvane_promised = bool(data.get("corvane_promised", false))
	corvane_joined = bool(data.get("corvane_joined", false))
	brewing_unlocked = bool(data.get("brewing_unlocked", false)) or corvane_joined
	echo2_fee_paid = bool(data.get("echo2_fee_paid", false))
	echo2_resolved = bool(data.get("echo2_resolved", false))
	cumulative_reaches = maxi(0, int(data.get("cumulative_reaches", 0)))
	reach_active = bool(data.get("reach_active", false))
	awaiting_manual = bool(data.get("awaiting_manual", false))
	reach_mode = "manual" if str(data.get("reach_mode", "idle")) == "manual" else "idle"
	reach_elapsed = maxf(0.0, float(data.get("reach_elapsed", 0.0)))
	reach_party = _string_list(data.get("reach_party", []))
	var picked: Array[String] = _string_list(data.get("selected_party", []))
	if picked.is_empty():
		selected_party = ["keeper"]
	else:
		selected_party = picked
	crates.clear()
	var stored: Variant = data.get("adventure_crates", [])
	if typeof(stored) == TYPE_ARRAY:
		for entry: Variant in stored:
			if typeof(entry) == TYPE_DICTIONARY:
				crates.append((entry as Dictionary).duplicate(true))
	_apply_count_map(herbs, data.get("adventure_herbs", {}), ["glowcap", "bitterroot"], 9999)
	_apply_count_map(potions, data.get("adventure_potions", {}), ["heart_salve", "bile_vial"], POTION_CAP)
	party_hp = maxi(0, int(data.get("adventure_party_hp", 0)))
	party_max_hp = maxi(0, int(data.get("adventure_party_max_hp", 0)))
	refresh_milestones()
	_changed()


func reset_for_new_game() -> void:
	adventure_unlocked = false
	corvane_outcome = ""
	corvane_promised = false
	corvane_joined = false
	brewing_unlocked = false
	echo2_fee_paid = false
	echo2_resolved = false
	cumulative_reaches = 0
	_clear_active_reach()
	selected_party = ["keeper"]
	crates.clear()
	herbs = {"glowcap": 0, "bitterroot": 0}
	potions = {"heart_salve": 0, "bile_vial": 0}
	present_battles = true
	_refresh_stand()
	_changed()


func roll_success_crate(reach_number: int) -> Dictionary:
	return build_success_crate(
		_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf(), _rng.randf(), _rng.randf(), reach_number
	)


func roll_consolation_crate() -> Dictionary:
	return consolation_of(roll_success_crate(cumulative_reaches + 1))


static func build_success_crate(
	primary_unit: float,
	primary_amt_unit: float,
	secondary_unit: float,
	secondary_amt_unit: float,
	herb_unit: float,
	herb_pick_unit: float,
	reach_number: int
) -> Dictionary:
	var primary: String = pick_weighted(primary_unit, RAW_IDS, RAW_WEIGHTS)
	var primary_amt: int = roll_inclusive(primary_amt_unit, PRIMARY_MIN, PRIMARY_MAX)
	var second_ids: PackedStringArray = PackedStringArray()
	var second_w: PackedInt32Array = PackedInt32Array()
	for i: int in range(RAW_IDS.size()):
		if RAW_IDS[i] != primary:
			second_ids.append(RAW_IDS[i])
			second_w.append(RAW_WEIGHTS[i])
	var secondary: String = pick_weighted(secondary_unit, second_ids, second_w)
	var secondary_amt: int = roll_inclusive(secondary_amt_unit, SECONDARY_MIN, SECONDARY_MAX)
	var herb: String = ""
	if herb_drops(reach_number, herb_unit):
		herb = herb_id_for_unit(herb_pick_unit)
	return crate_from_parts("success", primary, primary_amt, secondary, secondary_amt, SUCCESS_ESSENCE, herb)


static func consolation_of(full: Dictionary) -> Dictionary:
	var crate: Dictionary = full.duplicate(true)
	crate["kind"] = "consolation"
	for key: String in ["wood", "stone", "food"]:
		var n: int = int(crate.get(key, 0))
		crate[key] = half_amount(n) if n > 0 else 0
	crate["essence"] = 0
	crate["glowcap"] = 0
	crate["bitterroot"] = 0
	crate["fertilizer"] = 0
	crate["amberbind"] = 0
	return crate


static func half_amount(n: int) -> int:
	return maxi(1, int(n / 2))


static func herb_drops(reach_number: int, unit: float) -> bool:
	return reach_number >= HERB_REACH and unit < HERB_CHANCE


static func herb_id_for_unit(unit: float) -> String:
	return "glowcap" if unit < 0.5 else "bitterroot"


static func special_kind(unit: float) -> String:
	## 50% nothing, 30% herb, 15% Fertilizer 1, 5% Amberbind 1.
	if unit < 0.50:
		return "nothing"
	if unit < 0.80:
		return "herb"
	if unit < 0.95:
		return "fertilizer"
	return "amberbind"


static func pick_weighted(unit: float, ids: PackedStringArray, weights: PackedInt32Array) -> String:
	if ids.is_empty():
		return ""
	var total: int = 0
	for w: int in weights:
		total += w
	if total <= 0:
		return ids[0]
	var cursor: float = clampf(unit, 0.0, 0.999999) * float(total)
	var acc: float = 0.0
	for i: int in range(ids.size()):
		var weight: int = weights[i] if i < weights.size() else 0
		acc += float(weight)
		if cursor < acc:
			return ids[i]
	return ids[ids.size() - 1]


static func roll_inclusive(unit: float, lo: int, hi: int) -> int:
	if hi <= lo:
		return lo
	var span: int = hi - lo + 1
	var idx: int = int(floor(clampf(unit, 0.0, 0.999999) * float(span)))
	return lo + idx


static func crate_from_parts(
	kind: String,
	primary: String,
	primary_amt: int,
	secondary: String,
	secondary_amt: int,
	essence: int,
	herb: String
) -> Dictionary:
	var crate: Dictionary = {
		"kind": kind,
		"wood": 0,
		"stone": 0,
		"food": 0,
		"essence": essence,
		"glowcap": 0,
		"bitterroot": 0,
		"fertilizer": 0,
		"amberbind": 0,
	}
	if crate.has(primary):
		crate[primary] = int(crate[primary]) + primary_amt
	if crate.has(secondary):
		crate[secondary] = int(crate[secondary]) + secondary_amt
	if herb == "glowcap" or herb == "bitterroot":
		crate[herb] = int(crate[herb]) + 1
	return crate


func _apply_special(crate: Dictionary) -> void:
	var kind: String = special_kind(_rng.randf())
	if kind == "herb":
		var herb: String = herb_id_for_unit(_rng.randf())
		crate[herb] = int(crate.get(herb, 0)) + 1
	elif kind == "fertilizer":
		crate["fertilizer"] = int(crate.get("fertilizer", 0)) + 1
	elif kind == "amberbind":
		crate["amberbind"] = int(crate.get("amberbind", 0)) + 1


func _herb_for_potion(potion_id: String) -> String:
	if potion_id == "heart_salve":
		return "glowcap"
	if potion_id == "bile_vial":
		return "bitterroot"
	return ""


func _clear_active_reach() -> void:
	reach_active = false
	awaiting_manual = false
	reach_elapsed = 0.0
	reach_party.clear()
	party_hp = 0
	party_max_hp = 0


func _halt_party(party: Array[String]) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for actor: String in party:
		var group_name: String = "keeper" if actor == "keeper" else "elaia"
		for node: Node in tree.get_nodes_in_group(group_name):
			if node.has_method("halt"):
				node.call("halt")


func _actor_total(actor: String, stat_id: String) -> int:
	var base: int = 5
	if has_node("/root/KeeperStats"):
		base = int(KeeperStats.get_base_for(actor, stat_id))
	var gear: int = 0
	if has_node("/root/Equipment"):
		gear = int(Equipment.gear_bonus_for(actor, stat_id))
	return base + gear


func _keeper_totals() -> Dictionary:
	return {
		"might": _actor_total("keeper", "might"),
		"arcana": _actor_total("keeper", "arcana"),
		"resilience": _actor_total("keeper", "resilience"),
		"ward": _actor_total("keeper", "ward"),
		"vitality": _actor_total("keeper", "vitality"),
		"swiftness": _actor_total("keeper", "swiftness"),
		"fate": _actor_total("keeper", "fate"),
	}


func _strike_kind_for(actor: String) -> String:
	if not has_node("/root/Equipment"):
		return "physical"
	var item_id: String = Equipment.equipped_id_for(actor, "weapon")
	var kind: String = Equipment.item_damage_kind(item_id)
	if kind == "magical" or kind == "hybrid" or kind == "physical":
		return kind
	return "physical"


func _string_list(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry: Variant in raw:
		var id: String = str(entry)
		if id != "" and not out.has(id):
			out.append(id)
	return out


func _apply_count_map(target: Dictionary, raw: Variant, keys: Array, cap: int) -> void:
	var src: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	for key: Variant in keys:
		var id: String = str(key)
		target[id] = clampi(int(src.get(id, 0)), 0, cap)


func _refresh_stand() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node: Node in tree.get_nodes_in_group("brewing_stand"):
		if node.has_method("refresh"):
			node.call("refresh")


func _changed() -> void:
	adventure_changed.emit()
