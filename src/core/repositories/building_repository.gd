extends RefCounted

# Building Repository
# Loads and manages building definitions from buildings.json

const BUILDINGS_PATH = "res://src/data/buildings.json"

var _building_types: Dictionary = {}
var _buildings: Dictionary = {}
var _exterior_templates: Dictionary = {}

func _init():
	load_buildings()

func load_buildings() -> bool:
	if not FileAccess.file_exists(BUILDINGS_PATH):
		push_error("BuildingRepository: File not found: " + BUILDINGS_PATH)
		return false
	
	var file = FileAccess.open(BUILDINGS_PATH, FileAccess.READ)
	if not file:
		push_error("BuildingRepository: Cannot open " + BUILDINGS_PATH)
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("BuildingRepository: JSON parse error: " + json.get_error_message())
		return false
	
	var data = json.get_data()
	
	_building_types = data.get("building_types", {})
	_buildings = data.get("buildings", {})
	_exterior_templates = data.get("exterior_tile_templates", {})
	
	print("BuildingRepository: Loaded ", _buildings.size(), " buildings")
	return true

func get_building(building_id: String) -> Dictionary:
	return _buildings.get(building_id, {})

func get_all_buildings() -> Dictionary:
	return _buildings

func get_building_type(type_name: String) -> Dictionary:
	return _building_types.get(type_name, {})

func get_exterior_template(template_name: String) -> Dictionary:
	return _exterior_templates.get(template_name, {})

func get_building_ids() -> Array:
	return _buildings.keys()

func get_entry_point(building_id: String, entry_name: String = "default") -> Dictionary:
	var building = get_building(building_id)
	if building.is_empty():
		return {}
	
	var entry_points = building.get("entry_points", {})
	if entry_points.has(entry_name):
		return entry_points[entry_name]
	elif entry_points.has("default"):
		return entry_points["default"]
	
	return {}

func get_interior_layout(building_id: String) -> Dictionary:
	var building = get_building(building_id)
	return building.get("interior", {})

func get_environmental_state(building_id: String) -> Dictionary:
	var building = get_building(building_id)
	return building.get("environmental_state", {})

func get_building_context(building_id: String, time_of_day: String = "afternoon") -> Dictionary:
	var building = get_building(building_id)
	if building.is_empty():
		return {}
	
	var env_state = building.get("environmental_state", {})
	var time_desc = env_state.get("time_of_day_description", {})
	
	return {
		"id": building_id,
		"name": building.get("name", "Unknown"),
		"type": building.get("type", "building"),
		"description": building.get("description", ""),
		"lighting": env_state.get("lighting", "natural"),
		"atmosphere": env_state.get("noise_level", "quiet"),
		"smell": env_state.get("smell", ""),
		"current_time_description": time_desc.get(time_of_day, ""),
		"furniture": building.get("interior", {}).get("furniture", [])
	}

