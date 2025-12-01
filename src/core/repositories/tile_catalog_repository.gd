extends RefCounted

# Tile Catalog Repository - Loads and provides access to tile metadata
# Used for programmatic tile placement and LLM world context descriptions

const DATA_PATH = "res://src/data/tile_catalog.json"

var _sources: Dictionary = {}
var _tiles: Dictionary = {}
var _terrain_descriptions: Dictionary = {}
var _tile_size: int = 48

func _init():
	_load_data()

func _load_data():
	if not FileAccess.file_exists(DATA_PATH):
		push_error("TileCatalogRepository: Data file not found: " + DATA_PATH)
		return
	
	var file = FileAccess.open(DATA_PATH, FileAccess.READ)
	if not file:
		push_error("TileCatalogRepository: Could not open data file")
		return
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK:
		push_error("TileCatalogRepository: JSON parse error: " + json.get_error_message())
		return
	
	var data = json.data
	
	if data.has("_tile_size"):
		_tile_size = data["_tile_size"]
	
	if data.has("sources"):
		_sources = data["sources"]
	
	if data.has("tiles"):
		_tiles = data["tiles"]
	
	if data.has("terrain_descriptions"):
		_terrain_descriptions = data["terrain_descriptions"]
	
	print("TileCatalogRepository: Loaded ", _count_tiles(), " tiles from catalog")

func _count_tiles() -> int:
	var count = 0
	for category in _tiles.values():
		count += category.size()
	return count

# Get source ID by name (e.g., "A5" -> 0)
func get_source_id(source_name: String) -> int:
	if _sources.has(source_name):
		return _sources[source_name].get("id", -1)
	return -1

# Get a specific tile by category and name
func get_tile(category: String, tile_name: String) -> Dictionary:
	if _tiles.has(category) and _tiles[category].has(tile_name):
		var tile = _tiles[category][tile_name].duplicate()
		# Add the source_id for convenience
		tile["source_id"] = get_source_id(tile.get("source", ""))
		return tile
	return {}

# Get tile atlas coordinates as Vector2i
func get_tile_coords(category: String, tile_name: String) -> Vector2i:
	var tile = get_tile(category, tile_name)
	if tile.is_empty():
		return Vector2i(-1, -1)
	return Vector2i(tile.get("x", 0), tile.get("y", 0))

# Get all tiles in a category
func get_tiles_in_category(category: String) -> Dictionary:
	if _tiles.has(category):
		return _tiles[category]
	return {}

# Get all tiles with a specific tag
func get_tiles_with_tag(tag: String) -> Array:
	var result = []
	for category_name in _tiles.keys():
		for tile_name in _tiles[category_name].keys():
			var tile = _tiles[category_name][tile_name]
			if tile.has("tags") and tag in tile["tags"]:
				var tile_copy = tile.duplicate()
				tile_copy["category"] = category_name
				tile_copy["tile_name"] = tile_name
				tile_copy["source_id"] = get_source_id(tile.get("source", ""))
				result.append(tile_copy)
	return result

# Get terrain description for LLM context
func get_terrain_description(terrain_type: String) -> String:
	return _terrain_descriptions.get(terrain_type, "")

# Get description of a specific tile for LLM context
func get_tile_description(category: String, tile_name: String) -> String:
	var tile = get_tile(category, tile_name)
	return tile.get("description", "")

# Get all walkable ground tiles
func get_walkable_ground_tiles() -> Array:
	return get_tiles_with_tag("walkable")

# Get all obstacle tiles
func get_obstacle_tiles() -> Array:
	return get_tiles_with_tag("obstacle")

# Check if a tile is walkable
func is_tile_walkable(category: String, tile_name: String) -> bool:
	var tile = get_tile(category, tile_name)
	if tile.is_empty():
		return false
	return "walkable" in tile.get("tags", [])

# Generate a description of an area based on tile types present
func describe_area(tile_types: Array) -> String:
	var descriptions = []
	for tile_type in tile_types:
		if tile_type is Dictionary:
			var desc = tile_type.get("description", "")
			if desc and desc not in descriptions:
				descriptions.append(desc)
	
	if descriptions.is_empty():
		return "An unremarkable area."
	
	return ". ".join(descriptions) + "."

