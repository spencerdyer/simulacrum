extends RefCounted

# World Locations Repository
# Manages locations in the game world (towns, buildings, rooms, etc.)

var _store

func _init(store):
	_store = store

func _get_timestamp() -> float:
	return Time.get_unix_time_from_system()

func get_all() -> Array:
	return _store.get_table("world_locations")

func get_by_id(id: String) -> Dictionary:
	for loc in get_all():
		if loc.get("id") == id:
			return loc
	return {}

func get_children(parent_id: String) -> Array:
	var result = []
	for loc in get_all():
		if loc.get("parent_id") == parent_id:
			result.append(loc)
	return result

func create(data: Dictionary) -> String:
	var id = "loc_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	var now = _get_timestamp()
	
	var location = {
		"id": id,
		"parent_id": data.get("parent_id", ""),  # Empty = top-level location
		"name": data.get("name", "Unknown Location"),
		"type": data.get("type", "area"),  # area, building, room, etc.
		"description": data.get("description", ""),
		"owner_id": data.get("owner_id", ""),  # Character ID who owns this
		"properties": data.get("properties", {}),  # Flexible JSON for type-specific data
		"npcs_present": data.get("npcs_present", []),  # Character IDs currently here
		"objects": data.get("objects", []),  # Object definitions in this location
		"created_at": now,
		"updated_at": now
	}
	
	get_all().append(location)
	_store.save_data()
	return id

func update(id: String, updates: Dictionary):
	var locations = get_all()
	for i in range(locations.size()):
		if locations[i].get("id") == id:
			for key in updates.keys():
				locations[i][key] = updates[key]
			locations[i]["updated_at"] = _get_timestamp()
			_store.save_data()
			return

func delete(id: String):
	var locations = get_all()
	for i in range(locations.size() - 1, -1, -1):
		if locations[i].get("id") == id:
			locations.remove_at(i)
			_store.save_data()
			return

func get_text_description(id: String) -> String:
	var loc = get_by_id(id)
	if loc.is_empty():
		return "Unknown location."
	
	var desc = loc.get("name", "Unknown") + " (" + loc.get("type", "area") + ")"
	
	if loc.get("description", "") != "":
		desc += ": " + loc["description"]
	
	if loc.get("owner_id", "") != "":
		desc += " [Owned by: " + loc["owner_id"] + "]"
	
	var npcs = loc.get("npcs_present", [])
	if npcs.size() > 0:
		desc += " [Present: " + ", ".join(npcs) + "]"
	
	var objects = loc.get("objects", [])
	if objects.size() > 0:
		var obj_names = []
		for obj in objects:
			if obj is Dictionary:
				obj_names.append(obj.get("name", "unknown object"))
			else:
				obj_names.append(str(obj))
		desc += " [Contains: " + ", ".join(obj_names) + "]"
	
	return desc

