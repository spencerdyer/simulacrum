extends RefCounted

var _store
var _item_repo

func _init(store, item_repo):
	_store = store
	_item_repo = item_repo

func get_all():
	if _store == null: return []
	return _store.get_table("inventory")

func add_item(owner_id: String, item_def_id: String):
	var instance_id = str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)
	var list = get_all()
	list.append({
		"instance_id": instance_id,
		"owner_id": owner_id,
		"item_def_id": item_def_id,
		"equipped": false
	})
	_store.save_data()
	return instance_id

func update_owner(instance_id: String, new_owner_id: String):
	var list = get_all()
	if list == null: return
	
	for i in range(list.size()):
		var item = list[i]
		if item == null: continue
		if not item is Dictionary: continue
		
		if item.get("instance_id") == instance_id:
			item["owner_id"] = new_owner_id
			item["equipped"] = false # Reset equipped state on trade
			if _store: _store.save_data()
			return

func get_by_owner(owner_id: String, include_equipped: bool = false) -> Array:
	var result = []
	var list = get_all()
	if list == null: return result
	
	for i in range(list.size()):
		var item = list[i]
		if item == null: continue
		if not item is Dictionary: continue
		
		if item.get("owner_id") == owner_id:
			var is_equipped = item.get("equipped", false)
			if include_equipped or not is_equipped:
				var def_id = item.get("item_def_id")
				var def = _item_repo.get_by_id(def_id)
				if def:
					var full = item.duplicate()
					full.merge(def)
					result.append(full)
	return result

func get_by_instance_id(instance_id: String):
	var list = get_all()
	if list == null: return null
	
	for i in range(list.size()):
		var item = list[i]
		if item == null: continue
		if not item is Dictionary: continue
		
		if item.get("instance_id") == instance_id:
			return item
	return null

func set_equipped(instance_id: String, is_equipped: bool):
	var list = get_all()
	if list == null: return
	
	for i in range(list.size()):
		var item = list[i]
		if item == null: continue
		if not item is Dictionary: continue
		
		if item.get("instance_id") == instance_id:
			item["equipped"] = is_equipped
			if _store: _store.save_data()
			return

func remove_item(instance_id: String):
	var list = get_all()
	if list == null: return
	
	for i in range(list.size() - 1, -1, -1):
		var item = list[i]
		if item == null: continue
		if not item is Dictionary: continue
		
		if item.get("instance_id") == instance_id:
			list.remove_at(i)
			if _store: _store.save_data()
			return

func clear_owner_inventory(owner_id: String):
	var list = get_all()
	if list == null: return
	
	for i in range(list.size() - 1, -1, -1):
		var item = list[i]
		if item == null: continue
		if not item is Dictionary: continue
		
		if item.get("owner_id") == owner_id:
			list.remove_at(i)
	
	if _store: _store.save_data()
