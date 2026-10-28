class_name HubLife
extends RefCounted
## Runtime entry for autoload scripts. They load this file by a built path so
## the autoload compile does not depend on these classes.


static func tick_open(delta: float) -> void:
	WeatherState.tick(delta)
	CompanionChores.tick(delta)
	CompanionSchedule.tick(delta)


static func water_essence_mult() -> float:
	return WeatherState.water_essence_mult()


static func frostberry_spec() -> Dictionary:
	return WeatherState.frostberry_spec()


static func glowcap_weight_mult() -> float:
	return WeatherState.glowcap_weight_mult()


static func push_offline() -> void:
	WeatherState.push_offline()


static func pop_offline() -> void:
	WeatherState.pop_offline()


static func on_save_loaded() -> void:
	WeatherState.on_save_loaded()


static func reset_new_game() -> void:
	WeatherState.reset_default()
	CompanionChores.reset_for_new_game()


static func save_fields() -> Dictionary:
	return CompanionChores.save_fields()


static func apply_save_dict(data: Dictionary) -> void:
	CompanionChores.apply_save_dict(data)


static func migrate_fields(out: Dictionary) -> void:
	CompanionChores.migrate_fields(out)


static func apply_offline(eff: float, result: Dictionary) -> void:
	CompanionChores.apply_offline(eff, result)


static func weather_state_name() -> String:
	return WeatherState.get_state()


static func weather_audio() -> Dictionary:
	return WeatherState.audio_block()


static func chore_payout_audio(node_id: String) -> Dictionary:
	return CompanionChores.payout_audio(node_id)
