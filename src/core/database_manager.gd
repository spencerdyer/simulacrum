extends Node

# Facade / Service Container
var _store
var _item_repo
var _char_repo
var _inv_repo
var _world_location_repo
var _npc_facts_repo
var _npc_memories_repo
var _conversation_repo
var _relationships_repo
var _game_loader
var _equipment_system
var _trade_system
var _window_manager
var _settings_manager
var _save_manager
var _playtime_tracker
var _llm_provider

# Public Accessors
var items:
	get: return _item_repo
var characters:
	get: return _char_repo
var inventory:
	get: return _inv_repo
var world_locations:
	get: return _world_location_repo
var npc_facts:
	get: return _npc_facts_repo
var npc_memories:
	get: return _npc_memories_repo
var conversations:
	get: return _conversation_repo
var relationships:
	get: return _relationships_repo
var equipment:
	get: return _equipment_system
var trade:
	get: return _trade_system
var windows:
	get: return _window_manager
var settings:
	get: return _settings_manager
var saves:
	get: return _save_manager
var playtime:
	get: return _playtime_tracker
var llm:
	get: return _llm_provider

func _ready():
	# Bootstrap Settings (independent of game saves)
	_settings_manager = preload("res://src/core/settings_manager.gd").new()
	
	# Bootstrap Save System
	_save_manager = preload("res://src/core/save_manager.gd").new()
	_playtime_tracker = preload("res://src/core/playtime_tracker.gd").new()
	
	# Bootstrap LLM Provider Service
	_llm_provider = preload("res://src/services/llm_provider.gd").new()
	
	# Bootstrap Persistence
	_store = preload("res://src/core/persistence/data_store.gd").new()
	_store.load_data()
	
	# Bootstrap Repositories
	_item_repo = preload("res://src/core/repositories/item_repository.gd").new(_store)
	_char_repo = preload("res://src/core/repositories/character_repository.gd").new(_store)
	_inv_repo = preload("res://src/core/repositories/inventory_repo_v2.gd").new(_store, _item_repo)
	_world_location_repo = preload("res://src/core/repositories/world_location_repository.gd").new(_store)
	_npc_facts_repo = preload("res://src/core/repositories/npc_known_facts_repository.gd").new(_store)
	_npc_memories_repo = preload("res://src/core/repositories/npc_memories_repository.gd").new(_store)
	_conversation_repo = preload("res://src/core/repositories/conversation_history_repository.gd").new(_store)
	_relationships_repo = preload("res://src/core/repositories/relationships_repository.gd").new(_store)
	
	# Bootstrap Loaders
	_game_loader = preload("res://src/core/loaders/game_loader.gd").new(
		_item_repo, _char_repo, _inv_repo, _world_location_repo, _npc_facts_repo
	)
	_game_loader.run()
	
	# Bootstrap Systems
	_equipment_system = preload("res://src/systems/equipment_system.gd").new(_char_repo, _inv_repo, _item_repo)
	_trade_system = preload("res://src/systems/trade_system.gd").new(_inv_repo)
	_window_manager = preload("res://src/systems/window_manager.gd").new()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Auto-save on game close
		auto_save()
		get_tree().quit()

func auto_save():
	var save_name = _save_manager.get_current_save_name()
	var game_data = _store.get_all_data()
	var total_playtime = _playtime_tracker.get_total_playtime()
	_save_manager.save_game(save_name, game_data, total_playtime)
	print("Auto-saved to: ", save_name)

func save_game(save_name: String) -> bool:
	var game_data = _store.get_all_data()
	var total_playtime = _playtime_tracker.get_total_playtime()
	return _save_manager.save_game(save_name, game_data, total_playtime)

func load_game(save_name: String) -> bool:
	var save_data = _save_manager.load_game(save_name)
	if save_data.is_empty():
		return false
	
	# Restore game data
	if save_data.has("game_data"):
		_store.set_all_data(save_data["game_data"])
	
	# Restore playtime
	var loaded_playtime = 0.0
	if save_data.has("metadata") and save_data["metadata"].has("playtime"):
		loaded_playtime = save_data["metadata"]["playtime"]
	_playtime_tracker.start_session(loaded_playtime)
	
	# Re-run loader to ensure consistency
	_game_loader.run()
	
	print("Loaded game: ", save_name, " with ", _save_manager.format_playtime(loaded_playtime), " playtime")
	return true

# Compatibility shims
func get_player_character():
	return _char_repo.get_player()

func get_player_inventory(player_id):
	return _inv_repo.get_by_owner(player_id)

func get_player_equipment(player_id):
	var player = _char_repo.get_by_id(player_id)
	if not player: return {}
	var result = {}
	for slot in player["equipment"].keys():
		var instance_id = player["equipment"][slot]
		if instance_id:
			var instance = _inv_repo.get_by_instance_id(instance_id)
			if instance:
				var def = _item_repo.get_by_id(instance["item_def_id"])
				if def:
					var full = instance.duplicate()
					full.merge(def)
					result[slot] = full
		else:
			result[slot] = null
	return result

func equip_item(player_id, instance_id, slot):
	_equipment_system.equip_item(player_id, instance_id, slot)

func unequip_item(player_id, slot):
	_equipment_system.unequip_item(player_id, slot)
