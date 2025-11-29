extends Node

# Facade / Service Container
var _store
var _item_repo
var _char_repo
var _inv_repo
var _game_loader
var _equipment_system
var _trade_system

# Public Accessors
var items:
	get: return _item_repo
var characters:
	get: return _char_repo
var inventory:
	get: return _inv_repo
var equipment:
	get: return _equipment_system
var trade:
	get: return _trade_system

func _ready():
	# Bootstrap Persistence
	_store = preload("res://src/core/persistence/data_store.gd").new()
	_store.load_data()
	
	# Bootstrap Repositories
	_item_repo = preload("res://src/core/repositories/item_repository.gd").new(_store)
	_char_repo = preload("res://src/core/repositories/character_repository.gd").new(_store)
	# Using V2 to bypass cache corruption
	_inv_repo = preload("res://src/core/repositories/inventory_repo_v2.gd").new(_store, _item_repo)
	
	# Bootstrap Loaders
	_game_loader = preload("res://src/core/loaders/game_loader.gd").new(_item_repo, _char_repo, _inv_repo)
	_game_loader.run()
	
	# Bootstrap Systems
	_equipment_system = preload("res://src/systems/equipment_system.gd").new(_char_repo, _inv_repo, _item_repo)
	_trade_system = preload("res://src/systems/trade_system.gd").new(_inv_repo)

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
