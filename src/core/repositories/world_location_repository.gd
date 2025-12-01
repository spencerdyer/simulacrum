extends RefCounted

# World Locations Repository
# Manages locations in the game world (towns, buildings, rooms, etc.)
# 
# Location types: settlement, area, tavern, shop, house, church, room
#
# Building locations include:
#   - floor_layout: 2D array of tile IDs for interior
#   - entry_points: Dictionary of door positions {name: {x, y, facing}}
#   - exterior_tiles: Tile data for world map appearance
#   - environmental_state: Dynamic state for LLM context

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

func get_by_type(type: String) -> Array:
	var result = []
	for loc in get_all():
		if loc.get("type") == type:
			result.append(loc)
	return result

func get_buildings() -> Array:
	var building_types = ["tavern", "shop", "house", "church"]
	var result = []
	for loc in get_all():
		if loc.get("type") in building_types:
			result.append(loc)
	return result

func create(data: Dictionary) -> String:
	var id = data.get("id", "loc_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000))
	var now = _get_timestamp()
	
	var location = {
		"id": id,
		"parent_id": data.get("parent_id", ""),
		"name": data.get("name", "Unknown Location"),
		"type": data.get("type", "area"),
		"description": data.get("description", ""),
		"features": data.get("features", []),
		"owner_id": data.get("owner_id", ""),
		
		# Building-specific fields
		"floor_layout": data.get("floor_layout", {}),
		"entry_points": data.get("entry_points", {}),
		"exterior_tiles": data.get("exterior_tiles", {}),
		"exterior_position": data.get("exterior_position", {}),
		
		# Dynamic state
		"environmental_state": data.get("environmental_state", {}),
		"saved_state": data.get("saved_state", {}),
		
		# Contents
		"npcs_present": data.get("npcs_present", []),
		"objects": data.get("objects", []),
		"furniture": data.get("furniture", []),
		
		"created_at": now,
		"updated_at": now
	}
	
	get_all().append(location)
	_store.save_data()
	return id

func update(location: Dictionary):
	# In-memory update is automatic, just save
	location["updated_at"] = _get_timestamp()
	_store.save_data()

func update_by_id(id: String, updates: Dictionary):
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

# ============================================================================
# Building-specific methods
# ============================================================================

func get_entry_point(location_id: String, entry_name: String = "default") -> Dictionary:
	var loc = get_by_id(location_id)
	if loc.is_empty():
		return {}
	
	var entry_points = loc.get("entry_points", {})
	if entry_points.has(entry_name):
		return entry_points[entry_name]
	elif entry_points.has("default"):
		return entry_points["default"]
	return {}

func get_floor_layout(location_id: String) -> Dictionary:
	var loc = get_by_id(location_id)
	return loc.get("floor_layout", {})

func set_floor_layout(location_id: String, layout: Dictionary):
	update_by_id(location_id, {"floor_layout": layout})

func get_exterior_position(location_id: String) -> Vector2:
	var loc = get_by_id(location_id)
	var pos = loc.get("exterior_position", {})
	return Vector2(pos.get("x", 0), pos.get("y", 0))

func update_environmental_state(location_id: String, state_updates: Dictionary):
	var loc = get_by_id(location_id)
	if loc.is_empty():
		return
	
	var current_state = loc.get("environmental_state", {})
	for key in state_updates.keys():
		current_state[key] = state_updates[key]
	
	update_by_id(location_id, {"environmental_state": current_state})

# ============================================================================
# LLM Context methods
# ============================================================================

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

func get_full_context(location_id: String) -> Dictionary:
	"""Get comprehensive location data for LLM context"""
	var loc = get_by_id(location_id)
	if loc.is_empty():
		return {}
	
	# Get parent location for context
	var parent_name = ""
	var parent_id = loc.get("parent_id", "")
	if parent_id:
		var parent = get_by_id(parent_id)
		parent_name = parent.get("name", "")
	
	# Get child locations
	var children = get_children(location_id)
	var child_names = []
	for child in children:
		child_names.append(child.get("name", "Unknown"))
	
	return {
		"id": location_id,
		"name": loc.get("name", "Unknown"),
		"type": loc.get("type", "area"),
		"description": loc.get("description", ""),
		"features": loc.get("features", []),
		"parent_location": parent_name,
		"connected_areas": child_names,
		"environmental_state": loc.get("environmental_state", {}),
		"furniture": loc.get("furniture", []),
		"objects": loc.get("objects", [])
	}

func get_location_hierarchy(location_id: String) -> Array:
	"""Get the full hierarchy path from root to this location"""
	var hierarchy = []
	var current_id = location_id
	
	while current_id:
		var loc = get_by_id(current_id)
		if loc.is_empty():
			break
		hierarchy.insert(0, {
			"id": current_id,
			"name": loc.get("name", "Unknown"),
			"type": loc.get("type", "area")
		})
		current_id = loc.get("parent_id", "")
	
	return hierarchy

