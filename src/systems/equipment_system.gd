extends RefCounted

var _char_repo
var _inv_repo
var _item_repo

func _init(char_repo, inv_repo, item_repo):
	_char_repo = char_repo
	_inv_repo = inv_repo
	_item_repo = item_repo

func equip_item(player_id: String, instance_id: String, slot: String):
	var player = _char_repo.get_by_id(player_id)
	var item_instance = _inv_repo.get_by_instance_id(instance_id)
	
	if not player or not item_instance: return
	
	var item_def = _item_repo.get_by_id(item_instance["item_def_id"])
	if not item_def: return
	
	# Validation
	var allowed = false
	if item_def["type"] == slot: allowed = true
	if item_def["type"] == "HAND" and (slot == "RIGHT_HAND" or slot == "LEFT_HAND"): allowed = true
	
	if not allowed:
		print("System: Cannot equip ", item_def["name"], " to ", slot)
		return
		
	# Unequip existing
	if player["equipment"][slot] != null:
		unequip_item(player_id, slot)
		
	# Equip
	player["equipment"][slot] = instance_id
	_inv_repo.set_equipped(instance_id, true)
	_char_repo.update(player)
	print("System: Equipped ", item_def["name"], " to ", slot)

func unequip_item(player_id: String, slot: String):
	var player = _char_repo.get_by_id(player_id)
	if not player: return
	
	var instance_id = player["equipment"].get(slot)
	if instance_id:
		_inv_repo.set_equipped(instance_id, false)
		player["equipment"][slot] = null
		_char_repo.update(player)
		print("System: Unequipped from ", slot)

